<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\HazardReportController;
use App\Http\Controllers\LostPetReportController;
use App\Http\Controllers\FoundPetReportController;
use App\Http\Controllers\GenericReportController;
use App\Http\Controllers\PetController;
use App\Http\Controllers\RoutePlanningController;
use App\Http\Controllers\TravelRouteController;
use App\Http\Controllers\MediaController;

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
|
| Here is where you can register API routes for your application. These
| routes are loaded by the RouteServiceProvider and all of them will
| be assigned to the "api" middleware group. Make something great!
|
*/

// ====== AUTH ======
Route::post('/auth/register', [AuthController::class, 'register']);
Route::post('/auth/login', [AuthController::class, 'login']);

// ====== HAZARDS (globales, visibles para todos) ======
Route::middleware('api.token')->group(function (): void {
    // Obtener todos los peligros
    Route::get('/hazards', [HazardReportController::class, 'index']);

    // Comentarios por peligro
    Route::get('/hazards/{hazardReport}/comments', [HazardReportController::class, 'comments']);
    Route::post('/hazards/{hazardReport}/comments', [HazardReportController::class, 'storeComment']);

    // Obtener peligros no sincronizados
    Route::get('/hazards/unsynced', [HazardReportController::class, 'getUnsynced']);

    // Sincronizar peligros locales con BD global
    Route::post('/hazards/sync', [HazardReportController::class, 'sync']);

    // Obtener un peligro específico
    Route::get('/hazards/{hazardReport}', [HazardReportController::class, 'show']);

    // Crear un nuevo peligro (anónimo o autenticado)
    Route::post('/hazards', [HazardReportController::class, 'store']);

    // Actualizar un peligro
    Route::put('/hazards/{hazardReport}', [HazardReportController::class, 'update']);

    // Eliminar (archivar) un peligro
    Route::delete('/hazards/{hazardReport}', [HazardReportController::class, 'destroy']);
});

Route::middleware('api.token')->group(function (): void {
    Route::get('/lost-pet-reports', [LostPetReportController::class, 'index']);
    Route::post('/lost-pet-reports/sync', [LostPetReportController::class, 'sync']);
    Route::get('/lost-pet-reports/{lostPetReport}', [LostPetReportController::class, 'show']);
    Route::post('/lost-pet-reports', [LostPetReportController::class, 'store']);
    Route::put('/lost-pet-reports/{lostPetReport}', [LostPetReportController::class, 'update']);
    Route::delete('/lost-pet-reports/{lostPetReport}', [LostPetReportController::class, 'destroy']);

    Route::get('/found-pet-reports', [FoundPetReportController::class, 'index']);
    Route::post('/found-pet-reports/sync', [FoundPetReportController::class, 'sync']);
    Route::get('/found-pet-reports/{foundPetReport}', [FoundPetReportController::class, 'show']);
    Route::post('/found-pet-reports', [FoundPetReportController::class, 'store']);
    Route::put('/found-pet-reports/{foundPetReport}', [FoundPetReportController::class, 'update']);
    Route::delete('/found-pet-reports/{foundPetReport}', [FoundPetReportController::class, 'destroy']);

    Route::get('/generic-reports', [GenericReportController::class, 'index']);
    Route::post('/generic-reports/sync', [GenericReportController::class, 'sync']);
    Route::get('/generic-reports/{genericReport}', [GenericReportController::class, 'show']);
    Route::post('/generic-reports', [GenericReportController::class, 'store']);
    Route::put('/generic-reports/{genericReport}', [GenericReportController::class, 'update']);
    Route::delete('/generic-reports/{genericReport}', [GenericReportController::class, 'destroy']);
});

Route::middleware('api.token')->group(function (): void {
    Route::get('/auth/me', [AuthController::class, 'me']);
    Route::put('/auth/profile', [AuthController::class, 'updateProfile']);
    Route::post('/auth/logout', [AuthController::class, 'logout']);

    Route::get('/pets', [PetController::class, 'index']);
    Route::post('/pets/sync', [PetController::class, 'sync']);
    Route::post('/pets', [PetController::class, 'store']);
    Route::put('/pets/{pet}', [PetController::class, 'update']);
    Route::delete('/pets/{pet}', [PetController::class, 'destroy']);

    Route::get('/routes', [TravelRouteController::class, 'index']);
    Route::post('/routes/sync', [TravelRouteController::class, 'sync']);
    Route::post('/routes', [TravelRouteController::class, 'store']);
    Route::put('/routes/{route}', [TravelRouteController::class, 'update']);
    Route::delete('/routes/{route}', [TravelRouteController::class, 'destroy']);

    // Planificar ruta usando GraphHopper desde backend
    Route::post('/routes/plan', [RoutePlanningController::class, 'plan']);

    // Subida de archivos de imagen (manteniendo campos URL existentes)
    Route::post('/media/upload', [MediaController::class, 'upload']);

});

// Lectura pública de imágenes almacenadas por backend
Route::get('/media/{bucket}/{fileName}', [MediaController::class, 'show'])
    ->where('bucket', 'pets|hazards|profiles|lost_pets|found_pets|generic_reports')
    ->where('fileName', '[A-Za-z0-9._-]+');

// ====== HEALTH CHECK ======
Route::get('/health', function (Request $request) {
    return response()->json([
        'status' => 'ok',
        'timestamp' => now(),
    ]);
});
