<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\ProfileController;
use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\Storage;
use App\Http\Controllers\Api\JastipController;
use App\Http\Controllers\Api\RatingController;

// ============================================
// PUBLIC ROUTES (gak butuh login)
// ============================================
Route::post('/login', [AuthController::class, 'login']);
Route::post('/register', [AuthController::class, 'register']);
Route::post('/send-otp', [AuthController::class, 'sendOtp']);

// Forgot Password
Route::post('/forgot-password/send-otp', [AuthController::class, 'forgotPasswordSendOtp']);
Route::post('/forgot-password/reset', [AuthController::class, 'forgotPasswordReset']);

// Route serve file storage — DI LUAR AUTH
Route::get('/storage/{path}', function ($path) {
    if (!Storage::disk('public')->exists($path)) {
        return response()->json(['message' => 'File not found'], 404);
    }
    $file = Storage::disk('public')->get($path);
    $mimeType = Storage::disk('public')->mimeType($path);
    return response($file, 200)
        ->header('Content-Type', $mimeType)
        ->header('Access-Control-Allow-Origin', '*');
})->where('path', '.*');

// ============================================
// PROTECTED ROUTES (butuh login / token)
// ============================================
Route::middleware('auth:sanctum')->group(function () {
    Route::post('/logout', [AuthController::class, 'logout']);

    // Profile
    Route::get('/profile', [ProfileController::class, 'show']);
    Route::post('/profile/update', [ProfileController::class, 'update']);

    // Jastip
    Route::get('/jastips', [JastipController::class, 'index']);
    Route::post('/jastips', [JastipController::class, 'store']);
    Route::get('/jastips/my-orders', [JastipController::class, 'myOrders']);
    Route::get('/jastips/{id}', [JastipController::class, 'show']);
    Route::post('/jastips/{id}/take', [JastipController::class, 'take']);
    Route::post('/jastips/{id}/status', [JastipController::class, 'updateStatus']);

    // Rating
    Route::post('/ratings', [RatingController::class, 'store']);
    Route::get('/ratings/status/{type}/{id}', [RatingController::class, 'status']);
});