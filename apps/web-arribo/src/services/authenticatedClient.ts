import { tokenStorage } from '@/features/auth/services/tokenStorage'
import { apiClient } from '@/services/apiClient'

function authOptions() {
  return { token: tokenStorage.getAccessToken() }
}

export const authenticatedClient = {
  get<T>(path: string) {
    return apiClient.get<T>(path, authOptions())
  },

  post<T>(path: string, body?: unknown) {
    return apiClient.post<T>(path, body, authOptions())
  },

  patch<T>(path: string, body?: unknown) {
    return apiClient.patch<T>(path, body, authOptions())
  },

  delete<T>(path: string) {
    return apiClient.delete<T>(path, authOptions())
  },
}
