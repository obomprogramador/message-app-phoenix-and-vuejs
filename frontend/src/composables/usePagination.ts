// Mesma coisa do Hooks do ReactJS, objetivo compartilhar funções e dados por todo o app.

import { ref, computed, type ComputedRef } from 'vue'
import type { PaginationMeta } from '@/api/types'

interface UsePaginationOptions {
  initialPage?: number
  initialPerPage?: number
}

interface UsePaginationReturn {
  page: ReturnType<typeof ref<number>>
  perPage: ReturnType<typeof ref<number>>
  meta: ReturnType<typeof ref<PaginationMeta | null>>
  loadingMore: ReturnType<typeof ref<boolean>>
  hasNextPage: ComputedRef<boolean>
  hasPrevPage: ComputedRef<boolean>
  totalPages: ComputedRef<number>
  nextPage: () => void
  prevPage: () => void
  goToPage: (page: number) => void
  nextPageParams: ComputedRef<Record<string, string | number> | null>
  updateMeta: (meta: PaginationMeta) => void
  reset: () => void
}

export function usePagination(options: UsePaginationOptions = {}): UsePaginationReturn {
  const { initialPage = 1, initialPerPage = 20 } = options

  const page = ref(initialPage)
  const perPage = ref(initialPerPage)
  const meta = ref<PaginationMeta | null>(null)
  const loadingMore = ref(false)

  const hasNextPage = computed(() => {
    if (!meta.value) return false
    return meta.value.has_more ?? page.value < meta.value.total_pages
  })

  const hasPrevPage = computed(() => page.value > 1)

  const totalPages = computed(() => meta.value?.total_pages ?? 0)

  const nextPageParams = computed(() => {
    if (!hasNextPage.value) return null
    return { page: page.value + 1, per_page: perPage.value }
  })

  function nextPage() {
    if (hasNextPage.value) {
      page.value++
    }
  }

  function prevPage() {
    if (hasPrevPage.value) {
      page.value--
    }
  }

  function goToPage(target: number) {
    if (target >= 1 && target <= totalPages.value) {
      page.value = target
    }
  }

  function updateMeta(newMeta: PaginationMeta) {
    meta.value = newMeta
  }

  function reset() {
    page.value = initialPage
    meta.value = null
    loadingMore.value = false
  }

  return {
    page,
    perPage,
    meta,
    loadingMore,
    hasNextPage,
    hasPrevPage,
    totalPages,
    nextPage,
    prevPage,
    goToPage,
    nextPageParams,
    updateMeta,
    reset,
  }
}
