# A4M Pets - Ejemplos de API (PowerShell)
# 
# Este archivo contiene ejemplos de cómo llamar a los endpoints de la API
# Copiar y ejecutar en PowerShell

$BASE_URL = "http://localhost:8000/api"

# ============================================
# 1. CREAR UN NUEVO PELIGRO
# ============================================

Write-Host "1. Creando nuevo peligro..." -ForegroundColor Cyan

$newHazard = @{
    local_id = [guid]::NewGuid().ToString()
    incident_latitude = 3.4516
    incident_longitude = -76.5320
    impact_radius_meters = 500
    risk_level_code = "high"
    description = "Construcción en la zona, entrada restringida"
} | ConvertTo-Json

$createResponse = Invoke-RestMethod -Uri "$BASE_URL/hazards" `
    -Method POST `
    -ContentType "application/json" `
    -Body $newHazard

Write-Host "Peligro creado:" -ForegroundColor Green
Write-Host ($createResponse | ConvertTo-Json)
Write-Host ""

# Guardar el ID para usar en otros ejemplos
$hazardId = $createResponse.data.id
$localId = $createResponse.data.local_id

# ============================================
# 2. OBTENER TODOS LOS PELIGROS
# ============================================

Write-Host "2. Obteniendo todos los peligros..." -ForegroundColor Cyan

$allHazards = Invoke-RestMethod -Uri "$BASE_URL/hazards" `
    -Method GET `
    -ContentType "application/json"

Write-Host "Peligros encontrados: $($allHazards.data.Count)" -ForegroundColor Green
Write-Host ($allHazards.data | ConvertTo-Json)
Write-Host ""

if (-not $hazardId -and $allHazards.data.Count -gt 0) {
    $hazardId = $allHazards.data[0].id
}

# ============================================
# 3. FILTRAR PELIGROS POR UBICACIÓN
# ============================================

Write-Host "3. Filtrando peligros por ubicación (radio 5km)..." -ForegroundColor Cyan

$nearbyHazards = Invoke-RestMethod -Uri "$BASE_URL/hazards?latitude=3.4516&longitude=-76.5320&radius_km=5&risk_level=high" `
    -Method GET `
    -ContentType "application/json"

Write-Host "Peligros cercanos: $($nearbyHazards.data.Count)" -ForegroundColor Green
Write-Host ($nearbyHazards.data | ConvertTo-Json)
Write-Host ""

# ============================================
# 4. OBTENER PELIGRO ESPECÍFICO
# ============================================

Write-Host "4. Obteniendo peligro específico (ID: $hazardId)..." -ForegroundColor Cyan

if ($hazardId) {
    $singleHazard = Invoke-RestMethod -Uri "$BASE_URL/hazards/$hazardId" `
        -Method GET `
        -ContentType "application/json"

    Write-Host "Peligro:" -ForegroundColor Green
    Write-Host ($singleHazard | ConvertTo-Json)
} else {
    Write-Host "No se encontró ID de peligro para consultar." -ForegroundColor Yellow
}

Write-Host ""

# ============================================
# 5. ACTUALIZAR PELIGRO
# ============================================

Write-Host "5. Actualizando peligro..." -ForegroundColor Cyan

$updateHazard = @{
    description = "Construcción finalizada - zona segura nuevamente"
    risk_level_code = "low"
    impact_radius_meters = 100
} | ConvertTo-Json

if ($hazardId) {
    $updateResponse = Invoke-RestMethod -Uri "$BASE_URL/hazards/$hazardId" `
        -Method PUT `
        -ContentType "application/json" `
        -Body $updateHazard

    Write-Host "Peligro actualizado:" -ForegroundColor Green
    Write-Host ($updateResponse | ConvertTo-Json)
} else {
    Write-Host "No se encontró ID de peligro para actualizar." -ForegroundColor Yellow
}
Write-Host ""

# ============================================
# 6. SINCRONIZAR PELIGROS LOCALES
# ============================================

Write-Host "6. Sincronizando peligros locales..." -ForegroundColor Cyan

$syncPayload = @{
    hazards = @(
        @{
            local_id = [guid]::NewGuid().ToString()
            incident_latitude = 3.45
            incident_longitude = -76.53
            impact_radius_meters = 300
            risk_level_code = "medium"
            description = "Peligro local para sincronizar"
            last_modified_at = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
            remote_id = $null
        }
    )
} | ConvertTo-Json -Depth 3

$syncResponse = Invoke-RestMethod -Uri "$BASE_URL/hazards/sync" `
    -Method POST `
    -ContentType "application/json" `
    -Body $syncPayload

Write-Host "Sincronización completada:" -ForegroundColor Green
Write-Host ($syncResponse | ConvertTo-Json)
Write-Host ""

# ============================================
# 7. OBTENER PELIGROS NO SINCRONIZADOS
# ============================================

Write-Host "7. Obteniendo peligros no sincronizados..." -ForegroundColor Cyan

$unsyncedHazards = Invoke-RestMethod -Uri "$BASE_URL/hazards/unsynced" `
    -Method GET `
    -ContentType "application/json"

Write-Host "Peligros no sincronizados: $($unsyncedHazards.count)" -ForegroundColor Green
Write-Host ($unsyncedHazards.data | ConvertTo-Json)
Write-Host ""

# ============================================
# 8. ELIMINAR/ARCHIVAR PELIGRO
# ============================================

Write-Host "8. Archivando peligro (ID: $hazardId)..." -ForegroundColor Cyan

if ($hazardId) {
    $deleteResponse = Invoke-RestMethod -Uri "$BASE_URL/hazards/$hazardId" `
        -Method DELETE `
        -ContentType "application/json"

    Write-Host "Peligro archivado:" -ForegroundColor Green
    Write-Host ($deleteResponse | ConvertTo-Json)
} else {
    Write-Host "No se encontró ID de peligro para archivar." -ForegroundColor Yellow
}
Write-Host ""

# ============================================
# RESUMEN
# ============================================

Write-Host "================================" -ForegroundColor Yellow
Write-Host "Pruebas completadas exitosamente" -ForegroundColor Green
Write-Host "================================" -ForegroundColor Yellow
Write-Host ""
Write-Host "Documentación: Ver README_API.md para más detalles" -ForegroundColor Cyan
