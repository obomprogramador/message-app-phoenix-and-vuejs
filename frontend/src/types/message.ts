export type MessageDirection = 'received' | 'sent'

export interface Message {
  id: string
  contactId: string
  content: string
  direction: MessageDirection
  timestamp: Date
  isRead: boolean
  senderId?: string
  senderName?: string
  senderAvatarUrl?: string
}

export interface GroupMessage {
  id: string
  groupId: string
  content: string
  senderId: string
  senderName: string
  senderAvatarUrl?: string
  timestamp: Date
  isRead: boolean
}

export interface MessageMatch {
  messageId: string
  content: string
}
