# A4M Pets - Test API (Versión Mejorada)
# 
# Ejecutar este script en PowerShell para probar los endpoints de la API
# PS> .\test-api-v2.ps1

$BASE_URL = "http://localhost:8000/api"
$ErrorActionPreference = "Continue"

Write-Host ""
Write-Host "╔════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  A4M Pets - API Testing Suite v2.0    ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# ============================================
# TEST 1: Health Check
# ============================================

Write-Host "[TEST 1] Verificando salud del servidor..." -ForegroundColor Yellow

try {
    $health = Invoke-RestMethod -Uri "$BASE_URL/health" -Method GET -TimeoutSec 5 -ErrorAction Stop
    Write-Host "✓ Servidor disponible" -ForegroundColor Green
    Write-Host "  Status: $($health.status)" -ForegroundColor Gray
    Write-Host "  Timestamp: $($health.timestamp)" -ForegroundColor Gray
} catch {
    Write-Host "✗ Servidor no responde: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "Asegurate de que el servidor Laravel está corriendo:" -ForegroundColor Yellow
    Write-Host "  cd backend" -ForegroundColor Gray
    Write-Host "  php artisan serve" -ForegroundColor Gray
    exit 1
}

Write-Host ""

# ============================================
# TEST 2: Create Hazard
# ============================================

Write-Host "[TEST 2] Creando nuevo peligro..." -ForegroundColor Yellow

$newHazard = @{
    local_id = [guid]::NewGuid().ToString()
    incident_latitude = 3.4516
    incident_longitude = -76.5320
    impact_radius_meters = 500
    risk_level_code = "high"
    description = "Prueba de peligro - Construcción en la zona"
} | ConvertTo-Json

try {
    $createResponse = Invoke-RestMethod -Uri "$BASE_URL/hazards" `
        -Method POST `
        -ContentType "application/json" `
        -Body $newHazard `
        -TimeoutSec 5 `
        -ErrorAction Stop
    
    Write-Host "✓ Peligro creado exitosamente" -ForegroundColor Green
    Write-Host "  ID: $($createResponse.id)" -ForegroundColor Gray
    Write-Host "  Local ID: $($createResponse.local_id)" -ForegroundColor Gray
    Write-Host "  Status: $($createResponse.status)" -ForegroundColor Gray
    
    $hazardId = $createResponse.id
    $localId = $createResponse.local_id
} catch {
    Write-Host "✗ Error al crear peligro: $_" -ForegroundColor Red
}

Write-Host ""

# ============================================
# TEST 3: Get All Hazards
# ============================================

Write-Host "[TEST 3] Obteniendo todos los peligros..." -ForegroundColor Yellow

try {
    $allHazards = Invoke-RestMethod -Uri "$BASE_URL/hazards" `
        -Method GET `
        -ContentType "application/json" `
        -TimeoutSec 5 `
        -ErrorAction Stop
    
    $count = $allHazards.data.Count
    Write-Host "✓ $count peligro(s) encontrado(s)" -ForegroundColor Green
    
    if ($count -gt 0) {
        Write-Host "  Primero: $($allHazards.data[0].description)" -ForegroundColor Gray
    }
} catch {
    Write-Host "✗ Error al obtener peligros: $_" -ForegroundColor Red
}

Write-Host ""

# ============================================
# TEST 4: Filter by Location
# ============================================

Write-Host "[TEST 4] Filtrando peligros por ubicación (5km)..." -ForegroundColor Yellow

try {
    $nearbyHazards = Invoke-RestMethod -Uri "$BASE_URL/hazards?latitude=3.4516&longitude=-76.5320&radius_km=5&risk_level=high" `
        -Method GET `
        -ContentType "application/json" `
        -TimeoutSec 5 `
        -ErrorAction Stop
    
    $count = $nearbyHazards.data.Count
    Write-Host "✓ $count peligro(s) cercano(s) encontrado(s)" -ForegroundColor Green
} catch {
    Write-Host "✗ Error al filtrar peligros: $_" -ForegroundColor Red
}

Write-Host ""

# ============================================
# TEST 5: Get Specific Hazard
# ============================================

if ($hazardId) {
    Write-Host "[TEST 5] Obteniendo peligro específico..." -ForegroundColor Yellow
    
    try {
        $singleHazard = Invoke-RestMethod -Uri "$BASE_URL/hazards/$hazardId" `
            -Method GET `
            -ContentType "application/json" `
            -TimeoutSec 5 `
            -ErrorAction Stop
        
        Write-Host "✓ Peligro obtenido" -ForegroundColor Green
        Write-Host "  Descripción: $($singleHazard.description)" -ForegroundColor Gray
        Write-Host "  Risk Level: $($singleHazard.risk_level_code)" -ForegroundColor Gray
    } catch {
        Write-Host "✗ Error al obtener peligro: $_" -ForegroundColor Red
    }
    
    Write-Host ""
}

# ============================================
# TEST 6: Update Hazard
# ============================================

if ($hazardId) {
    Write-Host "[TEST 6] Actualizando peligro..." -ForegroundColor Yellow
    
    $updateHazard = @{
        description = "Construcción completada - zona segura"
        risk_level_code = "low"
        impact_radius_meters = 100
    } | ConvertTo-Json
    
    try {
        $updateResponse = Invoke-RestMethod -Uri "$BASE_URL/hazards/$hazardId" `
            -Method PUT `
            -ContentType "application/json" `
            -Body $updateHazard `
            -TimeoutSec 5 `
            -ErrorAction Stop
        
        Write-Host "✓ Peligro actualizado" -ForegroundColor Green
        Write-Host "  Nueva descripción: $($updateResponse.description)" -ForegroundColor Gray
    } catch {
        Write-Host "✗ Error al actualizar peligro: $_" -ForegroundColor Red
    }
    
    Write-Host ""
}

# ============================================
# TEST 7: Sync Hazards
# ============================================

Write-Host "[TEST 7] Sincronizando peligros locales..." -ForegroundColor Yellow

$syncPayload = @{
    hazards = @(
        @{
            local_id = [guid]::NewGuid().ToString()
            incident_latitude = 3.45
            incident_longitude = -76.53
            impact_radius_meters = 300
            risk_level_code = "medium"
            description = "Peligro local para sincronizar"
            last_modified_at = (Get-Date -AsUTC).ToString("yyyy-MM-dd HH:mm:ss")
            remote_id = $null
        },
        @{
            local_id = [guid]::NewGuid().ToString()
            incident_latitude = 3.46
            incident_longitude = -76.54
            impact_radius_meters = 400
            risk_level_code = "low"
            description = "Otro peligro para sincronizar"
            last_modified_at = (Get-Date -AsUTC).ToString("yyyy-MM-dd HH:mm:ss")
            remote_id = $null
        }
    )
} | ConvertTo-Json -Depth 3

try {
    $syncResponse = Invoke-RestMethod -Uri "$BASE_URL/hazards/sync" `
        -Method POST `
        -ContentType "application/json" `
        -Body $syncPayload `
        -TimeoutSec 5 `
        -ErrorAction Stop
    
    Write-Host "✓ Sincronización completada" -ForegroundColor Green
    Write-Host "  Sincronizados: $($syncResponse.sync_results.synced)" -ForegroundColor Gray
    Write-Host "  Conflictos: $($syncResponse.sync_results.conflicts)" -ForegroundColor Gray
    Write-Host "  Errores: $($syncResponse.sync_results.errors)" -ForegroundColor Gray
} catch {
    Write-Host "✗ Error en sincronización: $_" -ForegroundColor Red
}

Write-Host ""

# ============================================
# TEST 8: Get Unsynced
# ============================================

Write-Host "[TEST 8] Verificando peligros no sincronizados..." -ForegroundColor Yellow

try {
    $unsyncedHazards = Invoke-RestMethod -Uri "$BASE_URL/hazards/unsynced" `
        -Method GET `
        -ContentType "application/json" `
        -TimeoutSec 5 `
        -ErrorAction Stop
    
    $count = $unsyncedHazards.count
    Write-Host "✓ $count peligro(s) no sincronizado(s)" -ForegroundColor Green
} catch {
    Write-Host "✗ Error al verificar no sincronizados: $_" -ForegroundColor Red
}

Write-Host ""

# ============================================
# TEST 9: Delete/Archive Hazard
# ============================================

if ($hazardId) {
    Write-Host "[TEST 9] Archivando peligro..." -ForegroundColor Yellow
    
    try {
        $deleteResponse = Invoke-RestMethod -Uri "$BASE_URL/hazards/$hazardId" `
            -Method DELETE `
            -ContentType "application/json" `
            -TimeoutSec 5 `
            -ErrorAction Stop
        
        Write-Host "✓ Peligro archivado" -ForegroundColor Green
        Write-Host "  Nuevo status: $($deleteResponse.status)" -ForegroundColor Gray
    } catch {
        Write-Host "✗ Error al archivar peligro: $_" -ForegroundColor Red
    }
    
    Write-Host ""
}

# ============================================
# Summary
# ============================================

Write-Host "╔════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║  ✓ Pruebas completadas exitosamente   ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Host "El servidor está corriendo en: http://localhost:8000" -ForegroundColor Cyan
Write-Host "API disponible en: http://localhost:8000/api" -ForegroundColor Cyan
Write-Host ""
Write-Host "Documentación: " -ForegroundColor Cyan -NoNewline
Write-Host "Ver README_API.md para más detalles" -ForegroundColor Gray
Write-Host ""
