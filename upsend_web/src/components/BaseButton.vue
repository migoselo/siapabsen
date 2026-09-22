<script setup>
import { Icon } from '@iconify/vue'

defineProps({
  variant: {
    type: String,
    default: 'primary', // Pilihan: 'primary', 'ghost', 'danger'
  },
  icon: {
    type: String,
    default: '', // Contoh: 'material-symbols:add-rounded'
  },
  type: {
    type: String,
    default: 'button'
  }
})
</script>

<template>
  <button :type="type" class="base-btn" :class="`btn-${variant}`">
    <Icon v-if="icon" :icon="icon" width="18" height="18" />
    <slot /> <!-- Tempat teks tombol dirender -->
  </button>
</template>

<style scoped>
.base-btn {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  font-size: 14px;
  font-weight: 700;
  border-radius: 8px;
  padding: 9px 16px;
  cursor: pointer;
  border: none;
  font-family: 'Plus Jakarta Sans', sans-serif;
  transition: all 0.2s ease;
}

.btn-primary { background: #2f3b69; color: #ffffff; }
.btn-primary:hover { background: #252f58; }

.btn-ghost { background: transparent; border: 1px solid #d9dde5; color: #667085; }
.btn-ghost:hover { background: #f4f5f8; }

.btn-danger { background: #c53030; color: #ffffff; }
.btn-danger:hover { background: #9b2c2c; }
</style>