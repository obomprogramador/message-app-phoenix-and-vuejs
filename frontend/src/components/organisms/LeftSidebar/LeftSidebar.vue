<script setup lang="ts">
import type { Contact } from '@/types'
import ActionBar from '@/components/organisms/ActionBar/ActionBar.vue'
import ContactList from '@/components/organisms/ContactList/ContactList.vue'
import styles from './css/LeftSidebar.module.css'

interface Props {
  contacts: Contact[]
  searchQuery: string
  activeContactId?: string
  hasMore?: boolean
  loadingMore?: boolean
  isConnected?: boolean
  isReconnecting?: boolean
}

withDefaults(defineProps<Props>(), {
  isConnected: false,
  isReconnecting: false,
})

const emit = defineEmits<{
  'update:search-query': [value: string]
  'select': [contactId: string]
  'new-group': []
  'contacts': []
  'load-more': []
}>()
</script>

<template>
  <aside :class="styles.sidebar">
    <ActionBar
      :search-query="searchQuery"
      @update:search-query="emit('update:search-query', $event)"
      @new-group="emit('new-group')"
      @contacts="emit('contacts')"
    />
    <ContactList
      :contacts="contacts"
      :active-contact-id="activeContactId"
      :has-more="hasMore"
      :loading-more="loadingMore"
      @select="emit('select', $event)"
      @load-more="emit('load-more')"
    />
    <div :class="styles.statusBar">
      <span :class="[styles.statusDot, isConnected ? styles.connected : isReconnecting ? styles.reconnecting : styles.disconnected]" />
      <span :class="styles.statusText">
        {{ isConnected ? 'Conectado' : isReconnecting ? 'Reconectando...' : 'Desconectado' }}
      </span>
    </div>
  </aside>
</template>
