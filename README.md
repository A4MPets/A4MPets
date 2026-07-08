# A4MPets

A4MPets es un monorepo con frontend Flutter, backend Laravel 12 y GraphHopper como motor de rutas. La referencia principal de arquitectura vive en [docs/contexto_arquitectura_a4mpets.md](docs/contexto_arquitectura_a4mpets.md).

## Qué hay en el repositorio

- `frontend/`: interfaz Flutter, providers Riverpod, widgets y servicios de cliente.
- `backend/`: API Laravel, reglas de dominio, persistencia SQLite e integración con GraphHopper.
- `docker-compose.yml` y `docker-compose.server.yml`: orquestación de backend, frontend y GraphHopper.
- `scripts/`: utilidades de arranque, empaquetado y generación de reportes.
- `features/`: backlog documental de publicacion, vulnerabilidades y modelo de negocio.

## Requisitos

- Docker Desktop.
- PHP y Composer.
- Flutter SDK.

El mapa requerido por GraphHopper debe existir en `backend/graphhopper/data/map.osm.pbf`.

## Inicio rápido

### Todo en contenedores

```bash
docker compose up -d --build
```

URLs locales:

- Frontend: http://127.0.0.1:8080
- Backend: http://127.0.0.1:8000
- GraphHopper: http://127.0.0.1:8989

Logs útiles:

```bash
docker compose logs -f graphhopper
docker compose logs -f backend
docker compose logs -f frontend
```

Detener el stack:

```bash
docker compose down
```

### GraphHopper en contenedor y backend/frontend local

Levantar solo GraphHopper:

```bash
docker compose up -d graphhopper
```

Levantar backend local:

```bash
cd backend
composer install
copy .env.example .env
php artisan key:generate
php artisan config:clear
php artisan serve
```

Levantar frontend local:

```bash
cd frontend
flutter pub get
flutter run -d chrome
```

Si GraphHopper corre en local, el backend usa estas variables en `backend/.env`:

```env
GRAPHHOPPER_BASE_URL=http://127.0.0.1:8989
GRAPHHOPPER_API_KEY=
API_TOKEN_LIFETIME_MINUTES=43200
```

Para builds Android publicables, la app usa `com.a4mpets.app` y el nombre visible `A4MPets`. La URL publica de privacidad/terminos se configura al compilar Flutter:

```bash
cd frontend
flutter build appbundle --release --build-name 1.0.0 --build-number 1 --dart-define=A4M_PUBLIC_WEB_BASE_URL=https://a4mpets.com
```

La firma release lee `frontend/android/key.properties`; usa `frontend/android/key.properties.example` como plantilla y no subas el keystore al repositorio.

Aplicar cambios:

```bash
cd backend
php artisan config:clear
```

## Comandos rápidos

```bash
docker compose restart graphhopper
docker compose ps
```

## Automatización de navegador

Playwright está disponible en el root del proyecto y se usa con la configuración `playwright.f5.config.js`.

- Paquetes verificados: `playwright@1.59.1` y `@playwright/test@1.59.1`.
- Script disponible: `npm run test:e2e:f5`.

## Lectura recomendada

Para entender el sistema sin entrar al área de pruebas, empieza por:

1. [docs/contexto_arquitectura_a4mpets.md](docs/contexto_arquitectura_a4mpets.md)
2. `backend/routes/api.php`
3. `frontend/lib/main.dart`
