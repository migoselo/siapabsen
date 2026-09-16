<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (! Schema::hasTable('users')) {
            return;
        }

        Schema::table('users', function (Blueprint $table) {
            $columns = [
                'department' => fn () => $table->string('department')->nullable(),
                'grade' => fn () => $table->string('grade')->nullable(),
                'employee_type' => fn () => $table->string('employee_type')->nullable(),
                'joined_at' => fn () => $table->date('joined_at')->nullable(),
                'nik' => fn () => $table->string('nik')->nullable(),
                'birth_place' => fn () => $table->string('birth_place')->nullable(),
                'birth_date' => fn () => $table->date('birth_date')->nullable(),
                'gender' => fn () => $table->string('gender')->nullable(),
                'religion' => fn () => $table->string('religion')->nullable(),
                'blood_type' => fn () => $table->string('blood_type', 3)->nullable(),
                'marital_status' => fn () => $table->string('marital_status')->nullable(),
                'address' => fn () => $table->text('address')->nullable(),
                'emergency_contact' => fn () => $table->string('emergency_contact')->nullable(),
                'bank_name' => fn () => $table->string('bank_name')->nullable(),
                'bank_account_number' => fn () => $table->string('bank_account_number')->nullable(),
                'bank_account_name' => fn () => $table->string('bank_account_name')->nullable(),
                'tax_number' => fn () => $table->string('tax_number')->nullable(),
                'bpjs_employment' => fn () => $table->string('bpjs_employment')->nullable(),
                'bpjs_health' => fn () => $table->string('bpjs_health')->nullable(),
                'last_education' => fn () => $table->string('last_education')->nullable(),
                'education_institution' => fn () => $table->string('education_institution')->nullable(),
                'certification' => fn () => $table->text('certification')->nullable(),
                'spouse_name' => fn () => $table->string('spouse_name')->nullable(),
                'father_name' => fn () => $table->string('father_name')->nullable(),
                'mother_name' => fn () => $table->string('mother_name')->nullable(),
                'children_count' => fn () => $table->unsignedTinyInteger('children_count')->nullable(),
            ];

            foreach ($columns as $name => $definition) {
                if (! Schema::hasColumn('users', $name)) {
                    $definition();
                }
            }
        });
    }

    public function down(): void
    {
        if (! Schema::hasTable('users')) {
            return;
        }

        $columns = [
            'department', 'grade', 'employee_type', 'joined_at', 'nik',
            'birth_place', 'birth_date', 'gender', 'religion', 'blood_type',
            'marital_status', 'address', 'emergency_contact', 'bank_name',
            'bank_account_number', 'bank_account_name', 'tax_number',
            'bpjs_employment', 'bpjs_health', 'last_education',
            'education_institution', 'certification', 'spouse_name',
            'father_name', 'mother_name', 'children_count',
        ];

        Schema::table('users', function (Blueprint $table) use ($columns) {
            foreach ($columns as $column) {
                if (Schema::hasColumn('users', $column)) {
                    $table->dropColumn($column);
                }
            }
        });
    }
};