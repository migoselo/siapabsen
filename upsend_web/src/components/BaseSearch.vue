<!-- src/components/BaseSearch.vue -->
<script setup>
import { Icon } from '@iconify/vue'

defineProps({
  modelValue: {
    type: String,
    default: ''
  },
  placeholder: {
    type: String,
    default: 'Cari data...'
  },
  width: {
    type: String,
    default: '240px' // Lebar default, bisa ditimpa saat komponen dipanggil
  }
})

defineEmits(['update:modelValue'])
</script>

<template>
  <div class="base-search" :style="{ width: width }">
    <Icon icon="material-symbols:search-rounded" class="search-icon" width="18" height="18" />
    <input 
      type="text"
      :value="modelValue"
      @input="$emit('update:modelValue', $event.target.value)"
      :placeholder="placeholder"
      class="search-input"
    />
  </div>
</template>

<style scoped>
.base-search {
  display: flex;
  align-items: center;
  gap: 8px;
  height: 40px;
  padding: 0 12px;
  background: #f7f8fa;
  border: 1px solid #d9dde5;
  border-radius: 10px;
  transition: all 0.2s ease;
  font-family: 'Plus Jakarta Sans', sans-serif;
}

/* Efek menyala pada kotak utama saat input di dalamnya sedang fokus */
.base-search:focus-within {
  border-color: #2f3b69;
  box-shadow: 0 0 0 3px rgba(47, 59, 105, 0.1);
  background: #ffffff;
}

.search-icon {
  color: #667085;
  flex-shrink: 0;
}

.search-input {
  flex: 1;
  border: none;
  outline: none;
  background: transparent;
  font-size: 14px;
  color: #1c1c19;
  font-family: inherit;
  width: 100%;
}

.search-input::placeholder {
  color: #98a2b3;
}
</style>