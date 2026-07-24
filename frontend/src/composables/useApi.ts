// Mesma coisa do Hooks do ReactJS, objetivo compartilhar funções e dados por todo o app.

import { ref, type Ref } from 'vue'
import { ApiError, parseApiError } from '@/api/errors'

interface UseApiReturn<T, A extends unknown[]> {
  data: Ref<T | null>
  loading: Ref<boolean>
  error: Ref<ApiError | null>
  execute: (...args: A) => Promise<T>
  reset: () => void
}

export function useApi<T, A extends unknown[]>(
  apiFn: (...args: A) => Promise<{ data: T }>,
): UseApiReturn<T, A> {
  const data = ref<T | null>(null) as Ref<T | null>
  const loading = ref(false)
  const error = ref<ApiError | null>(null)

  async function execute(...args: A): Promise<T> {
    loading.value = true
    error.value = null

    try {
      const response = await apiFn(...args)
      data.value = response.data
      return response.data
    } catch (e) {
      const apiError = parseApiError(e)
      error.value = apiError
      throw apiError
    } finally {
      loading.value = false
    }
  }

  function reset() {
    data.value = null
    loading.value = false
    error.value = null
  }

  return { data, loading, error, execute, reset }
}
