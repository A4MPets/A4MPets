# Casos E2E Manuales Sobre Puntos Debiles Reales

| Campo | Valor |
|---|---|
| Proyecto | A4MPets |
| Tipo | Pruebas end-to-end manuales desde navegador |
| Objetivo | Ejecutar flujos completos como usuario final y detectar fallos visibles en sesion, aislamiento de datos, reportes, rutas, mapa, imagenes y recuperacion ante errores. |
| Herramienta | Chrome o Chromium con stack completo local |
| Evidencia requerida | Captura de pantalla, nombre unico usado y nota breve del resultado observado |

## Preparacion

1. Levantar el stack completo de la aplicacion.
2. Abrir el frontend en Chrome o Chromium.
3. Usar nombres unicos con fecha/hora para evitar confusiones, por ejemplo `E2E Manual 20260531 1530`.
4. Guardar evidencias en `docs/evidencias/e2e-manual-puntos-debiles/`.
5. Antes de cada caso, confirmar visualmente si la app esta con sesion iniciada o cerrada.

## Criterio General

Estos casos no se aprueban por codigos tecnicos ni por respuestas JSON. Se aprueban solo si el resultado visible para una persona usuaria coincide con lo esperado: mensajes claros, datos correctos, ausencia de datos ajenos, marcadores correctos, rutas visibles, fotos persistentes y formularios recuperables.

| Resultado | Definicion |
|---|---|
| Aprobado | El flujo completo funciona y el resultado visible coincide con lo esperado. |
| Fallido | La app permite una accion indebida, pierde datos, muestra datos ajenos, queda cargando, no dibuja elementos esperados o muestra una pantalla rota. |
| Bloqueado | No se puede ejecutar por ambiente, servicio caido, usuario inexistente o falta de dato inicial. |

## Datos Sugeridos

| Dato | Valor recomendado |
|---|---|
| Password de usuarios QA | `QAtest1234` |
| Usuario A | `qa_manual_a_<timestamp>@example.com` |
| Usuario B | `qa_manual_b_<timestamp>@example.com` |
| Mascota privada A | `Mascota Privada A <timestamp>` |
| Ruta privada A | `Ruta Privada A <timestamp>` |
| Reporte generico invitado | `Reporte Otro Invitado <timestamp>` |
| Peligro invitado | `Peligro Invitado <timestamp>` |
| Texto de evidencia | `E2E manual punto debil <timestamp>` |
| Telefono valido | `3001234567` |

## Casos

| ID | Riesgo real | Precondiciones | Pasos como usuario | Resultado visible esperado | Falla si se observa | Evidencia minima |
|---|---|---|---|---|---|---|
| E2E-001 | Un invitado podria crear reportes genericos aunque deberia estar bloqueado. | App abierta sin sesion activa. | 1. Abrir el mapa. 2. Abrir `Reportar`. 3. Elegir `Otro`. 4. Marcar una ubicacion en el mapa. 5. Escribir una descripcion unica. 6. Presionar `Crear reporte`. | La app pide iniciar sesion o bloquea el envio con un mensaje claro. No aparece marcador nuevo ni mensaje de exito. | El reporte se crea, aparece un marcador nuevo, se cierra el formulario como si hubiera sido exitoso o queda una confirmacion de creacion estando como invitado. | Captura del bloqueo o del fallo, descripcion unica usada y estado de sesion visible. |
| E2E-002 | Un invitado podria crear reportes de peligro anonimos no permitidos. | App abierta sin sesion activa. | 1. Abrir `Reportar`. 2. Elegir `Peligro`. 3. Marcar ubicacion. 4. Llenar descripcion unica. 5. Elegir nivel/radio si aplica. 6. Presionar `Reportar peligro`. | La app pide iniciar sesion o bloquea el envio. No aparece marcador ni circulo de peligro nuevo. | Se crea el peligro, aparece marcador/circulo nuevo, o se muestra exito sin sesion. | Captura del resultado, descripcion unica y nota de si aparecio marcador/circulo. |
| E2E-003 | Una cuenta nueva podria ver rutas de otro usuario; este defecto ya fue observado en F6. | Usuario A y B disponibles o registrables. | 1. Iniciar sesion como usuario A. 2. Crear una ruta con nombre unico. 3. Confirmar que aparece en `Gestionar Rutas`. 4. Cerrar sesion. 5. Registrar o iniciar sesion como usuario B. 6. Abrir `Gestionar Rutas`. 7. Abrir `Iniciar Viaje` y revisar el selector de ruta. | Usuario B ve estado vacio o solo sus propias rutas. La ruta de A no aparece en ningun listado ni selector. | La ruta de A aparece para B, se puede seleccionar, editar, borrar o usar para viaje. | Capturas de ruta visible en A y ausencia en B; si falla, captura donde B ve la ruta de A. |
| E2E-004 | Una cuenta nueva podria ver mascotas de otro usuario por errores de aislamiento de datos. | Usuario A y B disponibles o registrables. | 1. Iniciar sesion como usuario A. 2. Crear mascota con nombre unico. 3. Confirmar que aparece en `Gestionar Mascotas`. 4. Cerrar sesion. 5. Registrar o iniciar sesion como usuario B. 6. Abrir `Gestionar Mascotas`. | Usuario B no ve la mascota de A y no puede seleccionarla. | La mascota de A aparece en B, se puede abrir, editar, eliminar o usar en un reporte. | Capturas de mascota visible en A y ausencia en B; si falla, captura del listado de B. |
| E2E-005 | La planificacion de viaje puede romperse para usuarios reales si la sesion no acompana el flujo de rutas. | Usuario autenticado y GraphHopper funcionando. | 1. Iniciar sesion. 2. Crear una ruta con dos puntos. 3. Abrir `Iniciar Viaje`. 4. Seleccionar la ruta creada. 5. Esperar la planificacion. 6. Confirmar inicio de viaje. | Se dibuja una ruta en el mapa, se muestran datos de viaje y la app permite iniciar el viaje. | La app queda cargando, muestra error generico, no dibuja polilinea, pierde la ruta o devuelve al login. | Captura de ruta planificada o del error visible, nombre de ruta usado. |
| E2E-006 | La sesion o las rutas pueden perderse despues de recargar la aplicacion. | Usuario autenticado con ruta creada. | 1. Iniciar sesion. 2. Crear ruta con nombre unico. 3. Recargar la pagina del navegador. 4. Confirmar que la sesion sigue activa. 5. Abrir `Iniciar Viaje`. 6. Seleccionar la ruta y planificar. | La sesion permanece activa, la ruta propia sigue disponible y se planifica correctamente. | La app vuelve a invitado, desaparece la ruta propia, el viaje no planifica o pide login inesperadamente. | Captura antes y despues de recargar, nombre de ruta y resultado del viaje. |
| E2E-007 | Un reporte generico marcado como peligro para mascotas puede no reflejar radio/impacto en mapa o rutas. | Usuario autenticado. | 1. Abrir `Reportar`. 2. Elegir `Otro`. 3. Marcar ubicacion cerca de una ruta conocida. 4. Escribir descripcion unica. 5. Activar `Peligro para las mascotas`. 6. Elegir radio grande disponible. 7. Guardar. 8. Revisar mapa y detalle. | Aparece el marcador del reporte y un circulo/radio de impacto coherente. El detalle conserva que afecta a mascotas/rutas. | No aparece circulo, el radio no se conserva, el marcador no aparece o el detalle no refleja el peligro para mascotas. | Captura del formulario, marcador/circulo y detalle. |
| E2E-008 | Los filtros de peligro pueden no afectar la experiencia de planificacion de ruta. | Usuario autenticado, ruta creada y al menos un peligro cercano. | 1. Crear un peligro cerca de una ruta. 2. Crear o seleccionar una ruta cercana. 3. Abrir `Iniciar Viaje`. 4. Seleccionar la ruta. 5. Activar filtros `Medio` y `Alto`. 6. Observar la planificacion y las alertas. | La app muestra la ruta planificada y una senal visible de que considera peligros: cambio de ruta, alerta, contador, aviso o estado claro. | Los filtros no producen ninguna senal visible, la ruta desaparece, el viaje falla o no queda claro si los peligros fueron considerados. | Capturas antes/despues de activar filtros y descripcion del peligro creado. |
| E2E-009 | Marcar una mascota perdida como encontrada puede dejar marcadores o estados inconsistentes. | Usuario autenticado. | 1. Crear mascota con nombre unico. 2. Reportarla como perdida desde el mapa. 3. Confirmar marcador de mascota perdida. 4. Abrir detalle de la mascota. 5. Presionar `Ya se encontro` o equivalente. 6. Volver al mapa. | La mascota vuelve a estado normal y el marcador de perdida desaparece del mapa. | El marcador sigue visible, la mascota sigue perdida, aparecen reportes duplicados o el estado cambia solo en una pantalla. | Capturas del marcador antes, estado despues y mapa sin marcador perdido. |
| E2E-010 | La foto de una mascota puede no persistir al recargar o puede romperse al cargar desde backend. | Usuario autenticado e imagen valida disponible. | 1. Crear mascota con foto. 2. Confirmar que la foto se ve en listado o detalle. 3. Recargar la pagina. 4. Abrir de nuevo `Gestionar Mascotas`. 5. Abrir detalle de la mascota. | La foto sigue visible despues de recargar y no aparece rota ni reemplazada sin razon. | La foto desaparece, aparece rota, vuelve a imagen por defecto sin aviso o el detalle no carga. | Capturas antes y despues de recargar, nombre de mascota y archivo usado. |
| E2E-011 | La UI podria aceptar archivos no imagen o quedar bloqueada despues de rechazar uno. | Usuario autenticado, archivo TXT/PDF e imagen valida disponibles. | 1. Abrir formulario con campo de foto. 2. Intentar seleccionar TXT o PDF. 3. Observar resultado. 4. Intentar seleccionar una imagen valida despues. 5. Guardar el formulario. | El archivo invalido se rechaza o no es seleccionable. La app permite luego elegir una imagen valida y continuar. | Acepta archivo invalido como foto, queda bloqueada, no deja reintentar o falla al guardar despues. | Captura del rechazo o del fallo y captura posterior con imagen valida. |
| E2E-012 | Un error de red al guardar puede cerrar el formulario, perder datos o dejar la app cargando. | Usuario autenticado y formulario de reporte abierto. | 1. Abrir formulario de peligro o reporte generico. 2. Llenar ubicacion y descripcion unica. 3. Simular perdida de conexion o detener temporalmente backend. 4. Presionar guardar. 5. Restaurar conexion/backend. 6. Intentar guardar de nuevo sin volver a escribir todo. | La app muestra mensaje claro de error, conserva los datos del formulario y permite reintentar. | El panel se cierra, se pierde el texto/ubicacion, queda cargando indefinidamente o no permite reintento. | Captura del error visible, captura de datos conservados y resultado del reintento. |

## Plantilla De Evidencia

Copiar esta plantilla por cada ejecucion:

```text
Caso:
Fecha y hora:
Ambiente:
Usuario usado:
Datos unicos:
Resultado: Aprobado / Fallido / Bloqueado
Evidencias:
- Captura 1:
- Captura 2:
Observacion visible:
Hubo datos perdidos: Si / No
Hubo datos ajenos visibles: Si / No
Hubo bloqueo incorrecto: Si / No
Hubo pantalla cargando o congelada: Si / No
Hubo marcador, foto o ruta ausente: Si / No
```

## Orden Recomendado De Ejecucion

1. Ejecutar primero `E2E-001` y `E2E-002` con sesion cerrada.
2. Ejecutar `E2E-003` y `E2E-004` con dos usuarios nuevos.
3. Ejecutar `E2E-005` y `E2E-006` con el usuario A.
4. Ejecutar `E2E-007` y `E2E-008` con mapa y GraphHopper estables.
5. Ejecutar `E2E-009` a `E2E-011` para validar estados e imagenes.
6. Ejecutar `E2E-012` al final, porque altera temporalmente conectividad/backend.
