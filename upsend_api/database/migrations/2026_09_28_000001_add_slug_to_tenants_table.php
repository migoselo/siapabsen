<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Str;

return new class extends Migration
{
    public function up(): void
    {
        if (! Schema::hasTable('tenants') || Schema::hasColumn('tenants', 'slug')) {
            return;
        }

        Schema::table('tenants', function (Blueprint $table) {
            $table->string('slug')->nullable();
        });

        foreach (DB::table('tenants')->select('id', 'name')->orderBy('id')->get() as $tenant) {
            $baseSlug = Str::slug($tenant->name) ?: 'tenant';
            $slug = $baseSlug;
            $suffix = 1;

            while (DB::table('tenants')->where('slug', $slug)->exists()) {
                $slug = $baseSlug . '-' . $tenant->id . ($suffix > 1 ? '-' . $suffix : '');
                $suffix++;
            }

            DB::table('tenants')->where('id', $tenant->id)->update(['slug' => $slug]);
        }

        Schema::table('tenants', function (Blueprint $table) {
            $table->unique('slug');
        });
    }

    public function down(): void
    {
        // Keep repaired tenant identifiers when rolling back unrelated migrations.
    }
};