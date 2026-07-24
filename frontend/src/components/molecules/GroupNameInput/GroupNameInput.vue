<script setup lang="ts">
  import Icon from '@/components/atoms/Icon/Icon.vue'
  import Badge from '@/components/atoms/Badge/Badge.vue'
  import { GROUP_MODAL } from '@/constants/strings'
  import styles from './css/GroupNameInput.module.css'

  interface Props {
    modelValue: string
    selectedContacts: Array<{
      id: string
      name: string
    }>
  }

  defineProps<Props>()

  const emit = defineEmits<{
    'update:modelValue': [value: string]
    'remove-contact': [contactId: string]
  }>()

  function onInput(event: Event): void {
    const target = event.target as HTMLInputElement
    emit('update:modelValue', target.value)
  }
</script>

<template>
  <div :class="styles.wrapper">
    <label :class="styles.label">{{ GROUP_MODAL.GROUP_NAME_LABEL }}</label>
    <div :class="[styles.inputWrapper, 'inputField']">
      <Icon name="contacts" :size="18" />
      <input
        type="text"
        :value="modelValue"
        :placeholder="GROUP_MODAL.GROUP_NAME_PLACEHOLDER"
        @input="onInput"
      />
    </div>
    <div v-if="selectedContacts.length > 0" :class="styles.badges">
      <Badge
        v-for="contact in selectedContacts"
        :key="contact.id"
        :name="contact.name"
        @remove="emit('remove-contact', contact.id)"
      />
    </div>
  </div>
</template>
