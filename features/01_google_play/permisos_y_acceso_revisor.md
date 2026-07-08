# Permisos y acceso de revisor

## Objetivo

Cerrar la parte operativa de permisos sensibles y acceso para revision en Play Console.

## Lo que Google Play espera

- Declaracion de permisos si la app solicita permisos sensibles o de alto riesgo.
- Instrucciones claras para el revisor cuando la app tiene login o pantallas restringidas.
- Evidencia de por que cada permiso existe y para que flujo se usa.

## Estado actual del repo

- Android ya solicita ubicacion fina y gruesa.
- Android ya solicita notificaciones.
- Android ya declara foreground service para reproduccion de audio.
- El manifiesto tambien declara consulta a `TTS_SERVICE`.
- La app tiene login por email/nombre.
- Existe `acceso_revisor.md` con credenciales QA y pasos de revision.

## Brecha detectada

El paquete documental queda cubierto por `acceso_revisor.md`, la tabla de permisos de este documento y la cuenta QA creada por seeder solo en entornos `local` y `testing`.

## Pendientes concretos

- Copiar las instrucciones de `acceso_revisor.md` a Play Console.
- Preparar una build QA con backend sembrado antes de enviar a revision.
- Mantener credenciales de revisor fuera de produccion si el entorno publico no usa datos de prueba.

## Permisos que ya deben justificarse

- Ubicacion: mapa, seleccion de ubicacion y planeacion de ruta.
- Notificaciones: estado de la app, alertas o comunicaciones de sistema.
- Foreground service: reproduccion de audio o soporte de navegacion en primer plano.
- TTS: soporte de lectura o salida de voz si el flujo lo activa.

## Riesgo si no se atiende

La revision puede bloquearse por no poder entrar a la app o por permisos sin explicacion clara en Play Console.

## Cierre v1

La justificacion de permisos y el acceso revisor quedan documentados. Copiar estos datos a Play Console antes de enviar la build.
