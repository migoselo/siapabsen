<!-- src/components/BasePageHeader.vue -->
<script setup>
import { Icon } from '@iconify/vue'

defineProps({
  title: { type: String, required: true }
})

defineEmits(['back'])
</script>

<template>
  <div class="page-title-bar">
    <button class="btn-back" @click="$emit('back')" title="Kembali">
      <Icon icon="material-symbols:arrow-back-rounded" width="22" height="22" />
    </button>
    <h2>{{ title }}</h2>
  </div>
</template>

<style scoped>
.page-title-bar {
  display: flex;
  align-items: center;
  gap: 12px;
  margin-bottom: 24px;
  font-family: 'Plus Jakarta Sans', sans-serif;
}

.btn-back {
  border: none;
  background: transparent;
  color: #1c1c19;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 4px;
  border-radius: 8px;
  transition: background 0.2s ease;
}

.btn-back:hover {
  background: #d9dde5;
}

.page-title-bar h2 {
  margin: 0;
  font-size: 20px;
  font-weight: 700;
  color: #1c1c19;
}
</style>