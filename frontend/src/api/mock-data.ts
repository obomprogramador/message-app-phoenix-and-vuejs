// O objetivo é fazer o app front funcionar com dados mocados, mesmo que o back não esteja ativo.

import type {
  ContactResponse,
  MessageResponse,
  HealthResponse,
  PaginationMeta,
  ApiResponse,
} from './types'

function delay(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms))
}

export const mockContacts: ContactResponse[] = [
  {
    id: '1',
    name: 'Pedro Santos',
    nickname: '@pedro.santos',
    avatar_url: null,
    is_online: false,
    last_message: { content: 'Ola, tudo bem?', timestamp: '2026-07-21T10:30:00Z', direction: 'received' },
    linked_at: '2026-07-20T08:00:00Z',
  },
  {
    id: '2',
    name: 'Pedro Souza',
    nickname: '@pedro.souza',
    avatar_url: null,
    is_online: true,
    last_message: { content: 'Amanha nos encontramos', timestamp: '2026-07-21T09:15:00Z', direction: 'received' },
    linked_at: '2026-07-20T08:00:00Z',
  },
  {
    id: '3',
    name: 'Pedro Oliveira',
    nickname: '@pedro.oliveira',
    avatar_url: null,
    is_online: false,
    last_message: { content: 'Enviado o arquivo', timestamp: '2026-07-20T18:45:00Z', direction: 'received' },
    linked_at: '2026-07-20T08:00:00Z',
  },
  {
    id: '4',
    name: 'Pedro Costa',
    nickname: '@pedro.costa',
    avatar_url: null,
    is_online: true,
    linked_at: '2026-07-20T08:00:00Z',
  },
  {
    id: '5',
    name: 'Pedro Pereira',
    nickname: '@pedro.pereira',
    avatar_url: null,
    is_online: false,
    linked_at: '2026-07-20T08:00:00Z',
  },
]

const mockMessages: Record<string, MessageResponse[]> = {
  '1': [
    { id: 'm1', contact_id: '1', content: 'Ola!', direction: 'received', is_read: true, inserted_at: '2026-07-21T10:28:00Z' },
    { id: 'm2', contact_id: '1', content: 'Oi Maria, tudo bem!', direction: 'sent', is_read: true, inserted_at: '2026-07-21T10:29:00Z' },
    { id: 'm3', contact_id: '1', content: 'Ola, tudo bem?', direction: 'received', is_read: false, inserted_at: '2026-07-21T10:30:00Z' },
  ],
  '2': [
    { id: 'm4', contact_id: '2', content: 'Amanha nos encontramos', direction: 'received', is_read: true, inserted_at: '2026-07-21T09:15:00Z' },
  ],
  '3': [
    { id: 'm5', contact_id: '3', content: 'Ola, preciso do arquivo', direction: 'sent', is_read: true, inserted_at: '2026-07-20T18:40:00Z' },
    { id: 'm6', contact_id: '3', content: 'Enviado o arquivo', direction: 'received', is_read: true, inserted_at: '2026-07-20T18:45:00Z' },
  ],
}

const defaultMeta: PaginationMeta = {
  page: 1,
  per_page: 20,
  total: 5,
  total_pages: 1,
  has_more: false,
}

export const mockHealth: HealthResponse = {
  status: 'ok',
  timestamp: new Date().toISOString(),
  version: '1.0.0-mock',
}

// === Mock API Functions ===

export async function mockListContacts(): Promise<ApiResponse<ContactResponse[]>> {
  await delay(300)

  return { data: mockContacts, meta: defaultMeta }
}

export async function mockGetContact(id: string): Promise<ApiResponse<ContactResponse>> {
  await delay(200)

  const contact = mockContacts.find((c) => c.id === id)

  if (!contact) throw new Error('Contato nao encontrado')
  return { data: contact }
}

export async function mockLinkContact(nickname: string): Promise<ApiResponse<ContactResponse>> {
  await delay(500)

  const newContact: ContactResponse = {
    id: `mock-${Date.now()}`,
    name: nickname.replace('@', '').replace('.', ' ').replace(/\b\w/g, (c) => c.toUpperCase()),
    nickname,
    avatar_url: null,
    is_online: false,
    linked_at: new Date().toISOString(),
  }

  mockContacts.push(newContact)

  return { data: newContact }
}

export async function mockUnlinkContact(_id: string): Promise<ApiResponse<{ message: string }>> {
  await delay(300)

  return { data: { message: 'Contato desvinculado' } }
}

export async function mockListMessages(contactId: string): Promise<ApiResponse<MessageResponse[]>> {
  await delay(300)

  return { data: mockMessages[contactId] ?? [], meta: defaultMeta }
}

export async function mockSendMessage(
  contactId: string,
  content: string,
): Promise<ApiResponse<MessageResponse>> {
  await delay(400)

  const newMessage: MessageResponse = {
    id: `mock-m-${Date.now()}`,
    contact_id: contactId,
    content,
    direction: 'sent',
    is_read: false,
    inserted_at: new Date().toISOString(),
  }

  if (!mockMessages[contactId]) mockMessages[contactId] = []

  mockMessages[contactId].push(newMessage)

  return { data: newMessage }
}

export async function mockSearchMessages(
  _contactId: string,
  query: string,
): Promise<ApiResponse<MessageResponse[]>> {
  await delay(300)

  const allMessages = Object.values(mockMessages).flat()

  const results = allMessages.filter((m) =>
    m.content.toLowerCase().includes(query.toLowerCase()),
  )

  return { data: results, meta: defaultMeta }
}

export async function mockMarkAsRead(
  id: string,
): Promise<ApiResponse<{ id: string; is_read: boolean }>> {
  await delay(200)

  return { data: { id, is_read: true } }
}

export async function mockCheckHealth(): Promise<ApiResponse<HealthResponse>> {
  await delay(100)
  
  return { data: mockHealth }
}
