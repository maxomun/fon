# Autenticación

Integración con **api-firma** (`/api/v1/auth/*`).

## Flujo de login

1. El usuario envía email y contraseña desde `LoginForm`.
2. `AuthProvider.login()` llama a `POST /api/v1/auth/login`.
3. Se guardan tokens en `sessionStorage`:
   - `arribo_access_token`
   - `arribo_refresh_token`
4. Se obtiene el perfil con `GET /api/v1/auth/me`.
5. Redirect a `/dashboard`.

## Restaurar sesión

Al cargar la app, si hay `access_token` en `sessionStorage`:

1. Se llama a `GET /api/v1/auth/me`.
2. Si el token expiró (`401` / `TOKEN_EXPIRED`), se intenta `POST /api/v1/auth/refresh`.
3. Si falla, se limpia la sesión local.

## Rutas protegidas

- `ProtectedRoute` bloquea acceso sin sesión → redirect a `/login`.
- `LoginPage` redirige a `/dashboard` si ya hay sesión activa.
- `/` redirige según estado de autenticación.

## Logout

Desde el header del dashboard:

1. `DELETE /api/v1/auth/logout` con el access token.
2. Limpieza de `sessionStorage`.
3. Redirect a `/login`.

## Errores del API mostrados en login

| Código | Mensaje típico |
|---|---|
| `INVALID_CREDENTIALS` | Credenciales inválidas |
| `USER_INACTIVE` | Usuario inactivo |
| `TOKEN_EXPIRED` | Token expirado (refresh automático) |

## Archivos clave

```
src/features/auth/
├── context/AuthProvider.tsx
├── services/authService.ts
├── services/tokenStorage.ts
└── components/ProtectedRoute.tsx
```
