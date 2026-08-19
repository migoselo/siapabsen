<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (!Schema::hasTable('leave_requests')) {
            return;
        }

        Schema::table('leave_requests', function (Blueprint $table) {
            if (!Schema::hasColumn('leave_requests', 'start_time')) {
                $table->time('start_time')->nullable()->after('end_date');
            }
            if (!Schema::hasColumn('leave_requests', 'end_time')) {
                $table->time('end_time')->nullable()->after('start_time');
            }
        });
    }

    public function down(): void
    {
        if (!Schema::hasTable('leave_requests')) {
            return;
        }

        Schema::table('leave_requests', function (Blueprint $table) {
            $columns = [];
            if (Schema::hasColumn('leave_requests', 'start_time')) {
                $columns[] = 'start_time';
            }
            if (Schema::hasColumn('leave_requests', 'end_time')) {
                $columns[] = 'end_time';
            }
            if ($columns !== []) {
                $table->dropColumn($columns);
            }
        });
    }
};