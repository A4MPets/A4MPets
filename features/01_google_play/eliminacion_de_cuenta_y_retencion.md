# Eliminacion de cuenta y retencion

## Objetivo

Cumplir con la expectativa de Google Play para que el usuario pueda solicitar y ejecutar la eliminacion de su cuenta y entender que pasa con sus datos.

## Lo que Google Play espera

- Mecanismo de eliminacion accesible.
- Explicacion clara de retencion o anonimizado.
- Coherencia entre el flujo de eliminacion y la politica de privacidad.

## Estado actual del repo

- Existe `DELETE /api/auth/account` con contrasena y confirmacion `ELIMINAR`.
- La app muestra `Eliminar cuenta` desde el panel de perfil.
- La politica publica de borrado vive en `eliminacion_cuenta_publica.md`.
- La informacion del usuario, mascotas, reportes y comentarios se persiste en backend.

## Brecha detectada

La brecha tecnica principal queda cerrada. La brecha operativa restante es publicar la URL definitiva y reflejarla en Play Console.

## Pendientes concretos

- Publicar `https://a4mpets.com/eliminacion-cuenta` o ajustar `A4M_PUBLIC_WEB_BASE_URL`.
- Verificar el flujo en la build enviada a revision.
- Revisar periodicamente que nuevos modelos con datos personales se incluyan en el borrado o anonimizacion.

## Riesgo si no se atiende

Si la app permite crear cuenta pero no ofrece una forma clara de eliminarla, la publicacion queda debil ante revision de politicas y frente a usuarios que pidan control sobre sus datos.

## Cierre v1

El endpoint, el flujo in-app y la politica publica quedan definidos. Antes de revision, verificar el flujo en la build firmada contra el backend QA o produccion preparado para Play Console.
