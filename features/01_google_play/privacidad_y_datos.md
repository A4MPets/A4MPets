# Privacidad y datos

## Objetivo

Documentar lo necesario para cumplir con privacidad, seguridad y Data safety en Google Play, manteniendo coherencia con el comportamiento real de Flutter y Laravel.

## Lo que exige Google Play

- Politica de privacidad accesible por URL activa.
- Declaracion completa en la seccion Data safety.
- Coherencia entre lo que la app hace y lo que declara.
- Disclosure dentro de la app cuando se usan datos sensibles o permisos sensibles.

## Lo que usa hoy A4MPets

- Sesion local con `shared_preferences`.
- Usuarios autenticados con email, nombre, token y foto de perfil.
- Ubicacion para mapa, reportes y planeacion de ruta.
- Fotos o media local para mascotas, peligros y reportes.
- Comentarios y reportes geolocalizados.
- Consultas HTTP al backend y a GraphHopper.

## Brecha detectada

La politica de privacidad, terminos, pagina publica de eliminacion y Data Safety quedaron versionados en `features/01_google_play/`. La app expone enlaces in-app usando `A4M_PUBLIC_WEB_BASE_URL`, con default documentado `https://a4mpets.com`.

## Pendientes concretos

- Publicar `politica_privacidad.md`, `terminos.md` y `eliminacion_cuenta_publica.md` en las URLs definitivas.
- Copiar la declaracion de `data_safety.md` a Play Console.
- Mantener sincronizados los documentos cuando cambie el tratamiento de datos.

## Datos que deben declararse

- Informacion de cuenta: nombre, email, identificador de usuario.
- Ubicacion precisa o aproximada cuando el usuario activa mapa o rutas.
- Fotos o media cargada por el usuario.
- Interacciones con reportes y comentarios.
- Datos tecnicos de sesion y tokens.

## Riesgo si no se atiende

Google Play exige coherencia entre el comportamiento real y lo que se declara. Si la privacy policy o el Data safety no reflejan el uso real de datos, la publicacion queda expuesta a rechazo o sancion.

## Cierre v1

El paquete documental queda listo para publicarse. Antes de enviar la app, copiar `data_safety.md` a Play Console y publicar las paginas publicas bajo el dominio configurado.
