import { createRouter, createWebHistory } from 'vue-router'
import ChatPage from '@/pages/ChatPage.vue'
import { useContactsStore } from '@/stores/contacts'
import { checkApiAvailability } from '@/api/client'

const router = createRouter({
  history: createWebHistory(),
  routes: [
    {
      path: '/:contactId',
      name: 'chat',
      component: ChatPage,
    },
    {
      path: '/',
      name: 'home',
      component: ChatPage,
    },
  ],
})

router.beforeEach(async (to) => {
  if (to.params.contactId) return true

  await checkApiAvailability()
  const contactsStore = useContactsStore()
  const contactId = await contactsStore.fetchDefaultContact()
  if (contactId) {
    return { name: 'chat', params: { contactId } }
  }
  return true
})

export default router
