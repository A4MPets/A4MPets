# Frontend (Flutter)

## Configurar URL del Backend por Entorno

Este proyecto usa `A4M_API_BASE_URL` por `--dart-define`.

La app ya soporta fallback local (`127.0.0.1`, `10.0.2.2`), pero para celular fisico debes apuntar a la IP LAN del PC o servidor.

### 1) Entorno local para celular en la misma red

1. Copia `env/local.example.json` a `env/local.json`.
2. Ajusta la IP:

```json
{
	"A4M_API_BASE_URL": "http://192.168.1.100:8000/api"
}
```

3. Ejecuta:

```bash
flutter run -d <device-id> --dart-define-from-file=env/local.json
```

Tambien puedes usar el script de raiz:

```bash
npm run frontend:android
```

### 2) Entorno de produccion

1. Copia `env/production.example.json` a `env/production.json`.
2. Ajusta el dominio/IP final:

```json
{
	"A4M_API_BASE_URL": "https://api.tu-dominio.com/api"
}
```

3. Build:

```bash
flutter build apk --release --dart-define-from-file=env/production.json
```

## Nota Importante (Celular fisico)

Si el backend corre en tu PC, debe escuchar en todas las interfaces y no solo localhost.

- Correcto: `php artisan serve --host=0.0.0.0 --port=8000`
- Verifica firewall de Windows para permitir el puerto `8000`.
