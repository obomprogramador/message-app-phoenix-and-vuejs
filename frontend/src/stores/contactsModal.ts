import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import type { Contact } from '@/types'
import { useContactsStore } from './contacts'
import { useLoading } from '@/composables/useLoading'

interface LetterGroup {
  letter: string
  contacts: Contact[]
}

export const useContactsModalStore = defineStore('contactsModal', () => {
  const isOpen = ref(false)
  const searchQuery = ref('')

  const contactsStore = useContactsStore()
  const { loading, error, withError } = useLoading()

  const filteredContacts = computed<Contact[]>(() => {
    if (!searchQuery.value) return contactsStore.contacts
    const query = searchQuery.value.toLowerCase()
    return contactsStore.contacts.filter(
      (c) =>
        c.name.toLowerCase().includes(query) ||
        c.nickName.toLowerCase().includes(query),
    )
  })

  const groupedContacts = computed<LetterGroup[]>(() => {
    const groups: Record<string, Contact[]> = {}

    for (const contact of filteredContacts.value) {
      const letter = contact.name.charAt(0).toUpperCase()
      if (!groups[letter]) {
        groups[letter] = []
      }
      groups[letter]!.push(contact)
    }

    return Object.keys(groups)
      .sort()
      .map((letter) => ({ letter, contacts: groups[letter]! }))
  })

  function openModal() {
    isOpen.value = true
    searchQuery.value = ''
  }

  function closeModal() {
    isOpen.value = false
    searchQuery.value = ''
  }

  async function deleteContact(contactId: string) {
    await withError(async () => {
      await contactsStore.unlinkContact(contactId)
    })
  }

  return {
    isOpen,
    searchQuery,
    loading,
    error,
    filteredContacts,
    groupedContacts,
    openModal,
    closeModal,
    deleteContact,
  }
})
