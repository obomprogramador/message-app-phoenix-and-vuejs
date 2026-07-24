<script setup lang="ts">
import MessageInput from '@/components/atoms/MessageInput/MessageInput.vue'
import Button from '@/components/atoms/Button/Button.vue'
import Icon from '@/components/atoms/Icon/Icon.vue'
import { PLACEHOLDERS } from '@/constants/strings'
import styles from './css/MessageComposer.module.css'

interface Props {
  modelValue: string
  disabled?: boolean
}

withDefaults(defineProps<Props>(), {
  disabled: false,
})

const emit = defineEmits<{
  'update:modelValue': [value: string]
  send: []
}>()
</script>

<template>
  <div :class="styles.composer">
    <MessageInput
      :model-value="modelValue"
      :placeholder="PLACEHOLDERS.MESSAGE_INPUT"
      :disabled="disabled"
      @update:model-value="emit('update:modelValue', $event)"
      @send="emit('send')"
    />
    <Button variant="primary" size="md" :disabled="disabled" @click="emit('send')">
      <Icon name="send" :size="20" />
    </Button>
  </div>
</template>
