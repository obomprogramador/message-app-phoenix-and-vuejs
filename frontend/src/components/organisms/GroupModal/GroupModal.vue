<script setup lang="ts">
import type { Contact } from '@/types'
import { useKeydown } from '@/composables/useKeydown'
import Button from '@/components/atoms/Button/Button.vue'
import Icon from '@/components/atoms/Icon/Icon.vue'
import SearchInput from '@/components/atoms/SearchInput/SearchInput.vue'
import GroupNameInput from '@/components/molecules/GroupNameInput/GroupNameInput.vue'
import GroupContactItem from '@/components/molecules/GroupContactItem/GroupContactItem.vue'
import { GROUP_MODAL } from '@/constants/strings'
import styles from './css/GroupModal.module.css'

interface Props {
  isOpen: boolean
  groupName: string
  selectionLabel: string
  selectedContacts: Array<{ id: string; name: string }>
  filteredContacts: Contact[]
  searchQuery: string
  canCreate: boolean
  isContactSelected: (contactId: string) => boolean
  isContactDisabled: boolean
  loading?: boolean
}

withDefaults(defineProps<Props>(), {
  loading: false,
})

const emit = defineEmits<{
  close: []
  back: []
  'update:group-name': [value: string]
  'update:search-query': [value: string]
  'toggle-contact': [contact: Contact]
  'remove-contact': [contactId: string]
  'create-group': []
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
          <div :class="styles.headerLeft">
            <button :class="styles.backBtn" :aria-label="GROUP_MODAL.TITLE" @click="emit('back')">
              <Icon name="arrow-left" :size="20" />
            </button>
            <div :class="styles.headerText">
              <h2 :class="styles.title">{{ GROUP_MODAL.TITLE }}</h2>
              <span :class="styles.selectionLabel">{{ selectionLabel }}</span>
            </div>
          </div>
        </div>

        <div :class="styles.groupNameWrapper">
          <GroupNameInput
            :model-value="groupName"
            :selected-contacts="selectedContacts"
            @update:model-value="emit('update:group-name', $event)"
            @remove-contact="emit('remove-contact', $event)"
          />
        </div>

        <div :class="styles.contactsSection">
          <label :class="styles.contactsLabel">{{ GROUP_MODAL.CONTACTS_LABEL }}</label>
          <SearchInput
            :model-value="searchQuery"
            :placeholder="GROUP_MODAL.SEARCH_PLACEHOLDER"
            @update:model-value="emit('update:search-query', $event)"
          />
          <div :class="styles.contactsList">
            <GroupContactItem
              v-for="contact in filteredContacts"
              :key="contact.id"
              :contact="contact"
              :is-selected="isContactSelected(contact.id)"
              :is-disabled="isContactDisabled"
              @toggle="emit('toggle-contact', $event)"
            />
          </div>
        </div>

        <div :class="styles.footer">
          <Button variant="secondary" size="md" @click="emit('close')">
            {{ GROUP_MODAL.CANCEL_BUTTON }}
          </Button>
          <Button variant="primary" size="md" :disabled="!canCreate || loading" @click="emit('create-group')">
            {{ loading ? 'Criando...' : GROUP_MODAL.CREATE_BUTTON }}
          </Button>
        </div>
      </div>
    </div>
  </Teleport>
</template>
