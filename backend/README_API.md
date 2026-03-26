# Backend - A4M Pets

Sistema backend para sincronización y gestión de peligros reportados por usuarios de A4M Pets.

## Configuración Inicial

### 1. Instalación de dependencias

```bash
cd backend
composer install
```

### 2. Configuración de variables de entorno

```bash
# Copiar template a .env
cp .env.template .env

# Generar APP_KEY
php artisan key:generate
```

### 3. Configuración de base de datos

Para **desarrollo local** (ya configurado con SQLite):

```bash
# Crear la base de datos
touch database/database.sqlite

# Ejecutar migraciones
php artisan migrate

# (Opcional) Cargar datos de prueba
php artisan db:seed
```

Para **producción** (modificar .env):

```env
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=a4m_pets_prod
DB_USERNAME=root
DB_PASSWORD=your_password
```

### 4. Ejecutar servidor de desarrollo

```bash
php artisan serve
```

El servidor estará disponible en `http://localhost:8000`

## Estructura de la API

### Endpoints de Peligros

#### Obtener todos los peligros
```
GET /api/hazards
```

**Parámetros opcionales:**
- `latitude`, `longitude`, `radius_km` - Filtrar por ubicación
- `risk_level` - Filtrar por nivel: `low`, `medium`, `high`
- `include_archived` - Incluir peligros archivados (boolean)
- `page`, `per_page` - Paginación

**Ejemplo:**
```bash
curl "http://localhost:8000/api/hazards?latitude=3.4516&longitude=-76.5320&radius_km=5&risk_level=high"
```

#### Crear nuevo peligro
```
POST /api/hazards
```

**Body (JSON):**
```json
{
  "local_id": "uuid-local-del-cliente",
  "incident_latitude": 3.4516,
  "incident_longitude": -76.5320,
  "impact_radius_meters": 500,
  "risk_level_code": "high",
  "description": "Construcción en curso, peligroso para perros"
}
```

#### Obtener peligro específico
```
GET /api/hazards/{id}
```

#### Actualizar peligro
```
PUT /api/hazards/{id}
```

**Body (JSON):** Los mismos campos que en creación

#### Eliminar peligro (archiva)
```
DELETE /api/hazards/{id}
```

### Sincronización

#### Sincronizar peligros locales
```
POST /api/hazards/sync
```

**Body (JSON):**
```json
{
  "hazards": [
    {
      "local_id": "uuid-local-1",
      "incident_latitude": 3.4516,
      "incident_longitude": -76.5320,
      "impact_radius_meters": 500,
      "risk_level_code": "high",
      "description": "Primera lluvia, calles inundadas",
      "last_modified_at": "2024-01-15 10:30:45",
      "remote_id": null
    }
  ]
}
```

**Respuesta:**
```json
{
  "success": true,
  "message": "Sincronización completada: 1 sincronizados, 0 conflictos, 0 errores",
  "sync_results": {
    "synced": 1,
    "conflicts": 0,
    "errors": 0,
    "details": []
  }
}
```

#### Obtener peligros no sincronizados
```
GET /api/hazards/unsynced
```

## Resolución de Conflictos

El sistema utiliza **"Last Write Wins"** (LWW) para resolver conflictos de sincronización:

1. Cuando se recibe una actualización, se compara `last_modified_at`
2. Si el timestamp remoto es más nuevo, se actualiza
3. Si el timestamp local es más nuevo, se rechaza la actualización remota
4. Los conflictos retornan estado HTTP 409

**Campos clave en base de datos:**
- `last_modified_at`: Timestamp de última modificación local
- `synced_at`: Timestamp de última sincronización exitosa
- `status`: Estado (`created`, `synced`, `archived`)
- `local_id`: ID único generado en el cliente
- `remote_id`: ID en servidor global (cuando es sincronizado)

## Flujo de Sincronización

### Cliente (Flutter)

1. **Crear peligro localmente:**
   - Generar UUID único (`local_id`)
   - Guardar con `status='created'`
   - Incluir `last_modified_at` con timestamp actual

2. **Sincronizar periódicamente:**
   - Obtener peligros con `status='created'`
   - Enviar a `POST /api/hazards/sync`
   - Si exitoso: actualizar `status='synced'`, guardar `remote_id`

3. **Verificar cambios remotos:**
   - `GET /api/hazards` periódicamente
   - Comparar `remote_id` y `last_modified_at` con locales
   - Actualizar locales si hay cambios más nuevos

### Servidor (Laravel)

1. **Recibir sincronización:**
   - Validar datos
   - Resolver conflictos por timestamp
   - Actualizar o crear peligro
   - Retornar resultado

2. **Mantener integridad:**
   - Índices en `local_id` y `remote_id` para búsquedas rápidas
   - Marcar archivados en lugar de eliminar
   - Mantener historial de cambios

## Testing

### Con curl

```bash
# Crear peligro
curl -X POST http://localhost:8000/api/hazards \
  -H "Content-Type: application/json" \
  -d '{
    "local_id": "test-123",
    "incident_latitude": 3.4516,
    "incident_longitude": -76.5320,
    "impact_radius_meters": 500,
    "risk_level_code": "high",
    "description": "Test peligro"
  }'

# Obtener todos
curl http://localhost:8000/api/hazards

# Sincronizar
curl -X POST http://localhost:8000/api/hazards/sync \
  -H "Content-Type: application/json" \
  -d '{
    "hazards": [
      {
        "local_id": "test-456",
        "incident_latitude": 3.5,
        "incident_longitude": -76.6,
        "impact_radius_meters": 300,
        "risk_level_code": "medium",
        "description": "Test sync",
        "last_modified_at": "2024-01-15 10:30:45",
        "remote_id": null
      }
    ]
  }'
```

## Base de Datos

### Tabla: hazard_reports

| Campo | Tipo | Descripción |
|-------|------|-------------|
| id | bigint | PK |
| incident_latitude | decimal(10,8) | Latitud del peligro |
| incident_longitude | decimal(11,8) | Longitud del peligro |
| impact_radius_meters | decimal(8,2) | Radio de afectación en metros |
| risk_level_code | enum | Nivel: low, medium, high |
| description | string | Descripción del peligro |
| user_id | bigint | FK a users (nullable) |
| status | enum | created, synced, archived |
| local_id | string | ID unico local (cliente) |
| remote_id | string | ID unico remoto (servidor) |
| last_modified_at | timestamp | Última modificación |
| synced_at | timestamp | Última sincronización exitosa |
| created_at | timestamp | Creación en servidor |
| updated_at | timestamp | Última actualización en servidor |

## Notas Futuras

- [ ] Agregar autenticación (login/register)
- [ ] Filtrar peligros por usuario
- [ ] Agregar historial de auditoría
- [ ] Implementar webhooks para notificaciones
- [ ] Agregar fotos/multimedia a peligros
- [ ] Rate limiting para API
- [ ] Implementar featured flags para características nuevas

## Troubleshooting

### Error: "No path found" ejecutando migraciones

```bash
# Asegurar que existe la base de datos
touch database/database.sqlite
php artisan migrate
```

### Error: "SQLSTATE[HY000]: General error"

```bash
# Limpiar cache y reintentar
php artisan cache:clear
php artisan config:clear
php artisan migrate
```

### Port 8000 en uso

```bash
# Usar puerto diferente
php artisan serve --port=8001
```

## Soporte

Para reportar bugs o sugerencias, contactar al equipo de desarrollo.
