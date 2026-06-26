import { tokenStorage } from '@/features/auth/services/tokenStorage'
import {
  invalidateSession,
  isTokenExpiredError,
  refreshAccessToken,
} from '@/features/auth/services/sessionManager'
import { apiClient, ApiError } from '@/services/apiClient'

async function withAuth<T>(request: (token: string) => Promise<T>): Promise<T> {
  const token = tokenStorage.getAccessToken()

  if (!token) {
    invalidateSession()
    throw new ApiError('Sesión expirada', 401, 'TOKEN_EXPIRED')
  }

  try {
    return await request(token)
  } catch (error) {
    if (!isTokenExpiredError(error)) {
      throw error
    }

    const newToken = await refreshAccessToken()
    if (!newToken) {
      invalidateSession()
      throw error
    }

    try {
      return await request(newToken)
    } catch (retryError) {
      if (isTokenExpiredError(retryError)) {
        invalidateSession()
      }
      throw retryError
    }
  }
}

export const authenticatedClient = {
  get<T>(path: string) {
    return withAuth((token) => apiClient.get<T>(path, { token }))
  },

  post<T>(path: string, body?: unknown) {
    return withAuth((token) => apiClient.post<T>(path, body, { token }))
  },

  patch<T>(path: string, body?: unknown) {
    return withAuth((token) => apiClient.patch<T>(path, body, { token }))
  },

  delete<T>(path: string) {
    return withAuth((token) => apiClient.delete<T>(path, { token }))
  },

  postFormData<T>(path: string, formData: FormData) {
    return withAuth((token) =>
      apiClient.request<T>(path, {
        method: 'POST',
        body: formData,
        token,
      }),
    )
  },
}
