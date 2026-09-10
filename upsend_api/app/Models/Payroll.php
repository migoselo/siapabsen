<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use App\Models\Traits\HasTenant;

class Payroll extends Model
{
    use HasTenant;

    protected $fillable = [
        'tenant_id',
        'user_id',
        'payroll_period',
        'basic_salary',
        'transport_allowance',
        'meal_allowance',
        'attendance_allowance',
        'other_allowance',
        'tax_deduction',
        'other_deduction',
        'bank_name',
        'bank_account_name',
        'bank_account_number',
    ];

    protected $casts = [
        'payroll_period' => 'date:Y-m-d',
        'basic_salary' => 'decimal:2',
        'transport_allowance' => 'decimal:2',
        'meal_allowance' => 'decimal:2',
        'attendance_allowance' => 'decimal:2',
        'other_allowance' => 'decimal:2',
        'tax_deduction' => 'decimal:2',
        'other_deduction' => 'decimal:2',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function getTotalAllowanceAttribute(): float
    {
        return (float) $this->transport_allowance
            + (float) $this->meal_allowance
            + (float) $this->attendance_allowance
            + (float) $this->other_allowance;
    }

    public function getTotalIncomeAttribute(): float
    {
        return (float) $this->basic_salary + $this->total_allowance;
    }

    public function getTotalDeductionAttribute(): float
    {
        return (float) $this->tax_deduction + (float) $this->other_deduction;
    }

    public function getNetSalaryAttribute(): float
    {
        return $this->total_income - $this->total_deduction;
    }
}
