// Mesma coisa do Hooks do ReactJS, objetivo compartilhar funções e dados por todo o app.

import { ref, reactive } from 'vue'

interface UseLoadingReturn {
  loading: ReturnType<typeof ref<boolean>>
  error: ReturnType<typeof ref<string | null>>
  start: () => void
  stop: () => void
  withError: <T>(fn: () => Promise<T>) => Promise<T>
}

export function useLoading(): UseLoadingReturn {
  const loading = ref(false)
  const error = ref<string | null>(null)

  function start() {
    loading.value = true
    error.value = null
  }

  function stop() {
    loading.value = false
  }

  async function withError<T>(fn: () => Promise<T>): Promise<T> {
    start()
    try {
      return await fn()
    } catch (e) {
      error.value = e instanceof Error ? e.message : 'Erro desconhecido'
      throw e
    } finally {
      stop()
    }
  }

  return { loading, error, start, stop, withError }
}

interface UseLoadingMapReturn {
  isLoading: (id: string) => boolean
  getError: (id: string) => string | null
  start: (id: string) => void
  stop: (id: string) => void
  clear: (id: string) => void
}

export function useLoadingMap(): UseLoadingMapReturn {
  const states = reactive<Record<string, { loading: boolean; error: string | null }>>({})

  function getState(id: string) {
    if (!states[id]) {
      states[id] = { loading: false, error: null }
    }
    return states[id]
  }

  return {
    isLoading: (id: string) => getState(id).loading,
    getError: (id: string) => getState(id).error,
    start: (id: string) => {
      getState(id).loading = true
      getState(id).error = null
    },
    stop: (id: string) => {
      getState(id).loading = false
    },
    clear: (id: string) => {
      delete states[id]
    },
  }
}
