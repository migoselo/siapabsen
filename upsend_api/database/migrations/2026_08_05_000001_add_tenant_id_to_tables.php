<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

class AddTenantIdToTables extends Migration
{
    public function up()
    {
        // Tambahkan nama tabel yang perlu tenant_id sesuai diagram Anda
        $tables = [
            'tenants', // biasanya sudah ada, tapi aman dicantumkan
            'departments',
            'users',
            'locations',
            'leave_types',
            'leave_balances',
            'leave_requests',
            'leave_request_logs',
            'attendances',
            // tambahkan tabel lain jika diperlukan
        ];

        foreach ($tables as $tableName) {
            if (!Schema::hasTable($tableName)) {
                // skip jika tabel belum ada (aman)
                continue;
            }

            Schema::table($tableName, function (Blueprint $table) use ($tableName) {
                // hanya tambahkan jika belum ada kolom tenant_id
                if (!Schema::hasColumn($tableName, 'tenant_id')) {
                    $table->unsignedBigInteger('tenant_id')->nullable()->index()->after('id');

                    // NOTE: menambahkan foreign key bisa gagal jika constraints naming berbeda
                    // Kita coba tambahkan FK, tapi jika DB tidak mengizinkan, Anda bisa hapus/comment baris ini.
                    try {
                        $table->foreign('tenant_id')
                            ->references('id')
                            ->on('tenants')
                            ->onDelete('set null');
                    } catch (\Exception $e) {
                        // jika gagal, biarkan kolom tanpa FK agar migrasi tetap aman
                    }
                }
            });
        }
    }

    public function down()
    {
        $tables = [
            'attendances',
            'leave_request_logs',
            'leave_requests',
            'leave_balances',
            'leave_types',
            'locations',
            'users',
            'departments',
            'tenants',
        ];

        foreach ($tables as $tableName) {
            if (!Schema::hasTable($tableName) || !Schema::hasColumn($tableName, 'tenant_id')) {
                continue;
            }

            Schema::table($tableName, function (Blueprint $table) {
                // drop foreign key if exists — menggunakan array nama kolom agar Laravel menemukannya
                try {
                    $table->dropForeign(['tenant_id']);
                } catch (\Exception $e) {
                    // ignore jika nama foreign key berbeda atau tidak ada
                }

                // drop index if exists
                try {
                    $table->dropIndex(['tenant_id']);
                } catch (\Exception $e) {
                    // ignore
                }

                // drop column
                try {
                    $table->dropColumn('tenant_id');
                } catch (\Exception $e) {
                    // ignore
                }
            });
        }
    }
}