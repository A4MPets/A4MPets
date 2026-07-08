# Politica de privacidad de A4MPets

Version: 1.0.0  
Vigencia: 2026-06-28  
URL objetivo: `https://a4mpets.com/privacidad`

## Responsable

A4MPets opera una app para registrar mascotas, crear reportes comunitarios, planear rutas y recibir alertas relacionadas con mascotas y riesgos cercanos.

Contacto de privacidad: `privacidad@a4mpets.com`.

## Datos que tratamos

- Cuenta: nombre de usuario, correo, identificador interno, contrasena cifrada y token tecnico de sesion.
- Ubicacion: ubicacion precisa o aproximada cuando el usuario usa mapa, reportes, rutas o viaje.
- Mascotas: nombre, fechas, estado, fotos y metadatos de mascotas registradas.
- Reportes: ubicacion, descripcion, fotos, comentarios, fecha, nivel de riesgo y datos de contacto cuando el usuario los aporta.
- Datos tecnicos: errores, peticiones al backend y datos necesarios para mantener sesion y sincronizacion.

## Finalidades

- Autenticar usuarios y mantener sesiones.
- Mostrar mapa, reportes cercanos, rutas y alertas.
- Guardar mascotas, rutas y reportes creados por el usuario.
- Permitir comentarios y colaboracion comunitaria.
- Mantener seguridad, integridad del servicio y soporte operativo.

## Terceros y procesamiento

El frontend consulta el backend de A4MPets por HTTPS. El backend puede consultar GraphHopper para calcular rutas. GraphHopper procesa puntos de ruta y parametros de viaje necesarios para devolver instrucciones, distancia y duracion.

A4MPets no vende datos personales.

## Seguridad y retencion

Las contrasenas se guardan con hash. Los tokens de sesion tienen caducidad real y pueden revocarse con logout o eliminacion de cuenta. La media subida se guarda en buckets internos del backend y se sirve por endpoint controlado.

Los datos privados de cuenta se conservan mientras la cuenta exista. Al eliminar una cuenta, A4MPets borra tokens, mascotas, rutas y media privada, y anonimiza los reportes/comentarios comunitarios para preservar la utilidad del mapa sin conservar identidad personal.

## Derechos del usuario

El usuario puede cerrar sesion, actualizar su perfil y eliminar su cuenta desde la app. Tambien puede solicitar ayuda escribiendo a `privacidad@a4mpets.com`.

## Cambios

Los cambios relevantes se versionan en este repositorio y deben reflejarse en la ficha de Google Play y en la app.
