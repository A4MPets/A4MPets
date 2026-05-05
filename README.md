# A4MPets

Guia minima para ejecutar el proyecto en dos modos.

## Requisitos

- Docker Desktop
- PHP + Composer
- Flutter SDK

Mapa requerido para GraphHopper:

backend/graphhopper/data/map.osm.pbf

## Modo 1: Todo en contenedores

Desde la raiz del repo:

```bash
docker compose up -d --build
```

URLs:

- Frontend: http://127.0.0.1:8080
- Backend: http://127.0.0.1:8000
- GraphHopper: http://127.0.0.1:8989

Logs:

```bash
docker compose logs -f graphhopper
docker compose logs -f backend
docker compose logs -f frontend
```

Detener todo:

```bash
docker compose down
```

## Modo 2: GraphHopper en contenedor + Backend/Frontend local

### 1) Levantar solo GraphHopper (Docker)

Desde la raiz del repo:

```bash
docker compose up -d graphhopper
```

### 2) Levantar Backend local

En otra terminal:

```bash
cd backend
composer install
copy .env.example .env
php artisan key:generate
php artisan config:clear
php artisan serve
```

Backend local:

- http://127.0.0.1:8000

### 3) Levantar Frontend local

En otra terminal:

```bash
cd frontend
flutter pub get
flutter run -d chrome
```

### 4) Configuración de backend para GraphHopper local

En backend/.env:

```env
GRAPHHOPPER_BASE_URL=http://127.0.0.1:8989
GRAPHHOPPER_API_KEY=
```

Aplicar cambios:

```bash
cd backend
php artisan config:clear
```

## Comandos rapidos

Reiniciar solo GraphHopper:

```bash
docker compose restart graphhopper
```

Ver estado:

```bash
docker compose ps
```
