<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        if (!Schema::hasTable('leave_requests')) {
            Schema::create('leave_requests', function (Blueprint $table) {
                $table->id();
                $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
                $table->string('type');
                $table->date('start_date');
                $table->date('end_date');
                $table->integer('total_days')->default(0);
                $table->text('reason');
                $table->string('attachment_path')->nullable();
                $table->string('status')->default('pending');
                $table->timestamps();
            });

            return;
        }

        Schema::table('leave_requests', function (Blueprint $table) {
            if (!Schema::hasColumn('leave_requests', 'user_id')) {
                $table->foreignId('user_id')->nullable()->constrained('users')->cascadeOnDelete();
            }
            if (!Schema::hasColumn('leave_requests', 'type')) {
                $table->string('type')->nullable();
            }
            if (!Schema::hasColumn('leave_requests', 'start_date')) {
                $table->date('start_date')->nullable();
            }
            if (!Schema::hasColumn('leave_requests', 'end_date')) {
                $table->date('end_date')->nullable();
            }
            if (!Schema::hasColumn('leave_requests', 'reason')) {
                $table->text('reason')->nullable();
            }
            if (!Schema::hasColumn('leave_requests', 'attachment_path')) {
                $table->string('attachment_path')->nullable();
            }
            if (!Schema::hasColumn('leave_requests', 'status')) {
                $table->string('status')->default('pending');
            }
            if (!Schema::hasColumn('leave_requests', 'total_days')) {
                $table->integer('total_days')->default(0);
            }
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('leave_requests');
    }
};
