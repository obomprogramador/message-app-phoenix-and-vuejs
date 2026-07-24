<script setup lang="ts">
  import type { Contact } from '@/types'
  import Avatar from '@/components/atoms/Avatar/Avatar.vue'
  import Icon from '@/components/atoms/Icon/Icon.vue'
  import { CONTACTS_MODAL } from '@/constants/strings'
  import styles from './css/ContactListItem.module.css'

  interface Props {
    contact: Contact
    disabled?: boolean
  }

  withDefaults(defineProps<Props>(), {
    disabled: false,
  })

  const emit = defineEmits<{
    delete: [contactId: string]
  }>()
</script>

<template>
  <div :class="styles.item">
    <Avatar
      :src="contact.avatarUrl"
      :name="contact.name"
      size="md"
    />
    <div :class="styles.info">
      <span :class="styles.name">{{ contact.name }}</span>
      <span :class="styles.nickName">{{ contact.nickName }}</span>
    </div>
    <button
      :class="styles.deleteBtn"
      :aria-label="CONTACTS_MODAL.DELETE_ARIA"
      :disabled="disabled"
      @click="emit('delete', contact.id)"
    >
      <Icon name="trash" :size="18" />
    </button>
  </div>
</template>
