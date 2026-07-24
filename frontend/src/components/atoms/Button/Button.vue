<script setup lang="ts">
  import styles from './css/Button.module.css'

  interface Props {
    variant?: 'primary' | 'secondary' | 'ghost'
    size?: 'sm' | 'md' | 'lg'
    disabled?: boolean
  }

  const props = withDefaults(defineProps<Props>(), {
    variant: 'primary',
    size: 'md',
    disabled: false,
  })

  const emit = defineEmits<{
    click: [event: MouseEvent]
  }>()
</script>

<template>
  <button
    :class="[styles.button, styles[variant], styles[size]]"
    :disabled="disabled"
    @click="emit('click', $event)"
  >
    <slot />
  </button>
</template>
