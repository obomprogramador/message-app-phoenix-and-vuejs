<script setup lang="ts">
import { useKeydown } from '@/composables/useKeydown'
import Button from '@/components/atoms/Button/Button.vue'
import Icon from '@/components/atoms/Icon/Icon.vue'
import { NEW_CONTACT_POPUP } from '@/constants/strings'
import styles from './css/NewContactPopup.module.css'

interface Props {
  isOpen: boolean
  nickName: string
  feedbackMessage: {
    type: 'success' | 'error'
    title: string
    subtitle: string
  } | null
  loading?: boolean
}

withDefaults(defineProps<Props>(), {
  loading: false,
})

const emit = defineEmits<{
  close: []
  'update:nick-name': [value: string]
  'add-contact': []
}>()

function onKeyDown(e: KeyboardEvent): void {
  if (e.key === 'Escape') {
    emit('close')
  }
}

useKeydown(onKeyDown)
</script>

<template>
  <Teleport to="body">
    <div v-if="isOpen" :class="styles.overlay" @click.self="emit('close')">
      <div :class="styles.modal">
        <div :class="styles.header">
          <div :class="styles.headerLeft">
            <button :class="styles.backBtn" :aria-label="NEW_CONTACT_POPUP.TITLE" @click="emit('close')">
              <Icon name="arrow-left" :size="20" />
            </button>
            <div :class="styles.headerText">
              <h2 :class="styles.title">{{ NEW_CONTACT_POPUP.TITLE }}</h2>
              <span :class="styles.description">{{ NEW_CONTACT_POPUP.DESCRIPTION }}</span>
            </div>
          </div>
        </div>

        <div :class="styles.inputSection">
          <label :class="styles.inputLabel">{{ NEW_CONTACT_POPUP.USER_LABEL }}</label>
          <div :class="styles.inputRow">
            <div :class="styles.inputWrapper">
              <span :class="styles.inputPrefix">{{ NEW_CONTACT_POPUP.INPUT_PREFIX }}</span>
              <input
                type="text"
                :value="nickName"
                :placeholder="NEW_CONTACT_POPUP.INPUT_PLACEHOLDER"
                :class="styles.input"
                @input="emit('update:nick-name', ($event.target as HTMLInputElement).value)"
                @keydown.enter="emit('add-contact')"
              />
            </div>
            <Button variant="primary" size="md" :disabled="loading" @click="emit('add-contact')">
              {{ loading ? 'Buscando...' : NEW_CONTACT_POPUP.ADD_BUTTON }}
            </Button>
          </div>
        </div>

        <div v-if="feedbackMessage" :class="[styles.feedback, styles[feedbackMessage.type]]">
          <h3 :class="styles.feedbackTitle">{{ feedbackMessage.title }}</h3>
          <p :class="styles.feedbackSubtitle">{{ feedbackMessage.subtitle }}</p>
        </div>
      </div>
    </div>
  </Teleport>
</template>
