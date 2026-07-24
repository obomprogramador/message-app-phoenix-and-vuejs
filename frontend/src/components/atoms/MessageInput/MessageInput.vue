<script setup lang="ts">
  import styles from './css/MessageInput.module.css'

  interface Props {
    modelValue: string
    placeholder?: string
    disabled?: boolean
  }

  withDefaults(defineProps<Props>(), {
    placeholder: 'Digite sua mensagem...',
    disabled: false,
  })

  const emit = defineEmits<{
    'update:modelValue': [value: string]
    send: []
  }>()

  function onInput(event: Event): void {
    const target = event.target as HTMLInputElement
    emit('update:modelValue', target.value)
  }

  function onKeydown(event: KeyboardEvent): void {
    if (event.key === 'Enter' && !event.shiftKey) {
      event.preventDefault()
      emit('send')
    }
  }
</script>

<template>
  <div :class="styles.wrapper">
    <input
      type="text"
      :value="modelValue"
      :placeholder="placeholder"
      :disabled="disabled"
      :class="styles.input"
      @input="onInput"
      @keydown="onKeydown"
    />
  </div>
</template>
