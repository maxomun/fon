import type { AuthTokens } from '@/features/auth/types/auth.types'

const ACCESS_TOKEN_KEY = 'arribo_access_token'
const REFRESH_TOKEN_KEY = 'arribo_refresh_token'

export const tokenStorage = {
  save(tokens: AuthTokens) {
    sessionStorage.setItem(ACCESS_TOKEN_KEY, tokens.access_token)
    sessionStorage.setItem(REFRESH_TOKEN_KEY, tokens.refresh_token)
  },

  getAccessToken() {
    return sessionStorage.getItem(ACCESS_TOKEN_KEY)
  },

  getRefreshToken() {
    return sessionStorage.getItem(REFRESH_TOKEN_KEY)
  },

  clear() {
    sessionStorage.removeItem(ACCESS_TOKEN_KEY)
    sessionStorage.removeItem(REFRESH_TOKEN_KEY)
  },

  hasSession() {
    return Boolean(tokenStorage.getAccessToken())
  },
}
