<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasTable('tenants') && !Schema::hasColumn('tenants', 'alpha_deduction_per_day')) {
            Schema::table('tenants', function (Blueprint $table) {
                $table->decimal('alpha_deduction_per_day', 15, 2)->nullable()->after('status');
            });
        }
    }

    public function down(): void
    {
        if (Schema::hasTable('tenants') && Schema::hasColumn('tenants', 'alpha_deduction_per_day')) {
            Schema::table('tenants', function (Blueprint $table) {
                $table->dropColumn('alpha_deduction_per_day');
            });
        }
    }
};
