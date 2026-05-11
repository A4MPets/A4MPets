# Reporte de Evidencias - Fase F6: Pruebas Manuales Funcionales

**Proyecto:** A4MPets  
**Fecha de ejecucion:** 2026-05-11  
**Fase:** F6 - Pruebas manuales funcionales  
**Responsable de ejecucion:** QA manual  
**Herramientas:** Chrome / DevTools / Capturas de pantalla / Stack local A4MPets  
**Entorno:** `C:\projects\Web\A4MPets`

---

## Resumen Ejecutivo

La fase F6 corresponde a pruebas manuales funcionales y exploratorias. Su objetivo es revisar comportamientos visibles de la aplicacion que no se validan completamente con pruebas unitarias, integracion API, sistema integrado o E2E automatizado.

Esta fase debe ser ejecutada manualmente por QA desde el navegador, observando:

- Claridad de mensajes de error.
- Estados vacios.
- Estados de carga.
- Permisos de ubicacion.
- Datos limite y caracteres especiales.
- Comportamiento responsive.
- Accesibilidad basica por teclado.
- Contraste y legibilidad.
- Recuperacion visual ante errores.
- Consistencia de paneles, mapa, reportes, mascotas y perfil.

Resultado general:

| Campo | Valor |
|---|---|
| Casos planificados | 22 |
| Casos ejecutados o justificados | 22 |
| Casos aprobados | 19 |
| Casos fallidos | 1 |
| Casos bloqueados | 0 |
| Casos N/A justificados | 2 |
| Defectos criticos | 0 |
| Defectos altos | 0 |
| Defectos medios | 1 |
| Defectos bajos | 0 |
| Decision F6 | Aprobada con observaciones |

La fase F6 fue ejecutada manualmente desde navegador. El unico caso fallido corresponde a una inconsistencia funcional de privacidad/aislamiento en rutas de usuario, registrada como `DEF-F6-001`. Los casos fallidos o con defecto asociado quedan documentados para ser corregidos antes de la fase F8, de forma que la validacion final se ejecute sobre una version estabilizada del sistema.

## Alcance de F6

F6 no reemplaza las pruebas automatizadas ya ejecutadas:

- F1: pruebas unitarias backend.
- F2: pruebas unitarias y widget tests frontend.
- F3: integracion backend/API.
- F4: sistema integrado local de caja blanca.
- F5: caja negra E2E automatizada en navegador.

F6 complementa esas fases mediante inspeccion manual de experiencia de usuario, estados visuales y condiciones dificiles de automatizar.

## Ambiente Requerido

Antes de ejecutar F6, confirmar:

| Componente | Estado esperado | Resultado real |
|---|---|---|
| Backend Laravel | `http://localhost:8000/api/health` responde `status=ok` | PASS |
| Frontend Flutter Web | La app carga en Chrome sin pantalla blanca | PASS |
| GraphHopper | Servicio disponible para rutas | PASS |
| Base de datos local | Datos QA disponibles o ambiente limpio | PASS |
| Chrome DevTools | Consola y Network disponibles | PASS |
| Permisos de ubicacion | Se pueden aceptar, denegar y reiniciar desde el navegador | PASS |
| Viewport desktop | 1366x768 o similar | PASS |
| Viewport movil | 390x844 o similar desde DevTools | PASS |

## Preparacion Recomendada

1. Abrir una terminal en `C:\projects\Web\A4MPets`.
2. Levantar el stack local:

```bash
npm run dev
```

Alternativa con Docker:

```bash
docker compose up -d --build
```

3. Confirmar backend:

```bash
curl http://localhost:8000/api/health
```

4. Abrir la aplicacion en Chrome.
5. Abrir DevTools y mantener disponibles las pestanas Console y Network.
6. Preparar usuarios QA:

| Usuario | Email | Password |
|---|---|---|
| QA principal | `qa_a4m_01@example.com` | `QAtest1234` |
| QA secundario | `qa_a4m_02@example.com` | `QAtest1234` |

7. Preparar datos y archivos:

| Dato | Valor sugerido |
|---|---|
| Coordenadas base | `3.4516,-76.5320`, `3.4570,-76.5280`, `3.4620,-76.5240` |
| Mascota base | `Luna QA` |
| Telefono valido | `3001234567` |
| Archivo valido | PNG/JPG menor a 1 MB |
| Archivo invalido | TXT o PDF |
| Texto con caracteres especiales | `Peligro en la caneria, atencion al nino. Hay danos y riesgo alto. 🐾` |
| Texto largo | Texto de minimo 500 caracteres |

## Criterios de Resultado

| Resultado | Definicion |
|---|---|
| PASS | El comportamiento observado coincide con el resultado esperado. |
| FAIL | El comportamiento observado no coincide con el resultado esperado. |
| BLOCKED | El caso no se pudo ejecutar por dependencia, ambiente o dato faltante. |
| N/A | El caso no aplica por decision documentada. |

## Criterios de Severidad

| Severidad | Definicion |
|---|---|
| Critica | Impide usar un flujo principal o causa perdida/corrupcion de datos. |
| Alta | Bloquea una funcionalidad importante, pero existe workaround limitado. |
| Media | Afecta usabilidad, claridad o consistencia sin bloquear totalmente. |
| Baja | Problema visual menor, texto mejorable o inconsistencia no bloqueante. |

## Convencion de Evidencias

Guardar evidencias en:

```text
C:\projects\Web\A4MPets\docs\evidencias\F6\fotos
```

Nombres sugeridos:

| Tipo | Formato |
|---|---|
| Captura | `F6-001_validacion_registro.png` |
| Captura movil | `F6-016_viewport_movil.png` |
| Consola | `F6-016_console.txt` |
| Network/HAR | `F6-016_network.har` |
| Video corto | `F6-011_paneles.mp4` |
| Defecto | `DEF-F6-001_descripcion_corta.png` |

## Matriz de Ejecucion F6

| ID | Objetivo | Datos / condiciones | Resultado esperado | Resultado real | Estado | Evidencia | Defecto |
|---|---|---|---|---|---|---|---|
| F6-001 | Validar mensajes de error del registro. | Campos vacios, correo invalido, contrasena corta, contrasenas no coincidentes. | Cada campo muestra mensaje descriptivo junto al campo, sin tecnicismos. | Cada error se muestra en la parte inferior del panel por separado. | PASS | [F6-001-errores-registro.png](fotos/F6-001-errores-registro.png) | N/A |
| F6-002 | Validar mensajes de error del login. | Correo inexistente y correo existente con contrasena incorrecta. | El mensaje no revela si el usuario existe; muestra credenciales invalidas. | Los mensajes de error se muestran correctamente dependiendo del error cometido por el usuario. | PASS | [F6-002-errores-login.png](fotos/F6-002-errores-login.png) | N/A |
| F6-003 | Validar estado vacio de mascotas. | Usuario autenticado sin mascotas. | Mensaje orientativo indica que no hay mascotas y como crear la primera. | Se muestra el mensaje que indica que no hay mascotas correctamente. | PASS | [F6-003-mascotas-vacias.png](fotos/F6-003-mascotas-vacias.png) | N/A |
| F6-004 | Validar estado vacio de rutas. | Usuario autenticado sin rutas. | Mensaje adecuado indica que no hay rutas y orienta como crear una. | Si hay rutas creadas para esta cuenta recien hecha, esto no deberia ocurrir. | FAIL | [F6-004-rutas-vacias-fail.png](fotos/F6-004-rutas-vacias-fail.png) | DEF-F6-001 |
| F6-005 | Validar estado de carga al crear reportes. | Reporte de peligro completo. | Indicador de carga visible; boton deshabilitado o con estado de procesamiento. | El reporte funciona correctamente y crea el reporte. | PASS | [F6-005-crear-peligros.png](fotos/F6-005-crear-peligros.png) | N/A |
| F6-006 | Validar denegacion de permisos de ubicacion. | Permiso de ubicacion denegado en Chrome. | El mapa carga, se muestra mensaje informativo y seleccion manual funciona. | Denegar la ubicacion aun permite el correcto funcionamiento del resto de funcionalidades que no lo requiere; las que lo requieren lo solicitan directamente. | PASS | [F6-006-denegar-ubicacion.png](fotos/F6-006-denegar-ubicacion.png), [F6-006-ubicacion-denegada.png](fotos/F6-006-ubicacion-denegada.png) | N/A |
| F6-007 | Validar aceptacion de permisos de ubicacion. | Permiso de ubicacion aceptado en Chrome. | El mapa centra en la ubicacion del usuario o cercana y muestra marcador distinguible. | La aceptacion y utilizacion de permisos de ubicacion funciona correctamente. | PASS | [F6-007-ubicacion-aceptada.png](fotos/F6-007-ubicacion-aceptada.png), [F6-007-ubicacion-aceptada-mapa.png](fotos/F6-007-ubicacion-aceptada-mapa.png) | N/A |
| F6-008 | Validar caracteres especiales en reportes. | Acentos, enie, signos y emojis. | Los caracteres se guardan y muestran sin corrupcion ni simbolos de reemplazo. | Los reportes permiten caracteres especiales en el reporte. | PASS | [F6-008-caracteres-especiales.png](fotos/F6-008-caracteres-especiales.png) | N/A |
| F6-009 | Validar autor y orden de comentarios. | Realizar comentarios con diversas cuentas en un reporte. | Cada comentario muestra autor correcto y orden cronologico. | Cada comentario se ordena cronologicamente. | PASS | [F6-009-comentarios-peligros.png](fotos/F6-009-comentarios-peligros.png) | N/A |
| F6-010 | Validar nombre obligatorio al crear mascota. | Campo nombre vacio. | Mensaje visible indica que el nombre es obligatorio y no se envia al backend. | No es posible crear una mascota sin nombre porque se le asigna un nombre por defecto automaticamente. | PASS | [F6-010-mascotas.png](fotos/F6-010-mascotas.png) | N/A |
| F6-011 | Validar apertura/cierre de paneles. | Paneles de mascotas, rutas, reportes y capas. | No quedan residuos visuales ni estados inconsistentes; el mapa se mantiene usable. | Todos los paneles fueron verificados correctamente | PASS | N/A | N/A |
| F6-012 | Validar diferenciacion visual de riesgos. | Peligros bajo, medio y alto. | Circulos de impacto tienen colores/estilos distinguibles y leyenda comprensible. | Los peligros se distinguen correctamente por sus tipos y colores asociados. | PASS | [F6-012-peligros.png](fotos/F6-012-peligros.png) | N/A |
| F6-013 | Validar telefono en reportes de mascotas. | `3001234567` y texto `abc`. | Acepta telefono valido y rechaza o impide texto no numerico. | No es posible ingresar caracteres diferentes a numeros en este tipo de campos. | PASS | [F6-013-telefono-mascota.png](fotos/F6-013-telefono-mascota.png) | N/A |
| F6-014 | Validar formato de fechas. | Mascota y reportes con fechas variadas. | Fechas legibles, consistentes y no como timestamp tecnico. | El selector de fecha funciona correctamente y es comodo para el usuario. | PASS | [F6-014-fechas.png](fotos/F6-014-fechas.png) | N/A |
| F6-015 | Validar detalle completo de peligro. | Peligro con descripcion, riesgo, categoria, duracion, radio, foto y ubicacion. | Todos los campos se muestran completos, sin datos faltantes ni imagen rota. | Es posible crear peligros con imagenes y rellenar toda la solicitud. | PASS | [F6-015-datos-peligros.png](fotos/F6-015-datos-peligros.png) | N/A |
| F6-016 | Validar recuperacion ante error de red al guardar reporte. | Backend detenido o red desconectada durante envio. | Mensaje claro de error; formulario no queda bloqueado y permite reintento. | El error del envio se muestra correctamente y permite reenvio. | PASS | [F6-016-error-al-enviar-reporte.png](fotos/F6-016-error-al-enviar-reporte.png) | N/A |
| F6-017 | Validar camara/zoom del mapa al abrir/cerrar paneles. | Mapa en posicion y zoom personalizados. | Al cerrar paneles, el mapa conserva posicion y nivel de zoom. | Los diferentes niveles de zoom funcionan correctamente con los diferentes paneles. | PASS | N/A | N/A |
| F6-018 | Validar navegacion por teclado. | Uso exclusivo de tecla Tab y Enter/Espacio. | Botones principales reciben foco visible y orden logico. | No aplica: no se implemento manejo completo para teclado y Flutter Web no expone controles como DOM HTML tradicional. | N/A | N/A | N/A |
| F6-019 | Validar contraste y legibilidad. | Paneles login, registro, mascotas, reportes, rutas y detalles. | Textos legibles con contraste suficiente en paneles principales. | Verificado en modo oscuro y modo claro. | PASS | [F6-019-legibilidad.png](fotos/F6-019-legibilidad.png), [F6-019-legibilidad-dark.png](fotos/F6-019-legibilidad-dark.png) | N/A |
| F6-020 | Validar archivo subido de tipo no imagen en upload de imagenes. | Probar subir TXT o PDF en un campo de foto; luego, probar imagen valida. | Rechaza archivo invalido con mensaje claro y permite imagen valida despues. | El sistema no permite la carga de formatos no admitidos. | PASS | [F6-020-archivo-formato-incorrecto.png](fotos/F6-020-archivo-formato-incorrecto.png) | N/A |
| F6-021 | Validar carga del listado de peligros. | Listado de peligros con latencia normal o simulada desde DevTools. | Indicador de carga visible y datos aparecen despues. | No aplica para F6; se delega a F7 por tratarse de comportamiento asociado a carga/latencia. | N/A | N/A | N/A |
| F6-022 | Validar panel de perfil. | Usuario con nombre, correo y foto de perfil. | Panel muestra nombre, correo y foto sin datos faltantes ni imagen rota. | El panel de perfil muestra correctamente la informacion del usuario. | PASS | [F6-022-info-perfil.png](fotos/F6-022-info-perfil.png) | N/A |

## Registro de Defectos Encontrados

| ID defecto | Caso | Severidad | Titulo | Pasos para reproducir | Resultado esperado | Resultado observado | Evidencia | Estado |
|---|---|---|---|---|---|---|---|---|
| DEF-F6-001 | F6-004 | Media | Rutas no asociadas al usuario aparecen en una cuenta nueva | Iniciar sesion con una cuenta de prueba recien creada, abrir el panel de rutas y verificar que aparecen rutas que no pertenecen al usuario. | El usuario nuevo no deberia tener rutas asociadas y el panel deberia mostrar estado vacio. | Se observaron multiples rutas en una cuenta que debia estar vacia. | [F6-004-rutas-vacias-fail.png](fotos/F6-004-rutas-vacias-fail.png) | Pendiente de correccion antes de F8 |

## Observaciones de Cierre

- No se registraron defectos criticos ni altos durante la ejecucion manual.
- Los casos `F6-018` y `F6-021` se marcaron como `N/A` por justificacion tecnica: navegacion completa por teclado no esta implementada para Flutter Web y validacion de carga/latencia se cubrira en F7.
- El defecto `DEF-F6-001` debe corregirse antes de F8 para que la validacion final no arrastre problemas de aislamiento de datos entre cuentas.
- Las evidencias fotograficas quedaron vinculadas desde la matriz principal en `docs/evidencias/F6/fotos`.

## Cierre de F6

| Criterio | Resultado |
|---|---|
| Todos los casos F6-001 a F6-022 fueron ejecutados o justificados | Si |
| No hay defectos criticos abiertos | Si |
| No hay defectos altos sin decision | Si |
| La evidencia esta guardada en `docs/evidencias/F6` | Si |
| Se actualizaron resultados reales en esta matriz | Si |

**Decision final:** Aprobada con observaciones  

**Comentarios finales:**  
La fase F6 permitio validar manualmente los flujos funcionales principales del sistema desde navegador. En general, la aplicacion presenta mensajes comprensibles, estados visuales adecuados, buen comportamiento de permisos de ubicacion, manejo correcto de formularios, carga de imagenes y visualizacion consistente de reportes, peligros, mascotas y perfil.

El unico defecto funcional relevante fue `DEF-F6-001`, asociado a rutas visibles en una cuenta nueva. Este hallazgo no bloquea el cierre documental de F6, pero debe corregirse antes de F8 para asegurar aislamiento de datos por usuario en la validacion final. Con esa observacion, F6 queda cerrada como aprobada con observaciones.
