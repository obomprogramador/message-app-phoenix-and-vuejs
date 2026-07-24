<script setup lang="ts">
  import type { Contact } from '@/types'
  import Avatar from '@/components/atoms/Avatar/Avatar.vue'
  import Icon from '@/components/atoms/Icon/Icon.vue'
  import styles from './css/GroupContactItem.module.css'

  interface Props {
    contact: Contact
    isSelected: boolean
    isDisabled: boolean
  }

  defineProps<Props>()

  const emit = defineEmits<{
    toggle: [contact: Contact]
  }>()
</script>

<template>
  <div
    :class="[styles.item, isDisabled && styles.disabled]"
    @click="!isDisabled && emit('toggle', contact)"
  >
    <Avatar
      :src="contact.avatarUrl"
      :name="contact.name"
      size="md"
    />
    <div :class="styles.info">
      <span :class="styles.name">{{ contact.name }}</span>
    </div>
    <div :class="[styles.checkbox, isSelected && styles.checked]">
      <Icon v-if="isSelected" name="add" :size="16" />
    </div>
  </div>
</template>
