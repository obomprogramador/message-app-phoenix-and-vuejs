<script setup lang="ts">
import { ref, computed } from 'vue'
import type { Contact } from '@/types'
import ContactItem from '@/components/molecules/ContactItem/ContactItem.vue'
import { useInfiniteScroll } from '@/composables/useInfiniteScroll'
import styles from './css/ContactList.module.css'

interface Props {
  contacts: Contact[]
  activeContactId?: string
  hasMore?: boolean
  loadingMore?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  activeContactId: undefined,
  hasMore: false,
  loadingMore: false,
})

const emit = defineEmits<{
  select: [contactId: string]
  'load-more': []
}>()

const listRef = ref<HTMLDivElement | null>(null)

const { isLoadingMore } = useInfiniteScroll(
  listRef,
  () => emit('load-more'),
  { threshold: 150, direction: 'bottom', enabled: props.hasMore },
)
</script>

<template>
  <div ref="listRef" :class="styles.list">
    <ContactItem
      v-for="contact in contacts"
      :key="contact.id"
      :contact="contact"
      :is-active="contact.id === activeContactId"
      @select="emit('select', $event)"
    />
    <div v-if="isLoadingMore || loadingMore" :class="styles.loading">
      <span>Carregando...</span>
    </div>
  </div>
</template>
