<script setup>
import { computed } from 'vue'
import { Icon } from '@iconify/vue'

const props = defineProps({
  /**
   * Tentukan jenis tombol: 'edit' atau 'delete'
   */
  variant: {
    type: String,
    required: true,
    validator: (value) => ['edit', 'delete'].includes(value)
  },
  /**
   * Tooltip khusus jika ingin mengubah teks bawaan saat tombol di-hover
   */
  tooltip: {
    type: String,
    default: ''
  }
})

defineEmits(['click'])

// Menentukan ikon otomatis berdasarkan variant
const iconName = computed(() => {
  return props.variant === 'edit'
    ? 'material-symbols:edit-outline-rounded'
    : 'material-symbols:delete-outline-rounded'
})

// Menentukan teks tooltip otomatis
const computedTooltip = computed(() => {
  if (props.tooltip) return props.tooltip
  return props.variant === 'edit' ? 'Edit' : 'Hapus'
})
</script>

<template>
  <button
    type="button"
    class="icon-btn"
    :class="variant === 'delete' ? 'icon-btn-danger' : 'icon-btn-edit'"
    :title="computedTooltip"
    @click.stop="$emit('click')"
  >
    <Icon :icon="iconName" width="16" height="16" />
  </button>
</template>

<style scoped>
/* 
  CSS dipusatkan di sini. Anda bisa menghapus class .icon-btn 
  dan .icon-btn-danger dari halaman-halaman lain. 
*/
.icon-btn {
  width: 30px;
  height: 30px;
  border-radius: 6px;
  border: none;
  background: transparent;
  color: #667085; /* Warna default abu-abu untuk edit */
  display: inline-grid;
  place-items: center;
  cursor: pointer;
  transition: all 0.2s ease;
  flex-shrink: 0;
}

/* Hover state untuk Edit */
.icon-btn-edit:hover {
  background: #e8ebf5;
  color: #2f3b69;
}

/* Base state untuk Delete (Bikin icon jadi merah) */
.icon-btn-danger {
  color: #d92d20; 
}

/* Hover state untuk Delete (Latar merah muda, icon merah gelap) */
.icon-btn-danger:hover {
  background: #fdeeee;
  color: #c53030;
}
</style>