<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (!Schema::hasTable('locations')) {
            return;
        }

        Schema::table('locations', function (Blueprint $table): void {
            if (!Schema::hasColumn('locations', 'work_start_time')) {
                $table->time('work_start_time')->default('09:15:00');
            }
            if (!Schema::hasColumn('locations', 'work_end_time')) {
                $table->time('work_end_time')->default('17:00:00');
            }
        });
    }

    public function down(): void
    {
        if (!Schema::hasTable('locations')) {
            return;
        }

        Schema::table('locations', function (Blueprint $table): void {
            $columns = [];
            if (Schema::hasColumn('locations', 'work_start_time')) {
                $columns[] = 'work_start_time';
            }
            if (Schema::hasColumn('locations', 'work_end_time')) {
                $columns[] = 'work_end_time';
            }
            if ($columns !== []) {
                $table->dropColumn($columns);
            }
        });
    }
};