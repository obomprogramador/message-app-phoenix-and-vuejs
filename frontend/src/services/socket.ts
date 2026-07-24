import { Socket, type Channel } from 'phoenix'

const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || 'http://localhost:4000/api'

function buildSocketUrl(): string {
  const base = API_BASE_URL.replace('/api', '')
  const url = new URL(base)
  const protocol = url.protocol === 'https:' ? 'wss:' : 'ws:'
  return `${protocol}//${url.host}/socket`
}

let socket: Socket | null = null
const channels = new Map<string, Channel>()
const listeners = {
  open: [] as (() => void)[],
  close: [] as (() => void)[],
  error: [] as ((error: unknown) => void)[],
  reconnecting: [] as (() => void)[],
  reconnect: [] as (() => void)[],
}

function emit(event: 'open' | 'close' | 'error' | 'reconnecting' | 'reconnect', ...args: unknown[]) {
  const cbs = listeners[event as keyof typeof listeners] as ((...a: unknown[]) => void)[]
  cbs.forEach((cb) => cb(...args))
}

function createSocket(contactId: string): Socket {
  const s = new Socket(buildSocketUrl(), {
    params: { contact_id: contactId },
    reconnectAfter: (tries: number) => Math.min(tries * 2_000, 30_000),
  })

  s.onOpen(() => emit('open'))
  s.onClose(() => emit('close'))
  s.onError(() => emit('error'))
  s.onMessage(() => {})

  return s
}

export function getSocket(): Socket {
  if (!socket) {
    socket = createSocket('')
  }
  return socket
}

export function connectSocket(contactId: string): void {
  if (socket?.isConnected()) return

  if (socket) {
    socket.disconnect()
  }
  socket = createSocket(contactId)
  socket.connect()
}

export function disconnectSocket(): void {
  if (socket) {
    for (const ch of channels.values()) {
      ch.leave()
    }
    channels.clear()
    socket.disconnect()
    socket = null
  }
}

export function isConnected(): boolean {
  return socket?.isConnected() ?? false
}

export function rejoinAllChannels(): void {
  for (const [topic, channel] of channels) {
    channel.leave()
  }
  channels.clear()
}

export interface JoinCallbacks {
  ok?: () => void
  error?: (resp: unknown) => void
  timeout?: () => void
}

export function joinChannel(topic: string, callbacks?: JoinCallbacks): Channel {
  if (channels.has(topic)) {
    return channels.get(topic)!
  }

  const s = getSocket()
  const channel = s.channel(topic)

  channel
    .join()
    .receive('ok', () => callbacks?.ok?.())
    .receive('error', (resp: unknown) => {
      console.error(`Failed to join ${topic}:`, resp)
      callbacks?.error?.(resp)
    })
    .receive('timeout', () => {
      console.warn(`Timeout joining ${topic}`)
      callbacks?.timeout?.()
    })

  channel.onError(() => {
    console.warn(`Channel error on ${topic}`)
  })

  channels.set(topic, channel)
  return channel
}

export function leaveChannel(topic: string): void {
  const channel = channels.get(topic)
  if (channel) {
    channel.leave()
    channels.delete(topic)
  }
}

export function onSocketOpen(cb: () => void): void {
  listeners.open.push(cb)
  getSocket()
}

export function onSocketClose(cb: () => void): void {
  listeners.close.push(cb)
  getSocket()
}

export function onSocketError(cb: (error: unknown) => void): void {
  listeners.error.push(cb)
  getSocket()
}

export function onSocketReconnecting(cb: () => void): void {
  listeners.reconnecting.push(cb)
}

export function onSocketReconnect(cb: () => void): void {
  listeners.reconnect.push(cb)
}
