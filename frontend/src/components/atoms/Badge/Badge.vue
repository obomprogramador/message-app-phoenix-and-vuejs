<script setup lang="ts">
  import { computed } from 'vue'
  import Avatar from '@/components/atoms/Avatar/Avatar.vue'
  import Icon from '@/components/atoms/Icon/Icon.vue'
  import styles from './css/Badge.module.css'

  interface Props {
    name: string
  }

  const props = defineProps<Props>()

  const emit = defineEmits<{
    remove: []
  }>()

  const firstName = computed(() => props.name.split(' ')[0])
</script>

<template>
  <div :class="styles.badge">
    <Avatar :name="name" size="sm" />
    <span :class="styles.name">{{ firstName }}</span>
    <button
      :class="styles.removeBtn"
      :aria-label="`Remover ${name}`"
      @click="emit('remove')"
    >
      <Icon name="close" :size="14" />
    </button>
  </div>
</template>
