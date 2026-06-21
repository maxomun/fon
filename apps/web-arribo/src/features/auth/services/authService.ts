import { apiClient } from '@/services/apiClient'
import type {
  LoginCredentials,
  LoginResponse,
  MeResponse,
  RefreshResponse,
  ReenviarVerificacionResponse,
  RestablecerPasswordInput,
  RestablecerPasswordResponse,
  SolicitarRestablecimientoResponse,
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

  reenviarVerificacion(email: string) {
    return apiClient.post<ReenviarVerificacionResponse>(
      `${AUTH_BASE}/onboarding/reenviar-verificacion`,
      { email },
    )
  },

  solicitarRestablecimientoPassword(email: string) {
    return apiClient.post<SolicitarRestablecimientoResponse>(
      `${AUTH_BASE}/password/solicitar-restablecimiento`,
      { email },
    )
  },

  restablecerPassword(input: RestablecerPasswordInput) {
    return apiClient.post<RestablecerPasswordResponse>(
      `${AUTH_BASE}/password/restablecer`,
      input,
    )
  },
}
