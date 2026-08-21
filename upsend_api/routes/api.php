<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\LocationController;
use App\Http\Controllers\Api\UserController;
use App\Http\Controllers\Api\AttendanceController;
use App\Http\Controllers\Api\LeaveRequestController;
use App\Http\Controllers\Api\Admin\AttendanceAdminController;
use App\Http\Controllers\Api\Admin\DashboardController;
use Illuminate\Support\Facades\Route;



// ==== Auth ====
Route::post('/login', [AuthController::class, 'login']);
Route::post('/login-web', [AuthController::class, 'loginWeb']);  // BARU, dipakai dashboard web (email)
Route::post('/register', [AuthController::class, 'register']);

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

    // ==== Khusus admin ====
    Route::middleware('role:admin')->group(function () {
        Route::apiResource('locations', LocationController::class);

        Route::apiResource('users', UserController::class);
        Route::patch('/users/{user}/transfer', [UserController::class, 'transfer']);

        Route::get('/attendances', [AttendanceAdminController::class, 'index']);
        Route::get('/attendances/{attendance}/photo', [AttendanceAdminController::class, 'photo']);
        Route::get('/attendances/{attendance}', [AttendanceAdminController::class, 'show']);
        Route::patch('/attendances/{attendance}/approve', [AttendanceAdminController::class, 'approve']);
        Route::patch('/attendances/{attendance}/reject', [AttendanceAdminController::class, 'reject']);

        Route::prefix('dashboard')->group(function () {
            Route::get('/summary', [DashboardController::class, 'summary']);
            Route::get('/weekly-trend', [DashboardController::class, 'weeklyTrend']);
            Route::get('/today-attendance', [DashboardController::class, 'todayAttendance']); // baru
            Route::get('/by-location', [DashboardController::class, 'byLocation']);
            Route::get('/anomalies', [DashboardController::class, 'anomalies']);
            Route::get('/export', [DashboardController::class, 'export']);
        });
    });
});
