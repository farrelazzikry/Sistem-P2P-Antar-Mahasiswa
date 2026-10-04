<?php

use App\Http\Controllers\Api\AuthController;
use Illuminate\Support\Facades\Route;

// Auth
Route::post('/login', [AuthController::class, 'login']);
Route::post('/register', [AuthController::class, 'register']);
Route::post('/send-otp', [AuthController::class, 'sendOtp']);

// Forgot Password
Route::post('/forgot-password/send-otp', [AuthController::class, 'forgotPasswordSendOtp']);
Route::post('/forgot-password/reset', [AuthController::class, 'forgotPasswordReset']);

// Protected
Route::middleware('auth:sanctum')->group(function () {
    Route::post('/logout', [AuthController::class, 'logout']);
});