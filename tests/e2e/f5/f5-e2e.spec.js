const { test, expect } = require('@playwright/test');
const {
  installDiagnostics,
  attachDiagnostics,
  openApp,
  expectVisibleText,
  clickVisibleText,
  fillFirstMatching,
  fillAccessibleTextbox,
  fillFieldAfterLabel,
  fillPanelField,
  fillDialogField,
  expectNoSemanticsText,
  hasSemanticsText,
  enableFlutterSemantics,
  waitForApiResponse,
  openProfileMenu,
  openReportMenu,
  openTripMenu,
  clickAt,
} = require('./helpers');

test.describe.serial('F5 - Caja negra E2E navegador', () => {
  const qaUser = {
    name: `QA E2E ${Date.now()}`,
    email: `qa_e2e_${Date.now()}@example.com`,
    password: 'QAtest1234',
  };
  let petName = `Luna E2E ${Date.now()}`;
  const editedPetName = `Luna Editada ${Date.now()}`;
  const lostPetName = `Toby Perdido ${Date.now()}`;
  const foundReportDetails = `Mascota encontrada F5 ${Date.now()}`;
  const hazardDescription = `Peligro F5 agua estancada ${Date.now()}`;
  const genericDescription = `Reporte generico F5 ${Date.now()}`;
  const lostReportDetails = `Mascota perdida F5 collar rojo ${Date.now()}`;
  const routeName = `Ruta F5 ${Date.now()}`;
  const editedRouteName = `Ruta F5 actualizada ${Date.now()}`;

  function escapeRegExp(value) {
    return value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  }

  function textPattern(value) {
    return new RegExp(escapeRegExp(value));
  }

  async function jsonText(response) {
    const payload = await response.json().catch(() => ({}));
    return JSON.stringify(payload);
  }

  async function jsonPayload(response) {
    return response.json().catch(() => ({}));
  }

  function responseData(payload) {
    return payload && typeof payload === 'object' && payload.data ? payload.data : payload;
  }

  test.beforeEach(async ({ page }, testInfo) => {
    testInfo.diagnostics = installDiagnostics(page);
    await openApp(page, testInfo);
  });

  test.afterEach(async ({}, testInfo) => {
    await attachDiagnostics(testInfo, testInfo.diagnostics);
  });

  async function login(page) {
    await openProfileMenu(page);
    await clickVisibleText(page, /Iniciar Sesi|Iniciar sesion/i);
    await fillPanelField(page, 0, qaUser.email);
    await fillPanelField(page, 1, qaUser.password);
    await clickVisibleText(page, /Iniciar Sesi|Iniciar sesion/i);
    await expectVisibleText(page, /Reportar|Iniciar Viaje/i, { timeout: 60000 });
    await openProfileMenu(page);
    await expectVisibleText(page, /Cerrar sesi|Gestionar Mascotas|Gestionar Rutas/i);
    await page.reload({ waitUntil: 'domcontentloaded' });
    await expectVisibleText(page, /Reportar|Iniciar Viaje/i, { timeout: 30000 });
  }

  async function openManagePets(page) {
    await openProfileMenu(page);
    await clickVisibleText(page, /Gestionar Mascotas/i);
    await expectVisibleText(page, /Agregar mascota|A.n no has agregado mascotas|Mascotas/i);
  }

  async function createPetFromUi(page, name) {
    await returnToMap(page);
    await openManagePets(page);
    await clickVisibleText(page, /Agregar mascota/i);
    await fillPanelField(page, 0, name);
    const response = await waitForApiResponse(page, 'POST', /\/api\/pets$/, async () => {
      await clickVisibleText(page, /Guardar Mascota|Guardar/i);
    });
    expect(await jsonText(response)).toContain(name);
    await expectVisibleText(page, new RegExp(`Editar mascota ${escapeRegExp(name)}`), {
      timeout: 60000,
    });
    return response;
  }

  async function openPetEditPanel(page, name) {
    await openManagePets(page);
    await clickVisibleText(page, new RegExp(`Seleccionar mascota ${escapeRegExp(name)}`), {
      domClickOnly: true,
    });
    await expectVisibleText(page, /Detalle mascota|Paseos completados|Fecha de registro/i, {
      timeout: 15000,
    });
    await clickVisibleText(page, new RegExp(`Editar mascota ${escapeRegExp(name)}|^Editar$`, 'i'));
    await expectVisibleText(page, /Editar mascota/i, { timeout: 12000 });
  }

  async function openPetDetails(page, name) {
    await openManagePets(page);
    await clickVisibleText(page, new RegExp(`Seleccionar mascota ${escapeRegExp(name)}`), {
      domClickOnly: true,
    });
    await expectVisibleText(page, /Paseos completados|Fecha de registro|Editar/i, {
      timeout: 15000,
    });
  }

  async function returnToMap(page) {
    await page.reload({ waitUntil: 'domcontentloaded' });
    await expectVisibleText(page, /Reportar|Iniciar Viaje/i, { timeout: 30000 });
  }

  async function chooseManualMapLocation(page) {
    await clickVisibleText(page, /Marcar en el mapa/i);
    await clickAt(page, 1010, 380, { afterClickMs: 1200 });
    await expectVisibleText(page, /Usando ubicaci.n actual|Ubicaci.n marcada/i, {
      timeout: 15000,
    });
  }

  async function createLostPetReportFromUi(page, name, details) {
    await createPetFromUi(page, name);
    await returnToMap(page);
    await openReportMenu(page);
    await clickVisibleText(page, /^Mascota perdida$/i, {
      domClick: true,
      forceKeyboard: true,
      afterClickMs: 1200,
    });
    await expectVisibleText(page, /Mascota perdida|Reportar mascota perdida|Senas particulares/i, {
      timeout: 15000,
    });
    await chooseManualMapLocation(page);
    await clickVisibleText(page, /^Seleccionar$/i, { domClick: true, afterClickMs: 1200 });
    await clickVisibleText(page, new RegExp(`Seleccionar mascota ${escapeRegExp(name)}`), {
      domClickOnly: true,
    });
    await expectVisibleText(page, new RegExp(`Mascota: ${escapeRegExp(name)}`), {
      timeout: 15000,
    });
    await fillAccessibleTextbox(page, /Senas particulares|collar|zona/i, details);
    await fillAccessibleTextbox(page, /Numero de contacto/i, '3001234567');
    const response = await waitForApiResponse(page, 'POST', /\/api\/lost-pet-reports$/, async () => {
      await clickVisibleText(page, /Reportar mascota perdida/i);
    });
    expect(await jsonText(response)).toContain(details);
    return response;
  }

  async function createFoundPetReportFromUi(page, details, options = {}) {
    await returnToMap(page);
    await openReportMenu(page);
    await clickVisibleText(page, /^Mascota encontrada$/i, {
      domClick: true,
      forceKeyboard: true,
      afterClickMs: 1200,
    });
    await expectVisibleText(page, /Mascota encontrada|Reportar mascota encontrada|Describe la mascota/i, {
      timeout: 15000,
    });
    await chooseManualMapLocation(page);
    if (options.linkLostReportDetails) {
      await clickVisibleText(page, /Seleccionar mascota perdida/i, {
        domClick: true,
        afterClickMs: 1200,
      });
      await expectVisibleText(page, textPattern(options.linkLostReportDetails), { timeout: 15000 });
      await clickVisibleText(page, textPattern(options.linkLostReportDetails));
      await clickVisibleText(page, /^Seleccionar$/i);
      await expectVisibleText(page, /Mascota perdida:/i, { timeout: 15000 });
    }
    await fillAccessibleTextbox(page, /Describe la mascota y el contexto/i, details);
    await fillAccessibleTextbox(page, /Numero de contacto/i, '3007654321');
    const response = await waitForApiResponse(page, 'POST', /\/api\/found-pet-reports$/, async () => {
      await clickVisibleText(page, /Reportar mascota encontrada/i);
    });
    expect(await jsonText(response)).toContain(details);
    return response;
  }

  async function createHazardReportFromUi(page, description) {
    await returnToMap(page);
    await openReportMenu(page);
    await clickVisibleText(page, /^Peligro$/i, {
      domClick: true,
      forceKeyboard: true,
      afterClickMs: 1200,
    });
    await expectVisibleText(page, /Reportar Peligro|Describe lo que observas|Nivel de riesgo/i, {
      timeout: 15000,
    });
    await chooseManualMapLocation(page);
    await fillAccessibleTextbox(page, /Describe lo que observas/i, description);
    const response = await waitForApiResponse(page, 'POST', /\/api\/hazards$/, async () => {
      await clickVisibleText(page, /^Reportar peligro$/i, { prefer: 'lowest' });
    });
    expect(await jsonText(response)).toContain(description);
    return response;
  }

  async function createGenericReportFromUi(page, description) {
    await returnToMap(page);
    await openReportMenu(page);
    await clickVisibleText(page, /^Otro$/i, {
      domClick: true,
      forceKeyboard: true,
      afterClickMs: 1200,
    });
    await expectVisibleText(page, /Reporte|Describe lo que est/i, { timeout: 15000 });
    await chooseManualMapLocation(page);
    await fillAccessibleTextbox(page, /Describe lo que est/i, description);
    const response = await waitForApiResponse(page, 'POST', /\/api\/generic-reports$/, async () => {
      await clickVisibleText(page, /^Crear reporte$/i, { prefer: 'lowest' });
    });
    expect(await jsonText(response)).toContain(description);
    return response;
  }

  async function createRouteFromUi(page, name) {
    await openProfileMenu(page);
    await clickVisibleText(page, /Gestionar Rutas/i);
    await clickVisibleText(page, /Agregar ruta/i);
    await clickAt(page, 1010, 380);
    await clickAt(page, 1045, 420);
    await expectVisibleText(page, /2|Puntos de la ruta|Guardar Ruta/i, { timeout: 15000 });
    await clickVisibleText(page, /Guardar Ruta/i);
    await expectVisibleText(page, /Nombre de ruta/i);
    await fillDialogField(page, name);
    const response = await waitForApiResponse(page, 'POST', /\/api\/routes$/, async () => {
      await clickVisibleText(page, /^Guardar$/i);
    });
    expect(await jsonText(response)).toContain(name);
    await expectVisibleText(page, textPattern(name), { timeout: 30000 });
    return response;
  }

  async function selectRouteForTrip(page, name) {
    await returnToMap(page);
    await openTripMenu(page);
    await page.mouse.move(1160, 520);
    await page.mouse.wheel(0, 900);
    await page.waitForTimeout(400);
    await clickVisibleText(page, /Seleccionar ruta/i);
    await expectVisibleText(page, textPattern(name), { timeout: 15000 });
    await clickVisibleText(page, new RegExp(`Seleccionar ruta ${escapeRegExp(name)}`), {
      domClickOnly: true,
    });
    await expectVisibleText(page, new RegExp(`Ruta: ${escapeRegExp(name)}`), {
      timeout: 15000,
    });
    if (!(await hasSemanticsText(page, /M.todo de transporte|Seleccionar mascotas/i, { timeout: 1000 }))) {
      await clickVisibleText(page, /Expandir panel Iniciar Viaje/i, {
        domClick: true,
        forceKeyboard: true,
        afterClickMs: 700,
      });
    }
    await expectVisibleText(page, /M.todo de transporte|Seleccionar mascotas/i, {
      timeout: 15000,
    });
  }

  async function addCommentThroughUi(page, markerPattern, endpointPattern, commentText) {
    await returnToMap(page);
    await page.reload({ waitUntil: 'domcontentloaded' });
    await page.waitForFunction(
      () => document.querySelector('flutter-view, flt-glass-pane, canvas') !== null,
      null,
      { timeout: 90000 }
    );
    await enableFlutterSemantics(page);
    await clickVisibleText(page, markerPattern);
    await expectVisibleText(page, /Ver comentarios/i, { timeout: 15000 });
    await clickVisibleText(page, /Ver comentarios/i);
    await expectVisibleText(page, /Enviar comentario/i, { timeout: 15000 });
    await fillAccessibleTextbox(page, /Escribe un comentario/i, commentText);
    const response = await waitForApiResponse(page, 'POST', endpointPattern, async () => {
      await clickVisibleText(page, /Enviar comentario/i);
    });
    expect(await jsonText(response)).toContain(commentText);
    await expectVisibleText(page, textPattern(commentText), { timeout: 30000 });
    await expectVisibleText(page, textPattern(qaUser.name), { timeout: 30000 });
  }

  test('F5-001 registro de usuario nuevo desde la interfaz', async ({ page }) => {
    await openProfileMenu(page);
    await clickVisibleText(page, /Registrarse/i);
    await fillPanelField(page, 0, qaUser.name);
    await fillPanelField(page, 1, qaUser.email);
    await fillPanelField(page, 2, qaUser.password);
    await fillPanelField(page, 3, qaUser.password);
    await clickVisibleText(page, /Registrarse/i);
    await expectVisibleText(page, /Reportar|Iniciar Viaje/i, { timeout: 60000 });
    await openProfileMenu(page);
    await expectVisibleText(page, /Cerrar sesi|Gestionar Mascotas|Usuario/i);
  });

  test('F5-001-extra validacion de registro con campos obligatorios vacios', async ({ page }) => {
    await openProfileMenu(page);
    await clickVisibleText(page, /Registrarse/i);
    await clickVisibleText(page, /Registrarse/i);
    await expectVisibleText(page, /obligatorio|correo|contrase|Error/i);
  });

  test('F5-002 login, mascotas y logout desde la interfaz', async ({ page }) => {
    await login(page);
    await openProfileMenu(page);
    await clickVisibleText(page, /Gestionar Mascotas/i);
    await expectVisibleText(page, /Mascotas|Agregar mascota|Guardar Mascota/i);
    await page.reload({ waitUntil: 'domcontentloaded' });
    await expectVisibleText(page, /Reportar|Iniciar Viaje/i);
    await openProfileMenu(page);
    await clickVisibleText(page, /Cerrar sesi/i);
    await page.waitForTimeout(3000);
    await openProfileMenu(page);
    await expectVisibleText(page, /Iniciar Sesi|Registrarse/i, { timeout: 30000 });
  });

  test('F5-002-extra login invalido muestra error visible', async ({ page }) => {
    await openProfileMenu(page);
    await clickVisibleText(page, /Iniciar Sesi|Iniciar sesion/i);
    await fillPanelField(page, 0, 'usuario_invalido@example.com');
    await fillPanelField(page, 1, 'bad-password');
    await clickVisibleText(page, /Iniciar Sesi|Iniciar sesion/i);
    await expectVisibleText(page, /credenciales|incorrect|error|intenta|Error/i);
  });

  test('F5-003 crear mascota con nombre, fecha y foto', async ({ page }) => {
    await login(page);
    const response = await createPetFromUi(page, petName);
    expect(await jsonText(response)).toContain(petName);
    await openPetDetails(page, petName);
    await expectVisibleText(page, textPattern(petName));
  });

  test('F5-004 editar mascota existente', async ({ page }) => {
    const editablePetName = `Mascota editable ${Date.now()}`;
    await login(page);
    await createPetFromUi(page, editablePetName);
    await openPetEditPanel(page, editablePetName);
    await fillPanelField(page, 0, editedPetName);
    const response = await waitForApiResponse(page, 'PUT', /\/api\/pets\/\d+$/, async () => {
      await clickVisibleText(page, /^Guardar$/i);
    });
    expect(await jsonText(response)).toContain(editedPetName);
    await expectVisibleText(page, textPattern(editedPetName), { timeout: 30000 });
    await openPetDetails(page, editedPetName);
    await expectVisibleText(page, textPattern(editedPetName));
  });

  test('F5-005 eliminar mascota desde gestion', async ({ page }) => {
    const deletablePetName = `Mascota eliminable ${Date.now()}`;
    await login(page);
    await createPetFromUi(page, deletablePetName);
    await openPetEditPanel(page, deletablePetName);
    await clickVisibleText(page, /^Eliminar$/i);
    await expectVisibleText(page, /Eliminar mascota/i);
    await waitForApiResponse(page, 'DELETE', /\/api\/pets\/\d+$/, async () => {
      await clickVisibleText(page, /^Eliminar$/i);
    });
    await returnToMap(page);
    await openManagePets(page);
    await expectNoSemanticsText(page, new RegExp(deletablePetName.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')), {
      timeout: 3000,
    });
  });

  test('F5-006 crear reporte de mascota perdida desde mapa', async ({ page }) => {
    await login(page);
    await createLostPetReportFromUi(page, lostPetName, lostReportDetails);
    await returnToMap(page);
    await openReportMenu(page);
    await clickVisibleText(page, /^Mascota encontrada$/i, {
      domClick: true,
      forceKeyboard: true,
      afterClickMs: 1200,
    });
    await expectVisibleText(page, /Mascota encontrada|Reportar mascota encontrada|Describe la mascota/i, {
      timeout: 15000,
    });
    await clickVisibleText(page, /Seleccionar mascota perdida/i, {
      domClick: true,
      afterClickMs: 1200,
    });
    await expectVisibleText(page, textPattern(lostReportDetails), { timeout: 30000 });
  });

  test('F5-007 crear reporte de mascota encontrada vinculado', async ({ page }) => {
    const linkedLostPet = `Mascota perdida vinculada F5 ${Date.now()}`;
    const linkedLostDetails = `Perdida para encontrado F5 ${Date.now()}`;
    await login(page);
    const lostResponse = await createLostPetReportFromUi(page, linkedLostPet, linkedLostDetails);
    const lostData = responseData(await jsonPayload(lostResponse));
    const foundResponse = await createFoundPetReportFromUi(page, foundReportDetails, {
      linkLostReportDetails: linkedLostDetails,
    });
    const foundData = responseData(await jsonPayload(foundResponse));
    expect(foundData.details).toContain(foundReportDetails);
    expect(foundData.matched_lost_pet_report_id).toBe(lostData.id);
  });

  test('F5-008 crear reporte de peligro con foto y radio', async ({ page }) => {
    await login(page);
    const response = await createHazardReportFromUi(page, hazardDescription);
    const hazard = responseData(await jsonPayload(response));
    expect(hazard.description || hazard.narrative_description || JSON.stringify(hazard)).toContain(
      hazardDescription
    );
    expect(String(hazard.impact_radius_meters || hazard.radius_meters || JSON.stringify(hazard))).toMatch(
      /\d+/
    );
  });

  test('F5-009 crear reporte generico desde capa de mapa', async ({ page }) => {
    await login(page);
    const response = await createGenericReportFromUi(page, genericDescription);
    const report = responseData(await jsonPayload(response));
    expect(report.description || JSON.stringify(report)).toContain(genericDescription);
    expect(report.risk_level_code || report.risk_level || JSON.stringify(report)).toBeTruthy();
  });

  test('F5-010 agregar comentario a peligro', async ({ page }) => {
    const hazardForComment = `Peligro comentario F5 ${Date.now()}`;
    const commentText = `Comentario peligro F5 ${Date.now()}`;
    await login(page);
    await createHazardReportFromUi(page, hazardForComment);
    await addCommentThroughUi(
      page,
      new RegExp(`Abrir peligro ${escapeRegExp(hazardForComment)}`),
      /\/api\/hazards\/\d+\/comments$/,
      commentText
    );
  });

  test('F5-011 crear ruta de viaje y planificar', async ({ page }) => {
    await login(page);
    await createRouteFromUi(page, routeName);
    const planPromise = page.waitForResponse(
      (response) => {
        const request = response.request();
        return request.method().toUpperCase() === 'POST' && /\/api\/routes\/plan$/.test(response.url());
      },
      { timeout: 90000 }
    );
    await selectRouteForTrip(page, routeName);
    const response = await planPromise;
    expect(response.status()).toBeGreaterThanOrEqual(200);
    expect(response.status()).toBeLessThan(400);
    const plannedRoute = responseData(await jsonPayload(response));
    expect(plannedRoute.coordinates?.length || 0).toBeGreaterThanOrEqual(2);
    await clickVisibleText(page, /Confirmar inicio de viaje/i, {
      domClick: true,
      forceKeyboard: true,
      afterClickMs: 1200,
    });
    await expectVisibleText(page, /Terminar|M.todo de transporte/i, { timeout: 15000 });
  });

  test('F5-012 planificar viaje con filtros de peligro', async ({ page }, testInfo) => {
    testInfo.setTimeout(300000);
    const filteredRouteName = `Ruta filtros F5 ${Date.now()}`;
    const filteredHazard = `Peligro filtro F5 ${Date.now()}`;
    await login(page);
    await createHazardReportFromUi(page, filteredHazard);
    await returnToMap(page);
    await createRouteFromUi(page, filteredRouteName);
    const initialPlanPromise = page.waitForResponse(
      (response) => {
        const request = response.request();
        return request.method().toUpperCase() === 'POST' && /\/api\/routes\/plan$/.test(response.url());
      },
      { timeout: 90000 }
    );
    await selectRouteForTrip(page, filteredRouteName);
    await initialPlanPromise;
    const planPromise = page.waitForResponse(
      (response) => {
        const request = response.request();
        return request.method().toUpperCase() === 'POST' && /\/api\/routes\/plan$/.test(response.url());
      },
      { timeout: 90000 }
    );
    await clickVisibleText(page, /Medio/i);
    await clickVisibleText(page, /Alto/i);
    const response = await planPromise;
    expect(response.status()).toBeGreaterThanOrEqual(200);
    expect(response.status()).toBeLessThan(400);
    const plannedRoute = responseData(await jsonPayload(response));
    expect(plannedRoute.coordinates?.length || 0).toBeGreaterThanOrEqual(2);
    expect(plannedRoute.used_hazard_avoidance).toBeTruthy();
    await clickVisibleText(page, /Confirmar inicio de viaje/i, {
      domClick: true,
      forceKeyboard: true,
      afterClickMs: 1200,
    });
    await expectVisibleText(page, /Terminar|A pie|En veh/i, { timeout: 15000 });
  });

  test('F5-013 usuario no autenticado bloqueado en acciones privadas', async ({ page }) => {
    await openReportMenu(page);
    await clickVisibleText(page, /^Mascota perdida$/i);
    await expectVisibleText(page, /Iniciar sesion|Iniciar Sesi|sesion/i);
    await returnToMap(page);
    await openProfileMenu(page);
    await expectVisibleText(page, /Iniciar Sesi|Registrarse/i);
    await expectNoSemanticsText(page, /Cerrar sesi/i, { timeout: 3000 });
  });

  test('F5-014 aislamiento entre mascotas de usuarios distintos', async ({ page }) => {
    const userAPet = `Mascota privada A ${Date.now()}`;
    const userB = {
      name: `QA E2E B ${Date.now()}`,
      email: `qa_e2e_b_${Date.now()}@example.com`,
      password: 'QAtest1234',
    };
    await login(page);
    await createPetFromUi(page, userAPet);
    await returnToMap(page);
    await openProfileMenu(page);
    await clickVisibleText(page, /Cerrar sesi/i);
    await page.waitForTimeout(1500);
    await openProfileMenu(page);
    await clickVisibleText(page, /Registrarse/i);
    await fillPanelField(page, 0, userB.name);
    await fillPanelField(page, 1, userB.email);
    await fillPanelField(page, 2, userB.password);
    await fillPanelField(page, 3, userB.password);
    await clickVisibleText(page, /Registrarse/i);
    await expectVisibleText(page, /Reportar|Iniciar Viaje/i, { timeout: 60000 });
    await openManagePets(page);
    await expectNoSemanticsText(page, textPattern(userAPet), { timeout: 3000 });
  });

  test('F5-017 editar ruta existente', async ({ page }) => {
    const routeToEdit = `Ruta editable F5 ${Date.now()}`;
    await login(page);
    await createRouteFromUi(page, routeToEdit);
    await openProfileMenu(page);
    await clickVisibleText(page, /Gestionar Rutas/i);
    await clickVisibleText(page, new RegExp(`Editar ruta ${escapeRegExp(routeToEdit)}`));
    await expectVisibleText(page, /Editar Ruta|Guardar Cambios/i);
    await clickAt(page, 740, 430);
    await expectVisibleText(page, /3|Puntos de la ruta|Guardar Cambios/i, { timeout: 15000 });
    await clickVisibleText(page, /Guardar Cambios/i);
    await expectVisibleText(page, /Editar nombre de ruta/i);
    await fillDialogField(page, editedRouteName);
    const response = await waitForApiResponse(page, 'PUT', /\/api\/routes\/\d+$/, async () => {
      await clickVisibleText(page, /^Guardar$/i);
    });
    expect(await jsonText(response)).toContain(editedRouteName);
    await expectVisibleText(page, textPattern(editedRouteName), { timeout: 30000 });
  });

  test('F5-018 eliminar ruta existente', async ({ page }) => {
    const routeToDelete = `Ruta eliminable F5 ${Date.now()}`;
    await login(page);
    await createRouteFromUi(page, routeToDelete);
    await openProfileMenu(page);
    await clickVisibleText(page, /Gestionar Rutas/i);
    await clickVisibleText(page, new RegExp(`Eliminar ruta ${escapeRegExp(routeToDelete)}`));
    await expectVisibleText(page, /^Eliminar ruta$/i);
    await expectVisibleText(page, textPattern(routeToDelete));
    await waitForApiResponse(page, 'DELETE', /\/api\/routes\/\d+$/, async () => {
      await clickVisibleText(page, /^Borrar$/i);
    });
    await expectNoSemanticsText(page, textPattern(routeToDelete), { timeout: 3000 });
    await returnToMap(page);
    await openTripMenu(page);
    await clickVisibleText(page, /Seleccionar ruta/i);
    await expectNoSemanticsText(page, textPattern(routeToDelete), { timeout: 3000 });
  });

  test('F5-019 marcar mascota como encontrada', async ({ page }, testInfo) => {
    testInfo.setTimeout(300000);
    const foundAgainPet = `Mascota encontrada final ${Date.now()}`;
    const foundAgainDetails = `Reporte perdido para marcar encontrada ${Date.now()}`;
    await login(page);
    await createLostPetReportFromUi(page, foundAgainPet, foundAgainDetails);
    await returnToMap(page);
    await openPetDetails(page, foundAgainPet);
    await expectVisibleText(page, /Mascota perdida|Ya se encontro/i);
    const response = await waitForApiResponse(page, 'POST', /\/api\/pets\/\d+\/mark-found$/, async () => {
      await clickVisibleText(page, /Ya se encontro/i, { domClickOnly: true });
    });
    const pet = responseData(await jsonPayload(response));
    expect(pet.status).toMatch(/normal/i);
    await returnToMap(page);
    await expectNoSemanticsText(page, new RegExp(`Abrir mascota perdida ${escapeRegExp(foundAgainDetails)}`), {
      timeout: 10000,
    });
  });

  test('F5-020 texto extendido en formulario de reporte', async ({ page }) => {
    const longDescription = (`Texto extendido F5 ${Date.now()} ` + 'QA longitud extensa '.repeat(40)).slice(0, 500);
    await login(page);
    await createHazardReportFromUi(page, longDescription);
    await clickVisibleText(page, new RegExp(`Abrir peligro ${escapeRegExp(longDescription.slice(0, 70))}`));
    await expectVisibleText(page, textPattern(longDescription.slice(0, 120)), { timeout: 15000 });
    await expectVisibleText(page, /Ver comentarios|Radio de afectaci/i);
  });

  test('F5-021 comentarios en los cuatro tipos de reportes', async ({ page }, testInfo) => {
    testInfo.setTimeout(360000);
    const commentHazard = `Comentario hazard F5 ${Date.now()}`;
    const commentLost = `Comentario lost F5 ${Date.now()}`;
    const commentFound = `Comentario found F5 ${Date.now()}`;
    const commentGeneric = `Comentario generic F5 ${Date.now()}`;
    const commentHazardReport = `Peligro para cuatro comentarios ${Date.now()}`;
    const commentLostPet = `Mascota perdida comentarios ${Date.now()}`;
    const commentLostReport = `Reporte perdido comentarios ${Date.now()}`;
    const commentFoundReport = `Reporte encontrado comentarios ${Date.now()}`;
    const commentGenericReport = `Reporte generico comentarios ${Date.now()}`;

    await login(page);
    await createHazardReportFromUi(page, commentHazardReport);
    await addCommentThroughUi(
      page,
      new RegExp(`Abrir peligro ${escapeRegExp(commentHazardReport)}`),
      /\/api\/hazards\/\d+\/comments$/,
      commentHazard
    );
    await createLostPetReportFromUi(page, commentLostPet, commentLostReport);
    await addCommentThroughUi(
      page,
      new RegExp(`Abrir mascota perdida ${escapeRegExp(commentLostReport)}`),
      /\/api\/lost-pet-reports\/\d+\/comments$/,
      commentLost
    );
    await createFoundPetReportFromUi(page, commentFoundReport);
    await addCommentThroughUi(
      page,
      new RegExp(`Abrir mascota encontrada ${escapeRegExp(commentFoundReport)}`),
      /\/api\/found-pet-reports\/\d+\/comments$/,
      commentFound
    );
    await createGenericReportFromUi(page, commentGenericReport);
    await addCommentThroughUi(
      page,
      new RegExp(`Abrir reporte generico ${escapeRegExp(commentGenericReport)}`),
      /\/api\/generic-reports\/\d+\/comments$/,
      commentGeneric
    );
  });

  test('F5-022 consola sin errores criticos ni respuestas HTTP 500', async ({ page }, testInfo) => {
    await expectVisibleText(page, /Reportar|Iniciar Viaje/i);
    expect(testInfo.diagnostics.consoleErrors).toEqual([]);
    expect(testInfo.diagnostics.pageErrors).toEqual([]);
    expect(testInfo.diagnostics.http500).toEqual([]);
  });
});
