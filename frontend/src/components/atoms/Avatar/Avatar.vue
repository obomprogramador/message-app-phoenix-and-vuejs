<script setup lang="ts">
  import { computed } from 'vue'
  import styles from './css/Avatar.module.css'

  interface Props {
    src?: string
    name: string
    size?: 'sm' | 'md' | 'lg'
    status?: 'online' | 'offline' | 'away' | 'busy' | null
  }

  const props = withDefaults(defineProps<Props>(), {
    src: undefined,
    size: 'md',
    status: null,
  })

  const initials = computed(() => {
    return props.name
      .split(' ')
      .map((n) => n[0])
      .slice(0, 2)
      .join('')
      .toUpperCase()
  })
</script>

<template>
  <div :class="[styles.wrapper, styles[size]]">
    <img v-if="src" :src="src" :alt="name" :class="styles.image" />
    <span v-else :class="styles.initials">{{ initials }}</span>
    <span v-if="status" :class="[styles.statusDot, styles[status]]" />
  </div>
</template>
