import { apiClient } from '@/services/apiClient'

type ApiVersionResponse = {
  success: boolean
  data: {
    version: string
    servicio: string
  }
}

export async function fetchApiVersion(): Promise<string> {
  const response = await apiClient.get<ApiVersionResponse>('/api/v1/version')
  return response.data.version
}
