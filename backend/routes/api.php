<?php

use App\Http\Controllers\AuthController;
use App\Http\Controllers\FoundPetReportController;
use App\Http\Controllers\GenericReportController;
use App\Http\Controllers\HazardReportController;
use App\Http\Controllers\LostPetReportController;
use App\Http\Controllers\MediaController;
use App\Http\Controllers\PetController;
use App\Http\Controllers\RoutePlanningController;
use App\Http\Controllers\TravelRouteController;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

Route::prefix('auth')->group(function (): void {
    Route::post('/register', [AuthController::class, 'register']);
    Route::post('/login', [AuthController::class, 'login']);
});

Route::prefix('hazards')->group(function (): void {
    Route::get('/', [HazardReportController::class, 'index']);
    Route::post('/', [HazardReportController::class, 'store'])->middleware('api.token');
    Route::get('/{hazardReport}', [HazardReportController::class, 'show']);
    Route::get('/{hazardReport}/comments', [HazardReportController::class, 'comments']);
});

Route::prefix('lost-pet-reports')->group(function (): void {
    Route::get('/', [LostPetReportController::class, 'index']);
    Route::get('/{lostPetReport}', [LostPetReportController::class, 'show']);
    Route::get('/{lostPetReport}/comments', [LostPetReportController::class, 'comments']);
});

Route::prefix('found-pet-reports')->group(function (): void {
    Route::get('/', [FoundPetReportController::class, 'index']);
    Route::get('/{foundPetReport}', [FoundPetReportController::class, 'show']);
    Route::get('/{foundPetReport}/comments', [FoundPetReportController::class, 'comments']);
});

Route::prefix('generic-reports')->group(function (): void {
    Route::get('/', [GenericReportController::class, 'index']);
    Route::post('/', [GenericReportController::class, 'store'])->middleware('api.token');
    Route::get('/{genericReport}', [GenericReportController::class, 'show']);
    Route::get('/{genericReport}/comments', [GenericReportController::class, 'comments']);
});

Route::post('/media/upload', [MediaController::class, 'upload']);

Route::prefix('pets')->group(function (): void {
    Route::get('/', [PetController::class, 'index'])->middleware('api.token:required');
    Route::get('/{pet}', [PetController::class, 'show']);
});

Route::prefix('routes')->group(function (): void {
    Route::get('/', [TravelRouteController::class, 'index'])->middleware('api.token:required');
    Route::post('/plan', [RoutePlanningController::class, 'plan'])->middleware('api.token');
    Route::get('/{route}', [TravelRouteController::class, 'show']);
});

Route::middleware('api.token:required')->group(function (): void {
    Route::prefix('auth')->group(function (): void {
        Route::get('/me', [AuthController::class, 'me']);
        Route::put('/profile', [AuthController::class, 'updateProfile']);
        Route::post('/logout', [AuthController::class, 'logout']);
    });

    Route::prefix('hazards')->group(function (): void {
        Route::put('/{hazardReport}', [HazardReportController::class, 'update']);
        Route::delete('/{hazardReport}', [HazardReportController::class, 'destroy']);
        Route::post('/{hazardReport}/comments', [HazardReportController::class, 'storeComment']);
    });

    Route::prefix('lost-pet-reports')->group(function (): void {
        Route::post('/', [LostPetReportController::class, 'store']);
        Route::put('/{lostPetReport}', [LostPetReportController::class, 'update']);
        Route::delete('/{lostPetReport}', [LostPetReportController::class, 'destroy']);
        Route::post('/{lostPetReport}/comments', [LostPetReportController::class, 'storeComment']);
    });

    Route::prefix('found-pet-reports')->group(function (): void {
        Route::post('/', [FoundPetReportController::class, 'store']);
        Route::put('/{foundPetReport}', [FoundPetReportController::class, 'update']);
        Route::delete('/{foundPetReport}', [FoundPetReportController::class, 'destroy']);
        Route::post('/{foundPetReport}/comments', [FoundPetReportController::class, 'storeComment']);
    });

    Route::prefix('generic-reports')->group(function (): void {
        Route::put('/{genericReport}', [GenericReportController::class, 'update']);
        Route::delete('/{genericReport}', [GenericReportController::class, 'destroy']);
        Route::post('/{genericReport}/comments', [GenericReportController::class, 'storeComment']);
    });

    Route::prefix('pets')->group(function (): void {
        Route::post('/', [PetController::class, 'store']);
        Route::post('/{pet}/mark-found', [PetController::class, 'markFound']);
        Route::put('/{pet}', [PetController::class, 'update']);
        Route::delete('/{pet}', [PetController::class, 'destroy']);
    });

    Route::prefix('routes')->group(function (): void {
        Route::post('/', [TravelRouteController::class, 'store']);
        Route::put('/{route}', [TravelRouteController::class, 'update']);
        Route::delete('/{route}', [TravelRouteController::class, 'destroy']);
    });
});

Route::get('/media/{bucket}/{fileName}', [MediaController::class, 'show'])
    ->where('bucket', 'pets|hazards|profiles|lost_pets|found_pets|generic_reports')
    ->where('fileName', '[A-Za-z0-9._-]+');

Route::get('/health', function (Request $request) {
    return response()->json([
        'status' => 'ok',
        'timestamp' => now(),
    ]);
});
