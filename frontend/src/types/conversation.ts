import type { Contact } from './contact'
import type { Message } from './message'

export type ConversationType = 'contact' | 'group'

export interface Conversation {
  contact: Contact
  messages: Message[]
}
