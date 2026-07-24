<script setup lang="ts">
  import type { MessageDirection } from '@/types'
  import { useHighlightSegments } from '@/composables/useChatSearch'
  import { formatTime } from '@/utils/format'
  import Avatar from '@/components/atoms/Avatar/Avatar.vue'
  import styles from './css/MessageBubble.module.css'

  interface Props {
    content: string
    direction: MessageDirection
    timestamp: Date
    isRead?: boolean
    highlight?: string
    isActiveMatch?: boolean
    senderName?: string
    senderAvatarUrl?: string
  }

  const props = withDefaults(defineProps<Props>(), {
    isRead: false,
    highlight: '',
    isActiveMatch: false,
    senderName: '',
    senderAvatarUrl: undefined,
  })

  const { segments } = useHighlightSegments(
    () => props.content,
    () => props.highlight,
  )
</script>

<template>
  <div :class="[styles.wrapper, styles[direction]]">
    <Avatar
      v-if="senderName && direction === 'received'"
      :src="senderAvatarUrl"
      :name="senderName"
      size="sm"
      :class="styles.avatar"
    />
    <div :class="styles.bubbleContainer">
      <span v-if="senderName && direction === 'received'" :class="styles.senderName">{{ senderName }}</span>
      <div :class="[styles.bubble, styles[direction]]">
        <p :class="styles.text">
          <template v-for="(seg, i) in segments" :key="i">
            <mark v-if="seg.isMatch" :class="[styles.highlight, isActiveMatch && styles.activeHighlight]">{{ seg.text }}</mark>
            <template v-else>{{ seg.text }}</template>
          </template>
        </p>
        <span :class="styles.meta">
          {{ formatTime(timestamp) }}
          <template v-if="direction === 'sent'">
            <span :class="[styles.check, isRead && styles.read]">✓✓</span>
          </template>
        </span>
      </div>
    </div>
  </div>
</template>
