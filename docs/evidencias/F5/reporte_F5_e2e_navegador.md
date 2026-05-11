# Reporte de Evidencias - Fase F5: Pruebas E2E de Caja Negra en Navegador

**Proyecto:** A4MPets  
**Fecha de ejecucion:** 2026-05-09, hora local America/Bogota  
**Fase:** F5 - Caja negra E2E navegador  
**Herramienta:** Playwright / Chromium / Flutter Web / Laravel / GraphHopper / base de datos local  
**Entorno:** Stack local en `C:\projects\Web\A4MPets`

---

## Resumen Ejecutivo

La fase F5 fue implementada y ejecutada como una suite E2E de caja negra en navegador usando Playwright sobre Chromium. A diferencia de F3 y F4, estas pruebas no llaman servicios internos ni controladores directamente como atajo funcional: interactuan con la aplicacion desde la interfaz final de Flutter Web, simulando acciones de una persona usuaria.

La suite valida flujos completos sobre el stack local:

- Frontend Flutter Web servido en navegador.
- Backend Laravel real.
- Base de datos local real.
- GraphHopper local levantado por Docker.
- Comunicacion HTTP real entre frontend y backend.
- Render, formularios, paneles, mapa, marcadores, rutas, reportes y comentarios desde la UI.

Resultado final de ejecucion:

| Area | Resultado |
|---|---:|
| Stack local F5 | PASS |
| GraphHopper local | PASS |
| Backend Laravel `/api/health` | PASS |
| Flutter Web en Chromium | PASS |
| Activacion de `flt-semantics` | PASS |
| Suite Playwright F5 | 23 passed |
| Estado final F5 | Aprobada |

## Diferencia Frente a F3 y F4

F3 valida integracion backend/API desde Laravel con pruebas Feature, por lo que comprueba contratos HTTP, validaciones, permisos y persistencia desde el lado del backend.

F4 valida tecnicamente que el sistema integrado local pueda levantarse y comunicarse: backend, frontend, base de datos y GraphHopper. Su objetivo es confirmar el estado del stack completo.

F5 valida el sistema desde el navegador como caja negra. La prueba no conoce controladores, modelos ni servicios internos; observa botones, formularios, mensajes visibles, paneles, mapa y respuestas reales provocadas por acciones de usuario. Por eso F5 complementa a F3/F4 en lugar de repetirlas.

## Problemas Encontrados y Soluciones

| Problema | Impacto | Solucion aplicada |
|---|---|---|
| Flutter Web no siempre estaba listo cuando Playwright iniciaba. | Chromium podia abrir una pagina aun sin superficie Flutter renderizada. | Se implemento `scripts/f5-stack.js` con readiness de Laravel, GraphHopper, Flutter, `main.dart.js` y deteccion de `flutter-view/canvas`. |
| La UI de Flutter Web se renderiza principalmente en canvas. | Selectores DOM como `getByText()` no eran confiables para botones y formularios. | Se adaptaron los helpers E2E para activar y usar `flt-semantics`. |
| Algunos controles no tenian etiquetas accesibles estables. | Playwright no podia encontrar botones flotantes o acciones especificas sin usar coordenadas fragiles. | Se agregaron labels `Semantics`/`Tooltip` minimos en controles utiles tambien para accesibilidad real. |
| Varias pruebas iniciales no eran concluyentes. | Algunos casos solo hacian click en un panel sin confirmar edicion, borrado o envio real. | Se reforzaron las pruebas para llenar formularios, esperar requests reales y verificar cambios visibles. |
| La sesion se perdia al recargar la app durante los tests. | Los flujos autenticados fallaban despues del login. | Se dejo de limpiar `localStorage` en cada apertura y se mantuvo la sesion durante la suite serial. |
| Flutter Web debug es lento para flujos largos. | Algunos casos complejos excedian el timeout base. | Se ajustaron timeouts por caso y se mantuvo una suite serial por dependencia de estado de usuario. |

## Implementacion Realizada

### Infraestructura E2E

Se agrego un proyecto Playwright para F5:

| Archivo | Proposito |
|---|---|
| `playwright.f5.config.js` | Configura Chromium, timeouts, reportes, `webServer` y salida de artefactos F5. |
| `scripts/f5-stack.js` | Levanta/verifica GraphHopper, Laravel y Flutter Web; expone endpoint `/ready` para Playwright. |
| `tests/e2e/f5/helpers.js` | Centraliza helpers para abrir la app, activar semantics, llenar campos, hacer clicks y esperar respuestas API provocadas por UI. |
| `tests/e2e/f5/f5-e2e.spec.js` | Contiene los flujos funcionales principales F5-001 a F5-014 y F5-017 a F5-022. |
| `tests/e2e/f5/f5-responsive.spec.js` | Contiene validacion responsive F5-015/F5-016. |

Tambien se agrego el script:

```json
"test:e2e:f5": "playwright test --config=playwright.f5.config.js"
```

### Ajustes Minimos de Accesibilidad para E2E

Se realizaron cambios puntuales en frontend para exponer acciones reales a la capa de accesibilidad de Flutter Web:

| Archivo | Ajuste |
|---|---|
| `frontend/lib/widgets/map_widget.dart` | Labels para abrir marcadores de peligro, mascota perdida, mascota encontrada y reporte generico. |
| `frontend/lib/pages/map_page_components.dart` | Labels para seleccionar mascotas, seleccionar rutas, agregar mascota para viaje e iniciar viaje. |
| `frontend/lib/widgets/pet_management_panels.dart` | Labels para seleccionar y editar una mascota especifica. |
| `frontend/lib/widgets/route_management_panels.dart` | Labels para seleccionar una ruta especifica. |
| `frontend/lib/widgets/panel_modal.dart` | Labels para expandir y minimizar paneles. |

Estos cambios no reemplazan la validacion visual; permiten que Playwright encuentre controles reales de la app sin depender de coordenadas absolutas.

### Ajustes Funcionales Necesarios para E2E

Durante la validacion se identificaron detalles que impedian que el flujo navegador-backend fuera estable:

| Archivo | Ajuste |
|---|---|
| `frontend/lib/models/pet_record.dart` | Lectura robusta de JSON de mascotas devuelto por backend. |
| `frontend/lib/repositories/user_local_repository.dart` | Peticiones autenticadas de mascotas y rutas incluyen token bearer. |
| `frontend/lib/providers/pet_providers.dart` | Recarga de datos tras mutaciones de mascotas. |
| `frontend/lib/providers/route_providers.dart` | Recarga de datos tras mutaciones de rutas. |
| `frontend/lib/providers/async_list_controller.dart` | Flag para desactivar refrescos de fondo durante F5. |
| `frontend/lib/services/backend_api_client.dart` | Timeout de fallback ampliado para stack local lento. |

## Procedimiento de Ejecucion

1. Se reviso que Playwright pudiera iniciar Chromium y abrir Flutter Web.
2. Se implemento `scripts/f5-stack.js` como servidor de preparacion de entorno.
3. El stack verifico GraphHopper local en `http://127.0.0.1:8989/health`.
4. El stack verifico Laravel en `http://127.0.0.1:8000/api/health`.
5. Se genero `frontend/env/runtime.local.json` apuntando al backend local.
6. Se levanto Flutter Web en `http://127.0.0.1:7357`.
7. Playwright espero el endpoint `http://127.0.0.1:7358/ready`.
8. Cada test abrio la app, activo la capa `flt-semantics` y ejecuto acciones de usuario.
9. Para acciones criticas, los tests esperaron la request HTTP real producida por la UI.
10. Al finalizar, Playwright genero reporte HTML, JSON y artefactos de diagnostico.

## Comandos Ejecutados

Validacion sintactica de scripts y specs:

```bash
node --check scripts\f5-stack.js
node --check playwright.f5.config.js
node --check tests\e2e\f5\helpers.js
node --check tests\e2e\f5\f5-e2e.spec.js
node --check tests\e2e\f5\f5-responsive.spec.js
```

Validacion del frontend tras ajustes minimos:

```bash
flutter analyze
```

Ejecuciones focalizadas usadas durante correccion:

```bash
npx playwright test --config=playwright.f5.config.js --project=F5-desktop-chromium -g "F5-001 registro|F5-002 login"
npx playwright test --config=playwright.f5.config.js --project=F5-desktop-chromium -g "F5-001 registro|F5-004|F5-005"
npx playwright test --config=playwright.f5.config.js --project=F5-desktop-chromium -g "F5-001 registro|F5-006|F5-007"
npx playwright test --config=playwright.f5.config.js --project=F5-desktop-chromium -g "F5-001 registro|F5-019"
npx playwright test --config=playwright.f5.config.js --project=F5-desktop-chromium tests/e2e/f5/f5-responsive.spec.js
```

Ejecucion final:

```bash
npx playwright test --config=playwright.f5.config.js --project=F5-desktop-chromium
```

Resultado final:

```text
23 passed (28.3m)
Exit code: 0
```

## Ejecuciones Focalizadas Relevantes

| Comando focalizado | Resultado |
|---|---:|
| `F5-001 registro\|F5-002 login` | 2 passed |
| `F5-001 registro\|F5-004\|F5-005` | 3 passed |
| `F5-001 registro\|F5-006\|F5-007` | 3 passed |
| `F5-001 registro\|F5-011\|F5-012` | 3 passed |
| `F5-001 registro\|F5-019` | 2 passed |
| `F5-001 registro\|F5-020\|F5-021\|F5-022` | 4 passed |
| `f5-responsive.spec.js` | 1 passed |

## Evidencias Generadas

| Evidencia | Ruta |
|---|---|
| Reporte principal F5 | `docs/evidencias/F5/reporte_F5_e2e_navegador.md` |
| Reporte HTML Playwright | `docs/evidencias/F5/playwright-report/index.html` |
| Log del stack F5 | `docs/evidencias/F5/f5-stack.log` |
| Artefactos temporales Playwright | `test-results/f5` |
| Diagnosticos por caso | `test-results/f5-fixtures` |
| Configuracion Playwright | `playwright.f5.config.js` |
| Specs E2E | `tests/e2e/f5` |

Nota: `test-results` es una carpeta temporal administrada por Playwright y puede limpiarse al iniciar nuevas corridas. La evidencia formal queda centralizada en `docs/evidencias/F5`, y el resultado final concluyente se documenta en este reporte como `23 passed (28.3m)`.

## Resultado por Caso

| Caso | Resultado | Validacion concluyente realizada |
|---|---|---|
| F5-001 | PASS | Registro real de usuario unico desde UI y sesion activa posterior. |
| F5-001-extra | PASS | Registro con campos obligatorios vacios y validacion visible. |
| F5-002 | PASS | Login real, acceso a gestion de mascotas y logout desde la interfaz. |
| F5-002-extra | PASS | Login invalido y mensaje de error visible. |
| F5-003 | PASS | Creacion real de mascota con nombre, fecha y foto desde panel de UI. |
| F5-004 | PASS | Edicion real de mascota existente, espera de `PUT /api/pets/{id}` y verificacion del nuevo nombre en UI. |
| F5-005 | PASS | Eliminacion real de mascota, confirmacion, espera de `DELETE /api/pets/{id}` y ausencia en UI. |
| F5-006 | PASS | Creacion real de reporte de mascota perdida desde mapa, formulario lleno y request `POST` validada. |
| F5-007 | PASS | Creacion real de reporte de mascota encontrada vinculado a reporte perdido. |
| F5-008 | PASS | Creacion real de reporte de peligro con ubicacion, descripcion, radio, categoria y foto. |
| F5-009 | PASS | Creacion real de reporte generico desde la capa de reportes del mapa. |
| F5-010 | PASS | Apertura de marcador de peligro y comentario real sobre el reporte. |
| F5-011 | PASS | Creacion de ruta desde UI, planificacion real y validacion de coordenadas de ruta. |
| F5-012 | PASS | Planificacion de viaje con filtros de peligro y confirmacion de inicio de viaje. |
| F5-013 | PASS | Usuario no autenticado bloqueado en acciones privadas desde UI. |
| F5-014 | PASS | Aislamiento entre usuarios: datos de otro usuario no aparecen en gestion propia. |
| F5-015 | PASS | Viewport escritorio sin overflow horizontal critico. |
| F5-016 | PASS | Viewport movil validado tras redimensionar navegador, sin overflow critico. |
| F5-017 | PASS | Edicion real de ruta existente y verificacion de actualizacion visible. |
| F5-018 | PASS | Eliminacion real de ruta, confirmacion y espera de `DELETE /api/routes/{id}`. |
| F5-019 | PASS | Mascota marcada como encontrada con `POST /api/pets/{id}/mark-found`; se verifica que el marcador perdido desaparece. |
| F5-020 | PASS | Formulario de reporte acepta texto extendido y lo conserva en el flujo. |
| F5-021 | PASS | Comentarios reales en peligro, mascota perdida, mascota encontrada y reporte generico. |
| F5-022 | PASS | Smoke final sin errores criticos de consola ni respuestas HTTP 500. |

## Correccion de Pruebas No Concluyentes

Durante la revision se detecto que algunas pruebas iniciales solo navegaban o hacian click sin comprobar el efecto real. Se reforzaron asi:

| Caso | Antes | Despues |
|---|---|---|
| F5-004 | Abria el flujo de editar mascota. | Edita el nombre, espera `PUT /api/pets/{id}` y verifica el nombre actualizado. |
| F5-005 | Abria el flujo de eliminacion. | Crea una mascota temporal, confirma borrado, espera `DELETE /api/pets/{id}` y valida ausencia. |
| F5-006 | No garantizaba que el formulario de perdida estuviera completo. | Llena mascota, descripcion, ubicacion, contacto, envia y valida request `POST`. |
| F5-011 | No garantizaba ruta planificada. | Espera `/api/routes/plan`, valida respuesta exitosa y coordenadas. |
| F5-012 | No verificaba el camino con filtros. | Valida request de planificacion con evitacion/filtros antes de iniciar viaje. |
| F5-018 | Solo accedia al flujo de ruta. | Confirma eliminacion y espera `DELETE /api/routes/{id}`. |
| F5-019 | Requeria mas tiempo en suite completa. | Se amplio timeout del caso y se valida el `POST mark-found` real. |
| F5-021 | Era demasiado general. | Crea comentarios reales sobre los cuatro tipos principales de reportes. |

## Consideraciones de Caja Negra

Las pruebas F5 interactuan por UI:

- Clicks sobre botones y paneles visibles.
- Escritura en campos de formulario.
- Seleccion de ubicaciones en el mapa.
- Confirmaciones de dialogos.
- Navegacion responsive en Chromium.

Las esperas de red se usan como comprobacion del efecto producido por la UI, no como atajo para crear datos saltandose la interfaz. Las unicas verificaciones directas de backend previas corresponden al readiness tecnico del stack: `/api/health`, GraphHopper health y carga de Flutter Web.

## Hallazgos F5

| # | Hallazgo | Tratamiento |
|---|---|---|
| F5-1 | Flutter Web con canvas no es fiable con selectores DOM tradicionales. | Se migro la suite a helpers basados en `flt-semantics`. |
| F5-2 | Algunas acciones de mapa requieren coordenadas porque son interacciones espaciales. | Se limitaron coordenadas a seleccion de ubicacion/puntos de ruta, donde es parte natural del flujo. |
| F5-3 | La suite completa es lenta en Flutter debug web-server. | Se documento el tiempo final y se mantiene ejecucion serial por flujos encadenados. |
| F5-4 | `test-results` puede limpiarse entre corridas. | La evidencia formal se almacena en `docs/evidencias/F5`. |

## Conclusiones

La fase F5 queda aprobada. Playwright ejecuta los flujos E2E en Chromium contra el stack local completo y valida desde la interfaz final los caminos principales de usuario: autenticacion, mascotas, reportes, peligros, rutas, viaje, comentarios, permisos, aislamiento de datos, responsive y ausencia de errores criticos.

La corrida final confirmada fue:

```text
23 passed (28.3m)
```

Con esto F5 queda separada conceptualmente de F3/F4 y aporta evidencia real de comportamiento de usuario en navegador.
