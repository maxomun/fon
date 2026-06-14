# Estructura del proyecto

Organización orientada a **componentes** y **features** (módulos por dominio).

## Árbol de carpetas

```
src/
├── app/                        # Bootstrap de la aplicación
│   ├── App.tsx                 # Componente raíz
│   ├── router.tsx              # Rutas (React Router)
│   └── providers.tsx           # Providers globales (auth, etc.)
│
├── config/
│   └── env.ts                  # Variables de entorno (VITE_*)
│
├── services/
│   └── apiClient.ts            # Cliente HTTP base hacia api-firma
│
├── features/                   # Módulos de negocio
│   ├── auth/
│   │   ├── components/         # LoginPage, LoginForm, ProtectedRoute…
│   │   ├── utils/              # validateLogin
│   │   ├── context/            # AuthContext
│   │   ├── hooks/              # useAuth
│   │   ├── services/           # authService (login, logout, me)
│   │   └── types/              # Tipos TypeScript del dominio auth
│   └── dashboard/
│       └── components/         # DashboardPage y pantallas del módulo
│
└── components/                 # UI reutilizable (sin lógica de negocio)
    ├── ui/                     # Button, Input, Alert…
    └── layout/                 # AuthLayout, AppLayout
```

## Convenciones

| Carpeta | Qué va aquí |
|---|---|
| `app/` | Ensamblaje global: rutas, providers, entry de la app |
| `features/*` | Pantallas y lógica de un dominio (auth, dashboard, DTE…) |
| `components/ui/` | Piezas visuales reutilizables, sin llamadas al API |
| `components/layout/` | Estructuras de página (login centrado, header app) |
| `services/` | Infraestructura compartida (HTTP, storage) |
| `config/` | Configuración leída de variables de entorno |

## Rutas actuales

| Ruta | Componente | Acceso |
|---|---|---|
| `/login` | `LoginPage` | Público |
| `/dashboard` | `DashboardPage` | Protegido (placeholder) |
| `/` | — | Redirige a `/login` |

## Alias de imports

Se usa `@/` como alias de `src/`:

```typescript
import { Button } from '@/components/ui'
import { authService } from '@/features/auth/services/authService'
```

## Próximos pasos

- ~~**Paso 4:** `LoginForm` + UI de login en `features/auth/components/`~~ ✓
- ~~**Paso 5:** `AuthProvider`, sesión real con `api-firma`, `ProtectedRoute` funcional~~ ✓

Ver [AUTENTICACION.md](./AUTENTICACION.md) para el flujo completo.
