<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (!Schema::hasTable('divisions')) {
            Schema::create('divisions', function (Blueprint $table): void {
                $table->id();
                $table->unsignedBigInteger('tenant_id')->index();
                $table->string('name');
                $table->text('description')->nullable();
                $table->boolean('is_active')->default(true);
                $table->timestamps();
                $table->unique(['tenant_id', 'name']);
            });
        }

        if (!Schema::hasTable('shifts')) {
            Schema::create('shifts', function (Blueprint $table): void {
                $table->id();
                $table->unsignedBigInteger('tenant_id')->index();
                $table->unsignedBigInteger('division_id')->nullable()->index();
                $table->string('name');
                $table->time('work_start_time');
                $table->time('work_end_time');
                $table->boolean('is_active')->default(true);
                $table->timestamps();
                $table->foreign('division_id')->references('id')->on('divisions')->nullOnDelete();
            });
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('shifts');
        Schema::dropIfExists('divisions');
    }
};