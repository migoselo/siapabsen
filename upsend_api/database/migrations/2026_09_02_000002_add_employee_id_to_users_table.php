<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (! Schema::hasTable('users')) {
            return;
        }

        if (! Schema::hasColumn('users', 'employee_id')) {
            Schema::table('users', function (Blueprint $table) {
                $table->string('employee_id')->nullable()->after('email');
            });
        }

        try {
            DB::statement('CREATE UNIQUE INDEX UQ_users_tenant_employee_id ON users (tenant_id, employee_id)');
        } catch (\Throwable $exception) {
            // The production database may already contain this index.
        }
    }

    public function down(): void
    {
        if (Schema::hasTable('users') && Schema::hasColumn('users', 'employee_id')) {
            Schema::table('users', function (Blueprint $table) {
                $table->dropColumn('employee_id');
            });
        }
    }
};