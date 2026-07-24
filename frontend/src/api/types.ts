// === Pagination ===

export interface PaginationMeta {
  page: number
  per_page: number
  total: number
  total_pages: number
  has_more?: boolean
  next_cursor?: string
}

export interface PaginationParams {
  page?: number
  per_page?: number
}

export interface CursorPaginationParams {
  cursor?: string
  limit?: number
}

// === Request Types ===

export interface ContactLinkRequest {
  contact: {
    nickname: string
  }
}

export interface MessageSendRequest {
  message: {
    content: string
    direction: 'sent' | 'received'
  }
}

export interface GroupCreateRequest {
  group: {
    name: string
    description?: string
    member_ids: string[]
  }
}

export interface GroupUpdateRequest {
  group: {
    name?: string
    description?: string
  }
}

export interface GroupMemberAddRequest {
  member: {
    contact_id: string
    role: 'admin' | 'member'
  }
}

export interface GroupMemberUpdateRequest {
  member: {
    role: 'admin' | 'member'
  }
}

// === Response Types ===

export interface ContactResponse {
  id: string
  name: string
  nickname: string
  avatar_url: string | null
  is_online: boolean
  last_message?: {
    content: string
    timestamp: string
    direction: 'sent' | 'received'
  }
  linked_at?: string
}

export interface MessageResponse {
  id: string
  contact_id?: string
  content: string
  direction: 'sent' | 'received'
  is_read: boolean
  inserted_at: string
  sender?: {
    id: string
    name: string
    nickname: string
  }
}

export interface GroupResponse {
  id: string
  name: string
  description: string | null
  avatar_url: string | null
  created_by: {
    id: string
    name: string
    nickname: string
  } | null
  members_count: number
  inserted_at: string
  updated_at: string
}

export interface GroupMemberResponse {
  id: string
  contact: {
    id: string
    name: string
    nickname: string
    avatar_url: string | null
    is_online: boolean
  }
  role: 'admin' | 'member'
  joined_at: string
}

export interface GroupMessageResponse {
  id: string
  content: string
  is_read: boolean
  group_id: string
  sender_id: string
  sender: {
    id: string
    name: string
    nickname: string
    avatar_url: string | null
  } | null
  inserted_at: string
  updated_at: string
}

export interface HealthResponse {
  status: string
  timestamp: string
  version: string
}

// === Search Types ===

export interface MessageMatchResponse {
  id: string
  content: string
  highlight?: string
  inserted_at: string
}

// === Query Types ===

export interface ContactQueryParams extends PaginationParams {
  search?: string
  is_online?: boolean
}

export interface MessageQueryParams extends PaginationParams {
  before?: string
  after?: string
}

export interface SearchQueryParams extends PaginationParams {
  q: string
  contact_id?: string
  group_id?: string
}

// === Error Types ===

export interface ApiErrorResponse {
  error: {
    code: string
    message: string
    details?: Record<string, unknown>
  }
}

// === API Response Wrapper ===

export interface ApiResponse<T> {
  data: T
  meta?: PaginationMeta
}
