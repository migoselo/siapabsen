<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\LocationController;
use App\Http\Controllers\Api\UserController;
use App\Http\Controllers\Api\AttendanceController;
use App\Http\Controllers\Api\LeaveRequestController;
use App\Http\Controllers\Api\PayrollController;
use App\Http\Controllers\Api\RolePermissionController;
use App\Http\Controllers\Api\ShiftDivisionController;
use App\Http\Controllers\Api\TenantController;
use App\Http\Controllers\Api\Admin\AttendanceAdminController;
use App\Http\Controllers\Api\Admin\DashboardController;
use Illuminate\Support\Facades\Route;



// ==== Auth ====
Route::post('/login', [AuthController::class, 'login']);
Route::post('/login-web', [AuthController::class, 'loginWeb']);  // BARU, dipakai dashboard web (email)
Route::post('/register', [AuthController::class, 'register']);
Route::post('/activate-account', [AuthController::class, 'activateAccount']);
Route::post('/password/forgot', [AuthController::class, 'requestPasswordReset']);
Route::post('/password/reset', [AuthController::class, 'resetPassword']);

Route::get('/locations/public', [LocationController::class, 'publicIndex']);

Route::middleware('auth:sanctum')->group(function () {
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::get('/me', [AuthController::class, 'me']);
    Route::post('/change-password', [AuthController::class, 'changePassword']);

    Route::prefix('face')->group(function () {
        Route::post('/register', [\App\Http\Controllers\Api\FaceRecognitionController::class, 'register']);
        Route::post('/verify', [\App\Http\Controllers\Api\FaceRecognitionController::class, 'verify']);
        Route::get('/status', [\App\Http\Controllers\Api\FaceRecognitionController::class, 'status']);
    });

    // ==== Attendance - sisi karyawan (semua role login bisa akses) ====
    Route::prefix('attendances')->group(function () {
        Route::get('/{attendance}/my-photo', [AttendanceController::class, 'photo']);
        Route::get('/{attendance}/my-checkout-photo', [AttendanceController::class, 'checkoutPhoto']);
        Route::get('/nearby-locations', [AttendanceController::class, 'nearbyLocations']);
        Route::post('/check-in', [AttendanceController::class, 'checkIn']);
        Route::patch('/{attendance}/check-out', [AttendanceController::class, 'checkOut']);
        Route::get('/my-open-session', [AttendanceController::class, 'myOpenSession']);
        Route::get('/my-history', [AttendanceController::class, 'myHistory']);
    });

    Route::get('/leave-requests', [LeaveRequestController::class, 'index'])->middleware('permission:requests.view');
    Route::post('/leave-requests', [LeaveRequestController::class, 'store']);
    Route::delete('/leave-requests/{id}', [LeaveRequestController::class, 'destroy']);
    Route::get('/leave-balances', [LeaveRequestController::class, 'balances']);
    Route::get('/payrolls/{year}/{month}', [PayrollController::class, 'show'])
        ->middleware('permission:payroll.view')
        ->whereNumber(['year', 'month']);

    // ==== Khusus admin ====
    Route::middleware('role:admin,super_admin')->group(function () {
        Route::get('/payrolls', [PayrollController::class, 'index'])->middleware('permission:payroll.view');
        Route::post('/payrolls', [PayrollController::class, 'store'])->middleware('permission:payroll.manage');
        Route::put('/payrolls/{payroll}', [PayrollController::class, 'update'])->middleware('permission:payroll.manage');

        Route::get('/admin/leave-requests', [LeaveRequestController::class, 'adminIndex'])->middleware('permission:requests.view');
        Route::match(['put', 'patch'], '/admin/leave-requests/{leaveRequest}/status', [LeaveRequestController::class, 'updateStatus'])->middleware('permission:requests.review');

        Route::get('/locations', [LocationController::class, 'index'])->middleware('permission:locations.view|employees.view|dashboard.view|attendance.view|requests.view|payroll.view|structure.view');
        Route::post('/locations', [LocationController::class, 'store'])->middleware('permission:locations.manage');
        Route::get('/locations/{location}', [LocationController::class, 'show'])->middleware('permission:locations.view');
        Route::put('/locations/{location}', [LocationController::class, 'update'])->middleware('permission:locations.manage');
        Route::patch('/locations/{location}', [LocationController::class, 'update'])->middleware('permission:locations.manage');
        Route::delete('/locations/{location}', [LocationController::class, 'destroy'])->middleware('permission:locations.manage');

        Route::apiResource('tenants', TenantController::class)->only(['index', 'store', 'show', 'update', 'destroy']);
        Route::get('/divisions', [ShiftDivisionController::class, 'indexDivisions'])->middleware('permission:structure.view');
        Route::post('/divisions', [ShiftDivisionController::class, 'storeDivision'])->middleware('permission:structure.manage');
        Route::put('/divisions/{division}', [ShiftDivisionController::class, 'updateDivision'])->middleware('permission:structure.manage');
        Route::delete('/divisions/{division}', [ShiftDivisionController::class, 'destroyDivision'])->middleware('permission:structure.manage');
        Route::get('/shifts', [ShiftDivisionController::class, 'indexShifts'])->middleware('permission:structure.view');
        Route::post('/shifts', [ShiftDivisionController::class, 'storeShift'])->middleware('permission:structure.manage');
        Route::put('/shifts/{shift}', [ShiftDivisionController::class, 'updateShift'])->middleware('permission:structure.manage');
        Route::delete('/shifts/{shift}', [ShiftDivisionController::class, 'destroyShift'])->middleware('permission:structure.manage');

        Route::get('/users', [UserController::class, 'index'])->middleware('permission:employees.view');
        Route::get('/users/email-availability', [UserController::class, 'checkEmailAvailability'])->middleware('permission:employees.create');
        Route::post('/users', [UserController::class, 'store'])->middleware('permission:employees.create');
        Route::get('/users/{user}', [UserController::class, 'show'])->middleware('permission:employees.view');
        Route::put('/users/{user}', [UserController::class, 'update'])->middleware('permission:employees.update');
        Route::patch('/users/{user}', [UserController::class, 'update'])->middleware('permission:employees.update');
        Route::delete('/users/{user}', [UserController::class, 'destroy'])->middleware('permission:employees.deactivate');
        Route::post('/users/{user}/resend-invitation', [UserController::class, 'resendInvitation'])->middleware('permission:employees.invite');
        Route::patch('/users/{user}/transfer', [UserController::class, 'transfer'])->middleware('permission:employees.transfer');
        Route::get('/admin-permissions', [RolePermissionController::class, 'catalog'])->middleware('role:super_admin,superadmin');
        Route::get('/users/{user}/permissions', [RolePermissionController::class, 'index'])->middleware('role:super_admin,superadmin');
        Route::put('/users/{user}/permissions', [RolePermissionController::class, 'update'])->middleware('role:super_admin,superadmin');

        Route::get('/attendances', [AttendanceAdminController::class, 'index'])->middleware('permission:attendance.view');
        Route::get('/attendances/{attendance}/photo', [AttendanceAdminController::class, 'photo'])->middleware('permission:attendance.view');
        Route::get('/attendances/{attendance}/checkout-photo', [AttendanceAdminController::class, 'checkoutPhoto'])->middleware('permission:attendance.view');
        Route::get('/attendances/{attendance}', [AttendanceAdminController::class, 'show'])->middleware('permission:attendance.view');
        Route::patch('/attendances/{attendance}/approve', [AttendanceAdminController::class, 'approve'])->middleware('permission:attendance.review');
        Route::patch('/attendances/{attendance}/reject', [AttendanceAdminController::class, 'reject'])->middleware('permission:attendance.review');

        Route::prefix('dashboard')->group(function () {
            Route::get('/summary', [DashboardController::class, 'summary'])->middleware('permission:dashboard.view');
            Route::get('/trend', [DashboardController::class, 'trend'])->middleware('permission:dashboard.view');
            Route::get('/today-attendance', [DashboardController::class, 'todayAttendance'])->middleware('permission:dashboard.view');
            Route::get('/by-location', [DashboardController::class, 'byLocation'])->middleware('permission:dashboard.view');
            Route::get('/anomalies', [DashboardController::class, 'anomalies'])->middleware('permission:dashboard.view');
            Route::get('/export', [DashboardController::class, 'export'])->middleware('permission:dashboard.view');
        });
    });
});
