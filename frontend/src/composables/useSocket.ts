// Mesma coisa do Hooks do ReactJS, objetivo compartilhar funções e dados por todo o app.

import { ref, onUnmounted } from 'vue'
import {
  connectSocket,
  disconnectSocket,
  isConnected as checkConnected,
  joinChannel,
  leaveChannel,
  rejoinAllChannels,
  onSocketOpen,
  onSocketClose,
  onSocketError,
  type JoinCallbacks,
} from '@/services/socket'
import type { Channel } from 'phoenix'

const isConnected = ref(false)
const isReconnecting = ref(false)

let initialized = false
let reconnectingTimer: ReturnType<typeof setTimeout> | null = null

function setupListeners() {
  if (initialized) return
  initialized = true

  onSocketOpen(() => {
    isConnected.value = true
    isReconnecting.value = false
    if (reconnectingTimer) {
      clearTimeout(reconnectingTimer)
      reconnectingTimer = null
    }
  })

  onSocketClose(() => {
    isConnected.value = false
  })

  onSocketError(() => {
    isConnected.value = false
    if (!isReconnecting.value) {
      reconnectingTimer = setTimeout(() => {
        isReconnecting.value = true
      }, 3_000)
    }
  })
}

export function useSocket() {
  setupListeners()

  function connect(contactId: string) {
    connectSocket(contactId)
    isConnected.value = checkConnected()
  }

  function disconnect() {
    disconnectSocket()
    isConnected.value = false
    isReconnecting.value = false
  }

  function join(topic: string, callbacks?: JoinCallbacks): Channel {
    return joinChannel(topic, callbacks)
  }

  function leave(topic: string) {
    leaveChannel(topic)
  }

  function rejoinChannels() {
    rejoinAllChannels()
  }

  return {
    isConnected,
    isReconnecting,
    connect,
    disconnect,
    join,
    leave,
    rejoinChannels,
  }
}
