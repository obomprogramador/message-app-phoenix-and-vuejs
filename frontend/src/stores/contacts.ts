import { defineStore } from 'pinia'
import { ref, computed, watch } from 'vue'
import type { Contact } from '@/types'
import type { ContactQueryParams } from '@/api/types'
import { contactsApi } from '@/api/contacts'
import { toContactViewModel, toContactViewModelArray } from '@/api/transformers'
import { useLoading } from '@/composables/useLoading'
import { usePagination } from '@/composables/usePagination'

export const useContactsStore = defineStore('contacts', () => {
  const contacts = ref<Contact[]>([])
  const activeContactId = ref<string | undefined>(undefined)
  const searchQuery = ref('')
  const defaultContactId = ref<string>('')

  const { loading, error, withError } = useLoading()
  const pagination = usePagination({ initialPerPage: 20 })

  function setDefaultContact(id: string) {
    defaultContactId.value = id
  }

  async function fetchDefaultContact(): Promise<string | null> {
    if (defaultContactId.value) return defaultContactId.value
    try {
      const response = await contactsApi.listAll({ search: '@usuario' })
      if (response.data.length === 0) return null
      const firstId = response.data[0]!.id
      defaultContactId.value = firstId
      return firstId
    } catch {
      return null
    }
  }

  async function fetchContacts(params?: ContactQueryParams) {
    if (!defaultContactId.value) return
    return withError(async () => {
      const response = await contactsApi.list(defaultContactId.value, {
        page: pagination.page.value,
        per_page: pagination.perPage.value,
        ...params,
      })
      contacts.value = toContactViewModelArray(response.data)
      if (response.meta) pagination.updateMeta(response.meta)
    })
  }

  async function loadMoreContacts() {
    if (!defaultContactId.value || !pagination.hasNextPage.value || pagination.loadingMore.value) return
    pagination.loadingMore.value = true
    try {
      const params = pagination.nextPageParams.value
      if (!params) return
      const response = await contactsApi.list(defaultContactId.value, params as ContactQueryParams)
      const newContacts = toContactViewModelArray(response.data)
      contacts.value.push(...newContacts)
      pagination.nextPage()
      if (response.meta) pagination.updateMeta(response.meta)
    } finally {
      pagination.loadingMore.value = false
    }
  }

  async function linkContact(nickname: string) {
    if (!defaultContactId.value) return
    return withError(async () => {
      const response = await contactsApi.link(defaultContactId.value, nickname)
      const newContact = toContactViewModel(response.data)
      contacts.value.push(newContact)
      return newContact
    })
  }

  async function unlinkContact(contactId: string) {
    if (!defaultContactId.value) return
    return withError(async () => {
      await contactsApi.unlink(defaultContactId.value, contactId)
      const index = contacts.value.findIndex((c) => c.id === contactId)
      if (index !== -1) contacts.value.splice(index, 1)
    })
  }

  function setActiveContact(contactId: string) {
    activeContactId.value = contactId
    clearUnreadCount(contactId)
  }

  function clearUnreadCount(contactId: string) {
    const contact = contacts.value.find((c) => c.id === contactId)
    if (contact) {
      contact.unreadCount = 0
    }
  }

  function updateLastMessage(contactId: string, content: string, timestamp: Date) {
    const contact = contacts.value.find((c) => c.id === contactId)
    if (contact) {
      contact.lastMessage = content
      contact.lastMessageTime = timestamp
    }
  }

  function incrementUnreadCount(contactId: string) {
    const contact = contacts.value.find((c) => c.id === contactId)
    if (contact) {
      contact.unreadCount = (contact.unreadCount ?? 0) + 1
    }
  }

  const activeContact = computed<Contact | null>(() => {
    return contacts.value.find((c) => c.id === activeContactId.value) ?? null
  })

  const filteredContacts = computed<Contact[]>(() => {
    if (!searchQuery.value) return contacts.value
    const query = searchQuery.value.toLowerCase()
    return contacts.value.filter(
      (c) =>
        c.name.toLowerCase().includes(query) ||
        c.nickName.toLowerCase().includes(query),
    )
  })

  const hasContacts = computed(() => contacts.value.length > 0)

  watch(contacts, (value: Contact[]) => {
    if (value.length === 0) {
      activeContactId.value = undefined
    } else if (!value.some((c: Contact) => c.id === activeContactId.value)) {
      activeContactId.value = value[0]!.id
    }
  })

  return {
    contacts,
    activeContactId,
    searchQuery,
    defaultContactId,
    loading,
    error,
    activeContact,
    filteredContacts,
    hasContacts,
    pagination,
    setDefaultContact,
    fetchDefaultContact,
    fetchContacts,
    loadMoreContacts,
    linkContact,
    unlinkContact,
    setActiveContact,
    updateLastMessage,
    incrementUnreadCount,
    clearUnreadCount,
  }
})
