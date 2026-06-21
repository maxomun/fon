import { apiClient } from '@/services/apiClient'
import type {
  EstablecerPasswordInput,
  EstablecerPasswordResponse,
  VerificarEmailResponse,
} from '@/features/auth/types/onboarding.types'

const ONBOARDING_BASE = '/api/v1/auth/onboarding'

export const onboardingService = {
  verificarEmail(token: string) {
    return apiClient.post<VerificarEmailResponse>(`${ONBOARDING_BASE}/verificar-email`, {
      token,
    })
  },

  establecerPassword(input: EstablecerPasswordInput) {
    return apiClient.post<EstablecerPasswordResponse>(
      `${ONBOARDING_BASE}/establecer-password`,
      input,
    )
  },
}
