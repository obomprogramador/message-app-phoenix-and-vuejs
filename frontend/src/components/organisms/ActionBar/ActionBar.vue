<script setup lang="ts">
import Button from '@/components/atoms/Button/Button.vue'
import Icon from '@/components/atoms/Icon/Icon.vue'
import SearchInput from '@/components/atoms/SearchInput/SearchInput.vue'
import { PLACEHOLDERS } from '@/constants/strings'
import styles from './css/ActionBar.module.css'

interface Props {
  searchQuery: string
}

defineProps<Props>()

const emit = defineEmits<{
  'update:search-query': [value: string]
  'new-group': []
  'contacts': []
}>()
</script>

<template>
  <div :class="styles.bar">
    <div :class="styles.actions">
      <Button variant="ghost" size="sm" @click="emit('new-group')">
        <Icon name="new-group" :size="18" />
        <span>Novo Grupo</span>
      </Button>
      <Button variant="ghost" size="sm" @click="emit('contacts')">
        <Icon name="contacts" :size="18" />
        <span>Contatos</span>
      </Button>
    </div>
    <SearchInput
      :model-value="searchQuery"
      :placeholder="PLACEHOLDERS.SEARCH_CONVERSATION"
      @update:model-value="emit('update:search-query', $event)"
    />
  </div>
</template>
