/// <reference types="vite/client" />

declare module 'phoenix' {
  export class Socket {
    constructor(url: string, params?: Record<string, unknown>)
    connect(): void
    disconnect(): void
    isConnected(): boolean
    channel(topic: string, params?: Record<string, unknown>): Channel
    onOpen(callback: () => void): void
    onClose(callback: () => void): void
    onError(callback: (error: unknown) => void): void
    onMessage(callback: () => void): void
  }

  export class Channel {
    join(): Push
    leave(): Push
    on(event: string, callback: (payload: Record<string, unknown>) => void): void
    onError(callback: (error: unknown) => void): void
  }

  export class Push {
    receive(status: string, callback: (response: unknown) => void): Push
  }
}
