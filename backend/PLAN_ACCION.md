# ✅ PLAN DE ACCIÓN - Backend A4M Pets

## 📊 Estado Actual del Backend

### ✅ Completado
- [x] Base de datos SQLite configurada
- [x] Migraciones ejecutadas (incluyendo `hazard_reports`)
- [x] Controlador `HazardReportController` creado
- [x] Rutas API definidas en `routes/api.php`
- [x] Modelo `HazardReport` con métodos de sincronización
- [x] Variables de entorno configuradas
- [x] Caché limpiado

### ⚠️ En Progreso
- [ ] Servidor Laravel iniciado y escuchando en puerto 8000
- [ ] Endpoints probados y validados

### 📋 Próximos Pasos Después de Validar Backend

## 🎬 Ahora (Validar Backend)

### Paso 1: Asegurar que el servidor esté corriendo

Abre **2 terminales PowerShell separadas**:

**Terminal A - Servidor:**
```powershell
cd I:\projects\A4MPets\backend
php "I:\projects\A4MPets\backend\artisan" serve --port=8000
```

Espera a ver:
```
   INFO  Server running on [http://127.0.0.1:8000].
   Press Ctrl+C to quit.
```

**Terminal B - Testing (espera a que Terminal A esté lista):**
```powershell
cd I:\projects\A4MPets\backend
.\test-api-v2.ps1
```

### Paso 2: Verificar Resultados

Deberías ver outputcon ✓ en los 9 tests:
```
[TEST 1] ✓ Servidor disponible
[TEST 2] ✓ Peligro creado exitosamente
[TEST 3] ✓ 1 peligro(s) encontrado(s)
[TEST 4] ✓ 1 peligro(s) cercano(s) encontrado(s)
[TEST 5] ✓ Peligro obtenido
[TEST 6] ✓ Peligro actualizado
[TEST 7] ✓ Sincronización completada
[TEST 8] ✓ Peligros no sincronizados
[TEST 9] ✓ Peligro archivado
```

Si todo pasa ✓ → Backend listo para Flutter

Si hay ✗ → Ver sección de Troubleshooting abajo

## 🏗️ Arquitectura de Sincronización Implementada

```
┌─────────────────────────────────────────┐
│      Flutter App (Cliente)              │
│  - Local SQLite DB (peligros locales)  │
│  - Genera UUID como local_id           │
│  - Rastrea last_modified_at            │
└────────────────────┬────────────────────┘
                     │
                     ↓ (POST /api/hazards/sync)
                     │
┌─────────────────────────────────────────┐
│     Laravel API (Servidor)              │
│  - Tabla hazard_reports en SQLite       │
│  - Resuelve conflictos por timestamp   │
│  - Retorna remote_id después de sync    │
│  - Endpoints: GET, POST, PUT, DELETE    │
└─────────────────────────────────────────┘
```

### Flujo de Sincronización

1. **Cliente crea peligro localmente**
   - Genera UUID como `local_id`
   - Guarda con `status='created'`
   - Incluye `last_modified_at=ahora`

2. **Cliente envía a sincronizar**
   - POST /api/hazards/sync con lote de peligros
   - Servidor compara timestamps
   - Si no hay conflicto: actualiza a `status='synced'`, devuelve `remote_id`

3. **Resolución de Conflictos**
   - Strategy: "Last Write Wins" 
   - Cliente env ía su `last_modified_at`
   - Servidor compara con su copia
   - Gana quien tenga timestamp más reciente

## 📦 Archivos del Backend Completados

### Configuración
- ✅ `.env` - Variables de entorno para desarrollo
- ✅ `.env.template` - Template para deployments
- ✅ `setup.bat` - Automatización de configuración inicial

### Rutas y Controladores
- ✅ `routes/api.php` - 8 endpoints públicos definidos
- ✅ `app/Http/Controllers/HazardReportController.php` - Lógica de sincronización

### Base de Datos
- ✅ `database/migrations/2024_01_01_000003_create_hazard_reports_table.php` - Schema
- ✅ `app/Models/HazardReport.php` - Modelo Eloquent con scopes

### Documentación
- ✅ `README_API.md` - Documentación completa de API
- ✅ `QUICK_START.md` - Guía de inicio rápido
- ✅ `test-api-v2.ps1` - Script de prueba mejorado

## 🧪 Qué Hace el Test

El script `test-api-v2.ps1` valida:

1. **Health Check** - Servidor responde
2. **Crear** - POST /api/hazards (sin autenticación)
3. **Listar** - GET /api/hazards con paginación
4. **Filtrar** - GET /api/hazards?lat=...&lon=...&radius=...
5. **Obtener uno** - GET /api/hazards/{id}
6. **Actualizar** - PUT /api/hazards/{id} con detección de conflictos
7. **Sincronizar** - POST /api/hazards/sync con múltiples peligros
8. **Ver no sincronizados** - GET /api/hazards/unsynced
9. **Archivar** - DELETE /api/hazards/{id}

## ⚙️ Si Hay Problemas

### Error: Servidor no responde (404)

```powershell
# 1. Verifica que el servidor esté corriendo en otra terminal
cd I:\projects\A4MPets\backend
php "I:\projects\A4MPets\backend\artisan" serve --port=8000

# 2. Limpia caché si el servidor ya estaba corriendo
php artisan cache:clear
php artisan route:clear
```

### Error: Tabla no existe

```powershell
# 1. Verifica estado de migraciones
php artisan migrate:status

# 2. Si no está ejecutada, ejecuta:
php artisan migrate
```

### Error: Base de datos no existe

```powershell
# 1. Crea el archivo
New-Item -Path "database\database.sqlite" -Force

# 2. Ejecuta migraciones
php artisan migrate
```

## 🎯 Una Vez Validado el Backend

Cuando todos los tests pasen ✓:

1. **Crear servicio de sincronización en Flutter**
   - Archivo: `frontend/lib/services/hazard_sync_service.dart`
   - Métodos: `syncToBackend()`, `fetchFromBackend()`

2. **Almacenar credenciales de sincronización**
   - Guardar `remote_id` cuando se sincroniza
   - Actualizar `status` local después de sync

3. **Implementar sincronización periódica**
   - Cada 5 minutos cuando la app está activa
   - Al detectar nuevos peligros
   - Con reintentos automáticos

4. **Agregar UI de sincronización**
   - Indicador "Sincronizando..." en la app
   - Mostrar último tiempo de sincronización
   - Manejo de errores visible

## 📊 Información de Versión

- **Laravel**: 11.x con Eloquent
- **Base de Datos**: SQLite (desarrollo) / MySQL (producción)
- **API**: RESTful con 8 endpoints
- **Conflictos**: Resueltos por "Last Write Wins"
- **Migraciones**: 4 tablas (users, cache, jobs, hazard_reports)

---

**¿Listo para proceder?** Ejecuta los tests en Terminal B mientras el servidor corre en Terminal A.
