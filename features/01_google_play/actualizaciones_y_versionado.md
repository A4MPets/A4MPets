# Actualizaciones y versionado

## Objetivo

Definir una estrategia de actualizacion que no dependa solo de que el usuario reinstale la app cuando haya cambios criticos.

## Lo que Google Play sugiere

- App bundles actualizados y firmados.
- Versiones claras para release y hotfix.
- Si aplica, mecanismo de in-app updates con flujo flexible o inmediato.

## Estado actual del repo

- La app tiene una version base en `frontend/pubspec.yaml`.
- No hay flujo de in-app update implementado.
- El proyecto ya tiene un script y configuracion de Playwright, pero eso no sustituye una politica de actualizacion para usuarios.

## Brecha detectada

El proyecto define versionado SemVer con `versionName` y `versionCode` desde `frontend/pubspec.yaml`. Para v1 no se implementa Play Core in-app updates; el rollout sera manual o gradual desde Play Console.

## Pendientes concretos

- Mantener `frontend/pubspec.yaml` como fuente de `versionName+versionCode`.
- Identificar que cambios deben ser inmediatos y cuales pueden ser flexibles.
- Establecer una rutina de release notes y rollout gradual.
- Alinear la version de app con el proceso de firma y publicacion.

## Politica v1

- Hotfix: incrementar `versionCode` y, si aplica, patch SemVer.
- Minor release: incrementar version menor y `versionCode`.
- Cambios criticos de seguridad: publicar update y usar rollout gradual corto en Play Console.
- In-app updates nativos quedan como iteracion posterior.

## Relacion con el repo

La configuracion Android toma `versionName` y `versionCode` desde `frontend/pubspec.yaml`. Para la primera publicacion se usara `1.0.0+1` salvo que Play Console requiera incrementar el `versionCode`.

## Cierre v1

No se implementa Play Core in-app updates en v1. Las actualizaciones se gestionan con nuevas builds firmadas, release notes y rollout gradual manual en Play Console.
