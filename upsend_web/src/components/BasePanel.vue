<script setup>
/**
 * BasePanel.vue
 * Kartu pembungkus (border + sudut membulat) untuk tabel.
 *
 * Slot:
 *  - header  : (opsional) bar di bagian atas kartu, mis. judul + kolom pencarian
 *  - default : isi kartu (BaseTable, filter, pagination, dll)
 *
 * Props:
 *  - overflowVisible: true jika ada popup (kalender / dropdown) yang harus
 *    keluar dari kartu. Border tetap digambar lewat lapisan ::after.
 */
defineProps({
  overflowVisible: { type: Boolean, default: false },
})
</script>

<template>
  <section class="base-panel" :class="{ 'is-overflow-visible': overflowVisible }">
    <header v-if="$slots.header" class="base-panel-header">
      <slot name="header" />
    </header>
    <slot />
  </section>
</template>

<style scoped>
.base-panel {
  --panel-line: var(--line, #d9dde5);
  position: relative;
  background: #fff;
  border: 1px solid var(--panel-line);
  border-radius: 16px;
  overflow: hidden; /* memotong sudut header tabel agar ikut membulat */
}
.base-panel.is-overflow-visible {
  overflow: visible;
}
.base-panel.is-overflow-visible::after {
  content: '';
  position: absolute;
  inset: -1px;
  border: 1px solid var(--panel-line);
  border-radius: 16px;
  pointer-events: none;
  z-index: 25;
}

.base-panel-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  flex-wrap: wrap;
  gap: 12px;
  padding: 18px 24px;
  background: #fff;
  border-bottom: 1px solid var(--panel-line);
}
</style>