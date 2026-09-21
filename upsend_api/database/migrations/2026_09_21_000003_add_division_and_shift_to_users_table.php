<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (!Schema::hasTable('users')) {
            return;
        }

        Schema::table('users', function (Blueprint $table): void {
            if (!Schema::hasColumn('users', 'division_id')) {
                $table->unsignedBigInteger('division_id')->nullable()->index();
            }
            if (!Schema::hasColumn('users', 'shift_id')) {
                $table->unsignedBigInteger('shift_id')->nullable()->index();
            }
        });
    }

    public function down(): void
    {
        if (!Schema::hasTable('users')) {
            return;
        }

        Schema::table('users', function (Blueprint $table): void {
            if (Schema::hasColumn('users', 'shift_id')) {
                $table->dropColumn('shift_id');
            }
            if (Schema::hasColumn('users', 'division_id')) {
                $table->dropColumn('division_id');
            }
        });
    }
};