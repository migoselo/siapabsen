<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;
use App\Models\User;

return new class extends Migration
{
    public function up(): void
    {
        $users = DB::table('users')->whereNull('employee_id')->get();

        foreach ($users as $user) {
            $employeeId = User::generateEmployeeId((int) $user->tenant_id);

            DB::table('users')
                ->where('id', $user->id)
                ->update(['employee_id' => $employeeId]);
        }
    }

    public function down(): void
    {
        // Backfill tidak reversible dengan aman — dikosongkan
    }
};