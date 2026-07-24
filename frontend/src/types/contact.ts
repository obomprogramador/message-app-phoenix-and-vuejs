export interface Contact {
  id: string
  name: string
  nickName: string
  avatarUrl?: string
  lastMessage: string
  lastMessageTime: Date
  isOnline: boolean
  isLinked?: boolean
  type?: 'contact' | 'group'
  unreadCount?: number
}
