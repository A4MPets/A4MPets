# A4MPets F7 - Postman Cloudflare

Este paquete deja preparada la fase F7 para ejecutarla desde Postman Runner contra el backend publicado por Cloudflare Tunnel.

## Archivos

- `F7_A4MPets_Load.postman_collection.json`: coleccion Postman con casos F7-001 a F7-020.
- `F7_A4MPets_Cloudflare.postman_environment.json`: environment con `base_url`, credenciales QA y variables dinamicas.
- `f7-runner-data.csv`: datos de apoyo para iteraciones con nombres, coordenadas y comentarios variables.

## Preparacion

1. Levantar el stack local.
2. Levantar Cloudflare Tunnel con el comando definido en el proyecto:

```bash
npm run dev:cloudflare
```

3. Copiar la URL publica generada desde `.runtime/cloudflare-url.txt`.
4. Importar en Postman:
   - La coleccion `postman/F7_A4MPets_Load.postman_collection.json`.
   - El environment `postman/F7_A4MPets_Cloudflare.postman_environment.json`.
5. Editar el environment:
   - `base_url`: URL publica de Cloudflare, sin slash final.
   - `qa_login`: usuario QA existente.
   - `qa_password`: contrasena del usuario QA.
6. Ejecutar primero la carpeta `00 - Setup` para obtener `access_token` y crear un `hazard_id` base.

## Ejecucion Por Caso

Ejecuta cada carpeta con Postman Runner y las iteraciones indicadas:

| Caso | Carpeta/Request | Iteraciones |
|---|---|---:|
| F7-001 | `F7-001 - Health 50 iteraciones` | 50 |
| F7-002 | `F7-002 - Login 30 iteraciones` | 30 |
| F7-003 | `F7-003 - Listar peligros 50 iteraciones` | 50 |
| F7-004 | `F7-004 - Crear mascotas 20 iteraciones` | 20 |
| F7-005 | `F7-005 - Crear peligros 20 iteraciones` | 20 |
| F7-006 | `F7-006 - Subir media 10 iteraciones` | 10 |
| F7-007 | `F7-007 - Planificar ruta 15 iteraciones` | 15 |
| F7-008 | `F7-008 - Health incremental 10-20-30-50` | 10, 20, 30, 50 |
| F7-009 | `F7-009 - Burst hazards + health` | 20 para hazards; luego health manual tras 10s |
| F7-010 | `F7-010 - Crear mascota sin token 20 iteraciones` | 20 |
| F7-011 | `F7-011 - Rutas dos vs cinco puntos` | 10 por request |
| F7-012 | `F7-012 - Rutas con y sin filtros` | 10 por request |
| F7-013 a F7-016 | `F7-013 a F7-016 - Listados 30 iteraciones` | 30 por request/carpeta |
| F7-017 | `F7-017 - Comentar peligro 15 iteraciones` | 15 |
| F7-018 | `F7-018 - Cloudflare URL activa despues de 1 hora` | inicio y despues de 1 hora |
| F7-019/F7-020 | `F7-019 y F7-020 - Consolidacion` | 1 cierre + consolidado manual |

Cuando uses Runner, activa el environment `A4MPets F7 Cloudflare`. El archivo CSV es opcional porque la coleccion calcula sufijos y coordenadas por iteracion, pero puedes cargar `f7-runner-data.csv` si deseas evidenciar datos controlados.

## Evidencia

Exporta los resultados del Runner por caso o guarda capturas con:

- Total de iteraciones.
- Tests pasados/fallidos.
- Latencia promedio, minima y maxima.
- Cantidad de errores.
- Confirmacion de que no hubo respuestas HTTP 500.

Si exportas un resultado del Runner en JSON, puedes generar un resumen tecnico con:

```bash
node scripts/f7-postman-summary.js ruta/al/export-runner.json
```

Completa el documento:

```text
docs/evidencias/F7/reporte_F7_postman_cloudflare.md
```

## Notas

- F7 no reemplaza F3: aqui se mide estabilidad y tiempos contra el stack publicado por Cloudflare.
- F7 no reemplaza F5: aqui no se usa navegador ni UI, solo API HTTP desde Postman.
- GraphHopper debe estar activo para F7-007, F7-011 y F7-012.
