# Publicacion y firma

## Objetivo

Dejar A4MPets listo para generar, firmar y distribuir una release real en Google Play.

## Lo que Google Play espera

- App Bundle firmado para release.
- Nombre, icono e identificador del paquete estables.
- Versionado coherente para nuevas subidas.
- Objetivo de API actualizado segun la politica vigente.
- Flujo de publicacion y rollout controlado.

## Estado actual del repo

- El Android namespace y el `applicationId` usan `com.a4mpets.app`.
- El label visible usa `A4MPets`.
- La build de release lee `frontend/android/key.properties` cuando existe.
- `frontend/android/key.properties` esta ignorado por git y `frontend/android/key.properties.example` documenta las variables requeridas.
- `frontend/pubspec.yaml` usa una version inicial `1.0.0+1`.

## Brecha detectada

La identidad de publicacion quedo definida. La brecha restante operativa es generar y custodiar el keystore real fuera del repositorio antes de subir a Play Console.

## Pendientes concretos

- Generar keystore real y completar `frontend/android/key.properties` local/CI.
- Verificar que el SDK Android instalado permite compilar target 35 o superior.
- Generar app bundle (`.aab`) para release.
- Definir proceso de versionado para hotfixes y nuevas versiones.
- Decidir si la publicacion sera manual, staged rollout o canal gradual.

## Comando release

```bash
cd frontend
flutter build appbundle --release --build-name 1.0.0 --build-number 1
```

## Impacto en la aceptacion

Sin esto, la app puede existir internamente pero no queda lista para una publicacion seria en Google Play.

## Cierre v1

La configuracion Android del repo queda lista para compilar releases firmadas cuando exista un `key.properties` local/CI valido y un SDK Android con API 35 o superior.
