<script setup lang="ts">
  import Icon from '@/components/atoms/Icon/Icon.vue'
  import { PLACEHOLDERS } from '@/constants/strings'
  import styles from './css/SearchInput.module.css'

  interface Props {
    modelValue: string
    placeholder?: string
  }

  withDefaults(defineProps<Props>(), {
    placeholder: PLACEHOLDERS.SEARCH,
  })

  const emit = defineEmits<{
    'update:modelValue': [value: string]
  }>()

  function onInput(event: Event): void {
    const target = event.target as HTMLInputElement
    emit('update:modelValue', target.value)
  }
</script>

<template>
  <div :class="[styles.wrapper, 'inputField']">
    <Icon name="search" :size="16" />
    <input
      type="text"
      :value="modelValue"
      :placeholder="placeholder"
      @input="onInput"
    />
  </div>
</template>
