<!-- src/components/BaseSummaryCard.vue -->
<script setup>
import { Icon } from '@iconify/vue'

defineProps({
  tag: { type: String, required: true },       // Contoh: 'ANGGARAN', 'KARYAWAN'
  title: { type: String, required: true },     // Contoh: 'Total Anggaran Bulanan'
  value: { type: [String, Number], required: true }, // Contoh: 'Rp 15.000.000'
  subtitle: { type: String, default: '' },     // Contoh: '+3.2% vs bulan lalu'
  icon: { type: String, required: true },      // Contoh: 'material-symbols:groups-outline'
  theme: { 
    type: String, 
    default: 'blue', 
    validator: (v) => ['blue', 'green', 'amber', 'red'].includes(v)
  }
})
</script>

<template>
  <div class="summary-card">
    <div class="summary-top">
      <div class="summary-icon" :class="theme">
        <Icon :icon="icon" />
      </div>
      <span class="summary-tag" :class="theme">{{ tag }}</span>
    </div>
    <span class="summary-label">{{ title }}</span>
    <strong :class="`${theme}-text`">{{ value }}</strong>
    <small v-if="subtitle">{{ subtitle }}</small>
  </div>
</template>

<style scoped>
.summary-card {
  min-height: 146px;
  padding: 18px;
  background: #ffffff;
  border: 1px solid #d9dde5;
  border-radius: 14px;
  box-shadow: 0 5px 12px rgba(47, 59, 105, 0.04);
  font-family: 'Plus Jakarta Sans', sans-serif;
}
.summary-top {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 16px;
}
.summary-icon {
  width: 32px; height: 32px; border-radius: 7px;
  display: grid; place-items: center;
}
.summary-icon svg { width: 18px; height: 18px; }
.summary-tag {
  padding: 4px 7px; border-radius: 4px;
  font-size: 9px; font-weight: 800;
}
.summary-label {
  display: block; color: #667085; font-size: 14px; margin-bottom: 4px;
}
.summary-card strong {
  display: block; font-size: 26px; font-weight: 800; line-height: 1.1; margin-bottom: 9px;
}
.summary-card small { color: #667085; font-size: 11px; }

/* Themes */
.green { background: #e0f5e9; color: #17a057; }
.summary-tag.green { color: #15924f; background: #e5f5e9; }
.green-text { color: #17a057; }

.amber { background: #fff2d9; color: #efb34f; }
.summary-tag.amber { color: #b17a18; background: #fff0d3; }
.amber-text { color: #efb34f; }

.blue { background: #e8ebf5; color: #2f3b69; }
.summary-tag.blue { color: #2f3b69; background: #e8ebf5; }
.blue-text { color: #2f3b69; }

.red { background: #fde7e8; color: #d91e2e; }
.summary-tag.red { color: #d91e2e; background: #fdebed; }
.red-text { color: #c91f2d; }
</style>