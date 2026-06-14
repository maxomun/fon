# Desarrollo local — web-arribo

Aplicación web React (Vite + TypeScript) que consume el API **api-firma**.

## Requisitos

- Docker y Docker Compose
- **api-firma** corriendo en `http://localhost:3026`

## Configuración inicial

Desde la carpeta del proyecto:

```bash
cd apps/web-arribo
cp .env.example .env
```

Variables en `.env`:

| Variable | Descripción | Valor por defecto |
|---|---|---|
| `VITE_API_URL` | URL base del API FacturaOn | `http://localhost:3026` |

## Levantar el API (prerrequisito)

En otra terminal:

```bash
cd apps/api-firma
docker compose up -d
```

Verificar que responde:

```bash
curl http://localhost:3026/up
# debe devolver HTTP 200
```

## Levantar la web

```bash
cd apps/web-arribo
docker compose up --build -d
```

Abrir en el navegador: **http://localhost:5173**

## Comandos útiles

```bash
# Ver logs en tiempo real
docker logs -f web-arribo

# Bajar la web
docker compose down

# Rebuild (después de cambiar package.json o Dockerfile)
docker compose up --build -d

# Reiniciar sin rebuild
docker compose restart
```

## Desarrollo sin Docker (opcional)

Si preferís correr Vite directamente en el host:

```bash
cd apps/web-arribo
npm install
npm run dev
```

La app quedará en **http://localhost:5173**. El API sigue siendo necesario en el puerto 3026.

## Puertos

| Servicio | Puerto | URL |
|---|---|---|
| web-arribo | 5173 | http://localhost:5173 |
| api-firma | 3026 | http://localhost:3026 |

## Notas

- Las llamadas al API las hace el **navegador** hacia `VITE_API_URL` (no el contenedor de la web).
- CORS en api-firma está configurado para permitir orígenes en desarrollo (`*`).
- El hot-reload funciona con el volumen montado en Docker; si agregás dependencias nuevas, ejecutá `docker compose up --build -d`.
