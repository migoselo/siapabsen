<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (!Schema::hasColumn('payrolls', 'performance_allowance')) {
            Schema::table('payrolls', function (Blueprint $table): void {
                $table->decimal('performance_allowance', 15, 2)->default(0)->after('meal_allowance');
            });
        }
    }

    public function down(): void
    {
        if (Schema::hasColumn('payrolls', 'performance_allowance')) {
            Schema::table('payrolls', function (Blueprint $table): void {
                $table->dropColumn('performance_allowance');
            });
        }
    }
};