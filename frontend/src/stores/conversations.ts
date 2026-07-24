import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import type { Message, ConversationType } from '@/types'
import { messagesApi } from '@/api/messages'
import { groupsApi } from '@/api/groups'
import { toMessageViewModel } from '@/api/transformers'
import { useLoadingMap } from '@/composables/useLoading'
import { usePagination } from '@/composables/usePagination'
import { useContactsStore } from './contacts'

export const useConversationsStore = defineStore('conversations', () => {
  const conversations = ref<Record<string, Message[]>>({})
  const inputMessage = ref('')
  const loadingMap = useLoadingMap()
  const error = ref<string | null>(null)
  const activeConversationType = ref<ConversationType>('contact')
  const pagination = usePagination({ initialPerPage: 50 })

  async function fetchMessages(contactId: string, options?: { append?: boolean; prepend?: boolean }) {
    const contactsStore = useContactsStore()
    const currentUserId = contactsStore.defaultContactId
    loadingMap.start(contactId)
    error.value = null

    if (!options?.append && !options?.prepend) {
      pagination.reset()
    }

    try {
      let meta: typeof pagination.meta.value = null

      if (activeConversationType.value === 'group') {
        const response = await groupsApi.listMessages(contactId, {
          page: pagination.page.value,
          per_page: pagination.perPage.value,
        })
        const newMessages: Message[] = response.data.map((msg) => ({
          id: msg.id,
          contactId: msg.group_id,
          content: msg.content,
          direction: msg.sender_id === currentUserId ? 'sent' : 'received',
          timestamp: new Date(msg.inserted_at),
          isRead: msg.is_read,
          senderId: msg.sender_id,
          senderName: msg.sender?.name ?? '',
          senderAvatarUrl: msg.sender?.avatar_url ?? undefined,
        }))

        if (options?.prepend) {
          const existing = conversations.value[contactId] ?? []
          const existingIds = new Set(existing.map((m) => m.id))
          const unique = newMessages.filter((m) => !existingIds.has(m.id))
          conversations.value[contactId] = [...unique, ...existing]
        } else if (options?.append) {
          const existing = conversations.value[contactId] ?? []
          const existingIds = new Set(existing.map((m) => m.id))
          const unique = newMessages.filter((m) => !existingIds.has(m.id))
          conversations.value[contactId] = [...existing, ...unique]
        } else {
          conversations.value[contactId] = newMessages
        }

        meta = response.meta ?? null
      } else {
        const response = await messagesApi.list(contactId, currentUserId, {
          page: pagination.page.value,
          per_page: pagination.perPage.value,
        })
        const newMessages = response.data.map(toMessageViewModel)

        if (options?.prepend) {
          const existing = conversations.value[contactId] ?? []
          const existingIds = new Set(existing.map((m) => m.id))
          const unique = newMessages.filter((m) => !existingIds.has(m.id))
          conversations.value[contactId] = [...unique, ...existing]
        } else if (options?.append) {
          const existing = conversations.value[contactId] ?? []
          const existingIds = new Set(existing.map((m) => m.id))
          const unique = newMessages.filter((m) => !existingIds.has(m.id))
          conversations.value[contactId] = [...existing, ...unique]
        } else {
          conversations.value[contactId] = newMessages
        }

        meta = response.meta ?? null
      }

      if (meta) pagination.updateMeta(meta)
    } catch (e) {
      error.value = e instanceof Error ? e.message : 'Erro ao carregar mensagens'
    } finally {
      loadingMap.stop(contactId)
    }
  }

  async function loadOlderMessages() {
    const contactsStore = useContactsStore()
    const contactId = contactsStore.activeContactId
    if (!contactId || !pagination.hasNextPage.value || pagination.loadingMore.value) return

    pagination.loadingMore.value = true
    try {
      pagination.nextPage()
      await fetchMessages(contactId, { prepend: true })
    } finally {
      pagination.loadingMore.value = false
    }
  }

  async function sendMessage() {
    const contactsStore = useContactsStore()
    const contactId = contactsStore.activeContactId
    const currentUserId = contactsStore.defaultContactId
    if (!contactId || !inputMessage.value.trim()) return

    const content = inputMessage.value.trim()
    inputMessage.value = ''

    const optimisticMessage: Message = {
      id: `temp-${Date.now()}`,
      contactId,
      content,
      direction: 'sent',
      timestamp: new Date(),
      isRead: false,
    }

    if (!conversations.value[contactId]) {
      conversations.value[contactId] = []
    }
    conversations.value[contactId].push(optimisticMessage)

    contactsStore.updateLastMessage(contactId, content, new Date())

    try {
      let realMessage: Message

      if (activeConversationType.value === 'group') {
        const response = await groupsApi.sendMessage(contactId, content, currentUserId)
        realMessage = {
          id: response.data.id,
          contactId: response.data.group_id,
          content: response.data.content,
          direction: 'sent',
          timestamp: new Date(response.data.inserted_at),
          isRead: response.data.is_read,
          senderId: response.data.sender_id,
          senderName: response.data.sender?.name ?? '',
          senderAvatarUrl: response.data.sender?.avatar_url ?? undefined,
        }
      } else {
        const response = await messagesApi.send(contactId, content, currentUserId)
        realMessage = toMessageViewModel(response.data)
      }

      const index = conversations.value[contactId].findIndex(
        (m) => m.id === optimisticMessage.id,
      )
      if (index !== -1) {
        const alreadyExists = conversations.value[contactId].some(
          (m) => m.id === realMessage.id,
        )
        if (alreadyExists) {
          conversations.value[contactId].splice(index, 1)
        } else {
          conversations.value[contactId][index] = realMessage
        }
      }
    } catch (e) {
      const index = conversations.value[contactId].findIndex(
        (m) => m.id === optimisticMessage.id,
      )
      if (index !== -1) {
        conversations.value[contactId].splice(index, 1)
      }
      error.value = e instanceof Error ? e.message : 'Erro ao enviar mensagem'
    }
  }

  function addReceivedMessage(message: Message) {
    const contactId = message.contactId
    if (!conversations.value[contactId]) {
      conversations.value[contactId] = []
    }

    const exists = conversations.value[contactId].some((m) => m.id === message.id)
    if (exists) return

    conversations.value[contactId].push(message)
  }

  function markMessagesAsRead(messageIds: string[]) {
    const ids = new Set(messageIds)
    for (const contactId of Object.keys(conversations.value)) {
      const msgs = conversations.value[contactId]
      if (msgs) {
        conversations.value[contactId] = msgs.map((msg) =>
          ids.has(msg.id) ? { ...msg, isRead: true } : msg,
        )
      }
    }
  }

  function setActiveConversationType(type: ConversationType) {
    activeConversationType.value = type
  }

  const activeMessages = computed<Message[]>(() => {
    const contactsStore = useContactsStore()
    return contactsStore.activeContactId
      ? (conversations.value[contactsStore.activeContactId] ?? [])
      : []
  })

  const isLoading = computed(() => {
    const contactsStore = useContactsStore()
    return contactsStore.activeContactId
      ? loadingMap.isLoading(contactsStore.activeContactId)
      : false
  })

  return {
    conversations,
    inputMessage,
    activeMessages,
    activeConversationType,
    isLoading,
    pagination,
    error,
    fetchMessages,
    loadOlderMessages,
    sendMessage,
    addReceivedMessage,
    markMessagesAsRead,
    setActiveConversationType,
  }
})
