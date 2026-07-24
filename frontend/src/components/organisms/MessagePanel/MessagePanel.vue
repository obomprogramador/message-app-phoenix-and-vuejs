<script setup lang="ts">
import type { Contact, Message } from '@/types'
import MessageHeader from '@/components/molecules/MessageHeader/MessageHeader.vue'
import MessageSearchBar from '@/components/organisms/MessageSearchBar/MessageSearchBar.vue'
import MessageList from '@/components/organisms/MessageList/MessageList.vue'
import MessageComposer from '@/components/organisms/MessageComposer/MessageComposer.vue'
import styles from './css/MessagePanel.module.css'

interface Props {
  contact: Contact
  messages: Message[]
  inputMessage: string
  messageSearchOpen: boolean
  messageSearchQuery: string
  matchCounter: string
  totalMatches: number
  activeMatchMessageId: string | null
  loading?: boolean
  sending?: boolean
  hasMore?: boolean
  loadingMore?: boolean
}

withDefaults(defineProps<Props>(), {
  loading: false,
  sending: false,
  hasMore: false,
  loadingMore: false,
})

const emit = defineEmits<{
  'update:input-message': [value: string]
  send: []
  'open-search': []
  'close-search': []
  'update:search-query': [value: string]
  'next-match': []
  'prev-match': []
  'load-older': []
}>()
</script>

<template>
  <section :class="styles.panel">
    <MessageSearchBar
      v-if="messageSearchOpen"
      :model-value="messageSearchQuery"
      :match-counter="matchCounter"
      :has-matches="totalMatches > 0"
      @close="emit('close-search')"
      @next="emit('next-match')"
      @prev="emit('prev-match')"
      @update:model-value="emit('update:search-query', $event)"
    />
    <MessageHeader
      v-else
      :contact="contact"
      @open-search="emit('open-search')"
    />

    <MessageList
      v-if="!loading"
      :messages="messages"
      :search-query="messageSearchQuery"
      :active-match-message-id="activeMatchMessageId"
      :has-more="hasMore"
      :loading-more="loadingMore"
      @load-older="emit('load-older')"
    />
    <div v-else :class="styles.loading">
      <span>Carregando mensagens...</span>
    </div>

    <MessageComposer
      :model-value="inputMessage"
      :disabled="sending"
      @update:model-value="emit('update:input-message', $event)"
      @send="emit('send')"
    />
  </section>
</template>
