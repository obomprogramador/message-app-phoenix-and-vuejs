<script setup lang="ts">
  import type { Contact } from '@/types'
  import Avatar from '@/components/atoms/Avatar/Avatar.vue'
  import Icon from '@/components/atoms/Icon/Icon.vue'
  import { STATUS_LABELS } from '@/utils/format'
  import { ARIA_LABELS } from '@/constants/strings'
  import styles from './css/MessageHeader.module.css'

  defineProps<{ contact: Contact }>()

  const emit = defineEmits<{
    'open-search': []
  }>()
</script>

<template>
  <div :class="styles.header">
    <Avatar
      :src="contact.avatarUrl"
      :name="contact.name"
      :status="contact.isOnline ? 'online' : 'offline'"
      size="md"
    />
    <div :class="styles.info">
      <span :class="styles.name">{{ contact.name }}</span>
      <span :class="styles.status">
        {{ STATUS_LABELS[contact.isOnline ? 'online' : 'offline'] }}
      </span>
    </div>
    <button :class="styles.searchBtn" :aria-label="ARIA_LABELS.SEARCH_MESSAGES" @click="emit('open-search')">
      <Icon name="search" :size="20" />
    </button>
  </div>
</template>
