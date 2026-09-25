<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\LocationController;
use App\Http\Controllers\Api\UserController;
use App\Http\Controllers\Api\AttendanceController;
use App\Http\Controllers\Api\LeaveRequestController;
use App\Http\Controllers\Api\PayrollController;
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

    Route::get('/leave-requests', [LeaveRequestController::class, 'index']);
    Route::post('/leave-requests', [LeaveRequestController::class, 'store']);
    Route::delete('/leave-requests/{id}', [LeaveRequestController::class, 'destroy']);
    Route::get('/leave-balances', [LeaveRequestController::class, 'balances']);
    Route::get('/payrolls/{year}/{month}', [PayrollController::class, 'show'])
        ->whereNumber(['year', 'month']);

    // ==== Khusus admin ====
    Route::middleware('role:admin,super_admin')->group(function () {
        Route::get('/payrolls', [PayrollController::class, 'index']);
        Route::post('/payrolls', [PayrollController::class, 'store']);
        Route::put('/payrolls/{payroll}', [PayrollController::class, 'update']);

        Route::get('/admin/leave-requests', [LeaveRequestController::class, 'adminIndex']);
        Route::patch('/admin/leave-requests/{leaveRequest}/status', [LeaveRequestController::class, 'updateStatus']);

        Route::apiResource('locations', LocationController::class);

        Route::apiResource('tenants', TenantController::class)->only(['index', 'store', 'show', 'update', 'destroy']);
        Route::get('/divisions', [ShiftDivisionController::class, 'indexDivisions']);
        Route::post('/divisions', [ShiftDivisionController::class, 'storeDivision']);
        Route::put('/divisions/{division}', [ShiftDivisionController::class, 'updateDivision']);
        Route::delete('/divisions/{division}', [ShiftDivisionController::class, 'destroyDivision']);
        Route::get('/shifts', [ShiftDivisionController::class, 'indexShifts']);
        Route::post('/shifts', [ShiftDivisionController::class, 'storeShift']);
        Route::put('/shifts/{shift}', [ShiftDivisionController::class, 'updateShift']);
        Route::delete('/shifts/{shift}', [ShiftDivisionController::class, 'destroyShift']);

        Route::apiResource('users', UserController::class);
        Route::post('/users/{user}/resend-invitation', [UserController::class, 'resendInvitation']);
        Route::patch('/users/{user}/transfer', [UserController::class, 'transfer']);

        Route::get('/attendances', [AttendanceAdminController::class, 'index']);
        Route::get('/attendances/{attendance}/photo', [AttendanceAdminController::class, 'photo']);
        Route::get('/attendances/{attendance}/checkout-photo', [AttendanceAdminController::class, 'checkoutPhoto']);
        Route::get('/attendances/{attendance}', [AttendanceAdminController::class, 'show']);
        Route::patch('/attendances/{attendance}/approve', [AttendanceAdminController::class, 'approve']);
        Route::patch('/attendances/{attendance}/reject', [AttendanceAdminController::class, 'reject']);

        Route::prefix('dashboard')->group(function () {
            Route::get('/summary', [DashboardController::class, 'summary']);
            Route::get('/trend', [DashboardController::class, 'trend']);
            Route::get('/today-attendance', [DashboardController::class, 'todayAttendance']); // baru
            Route::get('/by-location', [DashboardController::class, 'byLocation']);
            Route::get('/anomalies', [DashboardController::class, 'anomalies']);
            Route::get('/export', [DashboardController::class, 'export']);
        });
    });
});
