<script setup lang="ts">
  import { computed, onMounted, watch } from 'vue'
  import { useRoute } from 'vue-router'
  import { storeToRefs } from 'pinia'
  import { useContactsStore } from '@/stores/contacts'
  import { useContactsModalStore } from '@/stores/contactsModal'
  import { useConversationsStore } from '@/stores/conversations'
  import { useGroupsStore } from '@/stores/groups'
  import { useGroupModalStore } from '@/stores/groupModal'
  import { useMessageSearchStore } from '@/stores/messageSearch'
  import { useNewContactPopupStore } from '@/stores/newContactPopup'
  import { useRealtimeMessages } from '@/composables/useRealtimeMessages'
  import type { Contact } from '@/types'
  import { EMPTY_STATES } from '@/constants/strings'
  import { checkApiAvailability } from '@/api/client'
  import LeftSidebar from '@/components/organisms/LeftSidebar/LeftSidebar.vue'
  import ContactsModal from '@/components/organisms/ContactsModal/ContactsModal.vue'
  import GroupModal from '@/components/organisms/GroupModal/GroupModal.vue'
  import NewContactPopup from '@/components/organisms/NewContactPopup/NewContactPopup.vue'
  import MessagePanel from '@/components/organisms/MessagePanel/MessagePanel.vue'
  import styles from './css/ChatPage.module.css'

  const route = useRoute()
  const contactsStore = useContactsStore()
  const contactsModalStore = useContactsModalStore()
  const conversationsStore = useConversationsStore()
  const groupsStore = useGroupsStore()
  const groupModalStore = useGroupModalStore()
  const messageSearchStore = useMessageSearchStore()
  const newContactPopupStore = useNewContactPopupStore()
  const { isConnected, isReconnecting, connect } = useRealtimeMessages()

  const { filteredContacts, searchQuery, activeContactId, hasContacts, defaultContactId } = storeToRefs(contactsStore)
  const { isOpen: isContactsModalOpen, searchQuery: modalSearchQuery, groupedContacts, loading: contactsModalLoading } = storeToRefs(contactsModalStore)
  const { activeMessages, inputMessage, isLoading: messagesLoading, error: conversationsError, activeConversationType } = storeToRefs(conversationsStore)
  const { groups } = storeToRefs(groupsStore)
  const {
    isOpen: isGroupModalOpen,
    groupName,
    selectionLabel,
    selectedContacts,
    filteredContacts: groupFilteredContacts,
    searchQuery: groupSearchQuery,
    canCreate,
    loading: groupLoading,
  } = storeToRefs(groupModalStore)
  const { messageSearchOpen, messageSearchQuery, matchCounter, totalMatches, activeMatch } = storeToRefs(messageSearchStore)
  const { isOpen: isNewContactPopupOpen, nickName, feedbackMessage, loading: newContactLoading } = storeToRefs(newContactPopupStore)

  const sidebarItems = computed<Contact[]>(() => {
    return [
      ...groups.value,
      ...filteredContacts.value,
    ]
  })

  const activeContact = computed<Contact | null>(() => {
    if (!activeContactId.value) return null
    return (
      groups.value.find((g) => g.id === activeContactId.value) ??
      filteredContacts.value.find((c) => c.id === activeContactId.value) ??
      null
    )
  })

  function handleSelectItem(itemId: string) {
    const isGroup = groupsStore.getGroupById(itemId)
    conversationsStore.setActiveConversationType(isGroup ? 'group' : 'contact')
    contactsStore.setActiveContact(itemId)
    if (isGroup) {
      groupsStore.clearUnreadCount(itemId)
    }
    conversationsStore.fetchMessages(itemId)
  }

  async function initContact() {
    const contactId = route.params.contactId as string | undefined
    if (!contactId) return

    contactsStore.setDefaultContact(contactId)
    await checkApiAvailability()
    await Promise.all([
      contactsStore.fetchContacts(),
      groupsStore.fetchGroups(),
    ])

    connect(contactId)
  }

  onMounted(initContact)

  watch(() => route.params.contactId, (newId) => {
    if (newId && typeof newId === 'string') {
      contactsStore.setDefaultContact(newId)
      contactsStore.fetchContacts()
      groupsStore.fetchGroups()
      connect(newId)
    }
  })

  watch(activeContactId, (newId) => {
    if (newId) {
      conversationsStore.fetchMessages(newId)
    }
  })
</script>

<template>
  <div :class="styles.layout">
    <LeftSidebar
      :contacts="sidebarItems"
      :search-query="searchQuery"
      :active-contact-id="activeContactId"
      :has-more="contactsStore.pagination.hasNextPage"
      :loading-more="contactsStore.pagination.loadingMore"
      :is-connected="isConnected"
      :is-reconnecting="isReconnecting"
      @update:search-query="searchQuery = $event"
      @select="handleSelectItem($event)"
      @contacts="contactsModalStore.openModal()"
      @new-group="groupModalStore.openModal()"
      @load-more="contactsStore.loadMoreContacts()"
    />

    <MessagePanel
      v-if="activeContact"
      :contact="activeContact"
      :messages="activeMessages"
      :input-message="inputMessage"
      :message-search-open="messageSearchOpen"
      :message-search-query="messageSearchQuery"
      :match-counter="matchCounter"
      :total-matches="totalMatches"
      :active-match-message-id="activeMatch?.messageId ?? null"
      :loading="messagesLoading"
      :sending="false"
      :has-more="conversationsStore.pagination.hasNextPage"
      :loading-more="conversationsStore.pagination.loadingMore"
      @update:input-message="inputMessage = $event"
      @send="conversationsStore.sendMessage()"
      @open-search="messageSearchStore.openMessageSearch()"
      @close-search="messageSearchStore.closeMessageSearch()"
      @update:search-query="messageSearchStore.messageSearchQuery = $event"
      @next-match="messageSearchStore.nextMatch()"
      @prev-match="messageSearchStore.prevMatch()"
      @load-older="conversationsStore.loadOlderMessages()"
    />

    <div v-else-if="!hasContacts && !groupsStore.hasGroups" :class="styles.placeholder">
      <p>{{ EMPTY_STATES.NO_CONTACTS }}</p>
    </div>

    <div v-else :class="styles.placeholder">
      <p>{{ EMPTY_STATES.SELECT_CONVERSATION }}</p>
    </div>

    <ContactsModal
      :is-open="isContactsModalOpen"
      :grouped-contacts="groupedContacts"
      :search-query="modalSearchQuery"
      :loading="contactsModalLoading"
      @close="contactsModalStore.closeModal()"
      @update:search-query="contactsModalStore.searchQuery = $event"
      @delete-contact="contactsModalStore.deleteContact($event)"
      @add-contact="newContactPopupStore.openModal()"
    />

    <GroupModal
      :is-open="isGroupModalOpen"
      :group-name="groupName"
      :selection-label="selectionLabel"
      :selected-contacts="selectedContacts"
      :filtered-contacts="groupFilteredContacts"
      :search-query="groupSearchQuery"
      :can-create="canCreate"
      :is-contact-selected="groupModalStore.isSelected"
      :is-contact-disabled="false"
      :loading="groupLoading"
      @close="groupModalStore.closeModal()"
      @back="groupModalStore.closeModal()"
      @update:group-name="groupModalStore.groupName = $event"
      @update:search-query="groupModalStore.searchQuery = $event"
      @toggle-contact="groupModalStore.toggleContact($event)"
      @remove-contact="groupModalStore.removeSelectedContact($event)"
      @create-group="groupModalStore.createGroup()"
    />

    <NewContactPopup
      :is-open="isNewContactPopupOpen"
      :nick-name="nickName"
      :feedback-message="feedbackMessage"
      :loading="newContactLoading"
      @close="newContactPopupStore.closeModal()"
      @update:nick-name="newContactPopupStore.nickName = $event"
      @add-contact="newContactPopupStore.searchAndAddContact()"
    />
  </div>
</template>
