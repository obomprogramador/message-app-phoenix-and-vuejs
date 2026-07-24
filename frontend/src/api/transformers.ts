import type { ContactResponse, MessageResponse, MessageMatchResponse } from './types'
import type { Contact, Message, MessageMatch } from '@/types'

export function toContactViewModel(api: ContactResponse): Contact {
  return {
    id: api.id,
    name: api.name,
    nickName: api.nickname,
    avatarUrl: api.avatar_url ?? undefined,
    isOnline: api.is_online,
    isLinked: true,
    lastMessage: api.last_message?.content ?? '',
    lastMessageTime: api.last_message?.timestamp
      ? new Date(api.last_message.timestamp) : new Date(),
  }
}

export function toMessageViewModel(api: MessageResponse): Message {
  return {
    id: api.id,
    contactId: api.contact_id ?? '',
    content: api.content,
    direction: api.direction,
    timestamp: new Date(api.inserted_at),
    isRead: api.is_read,
  }
}

export function toMessageMatchViewModel(api: MessageMatchResponse): MessageMatch {
  return {
    messageId: api.id,
    content: api.content,
  }
}

export function toContactViewModelArray(apis: ContactResponse[]): Contact[] {
  return apis.map(toContactViewModel)
}

export function toMessageViewModelArray(apis: MessageResponse[]): Message[] {
  return apis.map(toMessageViewModel)
}

export function toMessageMatchViewModelArray(apis: MessageMatchResponse[]): MessageMatch[] {
  return apis.map(toMessageMatchViewModel)
}
