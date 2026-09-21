<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Payroll;
use App\Models\User;
use App\Services\PayrollCalculationService;
use Carbon\Carbon;
use Illuminate\Http\Request;

class PayrollController extends Controller
{
    public function index(Request $request)
    {
        $monthValue = $request->string('month', now()->format('Y-m'))->toString();
        $month = Carbon::createFromFormat('Y-m', $monthValue);
        $periodStart = $month->copy()->startOfMonth();
        $periodEnd = $month->copy()->endOfMonth();

        $users = User::with(['homeLocation', 'tenant'])
            ->where('tenant_id', $request->user()->tenant_id ?? 1)
            ->orderBy('name')
            ->paginate($request->integer('per_page', 20));

        if ($request->filled('user_id')) {
            $users = User::with(['homeLocation', 'tenant'])
                ->where('tenant_id', $request->user()->tenant_id ?? 1)
                ->whereKey($request->integer('user_id'))
                ->orderBy('name')
                ->paginate($request->integer('per_page', 20));
        }

        $payrolls = Payroll::whereIn('user_id', $users->getCollection()->pluck('id'))
            ->whereBetween('payroll_period', [$periodStart->toDateString(), $periodEnd->toDateString()])
            ->get()
            ->keyBy('user_id');

        $users->getCollection()->transform(function (User $user) use ($payrolls, $periodStart, $monthValue) {
            $payroll = $payrolls->get($user->id);
            if (!$payroll) {
                $payroll = new Payroll([
                    'user_id' => $user->id,
                    'payroll_period' => $periodStart->toDateString(),
                ]);
            }
            $payroll->setRelation('user', $user);

            $calculation = app(PayrollCalculationService::class)->calculate(
                $payroll,
                (int) substr($monthValue, 0, 4),
                (int) substr($monthValue, 5, 2),
            );

            return array_merge($payroll->toArray(), [
                'id' => $payroll->id,
                'user_id' => $user->id,
                'user' => $user,
                'period' => $payroll->payroll_period?->format('Y-m-d'),
                'absence_days' => $calculation['absence_days'],
                'effective_work_days' => $calculation['effective_work_days'],
                'absence_deduction' => $calculation['absence_deduction'],
                'late_minutes' => $calculation['late_minutes'],
                'late_deduction' => $calculation['late_deduction'],
                'loan_deduction' => $calculation['loan_deduction'],
                'total_income' => $calculation['total_income'],
                'total_deduction' => $calculation['total_deduction'],
                'net_salary' => $calculation['net_salary'],
            ]);
        });

        return response()->json($users);
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'user_id' => 'required|exists:users,id',
            'payroll_period' => 'required|date',
            'basic_salary' => 'nullable|numeric|min:0',
            'transport_allowance' => 'nullable|numeric|min:0',
            'meal_allowance' => 'nullable|numeric|min:0',
            'performance_allowance' => 'nullable|numeric|min:0',
            'attendance_allowance' => 'nullable|numeric|min:0',
            'holiday_allowance' => 'nullable|numeric|min:0',
            'other_allowance' => 'nullable|numeric|min:0',
            'tax_deduction' => 'nullable|numeric|min:0',
            'other_deduction' => 'nullable|numeric|min:0',
            'bank_name' => 'nullable|string|max:255',
            'bank_account_name' => 'nullable|string|max:255',
            'bank_account_number' => 'nullable|string|max:255',
        ]);

        $data['tenant_id'] = $request->user()->tenant_id ?? 1;
        $payroll = Payroll::updateOrCreate(
            ['user_id' => $data['user_id'], 'payroll_period' => $data['payroll_period']],
            $data,
        );

        return response()->json($payroll->load('user.homeLocation'), 201);
    }

    public function update(Request $request, Payroll $payroll)
    {
        $data = $request->validate([
            'user_id' => 'sometimes|exists:users,id',
            'payroll_period' => 'sometimes|date',
            'basic_salary' => 'nullable|numeric|min:0',
            'transport_allowance' => 'nullable|numeric|min:0',
            'meal_allowance' => 'nullable|numeric|min:0',
            'performance_allowance' => 'nullable|numeric|min:0',
            'attendance_allowance' => 'nullable|numeric|min:0',
            'holiday_allowance' => 'nullable|numeric|min:0',
            'other_allowance' => 'nullable|numeric|min:0',
            'tax_deduction' => 'nullable|numeric|min:0',
            'other_deduction' => 'nullable|numeric|min:0',
            'bank_name' => 'nullable|string|max:255',
            'bank_account_name' => 'nullable|string|max:255',
            'bank_account_number' => 'nullable|string|max:255',
        ]);

        $payroll->update($data);

        return response()->json($payroll->load('user.homeLocation'));
    }

    public function show(
        Request $request,
        PayrollCalculationService $calculationService,
        int $year,
        int $month,
    )
    {
        abort_unless($month >= 1 && $month <= 12, 422, 'Bulan payroll tidak valid.');

        $period = sprintf('%04d-%02d-01', $year, $month);
        $user = $request->user();
        $payroll = Payroll::where('user_id', $request->user()->id)
            ->whereDate('payroll_period', $period)
            ->first();

        if (!$payroll) {
            $payroll = new Payroll([
                'user_id' => $user->id,
                'payroll_period' => $period,
            ]);
            $payroll->setRelation('user', $user);
        }

        $calculation = $calculationService->calculate($payroll, $year, $month);

        return response()->json([
            'id' => $payroll->id,
            'has_payroll' => $payroll->exists,
            'period' => $payroll->payroll_period->format('Y-m-d'),
            'employee' => [
                'name' => $request->user()->name,
                'employee_id' => $request->user()->employee_id,
            ],
            'bank_name' => $payroll->exists ? $payroll->bank_name : null,
            'bank_account_name' => $payroll->exists ? $payroll->bank_account_name : null,
            'bank_account_number' => $payroll->exists ? $payroll->bank_account_number : null,
            'basic_salary' => $payroll->exists ? (float) $payroll->basic_salary : null,
            'transport_allowance' => $payroll->exists ? (float) $payroll->transport_allowance : null,
            'meal_allowance' => $payroll->exists ? (float) $payroll->meal_allowance : null,
            'performance_allowance' => $payroll->exists ? (float) $payroll->performance_allowance : null,
            'attendance_allowance' => $payroll->exists ? (float) $payroll->attendance_allowance : null,
            'holiday_allowance' => $payroll->exists ? (float) $payroll->holiday_allowance : null,
            'other_allowance' => $payroll->exists ? (float) $payroll->other_allowance : null,
            'tax_deduction' => $payroll->exists ? (float) $payroll->tax_deduction : null,
            'other_deduction' => $payroll->exists ? (float) $payroll->other_deduction : null,
            'total_allowance' => $payroll->exists ? $payroll->total_allowance : null,
            'absence_days' => $calculation['absence_days'],
            'effective_work_days' => $calculation['effective_work_days'],
            'absence_deduction' => $calculation['absence_deduction'],
            'late_minutes' => $calculation['late_minutes'],
            'late_deduction' => $calculation['late_deduction'],
            'loan_deduction' => $calculation['loan_deduction'],
            'total_income' => $payroll->exists ? $calculation['total_income'] : null,
            'total_deduction' => $payroll->exists ? $calculation['total_deduction'] : null,
            'net_salary' => $payroll->exists ? $calculation['net_salary'] : null,
        ]);
    }
}
