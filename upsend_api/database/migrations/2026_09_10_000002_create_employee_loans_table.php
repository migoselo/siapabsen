<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasTable('employee_loans')) {
            return;
        }

        Schema::create('employee_loans', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('tenant_id')->nullable()->index();
            $table->unsignedInteger('user_id')->index();
            $table->string('loan_type')->default('bank_installment');
            $table->decimal('total_amount', 15, 2);
            $table->decimal('installment_amount', 15, 2);
            $table->unsignedInteger('remaining_term')->default(0);
            $table->decimal('remaining_amount', 15, 2)->default(0);
            $table->string('status')->default('ACTIVE');
            $table->date('started_on')->nullable();
            $table->date('ends_on')->nullable();
            $table->timestamps();

            $table->index(['user_id', 'status']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('employee_loans');
    }
};
