<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        if (!Schema::hasTable('attendances')) {
            return;
        }

        // If the application already uses 'employee_id' do nothing
        if (Schema::hasColumn('attendances', 'employee_id')) {
            return;
        }

        // Add nullable employee_id column and copy existing user_id values
        if (!Schema::hasColumn('attendances', 'employee_id')) {
            Schema::table('attendances', function (Blueprint $table) {
                $table->unsignedBigInteger('employee_id')->nullable()->after('user_id');
            });

            // Copy values from user_id -> employee_id
            try {
                DB::table('attendances')->update(['employee_id' => DB::raw('user_id')]);
            } catch (\Exception $e) {
                // ignore copy failures (DB specific); user can fix manually
            }

            // Add index and attempt to add foreign key
            Schema::table('attendances', function (Blueprint $table) {
                $table->index('employee_id');
            });

            try {
                Schema::table('attendances', function (Blueprint $table) {
                    $table->foreign('employee_id')->references('id')->on('users')->onDelete('cascade');
                });
            } catch (\Exception $e) {
                // Some DBs or setups may not allow adding FK here; ignore to keep migration safe
            }

            // Optionally drop old user_id column if present
            if (Schema::hasColumn('attendances', 'user_id')) {
                try {
                    Schema::table('attendances', function (Blueprint $table) {
                        $table->dropColumn('user_id');
                    });
                } catch (\Exception $e) {
                    // ignore if DB cannot drop the column automatically
                }
            }
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        if (!Schema::hasTable('attendances')) {
            return;
        }

        // Add user_id back if missing and copy data from employee_id
        if (!Schema::hasColumn('attendances', 'user_id')) {
            Schema::table('attendances', function (Blueprint $table) {
                $table->unsignedBigInteger('user_id')->nullable()->after('id');
            });

            try {
                DB::table('attendances')->update(['user_id' => DB::raw('employee_id')]);
            } catch (\Exception $e) {
                // ignore
            }
        }

        // Drop foreign key and index if they exist, then drop employee_id
        try {
            Schema::table('attendances', function (Blueprint $table) {
                // drop foreign key if exists
                try { $table->dropForeign(['employee_id']); } catch (\Exception $e) {}
                try { $table->dropIndex(['employee_id']); } catch (\Exception $e) {}
                if (Schema::hasColumn('attendances', 'employee_id')) {
                    $table->dropColumn('employee_id');
                }
            });
        } catch (\Exception $e) {
            // ignore errors during rollback
        }
    }
};
