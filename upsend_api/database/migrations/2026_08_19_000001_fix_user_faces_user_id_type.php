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

        DB::statement(<<<'SQL'
IF EXISTS (
    SELECT 1
    FROM sys.foreign_keys
    WHERE name = 'user_faces_user_id_foreign'
)
ALTER TABLE user_faces DROP CONSTRAINT user_faces_user_id_foreign
SQL);

        DB::statement(<<<'SQL'
IF EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'user_faces_user_id_index'
      AND object_id = OBJECT_ID('user_faces')
)
DROP INDEX user_faces_user_id_index ON user_faces
SQL);

        Schema::table('user_faces', function (Blueprint $table): void {
            $table->unsignedInteger('user_id')->change();
        });

        Schema::table('user_faces', function (Blueprint $table): void {
            $table->index('user_id');
            $table->foreign('user_id')
                ->references('id')
                ->on('users')
                ->cascadeOnDelete();
        });
    }

    public function down(): void
    {
        if (!Schema::hasTable('user_faces')) {
            return;
        }

        DB::statement(<<<'SQL'
IF EXISTS (
    SELECT 1
    FROM sys.foreign_keys
    WHERE name = 'user_faces_user_id_foreign'
)
ALTER TABLE user_faces DROP CONSTRAINT user_faces_user_id_foreign
SQL);

        Schema::table('user_faces', function (Blueprint $table): void {
            $table->unsignedInteger('user_id')->change();
        });
    }
};
