<script setup>
import { ref, watch } from 'vue'
import { Icon } from '@iconify/vue'

const props = defineProps({
  currentPage: { type: Number, default: 1 },
  lastPage: { type: Number, default: 1 },
  perPage: { type: Number, default: 20 },
  total: { type: Number, default: 0 },
  loading: { type: Boolean, default: false },
  perPageOptions: { type: Array, default: () => [10, 20, 50, 100] },
})
const emit = defineEmits(['page-change', 'per-page-change'])

const pageInput = ref(props.currentPage)
watch(() => props.currentPage, (page) => (pageInput.value = page))

function goToInputPage() {
  let page = Number(pageInput.value)
  if (isNaN(page) || page < 1) page = 1
  if (page > props.lastPage) page = props.lastPage
  pageInput.value = page
  if (page !== props.currentPage) emit('page-change', page)
}
</script>

<template>
  <div class="table-footer">
    <div class="table-footer-content">
      <div class="pager">
        <button
          type="button"
          class="pager-btn"
          :disabled="currentPage <= 1 || loading"
          title="Halaman Sebelumnya"
          @click="emit('page-change', currentPage - 1)"
        >
          <Icon icon="material-symbols:chevron-left-rounded" width="18" height="18" />
        </button>
        <div class="page-input-wrapper">
          <span>Halaman</span>
          <input
            v-model.number="pageInput"
            type="number"
            min="1"
            :max="lastPage"
            class="page-input"
            @keydown.enter="goToInputPage"
            @blur="goToInputPage"
          />
          <span>dari {{ lastPage }}</span>
        </div>
        <button
          type="button"
          class="pager-btn"
          :disabled="currentPage >= lastPage || loading"
          title="Halaman Berikutnya"
          @click="emit('page-change', currentPage + 1)"
        >
          <Icon icon="material-symbols:chevron-right-rounded" width="18" height="18" />
        </button>
      </div>

      <div class="per-page-select">
        <select
          :value="perPage"
          :disabled="loading"
          @change="emit('per-page-change', Number($event.target.value))"
        >
          <option v-for="n in perPageOptions" :key="n" :value="n">{{ n }} baris</option>
        </select>
      </div>

      <span class="total-records-info">{{ total }} catatan</span>
    </div>
  </div>
</template>

<style scoped>
.table-footer {
  display: flex;
  justify-content: flex-end;
  align-items: center;
  padding: 12px 24px;
  font-size: 13px;
  color: #667085;
  border-top: 1px solid #d9dde5;
  background: #f7f8fa;
  border-radius: 0 0 15px 15px;
}
.table-footer-content { display: flex; align-items: center; gap: 16px; }
.pager { display: flex; align-items: center; gap: 6px; }
.pager-btn {
  width: 32px;
  height: 32px;
  border-radius: 6px;
  border: 1px solid #d9dde5;
  background: #fff;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  transition: all 0.15s ease;
  color: #667085;
}
.pager-btn:hover:not(:disabled) { border-color: #2f3b69; color: #2f3b69; }
.pager-btn:disabled { opacity: 0.4; cursor: not-allowed; }
.page-input-wrapper {
  display: flex;
  align-items: center;
  gap: 6px;
  font-weight: 600;
  color: #667085;
  font-size: 13px;
}
.page-input {
  width: 44px;
  height: 32px;
  text-align: center;
  border: 1px solid #d9dde5;
  border-radius: 6px;
  background: #fff;
  color: #1c1c19;
  font-weight: 700;
  font-size: 13px;
  outline: none;
  -moz-appearance: textfield;
  font-family: inherit;
}
.page-input::-webkit-outer-spin-button,
.page-input::-webkit-inner-spin-button { -webkit-appearance: none; margin: 0; }
.page-input:focus { border-color: #2f3b69; box-shadow: 0 0 0 2px rgba(47, 59, 105, 0.12); }
.per-page-select select {
  height: 32px;
  padding: 0 10px;
  border: 1px solid #d9dde5;
  border-radius: 6px;
  background: #fff;
  color: #1c1c19;
  font-size: 13px;
  font-weight: 600;
  cursor: pointer;
  outline: none;
  font-family: inherit;
}
.per-page-select select:focus { border-color: #2f3b69; }
.total-records-info { font-size: 13px; font-weight: 600; color: #667085; white-space: nowrap; }
</style>