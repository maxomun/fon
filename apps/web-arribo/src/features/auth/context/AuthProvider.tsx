import { useCallback, useEffect, useMemo, useState, type ReactNode } from 'react'
import { AuthContext } from '@/features/auth/context/AuthContext'
import { authService } from '@/features/auth/services/authService'
import { tokenStorage } from '@/features/auth/services/tokenStorage'
import type {
  LoginCredentials,
  UserProfile,
} from '@/features/auth/types/auth.types'
import { isAuthOnboardingBlockCode } from '@/features/auth/types/auth.types'
import {
  invalidateSession,
  isTokenExpiredError,
  refreshAccessToken,
  registerSessionInvalidationHandler,
} from '@/features/auth/services/sessionManager'
import { ApiError } from '@/services/apiClient'

interface AuthProviderProps {
  children: ReactNode
}

async function fetchCurrentUser(accessToken: string): Promise<UserProfile> {
  const response = await authService.me(accessToken)
  return normalizeUserProfile(response.user)
}

function normalizeUserProfile(user: UserProfile): UserProfile {
  return {
    ...user,
    acceso_global: user.acceso_global ?? false,
    empresas: user.empresas ?? [],
    email_verificado: user.email_verificado ?? true,
    onboarding_completado: user.onboarding_completado ?? true,
    requiere_verificacion_email: user.requiere_verificacion_email ?? false,
    requiere_onboarding: user.requiere_onboarding ?? false,
    debe_cambiar_password: user.debe_cambiar_password ?? false,
  }
}

function isSessionBlockedError(error: unknown) {
  return error instanceof ApiError && isAuthOnboardingBlockCode(error.code)
}

async function tryRefreshSession(): Promise<UserProfile | null> {
  const accessToken = await refreshAccessToken()
  if (!accessToken) {
    return null
  }

  const currentUser = await fetchCurrentUser(accessToken)
  return normalizeUserProfile(currentUser)
}

export function AuthProvider({ children }: AuthProviderProps) {
  const [user, setUser] = useState<UserProfile | null>(null)
  const [isLoading, setIsLoading] = useState(true)

  useEffect(() => {
    registerSessionInvalidationHandler(() => {
      setUser(null)
    })

    return () => registerSessionInvalidationHandler(null)
  }, [])

  const restoreSession = useCallback(async () => {
    const accessToken = tokenStorage.getAccessToken()

    if (!accessToken) {
      setUser(null)
      return
    }

    try {
      const currentUser = await fetchCurrentUser(accessToken)
      setUser(currentUser)
      return
    } catch (error) {
      if (isSessionBlockedError(error)) {
        invalidateSession({ expired: false })
        setUser(null)
        return
      }

      if (isTokenExpiredError(error)) {
        try {
          const currentUser = await tryRefreshSession()
          if (currentUser) {
            setUser(currentUser)
            return
          }
        } catch {
          // Continúa con invalidación de sesión
        }
      }

      invalidateSession()
      setUser(null)
    }
  }, [])

  useEffect(() => {
    void restoreSession().finally(() => setIsLoading(false))
  }, [restoreSession])

  const login = useCallback(async (credentials: LoginCredentials) => {
    const response = await authService.login(credentials)
    tokenStorage.save(response)
    const currentUser = normalizeUserProfile(
      response.user ?? (await fetchCurrentUser(response.access_token)),
    )
    setUser(currentUser)
  }, [])

  const logout = useCallback(async () => {
    const accessToken = tokenStorage.getAccessToken()

    if (accessToken) {
      try {
        await authService.logout(accessToken)
      } catch {
        // Si el token ya expiró, igual limpiamos la sesión local
      }
    }

    tokenStorage.clear()
    setUser(null)
  }, [])

  const value = useMemo(
    () => ({
      user,
      isAuthenticated: user !== null,
      isLoading,
      login,
      logout,
    }),
    [user, isLoading, login, logout],
  )

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>
}
