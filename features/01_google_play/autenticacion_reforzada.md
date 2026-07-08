# Autenticacion reforzada

## Objetivo

Definir si A4MPets necesita autenticacion reforzada como segundo factor, recuperacion de cuenta o proteccion adicional de acceso.

## Aclaracion importante

Google Play no exige 2FA para publicar una app en general. Este documento existe porque el proyecto tiene autenticacion y porque, si se decide endurecer el acceso, hay que documentarlo sin romper la revision.

## Estado actual del repo

- El backend ya emite tokens propios.
- El frontend ya maneja sesion local y login.
- No existe un flujo de segundo factor.
- Tampoco hay recuperacion de cuenta documentada.

## Brecha detectada

Si la cuenta queda protegida solo por usuario y contrasena, el acceso es simple pero menos robusto para una app publica con datos personales, ubicacion y media.

## Opciones de fortalecimiento

- Segundo factor por correo o codigo temporal.
- Verificacion por dispositivo nuevo.
- Recuperacion de cuenta con enlace o codigo unico.
- Cierre de sesion remoto desde otros dispositivos.

## Relacion con Play Console

Si se agrega un segundo factor, los datos de acceso para revisores deben explicarlo con precision para no bloquear la revision.

## Siguiente paso sugerido

Decision v1: no incorporar MFA/OTP ni recuperacion de cuenta antes del primer lanzamiento. La prioridad de publicacion es tokens con caducidad, eliminacion de cuenta, acceso revisor claro y documentacion de privacidad. MFA, recuperacion y cierre remoto quedan como roadmap posterior para no agregar friccion a la revision inicial.
