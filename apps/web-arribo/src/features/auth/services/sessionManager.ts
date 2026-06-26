import { authService } from '@/features/auth/services/authService'
import { tokenStorage } from '@/features/auth/services/tokenStorage'
import { ApiError } from '@/services/apiClient'

const SESSION_EXPIRED_FLAG = 'arribo_session_expired'

let refreshPromise: Promise<string | null> | null = null
let onSessionInvalidated: (() => void) | null = null

export function registerSessionInvalidationHandler(handler: (() => void) | null) {
  onSessionInvalidated = handler
}

export function isTokenExpiredError(error: unknown) {
  return (
    error instanceof ApiError &&
    (error.code === 'TOKEN_EXPIRED' || error.status === 401)
  )
}

export function consumeSessionExpiredFlag() {
  const expired = sessionStorage.getItem(SESSION_EXPIRED_FLAG) === '1'
  if (expired) {
    sessionStorage.removeItem(SESSION_EXPIRED_FLAG)
  }
  return expired
}

export function invalidateSession(options?: { expired?: boolean }) {
  tokenStorage.clear()

  if (options?.expired !== false) {
    sessionStorage.setItem(SESSION_EXPIRED_FLAG, '1')
  }

  onSessionInvalidated?.()
}

export async function refreshAccessToken(): Promise<string | null> {
  if (refreshPromise) {
    return refreshPromise
  }

  refreshPromise = (async () => {
    const refreshToken = tokenStorage.getRefreshToken()
    if (!refreshToken) {
      return null
    }

    try {
      const tokens = await authService.refresh(refreshToken)
      tokenStorage.save(tokens)
      return tokens.access_token
    } catch {
      return null
    } finally {
      refreshPromise = null
    }
  })()

  return refreshPromise
}
