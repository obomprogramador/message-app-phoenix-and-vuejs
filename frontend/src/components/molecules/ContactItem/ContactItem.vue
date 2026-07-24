<script setup lang="ts">
  import type { Contact } from '@/types'
  import Avatar from '@/components/atoms/Avatar/Avatar.vue'
  import { formatTime } from '@/utils/format'
  import styles from './css/ContactItem.module.css'

  interface Props {
    contact: Contact
    isActive?: boolean
  }

  withDefaults(defineProps<Props>(), {
    isActive: false,
  })

  const emit = defineEmits<{
    select: [contactId: string]
  }>()
</script>

<template>
  <div
    :class="[styles.item, isActive && styles.active]"
    @click="emit('select', contact.id)"
  >
    <Avatar
      :src="contact.avatarUrl"
      :name="contact.name"
      :status="contact.isOnline ? 'online' : 'offline'"
    />
    <div :class="styles.info">
      <div :class="styles.header">
        <span :class="styles.name">{{ contact.name }}</span>
        <span :class="styles.time">{{ formatTime(contact.lastMessageTime) }}</span>
      </div>
      <div :class="styles.bottomRow">
        <p :class="styles.preview">{{ contact.lastMessage }}</p>
        <span v-if="contact.unreadCount && contact.unreadCount > 0" :class="styles.badge">
          {{ contact.unreadCount > 99 ? '99+' : contact.unreadCount }}
        </span>
      </div>
    </div>
  </div>
</template>
