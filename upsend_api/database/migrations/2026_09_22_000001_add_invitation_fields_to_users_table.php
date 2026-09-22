<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            if (!Schema::hasColumn('users', 'invitation_token')) {
                $table->string('invitation_token', 64)->nullable()->index();
            }
            if (!Schema::hasColumn('users', 'invitation_expires_at')) {
                $table->timestamp('invitation_expires_at')->nullable();
            }
            if (!Schema::hasColumn('users', 'invited_at')) {
                $table->timestamp('invited_at')->nullable();
            }
            if (!Schema::hasColumn('users', 'password_reset_token')) {
                $table->string('password_reset_token', 64)->nullable()->index();
            }
            if (!Schema::hasColumn('users', 'password_reset_expires_at')) {
                $table->timestamp('password_reset_expires_at')->nullable();
            }
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            foreach ([
                'invitation_token',
                'invitation_expires_at',
                'invited_at',
                'password_reset_token',
                'password_reset_expires_at',
            ] as $column) {
                if (Schema::hasColumn('users', $column)) {
                    $table->dropColumn($column);
                }
            }
        });
    }
};
