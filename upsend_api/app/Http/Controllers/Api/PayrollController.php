<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Payroll;
use App\Services\PayrollCalculationService;
use Illuminate\Http\Request;

class PayrollController extends Controller
{
    public function show(
        Request $request,
        PayrollCalculationService $calculationService,
        int $year,
        int $month,
    )
    {
        abort_unless($month >= 1 && $month <= 12, 422, 'Bulan payroll tidak valid.');

        $period = sprintf('%04d-%02d-01', $year, $month);
        $payroll = Payroll::where('user_id', $request->user()->id)
            ->whereDate('payroll_period', $period)
            ->first();

        if (!$payroll) {
            return response()->json([
                'message' => 'Slip gaji untuk periode tersebut belum tersedia.',
            ], 404);
        }

        $calculation = $calculationService->calculate($payroll, $year, $month);

        return response()->json([
            'id' => $payroll->id,
            'period' => $payroll->payroll_period->format('Y-m-d'),
            'employee' => [
                'name' => $request->user()->name,
                'employee_id' => $request->user()->employee_id,
            ],
            'bank_name' => $payroll->bank_name,
            'bank_account_name' => $payroll->bank_account_name,
            'bank_account_number' => $payroll->bank_account_number,
            'basic_salary' => (float) $payroll->basic_salary,
            'transport_allowance' => (float) $payroll->transport_allowance,
            'meal_allowance' => (float) $payroll->meal_allowance,
            'attendance_allowance' => (float) $payroll->attendance_allowance,
            'other_allowance' => (float) $payroll->other_allowance,
            'tax_deduction' => (float) $payroll->tax_deduction,
            'other_deduction' => (float) $payroll->other_deduction,
            'total_allowance' => $payroll->total_allowance,
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
    }
}
