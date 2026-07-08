# Declaracion Data Safety

Version: 1.0.0

## Datos recopilados o tratados

| Categoria Play | Datos A4MPets | Finalidad | Compartido |
|---|---|---|---|
| Informacion personal | Nombre, correo, identificador de usuario | Cuenta, autenticacion, soporte | No venta; backend propio |
| Ubicacion | Ubicacion precisa/aproximada, puntos de ruta y reportes | Mapa, rutas, alertas, reportes | GraphHopper procesa rutas cuando se planifica viaje |
| Fotos y videos | Fotos de perfil, mascotas y reportes | Identificacion visual y evidencia comunitaria | Backend propio |
| Actividad en la app | Reportes, comentarios, rutas y mascotas | Funcionalidad principal y comunidad | Backend propio |
| Identificadores | Token tecnico de sesion | Seguridad y autenticacion | Backend propio |

## Seguridad

- Transporte por HTTPS en despliegue publico.
- Contrasenas con hash.
- Tokens bearer con caducidad y revocacion.
- Eliminacion de cuenta con confirmacion por contrasena.

## Retencion

- Cuenta y datos privados: mientras la cuenta exista.
- Tokens: hasta vencimiento, logout o eliminacion de cuenta.
- Reportes/comentarios comunitarios: pueden conservarse anonimizados tras eliminar cuenta.

## Notas para Play Console

La declaracion debe mantenerse alineada con la app publicada. Si se agregan analiticas, publicidad, crash reporting externo o nuevos proveedores, este documento debe actualizarse antes de subir una nueva version.
