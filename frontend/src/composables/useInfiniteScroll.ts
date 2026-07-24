// Mesma coisa do Hooks do ReactJS, objetivo compartilhar funções e dados por todo o app.

import { ref, onMounted, onUnmounted, type Ref, watch } from 'vue'

function throttle(fn: (...args: unknown[]) => void, delay: number) {
  let lastCall = 0
  let timeoutId: ReturnType<typeof setTimeout> | null = null
  return function (this: unknown, ...args: unknown[]) {
    const now = Date.now()
    const remaining = delay - (now - lastCall)
    if (remaining <= 0) {
      if (timeoutId) {
        clearTimeout(timeoutId)
        timeoutId = null
      }
      lastCall = now
      fn.apply(this, args)
    } else if (!timeoutId) {
      timeoutId = setTimeout(() => {
        lastCall = Date.now()
        timeoutId = null
        fn.apply(this, args)
      }, remaining)
    }
  }
}

interface UseInfiniteScrollOptions {
  threshold?: number
  direction?: 'bottom' | 'top'
  enabled?: boolean
}

export function useInfiniteScroll(
  containerRef: Ref<HTMLElement | null>,
  callback: () => void | Promise<void>,
  options: UseInfiniteScrollOptions = {},
) {
  const { threshold = 200, direction = 'bottom', enabled = true } = options

  const isLoadingMore = ref(false)

  const sentinel = document.createElement('div')
  sentinel.style.height = '1px'
  sentinel.style.width = '100%'

  function checkScroll() {
    const el = containerRef.value
    if (!el || isLoadingMore.value || !enabled) return

    const atEdge =
      direction === 'bottom'
        ? el.scrollTop + el.clientHeight >= el.scrollHeight - threshold
        : el.scrollTop <= threshold

    if (atEdge) {
      isLoadingMore.value = true
      Promise.resolve(callback()).finally(() => {
        isLoadingMore.value = false
      })
    }
  }

  const throttledCheck = throttle(checkScroll, 300)

  onMounted(() => {
    const el = containerRef.value
    if (!el) return

    if (direction === 'top') {
      el.insertBefore(sentinel, el.firstChild)
    } else {
      el.appendChild(sentinel)
    }

    el.addEventListener('scroll', throttledCheck, { passive: true })
  })

  onUnmounted(() => {
    const el = containerRef.value
    if (el) {
      el.removeEventListener('scroll', throttledCheck)
      if (sentinel.parentNode === el) {
        el.removeChild(sentinel)
      }
    }
  })

  watch(
    () => enabled,
    (isEnabled) => {
      if (isEnabled) {
        checkScroll()
      }
    },
  )

  return { isLoadingMore }
}

export function useScrollToBottom(
  containerRef: Ref<HTMLElement | null>,
  shouldScroll: Ref<boolean>,
) {
  async function scrollToBottom(smooth = false) {
    await new Promise((r) => setTimeout(r, 0))
    const el = containerRef.value
    if (!el) return
    el.scrollTo({
      top: el.scrollHeight,
      behavior: smooth ? 'smooth' : 'instant',
    })
  }

  watch(shouldScroll, async (should) => {
    if (should) {
      await scrollToBottom()
    }
  })

  return { scrollToBottom }
}
