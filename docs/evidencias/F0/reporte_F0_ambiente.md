# Reporte de Evidencias - Fase F0: Preparacion y Smoke de Ambiente

**Proyecto:** A4MPets  
**Fecha de ejecucion:** 2026-05-08  
**Fase:** F0 - Preparacion y smoke de ambiente  
**Herramientas:** PowerShell, npm, Composer, Artisan, Docker, GraphHopper, Cloudflared  
**Entorno:** Windows, repositorio local `C:\projects\Web\A4MPets`

---

## Resumen Ejecutivo

La fase F0 valida que el entorno base del proyecto este listo para continuar con las fases automatizadas y de integracion del plan de pruebas.

Se verificaron:

- Estructura del repositorio y carpetas de evidencias.
- Dependencias de Node.js, PHP/Composer y Flutter.
- Arranque temporal del backend Laravel.
- Health check del backend.
- Migraciones y tablas principales.
- Registro y login de usuarios QA.
- Middleware de autenticacion sin token.
- Configuracion y arranque de GraphHopper.
- Ruta basica y ruta con tres puntos en GraphHopper.
- Generacion temporal de URL publica con Cloudflare Tunnel.
- Version bajo prueba en Git.

Resultado general:

| Estado | Cantidad |
|---|---:|
| PASS | 20 |
| PASS parcial | 1 |
| No ejecutado visualmente | 1 |
| FAIL | 0 |

## Version Bajo Prueba

Comandos ejecutados:

```bash
git log -1 --format="%H %ai %s"
git branch --show-current
```

Resultado:

```text
Commit: 6ba3ff8584167eb30ca8ed902c524ffa5d5f23a1
Fecha: 2026-05-08 13:26:31 -0500
Mensaje: pre test creation
Rama: feature/fixes
```

## Verificacion de Dependencias

Comandos y resultados relevantes:

```bash
node --version
npm --version
php --version
composer --version
flutter --version
npm ls concurrently puppeteer --depth=0
composer check-platform-reqs
```

Resultado:

| Componente | Resultado |
|---|---|
| Node.js | v24.15.0 |
| npm | 11.12.1 |
| PHP | 8.4.19 |
| Composer | 2.9.7 |
| Flutter | 3.41.7 |
| Dart | 3.11.5 |
| `concurrently` | Instalado: 9.2.1 |
| `puppeteer` | Instalado: 24.42.0 |
| Composer platform reqs | Todas las dependencias requeridas en estado `success` |

Validaciones de archivos/carpetas:

| Elemento | Estado |
|---|---|
| `backend/` | Existe |
| `frontend/` | Existe |
| `docs/` | Existe |
| `scripts/` | Existe |
| `package.json` raiz | Existe |
| `node_modules/` raiz | Existe |
| `backend/vendor/` | Existe |
| `docs/evidencias/F0` a `F8` | Existen |

## Backend Laravel

### Arranque temporal

Comando ejecutado:

```bash
npm run backend -- --dry-run
```

Resultado:

```text
Server running on [http://0.0.0.0:8000]
Backend listo en: http://127.0.0.1:8000/
Exit code: 0
```

### Health check

Solicitud ejecutada:

```http
GET http://127.0.0.1:8000/api/health
```

Resultado:

```text
HEALTH status=ok timestamp=2026-05-08T19:04:54.045707Z
```

### Registro y login QA

Solicitudes ejecutadas:

```http
POST /api/auth/register
POST /api/auth/login
GET /api/auth/me sin Authorization
```

Resultado:

| Validacion | Resultado |
|---|---|
| Registro `qa_a4m_01@example.com` | PASS, `success=true`, token de 64 caracteres |
| Registro `qa_a4m_02@example.com` | PASS, `success=true`, token de 64 caracteres |
| Login `qa_a4m_01@example.com` | PASS, `success=true`, token de 64 caracteres |
| `/api/auth/me` sin token | PASS, HTTP 401 |

## Base de Datos

Comando ejecutado:

```bash
php artisan migrate:status
```

Resultado:

```text
Todas las migraciones listadas aparecen en estado Ran.
Ultima migracion aplicada: 2026_05_01_000021_remove_domain_sync_columns
```

Tablas principales verificadas:

| Tabla | Estado |
|---|---|
| `users` | Existe |
| `pets` | Existe |
| `hazard_reports` | Existe |
| `lost_pet_reports` | Existe |
| `found_pet_reports` | Existe |
| `generic_reports` | Existe |
| `routes` | Existe |
| `route_points` | Existe |
| `report_comments` | Existe |
| `hazard_comments` | Existe |

## Frontend Flutter

Comando ejecutado:

```bash
npm run frontend -- --dry-run
```

Resultado:

```text
URLs API configuradas:
http://localhost:8000/api |
http://127.0.0.1:8000/api |
http://192.168.1.3:8000/api

Archivo generado:
frontend\env\runtime.local.json
```

Estado:

| Validacion | Estado |
|---|---|
| Flutter SDK disponible | PASS |
| Runner frontend genera configuracion runtime | PASS |
| Arranque visual en Chrome y validacion de mapa | No ejecutado visualmente en esta corrida |

## GraphHopper

### Configuracion

Archivos verificados:

| Elemento | Resultado |
|---|---|
| `backend/graphhopper/config.yml` | Existe |
| Perfil `car` | Definido |
| Perfil `foot` | Definido |
| Puertos configurados | 8989 HTTP, 8990 admin |
| `backend/graphhopper/data/map.osm.pbf` | Existe |
| Tamano `map.osm.pbf` | 311,442,414 bytes |

### Arranque del contenedor

Comando ejecutado:

```bash
npm run graphhopper
```

Resultado:

```text
Container a4mpets-graphhopper Started
```

Estado posterior:

```text
a4mpets-graphhopper   Up About a minute (healthy)   0.0.0.0:8989-8990->8989-8990/tcp
```

### Rutas de prueba

Ruta con dos puntos:

```http
GET http://127.0.0.1:8989/route?point=3.4516,-76.5320&point=3.4570,-76.5280&profile=car&type=json
```

Resultado:

```text
ROUTE status=200 paths=1 distance=1376.638
```

Ruta con tres puntos:

```http
GET http://127.0.0.1:8989/route?point=3.4516,-76.5320&point=3.4570,-76.5280&point=3.4620,-76.5240&profile=car&type=json
```

Resultado:

```text
ROUTE_3POINTS status=200 paths=1 distance=2279.574
```

## Docker y Docker Compose

Comandos ejecutados:

```bash
docker --version
docker compose version
docker ps --filter name=a4mpets-graphhopper
```

Resultado:

| Componente | Resultado |
|---|---|
| Docker CLI | 29.4.0 |
| Docker Compose | v5.1.1 |
| Contenedor GraphHopper | `Up ... (healthy)` |
| Puertos | 8989 y 8990 expuestos |

## Cloudflare Tunnel

Comandos ejecutados:

```bash
cloudflared --version
npm run backend:cloudflare -- --dry-run
```

Resultado:

```text
cloudflared version 2025.8.1
Tunnel detectado: https://steven-strange-ensure-satin.trycloudflare.com
Tunnel listo en: https://steven-strange-ensure-satin.trycloudflare.com/
URL publica guardada en: .runtime\cloudflare-url.txt
Exit code: 0
```

Nota: el comando fue ejecutado en modo `--dry-run`; el runner crea la URL temporal, valida conectividad y luego limpia procesos/archivos runtime al cerrarse.

## Docker Compose y Scripts

Validacion estatica de `docker-compose.yml`:

| Servicio | Validacion | Estado |
|---|---|---|
| `graphhopper` | Puertos 8989/8990, volumen de mapa, `config.yml` | PASS |
| `backend` | Puerto 8000, SQLite, `GRAPHHOPPER_BASE_URL=http://graphhopper:8989` | PASS |
| `frontend` | Puerto 8080, dependencia de backend | PASS |

Validacion de scripts en `package.json`:

| Script | Estado |
|---|---|
| `npm run backend` | Definido y validado con `--dry-run` |
| `npm run frontend` | Definido y validado con `--dry-run` |
| `npm run graphhopper` | Definido y ejecutado |
| `npm run dev` | Definido con backend, frontend y graphhopper via `concurrently` |
| `npm run dev:cloudflare` | Definido con backend cloudflare, frontend runtime y graphhopper |

## Mapeo de Casos F0

| Caso | Resultado | Evidencia |
|---|---|---|
| F0-001 | PASS | Estructura raiz verificada. |
| F0-002 | PASS | `node_modules`, `concurrently` y `puppeteer` instalados. |
| F0-003 | PASS | `backend/vendor` existe y `composer check-platform-reqs` en success. |
| F0-004 | PASS | `npm run backend -- --dry-run` inicia Laravel en puerto 8000. |
| F0-005 | PASS | `/api/health` responde `status=ok`. |
| F0-006 | PASS parcial | `npm run frontend -- --dry-run` genera runtime y Flutter existe. |
| F0-007 | No ejecutado visualmente | No se abrio Chrome para validar mapa en esta corrida. |
| F0-008 | PASS | `npm run graphhopper` inicia contenedor. |
| F0-009 | PASS | GraphHopper responde ruta con `paths=1`. |
| F0-010 | PASS | `config.yml` define perfiles `car` y `foot`. |
| F0-011 | PASS | `map.osm.pbf` existe y pesa 311,442,414 bytes. |
| F0-012 | PASS | Cloudflare Tunnel genera URL `trycloudflare.com` en modo dry-run. |
| F0-013 | PASS | Migraciones en `Ran` y tablas principales existen. |
| F0-014 | PASS | Registro QA principal exitoso. |
| F0-015 | PASS | Registro QA secundario exitoso. |
| F0-016 | PASS | Login QA principal exitoso. |
| F0-017 | PASS | Carpetas `docs/evidencias/F0` a `F8` existen. |
| F0-018 | PASS | `docker-compose.yml` define servicios, puertos y volumenes esperados. |
| F0-019 | PASS parcial | Scripts `dev` definidos; componentes validados por separado. No se dejo stack persistente levantado con `npm run dev`. |
| F0-020 | PASS | Commit y rama registrados. |
| F0-021 | PASS | Rutas con 2 y 3 puntos de Cali devuelven `paths=1`. |
| F0-022 | PASS | `/api/auth/me` sin token responde HTTP 401. |

## Hallazgos F0

| # | Hallazgo | Impacto | Tratamiento |
|---|---|---|---|
| 1 | La validacion visual del mapa en Chrome no se ejecuto en esta corrida. | F0-007 queda pendiente de evidencia visual. | Cubrir en F4 o en una corrida F0 visual con captura del navegador. |
| 2 | La primera consulta a GraphHopper fallo por conexion mientras el contenedor terminaba de inicializar. | Riesgo normal de arranque frio/indexacion. | Se espero 60 segundos y la ruta respondio HTTP 200. |
| 3 | `npm run backend:cloudflare -- --dry-run` crea y valida una URL temporal, pero limpia `.runtime/cloudflare-url.txt` al terminar. | La URL no queda persistida despues del dry-run. | Para pruebas manuales largas usar `npm run dev:cloudflare` sin `--dry-run`. |

## Conclusiones

El ambiente queda apto para continuar el ciclo de pruebas:

- Backend Laravel arranca y responde health.
- Base de datos migrada y tablas principales disponibles.
- Usuarios QA pueden registrarse e iniciar sesion.
- GraphHopper arranca, queda healthy y responde rutas sobre coordenadas de Cali.
- Cloudflare Tunnel puede generar una URL publica temporal.
- Dependencias principales de Node.js, PHP/Composer y Flutter estan instaladas.

Pendiente especifico: generar evidencia visual de F0-007 abriendo el frontend en Chrome y verificando el mapa renderizado.
