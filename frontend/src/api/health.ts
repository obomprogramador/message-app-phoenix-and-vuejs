import { apiClient, isApiAvailable, mockClient } from './client'
import type { HealthResponse, ApiResponse } from './types'

export const healthApi = {
  async check(): Promise<ApiResponse<HealthResponse>> {
    if (!isApiAvailable()) return mockClient.checkHealth()
    return apiClient.get<HealthResponse>('/health')
  },
}
