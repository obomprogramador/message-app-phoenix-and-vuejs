import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import type { Contact } from '@/types'
import type { GroupResponse } from '@/api/types'
import { groupsApi } from '@/api/groups'
import { useLoading } from '@/composables/useLoading'
import { usePagination } from '@/composables/usePagination'
import { useContactsStore } from './contacts'

function groupToContact(group: GroupResponse): Contact {
  return {
    id: group.id,
    name: group.name,
    nickName: `@group.${group.id}`,
    avatarUrl: group.avatar_url ?? undefined,
    lastMessage: '',
    lastMessageTime: new Date(group.inserted_at),
    isOnline: false,
    isLinked: true,
    type: 'group',
  }
}

export const useGroupsStore = defineStore('groups', () => {
  const groups = ref<Contact[]>([])
  const { loading, error, withError } = useLoading()
  const pagination = usePagination({ initialPerPage: 20 })

  async function fetchGroups() {
    return withError(async () => {
      const contactsStore = useContactsStore()
      const response = await groupsApi.list({
        page: pagination.page.value,
        per_page: pagination.perPage.value,
        contact_id: contactsStore.defaultContactId ?? undefined,
      })
      groups.value = response.data.map(groupToContact)
      if (response.meta) pagination.updateMeta(response.meta)
    })
  }

  async function loadMoreGroups() {
    if (!pagination.hasNextPage.value || pagination.loadingMore.value) return
    pagination.loadingMore.value = true
    try {
      const contactsStore = useContactsStore()
      const params = pagination.nextPageParams.value
      if (!params) return
      const response = await groupsApi.list({
        ...params as Record<string, string | number>,
        contact_id: contactsStore.defaultContactId ?? undefined,
      })
      const newGroups = response.data.map(groupToContact)
      groups.value.push(...newGroups)
      pagination.nextPage()
      if (response.meta) pagination.updateMeta(response.meta)
    } finally {
      pagination.loadingMore.value = false
    }
  }

  async function createGroup(data: {
    name: string
    description?: string
    member_ids: string[]
  }) {
    const contactsStore = useContactsStore()
    return withError(async () => {
      const response = await groupsApi.create({
        ...data,
        created_by_id: contactsStore.defaultContactId,
      })
      const newGroup = groupToContact(response.data)
      groups.value.push(newGroup)
      return newGroup
    })
  }

  function getGroupById(id: string): Contact | undefined {
    return groups.value.find((g) => g.id === id)
  }

  function updateLastMessage(groupId: string, content: string, timestamp: Date) {
    const group = groups.value.find((g) => g.id === groupId)
    if (group) {
      group.lastMessage = content
      group.lastMessageTime = timestamp
    }
  }

  function incrementUnreadCount(groupId: string) {
    const group = groups.value.find((g) => g.id === groupId)
    if (group) {
      group.unreadCount = (group.unreadCount ?? 0) + 1
    }
  }

  function clearUnreadCount(groupId: string) {
    const group = groups.value.find((g) => g.id === groupId)
    if (group) {
      group.unreadCount = 0
    }
  }

  const hasGroups = computed(() => groups.value.length > 0)

  return {
    groups,
    loading,
    error,
    hasGroups,
    pagination,
    fetchGroups,
    loadMoreGroups,
    createGroup,
    getGroupById,
    updateLastMessage,
    incrementUnreadCount,
    clearUnreadCount,
  }
})
