<script setup>
defineProps({
  columns: {
    type: Array,
    required: true,
    // Contoh: [{ key: 'name', label: 'Nama' }, { key: 'status', label: 'Status' }]
  },
  data: {
    type: Array,
    required: true,
  },
  emptyText: {
    type: String,
    default: 'Tidak ada data yang ditemukan.'
  },
  hasActions: {
    type: Boolean,
    default: false
  }
})
</script>

<template>
  <div class="table-wrap">
    <table class="table">
      <thead>
        <tr>
          <!-- Render Header Kolom Dinamis -->
          <th v-for="col in columns" :key="col.key">{{ col.label }}</th>
          <th v-if="hasActions" class="col-actions">Aksi</th>
        </tr>
      </thead>
      <tbody>
        <!-- State Kosong -->
        <tr v-if="!data || data.length === 0">
          <td :colspan="columns.length + (hasActions ? 1 : 0)" class="empty-row">
            {{ emptyText }}
          </td>
        </tr>
        
        <!-- Render Baris Data -->
        <tr v-for="(item, index) in data" :key="item.id || index">
          
          <td v-for="col in columns" :key="col.key">
            <!-- 
              SLOT DINAMIS: 
              Bisa di-inject dari parent. Format nama slot: `cell-[key_kolom]`
              Jika tidak ada slot yang di-passing, tampilkan teks biasa (item[col.key])
            -->
            <slot :name="`cell-${col.key}`" :item="item">
              {{ item[col.key] }}
            </slot>
          </td>

          <!-- Render Kolom Aksi -->
          <td v-if="hasActions">
            <slot name="actions" :item="item"></slot>
          </td>
        </tr>
      </tbody>
    </table>
  </div>
</template>

<style scoped>
.table-wrap { overflow-x: auto; }
.table { width: 100%; border-collapse: collapse; font-size: 14px; font-family: 'Plus Jakarta Sans', sans-serif;}
.table thead tr { background-color: #2f3b69; }
.table th {
  text-align: left; padding: 14px 24px; font-size: 12px;
  font-weight: 700; letter-spacing: 0.8px; text-transform: uppercase; color: #ffffff;
}
.col-actions { text-align: right !important; width: 1%; white-space: nowrap; }
.table tbody tr { border-bottom: 1px solid #f1f2f5; }
.table tbody tr:hover { background: #fafbfc; }
.table td { padding: 14px 24px; vertical-align: middle; color: #1c1c19;}
.empty-row { text-align: center; padding: 48px 24px; color: #667085; }
</style>