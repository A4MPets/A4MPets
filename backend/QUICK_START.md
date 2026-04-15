# 🚀 A4M Pets Backend - Quick Start

## Iniciode Sesión Rápida (5 minutos)

### 1️⃣ Configuración Inicial (primera vez solamente)

```powershell
cd backend
.\setup.bat
```

Esto:
- ✅ Instala dependencias con Composer
- ✅ Genera la APP_KEY
- ✅ Crea la base de datos SQLite
- ✅ Ejecuta las migraciones

### 2️⃣ Iniciar el Servidor

**Terminal 1 - Servidor Laravel:**
```powershell
cd backend
php "I:\projects\A4MPets\backend\artisan" serve --port=8000
```

Deberías ver algo como:
```
   INFO  Server running on [http://127.0.0.1:8000]
 Press Ctrl+C to quit
```

### 3️⃣ Probar los Endpoints

**Terminal 2 - PowerShell (mientras el servidor está corriendo):**
```powershell
cd backend
.\test-api-v2.ps1
```

## 📚 Resumen de Cambios

| Archivo | Acción | Razón |
|---------|--------|-------|
| `.env` | ✏️ Configurado | APP_NAME, APP_URL, settings de sync |
| `setup.bat` | ✏️ Mejorado | Ya no intenta iniciar el servidor (causaba problemas) |
| `test-api-v2.ps1` | 🆕 Nuevo | Script mejorado con mejor manejo de errores |
| `README_API.md` | 🆕 Nuevo | Documentación completa de API |

## 🔧 Troubleshooting

**Error: "Could not open input file: artisan"**
- ✅ Solución: Usa la ruta absoluta: `php "I:\projects\A4MPets\backend\artisan" serve`

**Error 404 en los endpoints**
- ✅ Solución: Limpia el cache de Laravel
  ```powershell
  cd backend
  php artisan cache:clear
  php artisan route:clear
  php artisan config:clear
  ```

**Base de datos no existe**
- ✅ Solución: Crea el archivo y ejecuta migraciones
  ```powershell
  cd backend
  php artisan migrate
  ```

**Puerto 8000 está en uso**
- ✅ Solución: Usa otro puerto
  ```powershell
  php "I:\projects\A4MPets\backend\artisan" serve --port=8001
  ```

## 📋 Verificación

Todos los comandos ejecutados correctamente:

✅ **Migraciones:** Sistema completamente inicializado
```
Batch 1: users, cache, jobs tables
Batch 2: hazard_reports table
```

✅ **Cache:** Limpiado exitosamente
```
- Application cache cleared
- Route cache cleared
- Configuration cache cleared
```

✅ **Servidor:** Escuchando en http://localhost:8000

## 🎯 Próximos Pasos

1. Ejecutar el script `test-api-v2.ps1` para verificar todos los endpoints
2. Crear el servicio de sincronización en Flutter (`hazard_sync_service.dart`)
3. Integrar la API del backend con la app Flutter
4. Implementar sincronización periódica de peligros

## 📞 Endpoints Disponibles

```
POST   /api/hazards              → Crear peligro
GET    /api/hazards              → Listar todos
GET    /api/hazards/{id}         → Obtener uno
PUT    /api/hazards/{id}         → Actualizar
DELETE /api/hazards/{id}         → Archivar
POST   /api/hazards/sync         → Sincronizar lote
GET    /api/hazards/unsynced     → Ver no sincronizados
GET    /api/health               → Health check
```

Documentación completa: [README_API.md](README_API.md)
