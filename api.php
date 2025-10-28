<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\MobileAuthController;
use App\Http\Controllers\Api\MobileBookingController;
use App\Http\Controllers\Api\MobileProfileController;
use App\Http\Controllers\Api\MobilePetController;
use App\Http\Controllers\Api\MobileDashboardController;

/*
|--------------------------------------------------------------------------
| API Routes - VETech Mobile Application
|--------------------------------------------------------------------------
|
| These routes are for the mobile application.
| All routes return JSON responses.
| Authentication uses Laravel Sanctum tokens.
|
*/

// Public routes (no authentication required)
Route::prefix('v1')->group(function () {
    // Authentication
    Route::post('/register', [MobileAuthController::class, 'register']);
    Route::post('/login', [MobileAuthController::class, 'login']);
    Route::post('/forgot-password', [MobileAuthController::class, 'forgotPassword']);
    Route::post('/reset-password', [MobileAuthController::class, 'resetPassword']);
});

// Protected routes (requires authentication)
Route::prefix('v1')->middleware('auth:sanctum')->group(function () {
    // Auth
    Route::post('/logout', [MobileAuthController::class, 'logout']);
    Route::get('/user', [MobileAuthController::class, 'user']);
    
    // Config - Get OpenAI API Key
    Route::get('/openai-key', [MobileAuthController::class, 'getOpenAIKey']);
    
    // Dashboard
    Route::get('/dashboard', [MobileDashboardController::class, 'index']);
    
    // Profile Management
    Route::get('/profile', [MobileProfileController::class, 'show']);
    Route::put('/profile', [MobileProfileController::class, 'update']);
    Route::put('/profile/password', [MobileProfileController::class, 'updatePassword']);
    Route::delete('/profile', [MobileProfileController::class, 'destroy']);
    
    // Booking Management
    Route::get('/bookings', [MobileBookingController::class, 'index']);
    Route::post('/bookings', [MobileBookingController::class, 'store']);
    Route::get('/bookings/{booking}', [MobileBookingController::class, 'show']);
    Route::put('/bookings/{booking}', [MobileBookingController::class, 'update']);
    Route::delete('/bookings/{booking}', [MobileBookingController::class, 'destroy']);
    
    // Pet Management
    Route::get('/pets', [MobilePetController::class, 'index']);
    Route::post('/pets', [MobilePetController::class, 'store']);
    Route::get('/pets/{pet}', [MobilePetController::class, 'show']);
    Route::put('/pets/{pet}', [MobilePetController::class, 'update']);
    Route::delete('/pets/{pet}', [MobilePetController::class, 'destroy']);
    
    // Pet Tag Assignment
    Route::post('/pets/scan-tag', [MobilePetController::class, 'scanAndAssignTag']);
    Route::post('/pets/{pet}/assign-tag', [MobilePetController::class, 'assignTag']);
    Route::post('/pets/{pet}/release-tag', [MobilePetController::class, 'releaseTag']);
    
    // Pet Medical Records
    Route::get('/pets/{pet}/treatments', [MobilePetController::class, 'treatments']);
    Route::get('/pets/{pet}/treatments/{treatment}', [MobilePetController::class, 'treatmentDetail']);
});
