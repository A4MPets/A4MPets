# Acceso para revisor de Google Play

## Cuenta QA

Usar solo en entornos local, QA o builds preparados para revision.

- Usuario/correo: `reviewer@a4mpets.test`
- Contrasena: `ReviewerPass123!`

La cuenta se crea por seeder solo en entornos `local` y `testing`.

## Pasos de revision

1. Abrir A4MPets.
2. Entrar al panel de perfil.
3. Elegir `Iniciar Sesion`.
4. Usar las credenciales QA.
5. Revisar mascotas, rutas, mapa, reportes, comentarios, privacidad, terminos y eliminacion de cuenta.

## Permisos esperados

- Ubicacion: se solicita cuando el usuario usa mapa, centrar ubicacion, reportes o rutas.
- Notificaciones: se usan para estado de audio/navegacion cuando hay viaje activo.
- Foreground service media playback: mantiene indicaciones de audio en primer plano.
- TTS query: permite detectar servicios de texto a voz para indicaciones.

## Observaciones

Si se activa eliminacion de cuenta durante una revision, volver a ejecutar seeders o crear una cuenta nueva de revision antes del siguiente ciclo.
