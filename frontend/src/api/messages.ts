import { apiClient, isApiAvailable, mockClient } from './client'
import type {
  MessageResponse,
  MessageSendRequest,
  MessageQueryParams,
  SearchQueryParams,
  ApiResponse,
} from './types'

export const messagesApi = {
  async list(
    contactId: string,
    currentUserId?: string,
    params?: MessageQueryParams,
  ): Promise<ApiResponse<MessageResponse[]>> {
    if (!isApiAvailable()) return mockClient.listMessages(contactId)

    return apiClient.get<MessageResponse[]>(
      `/contacts/${contactId}/messages`,
      {
        current_user_id: currentUserId,
        ...params,
      } as Record<string, string | number | boolean>,
    )
  },

  async send(
    contactId: string,
    content: string,
    fromContactId?: string,
    direction: 'sent' | 'received' = 'sent',
  ): Promise<ApiResponse<MessageResponse>> {
    if (!isApiAvailable()) return mockClient.sendMessage(contactId, content)

    const body: MessageSendRequest & { from_contact_id?: string } = {
      message: { content, direction },
      from_contact_id: fromContactId,
    }
    return apiClient.post<MessageResponse>(
      `/contacts/${contactId}/messages`,
      body,
    )
  },

  async search(
    contactId: string,
    query: string,
    params?: Omit<SearchQueryParams, 'q'>,
  ): Promise<ApiResponse<MessageResponse[]>> {
    if (!isApiAvailable()) return mockClient.searchMessages(contactId, query)

    return apiClient.get<MessageResponse[]>(
      `/contacts/${contactId}/messages/search`,
      { q: query, ...params },
    )
  },

  async markAsRead(id: string): Promise<ApiResponse<{ id: string; is_read: boolean }>> {
    if (!isApiAvailable()) return mockClient.markAsRead(id)
      
    return apiClient.patch<{ id: string; is_read: boolean }>(
      `/messages/${id}/read`,
    )
  },
}
