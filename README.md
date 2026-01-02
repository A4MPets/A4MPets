# A4MPets
# TEST

## Guía rápida para ejecutar el proyecto

Proyecto monorepo:

- **backend/** → API en Laravel 12 (PHP + SQLite)
- **frontend/** → App en Flutter

### 1. Requisitos (una sola vez en el PC)

Ya deberían estar instalados y funcionando:

- **PHP** (ruta tipo `C:\src\php-8.x...`)
- **Composer**
- **Flutter SDK** (ruta tipo `C:\src\flutter`)
- **Git**
- **Navegador** (Chrome recomendado para Flutter web)

### 2. Primera vez que clono el repositorio

```bash
git clone <url-del-repo> A4MPets
cd A4MPets
```

### 2.1. Backend (Laravel) – configuración inicial

```bash
cd backend

# Instalar dependencias
composer install

# Copiar archivo de entorno
copy .env.example .env  # en PowerShell/CMD de Windows

# Generar APP_KEY
php artisan key:generate
```

Editar el archivo **`backend/.env`** y asegurarse de que quede así para la base de datos SQLite:

```env
DB_CONNECTION=sqlite
DB_DATABASE=database/database.sqlite

SESSION_DRIVER=file
CACHE_DRIVER=file
```

Crear el archivo de base de datos (vacío) en:

```text
backend/database/database.sqlite
```

Luego ejecutar las migraciones:

```bash
php artisan migrate
```

Si todo sale bien, ya se puede levantar el servidor:

```bash
php artisan serve
# Servidor en: http://127.0.0.1:8000
```

---

### 2.2. Frontend (Flutter) – configuración inicial

Desde la raíz del proyecto (si aún no existe la carpeta):

```bash
cd A4MPets
flutter create frontend   # Solo la primera vez
```

Entrar a la carpeta del frontend y obtener dependencias:

```bash
cd frontend
flutter pub get
```

Probar la app en Chrome:

```bash
flutter run -d chrome
```

---

## 3. Cada vez que quiera ejecutar el proyecto

### 3.1. Levantar el backend (Laravel)

En una terminal:

```bash
cd A4MPets/backend
php artisan serve
# http://127.0.0.1:8000
```

### 3.2. Levantar el frontend (Flutter)

En otra terminal:

```bash
cd A4MPets/frontend
flutter run -d chrome
```

---

## 4. Comandos útiles

* Limpiar caché/config de Laravel (por si cambio algo en `.env`):

  ```bash
  cd backend
  php artisan config:clear
  php artisan cache:clear
  php artisan optimize:clear
  ```

* Volver a correr migraciones (si cambio el esquema):

  ```bash
  cd backend
  php artisan migrate
  ```

---

## 5. Notas

* Si aparece un error tipo **`could not find driver (Connection: sqlite)`**:

  * Revisar que en `php.ini` estén activadas las extensiones:

    ```ini
    extension=pdo_sqlite
    extension=sqlite3
    ```
  * Cerrar terminal, abrir otra y probar de nuevo.

* Siempre tener **dos terminales**:

  * Una para `php artisan serve`
  * Otra para `flutter run -d chrome`
