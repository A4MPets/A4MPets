# A4MPets

## Guía rápida para ejecutar el proyecto

Proyecto monorepo:

-   **backend/** → API en Laravel 12 (PHP + SQLite)\
-   **frontend/** → App en Flutter

------------------------------------------------------------------------

### 1. Requisitos (una sola vez en el PC)

Ya deberían estar instalados y funcionando:

-   **PHP** (ruta tipo `C:\src\php-8.x...`)
-   **Composer**
-   **Flutter SDK** (ruta tipo `C:\src\flutter`)
-   **Git**
-   **Navegador** (Chrome recomendado para Flutter web)

#### 🔗 Links oficiales de descarga

-   **Git**\
    https://git-scm.com/download/win

-   **PHP 8.x para Windows**\
    https://windows.php.net/download/

-   **Composer (Windows installer)**\
    https://getcomposer.org/download/

-   **Flutter SDK para Windows**\
    https://docs.flutter.dev/get-started/install/windows

> Recomendado pero opcional:\
> **Visual Studio Code** → https://code.visualstudio.com/

------------------------------------------------------------------------

### 2. Primera vez que clono el repositorio

``` bash
git clone <url-del-repo> A4MPets
cd A4MPets
```

------------------------------------------------------------------------

### 2.1. Backend (Laravel) -- configuración inicial

``` bash
cd backend

# Instalar dependencias
composer install

# Copiar archivo de entorno
copy .env.example .env  # en PowerShell/CMD de Windows

# Generar APP_KEY
php artisan key:generate
```

Editar el archivo **`backend/.env`** y asegurarse de que quede así para
la base de datos SQLite:

``` env
DB_CONNECTION=sqlite
DB_DATABASE=database/database.sqlite

SESSION_DRIVER=file
CACHE_DRIVER=file
```

Crear el archivo de base de datos (vacío) en:

``` text
backend/database/database.sqlite
```

Luego ejecutar las migraciones:

``` bash
php artisan migrate
```

Si todo sale bien, ya se puede levantar el servidor:

``` bash
php artisan serve
# Servidor en: http://127.0.0.1:8000
```

------------------------------------------------------------------------

### 2.2. Frontend (Flutter) -- configuración inicial

Desde la raíz del proyecto (si aún no existe la carpeta):

``` bash
cd A4MPets
flutter create frontend   # Solo la primera vez
```

Entrar a la carpeta del frontend y obtener dependencias:

``` bash
cd frontend
flutter pub get
```

Probar la app en Chrome:

``` bash
flutter run -d chrome
```

------------------------------------------------------------------------

## 3. Cada vez que quiera ejecutar el proyecto

### 3.1. Levantar el backend (Laravel)

En una terminal:

``` bash
cd A4MPets/backend
php artisan serve
# http://127.0.0.1:8000
```

### 3.2. Levantar el frontend (Flutter)

En otra terminal:

``` bash
cd A4MPets/frontend
flutter run -d chrome
```

### 3.3. Levantar todo con Docker Compose (frontend + backend + graphhopper)

Desde la raíz del repo:

```bash
docker compose up --build
```

Servicios disponibles:

- Frontend Flutter web: `http://localhost:8080`
- Backend Laravel API: `http://localhost:8000`
- GraphHopper: `http://localhost:8989`

Si quieres parar todo:

```bash
docker compose down
```

Si prefieres seguir ejecutando frontend y backend en local, pero usar solo GraphHopper en contenedor:

```bash
docker compose up graphhopper
```

------------------------------------------------------------------------

## 4. Comandos útiles

-   Limpiar caché/config de Laravel (por si cambio algo en `.env`):

``` bash
cd backend
php artisan config:clear
php artisan cache:clear
php artisan optimize:clear
```

-   Volver a correr migraciones (si cambio el esquema):

``` bash
cd backend
php artisan migrate
```

------------------------------------------------------------------------

## 5. Notas

-   Si aparece un error tipo
    **`could not find driver (Connection: sqlite)`**:

    -   Revisar que en `php.ini` estén activadas las extensiones:

        ``` ini
        extension=pdo_sqlite
        extension=sqlite3
        ```

    -   Cerrar terminal, abrir otra y probar de nuevo.

-   Siempre tener **dos terminales**:

    -   Una para `php artisan serve`
    -   Otra para `flutter run -d chrome`

------------------------------------------------------------------------

## 6. GraphHopper Self-Hosted (Docker)

Para evitar límites de APIs externas, este proyecto usa GraphHopper local como
parte del mismo `docker-compose.yml`.

### 6.1. Requisitos

-   Docker Desktop instalado y corriendo.

### 6.2. Preparar datos de mapa

1. Descargar un `.osm.pbf` (por ejemplo de Geofabrik).
2. Guardarlo como:

```text
backend/graphhopper/data/map.osm.pbf
```

### 6.3. Levantar solo GraphHopper

Desde la raíz del repo:

```bash
docker compose up -d graphhopper
```

La primera vez puede tardar varios minutos porque GraphHopper importa el mapa
y construye el grafo en `backend/graphhopper/data/graph-cache`.

### 6.4. Verificar servicio

```bash
curl http://127.0.0.1:8989/health
```

### 6.5. Configurar backend Laravel local

En `backend/.env`:

```env
GRAPHHOPPER_BASE_URL=http://127.0.0.1:8989
GRAPHHOPPER_API_KEY=
```

Luego limpiar config cache:

```bash
cd backend
php artisan config:clear
```

Con eso, `/api/routes/plan` usará GraphHopper local sin API key.
