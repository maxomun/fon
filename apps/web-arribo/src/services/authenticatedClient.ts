import { env } from '@/config/env'
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

  download(path: string, options?: { fallbackFilename?: string }) {
    return withAuth(async (token) => {
      const baseUrl = env.apiUrl.replace(/\/$/, '')
      const response = await fetch(`${baseUrl}${path}`, {
        headers: { Authorization: `Bearer ${token}` },
      })

      if (!response.ok) {
        const data = (await response.json().catch(() => ({}))) as {
          message?: string
          error?: string
          code?: string
        }
        throw new ApiError(
          data.message ?? data.error ?? 'No se pudo descargar el archivo',
          response.status,
          data.code,
        )
      }

      const blob = await response.blob()
      const filename =
        parseDownloadFilename(response) ??
        options?.fallbackFilename ??
        'descarga.xml'

      return { blob, filename }
    })
  },
}

function parseDownloadFilename(response: Response) {
  const custom = response.headers.get('X-Download-Filename')?.trim()
  if (custom) {
    return custom
  }

  const disposition = response.headers.get('Content-Disposition') ?? ''
  if (!disposition) {
    return null
  }

  const utf8Match = disposition.match(/filename\*=UTF-8''([^;\n]+)/i)
  if (utf8Match?.[1]) {
    try {
      return decodeURIComponent(utf8Match[1])
    } catch {
      return utf8Match[1]
    }
  }

  const quotedMatch = disposition.match(/filename="([^"]+)"/i)
  if (quotedMatch?.[1]) {
    return quotedMatch[1]
  }

  const plainMatch = disposition.match(/filename=([^;\n]+)/i)
  if (plainMatch?.[1]) {
    return plainMatch[1].trim()
  }

  return null
}
