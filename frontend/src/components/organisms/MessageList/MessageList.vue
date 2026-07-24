<script setup lang="ts">
import { ref, watch, nextTick, onMounted } from 'vue'
import type { Message } from '@/types'
import MessageBubble from '@/components/molecules/MessageBubble/MessageBubble.vue'
import { useInfiniteScroll } from '@/composables/useInfiniteScroll'
import styles from './css/MessageList.module.css'

interface Props {
  messages: Message[]
  searchQuery?: string
  activeMatchMessageId?: string | null
  hasMore?: boolean
  loadingMore?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  searchQuery: '',
  activeMatchMessageId: null,
  hasMore: false,
  loadingMore: false,
})

const emit = defineEmits<{
  'load-older': []
}>()

const listRef = ref<HTMLDivElement | null>(null)
let shouldAutoScroll = true
let isPrepending = false
const hasNewMessages = ref(false)
const pendingScrollCount = ref(0)

function isNearBottom(): boolean {
  if (!listRef.value) return true
  const { scrollTop, scrollHeight, clientHeight } = listRef.value
  return scrollHeight - scrollTop - clientHeight < 80
}

const { isLoadingMore } = useInfiniteScroll(
  listRef,
  () => {
    if (props.hasMore && !props.loadingMore) {
      isPrepending = true
      emit('load-older')
    }
  },
  { threshold: 100, direction: 'top', enabled: props.hasMore },
)

function scrollToBottom() {
  if (!listRef.value) return
  listRef.value.scrollTop = listRef.value.scrollHeight
  hasNewMessages.value = false
  pendingScrollCount.value = 0
}

watch(
  () => props.messages.length,
  async (newLength, oldLength) => {
    await nextTick()
    if (!listRef.value) return

    if (isPrepending) {
      const newScrollHeight = listRef.value.scrollHeight
      const previousScrollHeight = (listRef.value as HTMLElement & { _prevScrollHeight?: number })._prevScrollHeight ?? newScrollHeight
      const diff = newScrollHeight - previousScrollHeight
      if (diff > 0) {
        listRef.value.scrollTop += diff
      }
      isPrepending = false
      return
    }

    if (newLength > (oldLength ?? 0) && isNearBottom()) {
      shouldAutoScroll = true
    }

    if (shouldAutoScroll) {
      listRef.value.scrollTop = listRef.value.scrollHeight
      hasNewMessages.value = false
      pendingScrollCount.value = 0
    } else if (newLength > (oldLength ?? 0)) {
      pendingScrollCount.value += newLength - (oldLength ?? 0)
      hasNewMessages.value = true
    }
  },
)

function onScroll() {
  if (!listRef.value) return
  shouldAutoScroll = isNearBottom()
  if (shouldAutoScroll) {
    hasNewMessages.value = false
    pendingScrollCount.value = 0
  }
}

watch(
  () => props.activeMatchMessageId,
  async (id) => {
    if (!id || !listRef.value) return
    await nextTick()
    const el = listRef.value.querySelector(`[data-message-id="${id}"]`)
    if (el) {
      el.scrollIntoView({ behavior: 'smooth', block: 'center' })
    }
  },
)

onMounted(() => {
  if (listRef.value) {
    listRef.value.scrollTop = listRef.value.scrollHeight
  }
})
</script>

<template>
  <div ref="listRef" :class="styles.list" @scroll="onScroll">
    <div v-if="isLoadingMore || loadingMore" :class="styles.loadingTop">
      <span>Carregando mensagens mais antigas...</span>
    </div>
    <MessageBubble
      v-for="message in messages"
      :key="message.id"
      :data-message-id="message.id"
      :content="message.content"
      :direction="message.direction"
      :timestamp="message.timestamp"
      :is-read="message.isRead"
      :highlight="searchQuery"
      :is-active-match="message.id === activeMatchMessageId"
      :sender-name="message.senderName"
      :sender-avatar-url="message.senderAvatarUrl"
    />
    <Transition name="fade">
      <button
        v-if="hasNewMessages"
        :class="styles.newMessagesBtn"
        @click="scrollToBottom"
      >
        <span v-if="pendingScrollCount > 0">{{ pendingScrollCount }} nova(s) mensagem(ns)</span>
        <span v-else>Novas mensagens</span>
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <polyline points="6 9 12 15 18 9"></polyline>
        </svg>
      </button>
    </Transition>
  </div>
</template>
