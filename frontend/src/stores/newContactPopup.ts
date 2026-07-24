import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import type { Contact } from '@/types'
import { useContactsStore } from './contacts'
import { useLoading } from '@/composables/useLoading'
import { NEW_CONTACT_POPUP } from '@/constants/strings'

type FeedbackState = 'idle' | 'success' | 'error'

export const useNewContactPopupStore = defineStore('newContactPopup', () => {
  const isOpen = ref(false)
  const nickName = ref('')
  const feedbackState = ref<FeedbackState>('idle')
  const searchedContact = ref<Contact | null>(null)
  const searchedNickName = ref('')

  const contactsStore = useContactsStore()
  const { loading, error, withError } = useLoading()

  const normalizedNickName = computed(() => {
    if (!nickName.value.trim()) return ''
    const trimmed = nickName.value.trim()
    return trimmed.startsWith('@') ? trimmed : `@${trimmed}`
  })

  const feedbackMessage = computed(() => {
    if (feedbackState.value === 'success' && searchedContact.value) {
      return {
        type: 'success' as const,
        title: NEW_CONTACT_POPUP.SUCCESS_TITLE,
        subtitle: NEW_CONTACT_POPUP.SUCCESS_SUBTITLE(
          searchedContact.value.name,
          searchedContact.value.nickName,
        ),
      }
    }
    if (feedbackState.value === 'error') {
      return {
        type: 'error' as const,
        title: NEW_CONTACT_POPUP.ERROR_TITLE,
        subtitle: NEW_CONTACT_POPUP.ERROR_SUBTITLE(searchedNickName.value),
      }
    }
    return null
  })

  async function searchAndAddContact() {
    const query = normalizedNickName.value
    if (!query) return

    searchedNickName.value = query

    await withError(async () => {
      try {
        const newContact = await contactsStore.linkContact(query)
        if (newContact) {
          searchedContact.value = newContact
          feedbackState.value = 'success'
        }
      } catch {
        searchedContact.value = null
        feedbackState.value = 'error'
      }
    })

    nickName.value = ''
  }

  function resetState() {
    nickName.value = ''
    feedbackState.value = 'idle'
    searchedContact.value = null
    searchedNickName.value = ''
  }

  function openModal() {
    isOpen.value = true
    resetState()
  }

  function closeModal() {
    isOpen.value = false
    resetState()
  }

  return {
    isOpen,
    nickName,
    loading,
    error,
    feedbackState,
    searchedContact,
    searchedNickName,
    normalizedNickName,
    feedbackMessage,
    searchAndAddContact,
    openModal,
    closeModal,
  }
})
