<script setup lang="ts">
import type { Contact } from '@/types'
import { useKeydown } from '@/composables/useKeydown'
import Button from '@/components/atoms/Button/Button.vue'
import Icon from '@/components/atoms/Icon/Icon.vue'
import SearchInput from '@/components/atoms/SearchInput/SearchInput.vue'
import ContactListItem from '@/components/molecules/ContactListItem/ContactListItem.vue'
import { CONTACTS_MODAL } from '@/constants/strings'
import styles from './css/ContactsModal.module.css'

interface Props {
  isOpen: boolean
  groupedContacts: Array<{
    letter: string
    contacts: Contact[]
  }>
  searchQuery: string
  loading?: boolean
}

withDefaults(defineProps<Props>(), {
  loading: false,
})

const emit = defineEmits<{
  'update:search-query': [value: string]
  close: []
  'add-contact': []
  'delete-contact': [contactId: string]
}>()

function onKeyDown(e: KeyboardEvent): void {
  if (e.key === 'Escape') {
    emit('close')
  }
}

useKeydown(onKeyDown)
</script>

<template>
  <Teleport to="body">
    <div v-if="isOpen" :class="styles.overlay" @click.self="emit('close')">
      <div :class="styles.modal">
        <div :class="styles.header">
          <h2 :class="styles.title">{{ CONTACTS_MODAL.TITLE }}</h2>
          <div :class="styles.headerActions">
            <Button variant="primary" size="sm" @click="emit('add-contact')">
              <Icon name="add" :size="18" />
              <span>{{ CONTACTS_MODAL.ADD_BUTTON }}</span>
            </Button>
            <button :class="styles.closeBtn" :aria-label="CONTACTS_MODAL.TITLE" @click="emit('close')">
              <Icon name="close" :size="20" />
            </button>
          </div>
        </div>

        <div :class="styles.searchWrapper">
          <SearchInput
            :model-value="searchQuery"
            :placeholder="CONTACTS_MODAL.SEARCH_PLACEHOLDER"
            @update:model-value="emit('update:search-query', $event)"
          />
        </div>

        <div :class="styles.listContainer">
          <div v-if="groupedContacts.length === 0" :class="styles.emptyState">
            <p>{{ CONTACTS_MODAL.EMPTY_STATE }}</p>
          </div>
          <template v-else>
            <div
              v-for="group in groupedContacts"
              :key="group.letter"
              :class="styles.group"
            >
              <div :class="styles.letterHeader">{{ group.letter }}</div>
          <ContactListItem
            v-for="contact in group.contacts"
            :key="contact.id"
            :contact="contact"
            :disabled="loading"
            @delete="emit('delete-contact', $event)"
          />
            </div>
          </template>
        </div>
      </div>
    </div>
  </Teleport>
</template>
