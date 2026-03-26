<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\HazardReportController;
use App\Http\Controllers\RoutePlanningController;

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

// ====== PUBLIC API - Sin autenticación ======
// Todos los endpoints de peligros son públicos (sin login requerido todavía)

// Obtener todos los peligros
Route::get('/hazards', [HazardReportController::class, 'index']);

// Obtener peligros no sincronizados
Route::get('/hazards/unsynced', [HazardReportController::class, 'getUnsynced']);

// Sincronizar peligros locales con BD global
Route::post('/hazards/sync', [HazardReportController::class, 'sync']);

// Planificar ruta usando GraphHopper desde backend
Route::post('/routes/plan', [RoutePlanningController::class, 'plan']);

// Obtener un peligro específico
Route::get('/hazards/{hazardReport}', [HazardReportController::class, 'show']);

// Crear un nuevo peligro (anónimo)
Route::post('/hazards', [HazardReportController::class, 'store']);

// Actualizar un peligro
Route::put('/hazards/{hazardReport}', [HazardReportController::class, 'update']);

// Eliminar (archivar) un peligro
Route::delete('/hazards/{hazardReport}', [HazardReportController::class, 'destroy']);

// ====== HEALTH CHECK ======
Route::get('/health', function (Request $request) {
    return response()->json([
        'status' => 'ok',
        'timestamp' => now(),
    ]);
});
