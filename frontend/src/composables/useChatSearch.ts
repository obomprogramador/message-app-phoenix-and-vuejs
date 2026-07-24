// Mesma coisa do Hooks do ReactJS, objetivo compartilhar funções e dados por todo o app.

import { computed } from 'vue'

export interface HighlightSegment {
  text: string
  isMatch: boolean
}

export function useHighlightSegments(content: () => string, query: () => string) {
  const segments = computed<HighlightSegment[]>(() => {
    const text = content()
    const searchQuery = query()

    if (!searchQuery) return [{ text, isMatch: false }]

    const lowerQuery = searchQuery.toLowerCase()
    const result: HighlightSegment[] = []
    let remaining = text

    while (remaining.length > 0) {
      const idx = remaining.toLowerCase().indexOf(lowerQuery)
      if (idx === -1) {
        result.push({ text: remaining, isMatch: false })
        break
      }
      if (idx > 0) {
        result.push({ text: remaining.slice(0, idx), isMatch: false })
      }
      result.push({ text: remaining.slice(idx, idx + lowerQuery.length), isMatch: true })
      remaining = remaining.slice(idx + lowerQuery.length)
    }

    return result
  })

  return { segments }
}
