import { useCallback, useEffect, useMemo, useState, type ReactNode } from 'react'
import { AuthContext } from '@/features/auth/context/AuthContext'
import { authService } from '@/features/auth/services/authService'
import { tokenStorage } from '@/features/auth/services/tokenStorage'
import type {
  LoginCredentials,
  UserProfile,
} from '@/features/auth/types/auth.types'
import { ApiError } from '@/services/apiClient'

interface AuthProviderProps {
  children: ReactNode
}

async function fetchCurrentUser(accessToken: string): Promise<UserProfile> {
  const response = await authService.me(accessToken)
  return response.user
}

async function tryRefreshSession(): Promise<UserProfile | null> {
  const refreshToken = tokenStorage.getRefreshToken()
  if (!refreshToken) {
    return null
  }

  const tokens = await authService.refresh(refreshToken)
  tokenStorage.save(tokens)
  return fetchCurrentUser(tokens.access_token)
}

export function AuthProvider({ children }: AuthProviderProps) {
  const [user, setUser] = useState<UserProfile | null>(null)
  const [isLoading, setIsLoading] = useState(true)

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
      const shouldRefresh =
        error instanceof ApiError &&
        (error.code === 'TOKEN_EXPIRED' || error.status === 401)

      if (!shouldRefresh) {
        tokenStorage.clear()
        setUser(null)
        return
      }
    }

    try {
      const currentUser = await tryRefreshSession()
      setUser(currentUser)
      if (!currentUser) {
        tokenStorage.clear()
      }
    } catch {
      tokenStorage.clear()
      setUser(null)
    }
  }, [])

  useEffect(() => {
    void restoreSession().finally(() => setIsLoading(false))
  }, [restoreSession])

  const login = useCallback(async (credentials: LoginCredentials) => {
    const tokens = await authService.login(credentials)
    tokenStorage.save(tokens)
    const currentUser = await fetchCurrentUser(tokens.access_token)
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
