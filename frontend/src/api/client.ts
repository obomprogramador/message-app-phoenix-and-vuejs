import type { ApiResponse } from './types'
import { ApiError, NetworkError } from './errors'
import {
  mockCheckHealth,
  mockListContacts,
  mockGetContact,
  mockLinkContact,
  mockUnlinkContact,
  mockListMessages,
  mockSendMessage,
  mockSearchMessages,
  mockMarkAsRead,
} from './mock-data'

const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || 'http://localhost:4000/api'

let apiAvailable: boolean | null = null

interface RequestOptions {
  method: 'GET' | 'POST' | 'PUT' | 'PATCH' | 'DELETE'
  path: string
  body?: unknown
  params?: Record<string, string | number | boolean>
  headers?: Record<string, string>
  signal?: AbortSignal
}

async function request<T>(options: RequestOptions): Promise<ApiResponse<T>> {
  const { method, path, body, params, headers = {}, signal } = options
  const url = new URL(`${API_BASE_URL}${path}`)

  if (params) {
    Object.entries(params).forEach(([key, value]) => {
      url.searchParams.append(key, String(value))
    })
  }

  const config: RequestInit = {
    method,
    headers: {
      'Content-Type': 'application/json',
      Accept: 'application/json',
      ...headers,
    },
    signal,
  }

  if (body) {
    config.body = JSON.stringify(body)
  }

  const response = await fetch(url.toString(), config)

  if (!response.ok) {
    const error = await response.json().catch(() => ({}))
    const message =
      error.error?.message || error.errors?.detail || 'Erro desconhecido'
    throw new ApiError(response.status, message, error)
  }

  if (response.status === 204) {
    return { data: null as T }
  }

  return response.json()
}

// === Health Check ===

export async function checkApiAvailability(): Promise<boolean> {
  try {
    await request({ method: 'GET', path: '/health' })
    apiAvailable = true
    return true
  } catch {
    apiAvailable = false
    return false
  }
}

export function isApiAvailable(): boolean {
  return apiAvailable === true
}

// === Mock Route Helpers ===

function mockRoute<T>(mockFn: () => Promise<ApiResponse<T>>): () => Promise<ApiResponse<T>> {
  return async () => {
    if (apiAvailable === false) {
      return mockFn()
    }
    throw new NetworkError()
  }
}

// === API Client ===

export const apiClient = {
  get: <T>(path: string, params?: Record<string, string | number | boolean>, signal?: AbortSignal) =>
    request<T>({ method: 'GET', path, params, signal }),

  post: <T>(path: string, body?: unknown, signal?: AbortSignal) =>
    request<T>({ method: 'POST', path, body, signal }),

  put: <T>(path: string, body?: unknown, signal?: AbortSignal) =>
    request<T>({ method: 'PUT', path, body, signal }),

  patch: <T>(path: string, body?: unknown, signal?: AbortSignal) =>
    request<T>({ method: 'PATCH', path, body, signal }),

  delete: <T>(path: string, signal?: AbortSignal) =>
    request<T>({ method: 'DELETE', path, signal }),
}

// === Mock API Client (fallback) ===

export const mockClient = {
  checkHealth: mockRoute(mockCheckHealth),
  listContacts: mockRoute(mockListContacts),
  getContact: (id: string) => mockRoute(() => mockGetContact(id))(),
  linkContact: (nickname: string) => mockRoute(() => mockLinkContact(nickname))(),
  unlinkContact: (id: string) => mockRoute(() => mockUnlinkContact(id))(),
  listMessages: (contactId: string) => mockRoute(() => mockListMessages(contactId))(),
  sendMessage: (contactId: string, content: string) =>
    mockRoute(() => mockSendMessage(contactId, content))(),
  searchMessages: (contactId: string, query: string) =>
    mockRoute(() => mockSearchMessages(contactId, query))(),
  markAsRead: (id: string) => mockRoute(() => mockMarkAsRead(id))(),
}

export type { ApiResponse }
