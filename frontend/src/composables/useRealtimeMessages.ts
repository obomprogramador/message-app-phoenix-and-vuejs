// Mesma coisa do Hooks do ReactJS, objetivo compartilhar funções e dados por todo o app.

import { computed, watch, onUnmounted } from 'vue'
import { storeToRefs } from 'pinia'
import { useSocket } from '@/composables/useSocket'
import { useContactsStore } from '@/stores/contacts'
import { useConversationsStore } from '@/stores/conversations'
import { useGroupsStore } from '@/stores/groups'
import type { Message } from '@/types'
import type { Channel } from 'phoenix'

const activeChannels = new Map<string, Channel>()

function buildDirectTopic(contactId: string): string {
  return `messages:${contactId}`
}

function buildGroupTopic(groupId: string): string {
  return `group:${groupId}`
}

function parseDirectMessage(payload: Record<string, unknown>, currentUserId: string): Message {
  const fromId = payload.from_contact_id as string
  const direction = fromId === currentUserId ? 'sent' : 'received'
  const contactId = direction === 'received' ? fromId : (payload.contact_id as string)

  return {
    id: payload.id as string,
    contactId,
    content: payload.content as string,
    direction,
    timestamp: new Date(payload.inserted_at as string),
    isRead: payload.is_read as boolean,
  }
}

function parseGroupMessage(payload: Record<string, unknown>, currentUserId: string): Message {
  const senderId = payload.sender_id as string
  const sender = payload.sender as Record<string, string> | undefined

  return {
    id: payload.id as string,
    contactId: payload.group_id as string,
    content: payload.content as string,
    direction: senderId === currentUserId ? 'sent' : 'received',
    timestamp: new Date(payload.inserted_at as string),
    isRead: payload.is_read as boolean,
    senderId,
    senderName: sender?.name ?? '',
    senderAvatarUrl: sender?.avatar_url ?? undefined,
  }
}

export function useRealtimeMessages() {
  const socket = useSocket()
  const contactsStore = useContactsStore()
  const conversationsStore = useConversationsStore()
  const groupsStore = useGroupsStore()

  const { activeContactId, defaultContactId } = storeToRefs(contactsStore)
  const { activeConversationType } = storeToRefs(conversationsStore)

  const pendingGroupTopics = new Map<string, true>()

  function leaveAllChannels() {
    for (const [topic] of activeChannels) {
      socket.leave(topic)
    }
    activeChannels.clear()
  }

  function setupDirectChannelListeners(channel: Channel) {
    channel.on('new_message', (payload: Record<string, unknown>) => {
      const currentUserId = defaultContactId.value
      if (!currentUserId) return

      const message = parseDirectMessage(payload, currentUserId)
      const messageContactId = message.contactId
      const isActive = activeContactId.value === messageContactId &&
        activeConversationType.value === 'contact'

      if (isActive) {
        conversationsStore.addReceivedMessage(message)
      }

      contactsStore.updateLastMessage(messageContactId, message.content, message.timestamp)

      if (!isActive) {
        contactsStore.incrementUnreadCount(messageContactId)
      }
    })

    channel.on('messages_read', (payload: Record<string, unknown>) => {
      const messageIds = payload.message_ids as string[]
      conversationsStore.markMessagesAsRead(messageIds)
    })
  }

  function setupGroupChannelListeners(channel: Channel, groupId: string) {
    channel.on('new_message', (payload: Record<string, unknown>) => {
      const currentUserId = defaultContactId.value
      if (!currentUserId) return

      const message = parseGroupMessage(payload, currentUserId)
      const isActive = activeContactId.value === groupId &&
        activeConversationType.value === 'group'

      if (isActive) {
        conversationsStore.addReceivedMessage(message)
      }

      groupsStore.updateLastMessage(groupId, message.content, message.timestamp)

      if (!isActive) {
        groupsStore.incrementUnreadCount(groupId)
      }
    })

    channel.on('messages_read', (payload: Record<string, unknown>) => {
      const messageIds = payload.message_ids as string[]
      conversationsStore.markMessagesAsRead(messageIds)
    })
  }

  function joinDirectChannel(userId: string) {
    const topic = buildDirectTopic(userId)
    if (activeChannels.has(topic)) return

    const channel = socket.join(topic)
    activeChannels.set(topic, channel)
    setupDirectChannelListeners(channel)
  }

  function joinGroupChannel(groupId: string) {
    const topic = buildGroupTopic(groupId)

    if (activeChannels.has(topic)) return

    pendingGroupTopics.set(topic, true)

    const channel = socket.join(topic, {
      ok: () => {
        activeChannels.set(topic, channel)
        setupGroupChannelListeners(channel, groupId)
      },
      error: () => {
        pendingGroupTopics.delete(topic)
        activeChannels.delete(topic)
      },
      timeout: () => {
        pendingGroupTopics.delete(topic)
        activeChannels.delete(topic)
      },
    })
  }

  function leaveGroupChannel(groupId: string) {
    const topic = buildGroupTopic(groupId)
    const channel = activeChannels.get(topic)
    if (channel) {
      socket.leave(topic)
      activeChannels.delete(topic)
    }
    pendingGroupTopics.delete(topic)
  }

  function reconnectChannels() {
    socket.rejoinChannels()

    const userId = defaultContactId.value
    if (userId) {
      joinDirectChannel(userId)
    }

    for (const [topic] of pendingGroupTopics) {
      const groupId = topic.replace('group:', '')
      const channel = socket.join(topic, {
        ok: () => {
          activeChannels.set(topic, channel)
          setupGroupChannelListeners(channel, groupId)
        },
        error: () => {
          pendingGroupTopics.delete(topic)
          activeChannels.delete(topic)
        },
        timeout: () => {
          pendingGroupTopics.delete(topic)
          activeChannels.delete(topic)
        },
      })
    }
  }

  function connect(contactId: string) {
    socket.connect(contactId)
  }

  function disconnect() {
    leaveAllChannels()
    pendingGroupTopics.clear()
    socket.disconnect()
  }

  const currentGroupTopic = computed(() => {
    if (activeConversationType.value === 'group' && activeContactId.value) {
      return buildGroupTopic(activeContactId.value)
    }
    return null
  })

  watch(currentGroupTopic, (newTopic, oldTopic) => {
    if (oldTopic && oldTopic !== newTopic) {
      const oldGroupId = oldTopic.replace('group:', '')
      leaveGroupChannel(oldGroupId)
    }
    if (newTopic) {
      const newGroupId = newTopic.replace('group:', '')
      joinGroupChannel(newGroupId)
    }
  })

  watch(defaultContactId, (userId) => {
    if (userId && socket.isConnected.value) {
      joinDirectChannel(userId)
    }
  })

  watch(socket.isConnected, (connected, wasConnected) => {
    if (connected && wasConnected === false) {
      reconnectChannels()
    }
  })

  onUnmounted(() => {
    disconnect()
  })

  return {
    isConnected: socket.isConnected,
    isReconnecting: socket.isReconnecting,
    connect,
    disconnect,
  }
}
