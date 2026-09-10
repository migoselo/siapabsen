<?php

namespace App\Services;

use App\Models\Attendance;
use App\Models\LeaveRequest;
use App\Models\Payroll;
use Carbon\Carbon;
use Illuminate\Support\Facades\DB;

class PayrollCalculationService
{
    public function calculate(Payroll $payroll, int $year, int $month): array
    {
        $timezone = config('app.timezone');
        $periodStart = Carbon::create($year, $month, 1, 0, 0, 0, $timezone);
        $periodEnd = $periodStart->copy()->endOfMonth();
        $today = Carbon::now($timezone);
        if ($periodEnd->isFuture()) {
            $periodEnd = $today->copy()->endOfDay();
        }
        $attendance = Attendance::with('location')
            ->where('employee_id', $payroll->user_id)
            ->whereBetween('check_in_time', [$periodStart, $periodEnd])
            ->get();

        $registeredAt = $payroll->user?->created_at;
        $calculationStart = $registeredAt?->copy()->setTimezone($timezone)->startOfDay() ?? $periodStart;
        $calculationStart = $calculationStart->lessThan($periodStart) ? $periodStart : $calculationStart;
        $calculationStart->setTimezone($timezone);
        $effectiveWorkDays = $this->effectiveWorkDays($calculationStart, $periodEnd);
        $attendedDates = $attendance
            ->filter(function (Attendance $item): bool {
                return $item->check_in_time !== null
                    && !in_array(strtolower((string) $item->status), ['alpha', 'mangkir', 'bolos'], true);
            })
            ->map(fn (Attendance $item): string => $item->check_in_time
                ->copy()
                ->setTimezone($timezone)
                ->toDateString())
            ->unique()
            ->values();
        $approvedLeaveDates = $this->approvedLeaveDates(
            $payroll->user_id,
            $periodStart,
            $periodEnd,
        );
        $coveredDates = $attendedDates->merge($approvedLeaveDates)->unique();
        $absenceDays = max(0, $effectiveWorkDays - $coveredDates->count());
        $absenceDeduction = $effectiveWorkDays > 0
            ? ($absenceDays / $effectiveWorkDays) * (float) $payroll->basic_salary
            : 0;

        $lateMinutes = 0;
        $lateDeduction = 0;
        foreach ($attendance->groupBy(fn (Attendance $item): string => $item->check_in_time
            ->copy()
            ->setTimezone($timezone)
            ->toDateString()) as $dailyAttendance) {
            $item = $dailyAttendance->sortBy('check_in_time')->first();
            if (!$item->check_in_time) {
                continue;
            }

            $workStart = $this->workStart($item);
            $checkIn = $item->check_in_time->copy()->setTimezone($workStart->getTimezone());
            $minutesLate = max(0, (int) round($workStart->diffInMinutes($checkIn, false)));
            $lateMinutes += $minutesLate;
            $lateDeduction += $this->lateDeduction(
                $minutesLate,
                (float) $payroll->basic_salary,
                $effectiveWorkDays,
            );
        }

        $loanDeduction = DB::table('employee_loans')
            ->where('user_id', $payroll->user_id)
            ->where('status', 'ACTIVE')
            ->get()
            ->sum(fn (object $loan): float => min(
                (float) $loan->installment_amount,
                max(0, (float) $loan->remaining_amount),
            ));

        $totalIncome = (float) $payroll->total_income;
        $totalDeduction = (float) $payroll->tax_deduction
            + (float) $payroll->other_deduction
            + $absenceDeduction
            + $lateDeduction
            + $loanDeduction;

        return [
            'absence_days' => $absenceDays,
            'effective_work_days' => $effectiveWorkDays,
            'absence_deduction' => round($absenceDeduction, 2),
            'late_minutes' => $lateMinutes,
            'late_deduction' => round($lateDeduction, 2),
            'loan_deduction' => round($loanDeduction, 2),
            'total_income' => $totalIncome,
            'total_deduction' => round($totalDeduction, 2),
            'net_salary' => round($totalIncome - $totalDeduction, 2),
        ];
    }

    private function effectiveWorkDays(Carbon $start, Carbon $end): int
    {
        $days = 0;
        for ($date = $start->copy(); $date->lte($end); $date->addDay()) {
            if ($date->isWeekday()) {
                $days++;
            }
        }

        return $days;
    }

    private function workStart(Attendance $attendance): Carbon
    {
        $time = $attendance->location?->work_start_time ?? '09:15:00';
        if (str_contains($time, '.')) {
            $time = explode('.', $time, 2)[0];
        }
        $time = strlen($time) === 5 ? $time . ':00' : $time;

        $checkIn = $attendance->check_in_time->copy()->setTimezone(config('app.timezone'));

        return Carbon::createFromFormat(
            'Y-m-d H:i:s',
            $checkIn->toDateString() . ' ' . $time,
            $checkIn->getTimezone(),
        );
    }

    private function approvedLeaveDates(int $userId, Carbon $start, Carbon $end): array
    {
        $dates = [];
        $leaves = LeaveRequest::query()
            ->where('user_id', $userId)
            ->where('status', 'approved')
            ->whereDate('start_date', '<=', $end)
            ->whereDate('end_date', '>=', $start)
            ->get(['start_date', 'end_date']);

        foreach ($leaves as $leave) {
            $leaveStart = Carbon::parse($leave->start_date)->max($start);
            $leaveEnd = Carbon::parse($leave->end_date)->min($end);
            for ($date = $leaveStart->copy(); $date->lte($leaveEnd); $date->addDay()) {
                if ($date->isWeekday()) {
                    $dates[] = $date->toDateString();
                }
            }
        }

        return array_values(array_unique($dates));
    }

    private function lateDeduction(int $minutesLate, float $basicSalary, int $effectiveWorkDays): float
    {
        return match (true) {
            $minutesLate <= 15 => 0,
            $minutesLate <= 60 => 25000,
            $minutesLate > 60 && $effectiveWorkDays > 0 => $basicSalary / $effectiveWorkDays / 2,
            default => 0,
        };
    }
}
