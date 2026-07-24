export const LOCALE = 'pt-BR'

export const STATUS_LABELS: Record<string, string> = {
  online: 'online',
  offline: 'offline',
  away: 'ausente',
  busy: 'ocupado',
} as const

export function formatTime(date: Date): string {
  return date.toLocaleTimeString(LOCALE, {
    hour: '2-digit',
    minute: '2-digit',
  })
}
