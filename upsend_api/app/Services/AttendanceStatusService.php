<?php

namespace App\Services;

use App\Models\Attendance;
use App\Models\LeaveRequest;
use Carbon\Carbon;

class AttendanceStatusService
{
    public function determine(Attendance $attendance, ?Carbon $referenceTime = null): string
    {
        $checkIn = $attendance->check_in_time;
        if ($checkIn === null) {
            return 'tepat_waktu';
        }

        $location = $attendance->location;
        $workStart = $this->timeOnDate(
            $checkIn,
            $location?->work_start_time ?? '09:15:00',
        );
        $workEnd = $this->timeOnDate(
            $checkIn,
            $location?->work_end_time ?? '17:00:00',
        );

        if ($checkIn->greaterThan($workStart)) {
            return 'telat';
        }

        $checkOut = $attendance->check_out_time;
        if ($checkOut === null) {
            $now = $referenceTime ?? now();
            return $now->greaterThan($workEnd) ? 'lupa_absen' : 'tepat_waktu';
        }

        if ($checkOut->greaterThan($workEnd) && $this->hasValidOvertime(
            $attendance,
            $checkOut,
        )) {
            return 'lembur';
        }

        if ($checkOut->greaterThan($workEnd)) {
            return 'lupa_absen';
        }

        return 'tepat_waktu';
    }

    private function hasValidOvertime(Attendance $attendance, Carbon $checkOut): bool
    {
        $date = $attendance->check_in_time->toDateString();

        return LeaveRequest::query()
            ->where('user_id', $attendance->employee_id)
            ->whereRaw('LOWER(type) = ?', ['lembur'])
            ->where('status', 'approved')
            ->whereDate('start_date', '<=', $date)
            ->whereDate('end_date', '>=', $date)
            ->whereNotNull('start_time')
            ->whereNotNull('end_time')
            ->get()
            ->contains(function (LeaveRequest $request) use ($attendance, $checkOut): bool {
                $start = $this->timeOnDate($attendance->check_in_time, $request->start_time);
                return $checkOut->greaterThanOrEqualTo($start);
            });
    }

    private function timeOnDate(Carbon $date, string $time): Carbon
    {
        return Carbon::createFromFormat(
            'Y-m-d H:i:s',
            $date->toDateString() . ' ' . $this->normaliseTime($time),
            $date->getTimezone(),
        );
    }

    private function normaliseTime(string $time): string
    {
        $time = trim($time);
        if (str_contains($time, '.')) {
            $time = explode('.', $time, 2)[0];
        }

        return strlen($time) === 5 ? $time . ':00' : $time;
    }
}
