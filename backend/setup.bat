@echo off
REM Script para configurar y ejecutar el backend de A4M Pets

echo.
echo ===================================
echo A4M Pets - Backend Setup
echo ===================================
echo.

REM Verificar si estamos en la carpeta backend
if not exist "composer.json" (
    echo Error: Este script debe ejecutarse desde la carpeta backend
    echo Por favor navega a: backend\
    pause
    exit /b 1
)

REM Paso 1: Instalar dependencias
echo [1/4] Instalando dependencias con Composer...
call composer install
if errorlevel 1 goto error

REM Paso 2: Generar APP_KEY si no existe
echo.
echo [2/4] Generando APP_KEY...
php artisan key:generate --quiet
if errorlevel 1 goto error

REM Paso 3: Crear base de datos si no existe
echo.
echo [3/4] Preparando base de datos...
if not exist "database\database.sqlite" (
    echo Creando database.sqlite...
    type nul > database\database.sqlite
)

REM Paso 4: Ejecutar migraciones
echo.
echo [4/4] Ejecutando migraciones...
call php artisan migrate --quiet
if errorlevel 1 goto error

echo.
echo ===================================
echo Configuración completada exitosamente!
echo ===================================
echo.
echo Pasos finales:
echo 1. Abre una nueva terminal PowerShell
echo 2. Ejecuta: php "I:\projects\A4MPets\backend\artisan" serve --port=8000
echo 3. El servidor estara disponible en http://localhost:8000
echo.
echo Una vez que el servidor este corriendo, puedes probar los endpoints:
echo   PowerShell: .\test-api-v2.ps1
echo.
goto end

:error
echo.
echo ERROR: Fallo durante la configuracion
echo Por favor verifica que:
echo - PHP esta instalado y en el PATH
echo - Composer esta instalado
echo - Tienes permisos para crear archivos
pause
exit /b 1

:end
