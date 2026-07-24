// Mesma coisa do Hooks do ReactJS, objetivo compartilhar funções e dados por todo o app.

import { onMounted, onUnmounted } from 'vue'

export function useKeydown(handler: (e: KeyboardEvent) => void): void {
  onMounted(() => {
    document.addEventListener('keydown', handler)
  })

  onUnmounted(() => {
    document.removeEventListener('keydown', handler)
  })
}
