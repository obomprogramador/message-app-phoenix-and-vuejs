import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import type { Contact } from '@/types'
import { useContactsStore } from './contacts'
import { useGroupsStore } from './groups'
import { useLoading } from '@/composables/useLoading'

export const useGroupModalStore = defineStore('groupModal', () => {
  const isOpen = ref(false)
  const groupName = ref('')
  const selectedContacts = ref<Contact[]>([])
  const searchQuery = ref('')

  const contactsStore = useContactsStore()
  const groupsStore = useGroupsStore()
  const { loading, error, withError } = useLoading()

  const selectionLabel = computed(() => {
    return `${selectedContacts.value.length} de ${contactsStore.contacts.length} contatos selecionados`
  })

  const canCreate = computed(() => {
    return groupName.value.trim().length > 0 && selectedContacts.value.length > 0
  })

  const filteredContacts = computed<Contact[]>(() => {
    if (!searchQuery.value) return contactsStore.contacts
    const query = searchQuery.value.toLowerCase()
    return contactsStore.contacts.filter(
      (c) =>
        c.name.toLowerCase().includes(query) ||
        c.nickName.toLowerCase().includes(query),
    )
  })

  function isSelected(contactId: string): boolean {
    return selectedContacts.value.some((c) => c.id === contactId)
  }

  function toggleContact(contact: Contact): void {
    const index = selectedContacts.value.findIndex((c) => c.id === contact.id)
    if (index !== -1) {
      selectedContacts.value.splice(index, 1)
    } else {
      selectedContacts.value.push(contact)
    }
  }

  function removeSelectedContact(contactId: string): void {
    const index = selectedContacts.value.findIndex((c) => c.id === contactId)
    if (index !== -1) {
      selectedContacts.value.splice(index, 1)
    }
  }

  function openModal() {
    isOpen.value = true
    groupName.value = ''
    selectedContacts.value = []
    searchQuery.value = ''
  }

  function closeModal() {
    isOpen.value = false
    groupName.value = ''
    selectedContacts.value = []
    searchQuery.value = ''
  }

  async function createGroup() {
    if (!groupName.value.trim() || selectedContacts.value.length === 0) return

    await withError(async () => {
      const newGroup = await groupsStore.createGroup({
        name: groupName.value.trim(),
        member_ids: selectedContacts.value.map((c) => c.id),
      })

      if (newGroup) {
        groupsStore.fetchGroups()
      }

      closeModal()
    })
  }

  return {
    isOpen,
    groupName,
    selectedContacts,
    searchQuery,
    loading,
    error,
    selectionLabel,
    canCreate,
    filteredContacts,
    isSelected,
    toggleContact,
    removeSelectedContact,
    openModal,
    closeModal,
    createGroup,
  }
})
