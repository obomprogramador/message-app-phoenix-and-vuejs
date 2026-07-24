import { apiClient, isApiAvailable, mockClient } from './client'
import type {
  ContactResponse,
  ContactLinkRequest,
  ContactQueryParams,
  ApiResponse,
} from './types'

export const contactsApi = {
  async list(
    defaultContactId: string,
    params?: ContactQueryParams,
  ): Promise<ApiResponse<ContactResponse[]>> {
    if (!isApiAvailable()) return mockClient.listContacts()

    return apiClient.get<ContactResponse[]>(
      '/contacts',
      {
        default_contact_id: defaultContactId,
        ...params,
      }  as Record<string, string | number | boolean>
    )

  },

  async listAll(
    params?: ContactQueryParams,
  ): Promise<ApiResponse<ContactResponse[]>> {
    if (!isApiAvailable()) return mockClient.listContacts()
    
      return apiClient.get<ContactResponse[]>(
      '/contacts',
      {
        ...params,
      } as Record<string, string | number | boolean>
    )

  },

  async get(id: string): Promise<ApiResponse<ContactResponse>> {
    if (!isApiAvailable()) return mockClient.getContact(id)
    return apiClient.get<ContactResponse>(`/contacts/${id}`)
  },

  async link(
    defaultContactId: string,
    nickname: string,
  ): Promise<ApiResponse<ContactResponse>> {
    if (!isApiAvailable()) return mockClient.linkContact(nickname)
    
    const body: ContactLinkRequest & { default_contact_id?: string } = {
      contact: { nickname },
      default_contact_id: defaultContactId,
    }
    
    return apiClient.post<ContactResponse>('/contacts', body)
  },

  async unlink(
    defaultContactId: string,
    id: string,
  ): Promise<ApiResponse<{ message: string }>> {
    if (!isApiAvailable()) return mockClient.unlinkContact(id)
    
    return apiClient.delete<{ message: string }>(
      `/contacts/${id}?default_contact_id=${defaultContactId}`,
    )
  },
}
