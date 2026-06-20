import { apiClient } from '@/services/apiClient'
import type {
  LoginCredentials,
  LoginResponse,
  MeResponse,
  RefreshResponse,
} from '@/features/auth/types/auth.types'

const AUTH_BASE = '/api/v1/auth'

export const authService = {
  login(credentials: LoginCredentials) {
    return apiClient.post<LoginResponse>(`${AUTH_BASE}/login`, credentials)
  },

  me(token: string) {
    return apiClient.get<MeResponse>(`${AUTH_BASE}/me`, { token })
  },

  logout(token: string) {
    return apiClient.delete<{ success: boolean; message: string }>(
      `${AUTH_BASE}/logout`,
      { token },
    )
  },

  refresh(refreshToken: string) {
    return apiClient.post<RefreshResponse>(`${AUTH_BASE}/refresh`, {
      refresh_token: refreshToken,
    })
  },
}
