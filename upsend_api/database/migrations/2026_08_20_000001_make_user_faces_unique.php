<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (!Schema::hasTable('user_faces')) {
            return;
        }

        $duplicateUserIds = DB::table('user_faces')
            ->select('user_id')
            ->groupBy('user_id')
            ->havingRaw('COUNT(*) > 1')
            ->pluck('user_id');

        foreach ($duplicateUserIds as $userId) {
            $keepId = DB::table('user_faces')
                ->where('user_id', $userId)
                ->orderByDesc('id')
                ->value('id');

            DB::table('user_faces')
                ->where('user_id', $userId)
                ->where('id', '!=', $keepId)
                ->delete();
        }

        Schema::table('user_faces', function (Blueprint $table): void {
            $table->unique('user_id', 'user_faces_user_id_unique');
        });
    }

    public function down(): void
    {
        if (!Schema::hasTable('user_faces')) {
            return;
        }

        Schema::table('user_faces', function (Blueprint $table): void {
            $table->dropUnique('user_faces_user_id_unique');
        });
    }
};
