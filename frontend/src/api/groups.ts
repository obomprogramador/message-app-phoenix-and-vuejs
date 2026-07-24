import { apiClient, isApiAvailable } from './client'
import type {
  GroupResponse,
  GroupCreateRequest,
  GroupUpdateRequest,
  GroupMemberResponse,
  GroupMemberAddRequest,
  GroupMemberUpdateRequest,
  GroupMessageResponse,
  PaginationParams,
  ApiResponse,
} from './types'

async function mockNotAvailable(): Promise<never> {
  throw new Error('API nao disponivel - funcionalidade de grupos ainda nao implementada em mock')
}

export const groupsApi = {
  async list(params?: PaginationParams & { contact_id?: string }): Promise<ApiResponse<GroupResponse[]>> {
    if (!isApiAvailable()) return mockNotAvailable()

    return apiClient.get<GroupResponse[]>(
      '/groups',
      params as Record<string, string | number | boolean>
    )
  },

  async get(id: string): Promise<ApiResponse<GroupResponse>> {
    if (!isApiAvailable()) return mockNotAvailable()
    return apiClient.get<GroupResponse>(`/groups/${id}`)
  },

  async create(data: {
    name: string
    description?: string
    member_ids: string[]
    created_by_id?: string
  }): Promise<ApiResponse<GroupResponse>> {
    if (!isApiAvailable()) return mockNotAvailable()
    
    const body = { group: data }
    
    return apiClient.post<GroupResponse>('/groups', body)
  },

  async update(
    id: string,
    data: { name?: string; description?: string },
  ): Promise<ApiResponse<GroupResponse>> {
    if (!isApiAvailable()) return mockNotAvailable()

    const body: GroupUpdateRequest = { group: data }

    return apiClient.put<GroupResponse>(`/groups/${id}`, body)
  },

  async delete(id: string): Promise<ApiResponse<{ message: string }>> {
    if (!isApiAvailable()) return mockNotAvailable()
    return apiClient.delete<{ message: string }>(`/groups/${id}`)
  },

  async listMembers(
    groupId: string,
    params?: PaginationParams,
  ): Promise<ApiResponse<GroupMemberResponse[]>> {
    if (!isApiAvailable()) return mockNotAvailable()

    return apiClient.get<GroupMemberResponse[]>(
      `/groups/${groupId}/members`,
      params as Record<string, string | number | boolean>
    )
  },

  async addMember(
    groupId: string,
    contactId: string,
    role: 'admin' | 'member' = 'member',
  ): Promise<ApiResponse<GroupMemberResponse>> {
    if (!isApiAvailable()) return mockNotAvailable()
    
    const body: GroupMemberAddRequest = {
      member: { contact_id: contactId, role }
    }

    return apiClient.post<GroupMemberResponse>(`/groups/${groupId}/members`, body)
  },

  async updateMemberRole(
    groupId: string,
    contactId: string,
    role: 'admin' | 'member',
  ): Promise<ApiResponse<GroupMemberResponse>> {
    if (!isApiAvailable()) return mockNotAvailable()

    const body: GroupMemberUpdateRequest = { member: { role } }

    return apiClient.patch<GroupMemberResponse>(
      `/groups/${groupId}/members/${contactId}`,
      body,
    )
  },

  async removeMember(
    groupId: string,
    contactId: string,
  ): Promise<ApiResponse<{ message: string }>> {
    if (!isApiAvailable()) return mockNotAvailable()

    return apiClient.delete<{ message: string }>(
      `/groups/${groupId}/members/${contactId}`,
    )
  },

  async listMessages(
    groupId: string,
    params?: PaginationParams,
  ): Promise<ApiResponse<GroupMessageResponse[]>> {
    if (!isApiAvailable()) return mockNotAvailable()

    return apiClient.get<GroupMessageResponse[]>(
      `/groups/${groupId}/messages`,
      params as Record<string, string | number | boolean>,
    )
  },

  async sendMessage(
    groupId: string,
    content: string,
    senderId: string,
  ): Promise<ApiResponse<GroupMessageResponse>> {
    if (!isApiAvailable()) return mockNotAvailable()
      
    return apiClient.post<GroupMessageResponse>(
      `/groups/${groupId}/messages`,
      { message: { content, sender_id: senderId } },
    )
  },
}
