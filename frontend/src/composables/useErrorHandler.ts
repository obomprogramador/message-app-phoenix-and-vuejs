// Mesma coisa do Hooks do ReactJS, objetivo compartilhar funções e dados por todo o app.

import { ref, computed, type ComputedRef } from 'vue'
import { ApiError, ValidationError, NetworkError, parseApiError } from '@/api/errors'

interface ErrorState {
  visible: boolean
  message: string
  type: 'error' | 'warning' | 'info'
}

interface UseErrorHandlerReturn {
  errorState: ReturnType<typeof ref<ErrorState>>
  isVisible: ComputedRef<boolean>
  show: (message: string, type?: ErrorState['type']) => void
  hide: () => void
  handle: (error: unknown) => void
  getValidationDetails: (error: unknown) => Record<string, string[]> | null
}

export function useErrorHandler(): UseErrorHandlerReturn {
  const errorState = ref<ErrorState>({
    visible: false,
    message: '',
    type: 'error',
  })

  const isVisible = computed(() => errorState.value.visible)

  function show(message: string, type: ErrorState['type'] = 'error') {
    errorState.value = { visible: true, message, type }
  }

  function hide() {
    errorState.value = { visible: false, message: '', type: 'error' }
  }

  function handle(error: unknown) {
    const apiError = parseApiError(error)

    if (apiError instanceof ValidationError) {
      show(apiError.message, 'warning')
      return
    }

    if (apiError instanceof NetworkError) {
      show('Verifique sua conexao com a internet', 'error')
      return
    }

    if (apiError.status === 404) {
      show(apiError.message, 'warning')
      return
    }

    if (apiError.status === 401 || apiError.status === 403) {
      show(apiError.message, 'error')
      return
    }

    show(apiError.message || 'Ocorreu um erro inesperado', 'error')
  }

  function getValidationDetails(error: unknown): Record<string, string[]> | null {
    if (error instanceof ValidationError) {
      return error.details
    }
    return null
  }

  return { errorState, isVisible, show, hide, handle, getValidationDetails }
}
