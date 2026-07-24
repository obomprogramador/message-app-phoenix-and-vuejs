<script setup lang="ts">
import { useKeydown } from '@/composables/useKeydown'
import Icon from '@/components/atoms/Icon/Icon.vue'
import { PLACEHOLDERS, ARIA_LABELS } from '@/constants/strings'
import styles from './css/MessageSearchBar.module.css'

interface Props {
  modelValue: string
  matchCounter: string
  hasMatches: boolean
}

defineProps<Props>()

const emit = defineEmits<{
  'update:modelValue': [value: string]
  close: []
  next: []
  prev: []
}>()

function onInput(event: Event): void {
  const target = event.target as HTMLInputElement
  emit('update:modelValue', target.value)
}

function onKeyDown(e: KeyboardEvent): void {
  if (e.key === 'Escape') {
    emit('close')
  } else if (e.key === 'Enter' && e.shiftKey) {
    e.preventDefault()
    emit('prev')
  } else if (e.key === 'Enter') {
    e.preventDefault()
    emit('next')
  }
}

useKeydown(onKeyDown)
</script>

<template>
  <div :class="styles.searchBar">
    <button :class="styles.closeBtn" @click="emit('close')" :aria-label="ARIA_LABELS.CLOSE_SEARCH">
      <Icon name="close" :size="20" />
    </button>

    <div :class="[styles.inputWrapper, 'inputField']">
      <Icon name="search" :size="16" />
      <input
        type="text"
        :value="modelValue"
        :placeholder="PLACEHOLDERS.SEARCH_MESSAGE"
        @input="onInput"
        autofocus
      />
    </div>

    <span :class="styles.counter">{{ matchCounter }}</span>

    <div :class="styles.navButtons">
      <button
        :class="styles.navBtn"
        :disabled="!hasMatches"
        @click="emit('prev')"
        :aria-label="ARIA_LABELS.PREVIOUS_RESULT"
      >
        <Icon name="arrow-up" :size="18" />
      </button>
      <button
        :class="styles.navBtn"
        :disabled="!hasMatches"
        @click="emit('next')"
        :aria-label="ARIA_LABELS.NEXT_RESULT"
      >
        <Icon name="arrow-down" :size="18" />
      </button>
    </div>
  </div>
</template>
