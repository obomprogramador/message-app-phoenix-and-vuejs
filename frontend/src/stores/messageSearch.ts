import { defineStore } from 'pinia'
import { ref, computed, watch } from 'vue'
import type { MessageMatch } from '@/types'
import { useContactsStore } from './contacts'
import { useConversationsStore } from './conversations'

export const useMessageSearchStore = defineStore('messageSearch', () => {
  const messageSearchOpen = ref(false)
  const messageSearchQuery = ref('')
  const messageMatches = ref<MessageMatch[]>([])
  const activeMatchIndex = ref(0)

  const totalMatches = computed(() => messageMatches.value.length)

  const activeMatch = computed(() =>
    messageMatches.value[activeMatchIndex.value] ?? null,
  )

  const matchCounter = computed(() => {
    if (totalMatches.value === 0) return '0 / 0'
    return `${activeMatchIndex.value + 1} / ${totalMatches.value}`
  })

  function searchMessages() {
    const query = messageSearchQuery.value.toLowerCase().trim()
    const contactsStore = useContactsStore()
    const conversationsStore = useConversationsStore()

    if (!query || !contactsStore.activeContactId) {
      messageMatches.value = []
      activeMatchIndex.value = 0
      return
    }

    const messages =
      conversationsStore.conversations[contactsStore.activeContactId] ?? []
    const results: MessageMatch[] = []

    for (const msg of messages) {
      if (msg.content.toLowerCase().includes(query)) {
        results.push({ messageId: msg.id, content: msg.content })
      }
    }

    messageMatches.value = results
    activeMatchIndex.value = 0
  }

  function nextMatch() {
    if (messageMatches.value.length === 0) return
    activeMatchIndex.value =
      (activeMatchIndex.value + 1) % messageMatches.value.length
  }

  function prevMatch() {
    if (messageMatches.value.length === 0) return
    activeMatchIndex.value =
      (activeMatchIndex.value - 1 + messageMatches.value.length) %
      messageMatches.value.length
  }

  function openMessageSearch() {
    messageSearchOpen.value = true
    messageSearchQuery.value = ''
    messageMatches.value = []
    activeMatchIndex.value = 0
  }

  function closeMessageSearch() {
    messageSearchOpen.value = false
    messageSearchQuery.value = ''
    messageMatches.value = []
    activeMatchIndex.value = 0
  }

  watch(messageSearchQuery, () => {
    searchMessages()
  })

  return {
    messageSearchOpen,
    messageSearchQuery,
    messageMatches,
    activeMatchIndex,
    totalMatches,
    activeMatch,
    matchCounter,
    searchMessages,
    nextMatch,
    prevMatch,
    openMessageSearch,
    closeMessageSearch,
  }
})
