<script setup>
import { ref, computed, onMounted } from 'vue'
import { Icon } from '@iconify/vue'
import api from '../api'

/*
  View ini cuma berisi KONTEN halaman (sidebar & topbar sudah ditangani
  MainLayout.vue lewat router-view) — ikut pola yang sama dengan
  DashboardView.vue / LokasiKerjaView.vue.
*/

const employees = ref([])
const loading = ref(false)
const searchQuery = ref('')

const filteredEmployees = computed(() => {
  const q = searchQuery.value.trim().toLowerCase()
  if (!q) return employees.value
  return employees.value.filter(
    (e) => e.name.toLowerCase().includes(q) || e.email.toLowerCase().includes(q),
  )
})

function initials(name) {
  if (!name) return ''
  return name.split(' ').map((w) => w[0]).slice(0, 2).join('').toUpperCase()
}

async function fetchEmployees() {
  loading.value = true
  try {
    // TODO: sesuaikan endpoint dengan API yang disediakan tim backend
    const res = await api.get('/employees')
    employees.value = res.data.employees
  } catch (err) {
    console.error('Gagal mengambil data karyawan:', err)
  } finally {
    loading.value = false
  }
}

function onSearchInput() {
  // TODO: kalau pencarian dilakukan di server, panggil endpoint terpisah di sini
}

function handleAddEmployee() {
  // TODO: buka modal/route form tambah karyawan
  console.log('tambah karyawan baru')
}

onMounted(() => {
  fetchEmployees()
})
</script>

<template>
  <div class="karyawan">
    <section class="panel table-panel">
      <div class="table-head">
        <div class="search">
          <Icon icon="material-symbols:search-rounded" width="18" height="18" />
          <input
            type="text"
            v-model="searchQuery"
            @input="onSearchInput"
            placeholder="Cari nama karyawan ..."
          />
        </div>
        <button class="icon-btn-solid" @click="handleAddEmployee">
          <Icon icon="material-symbols:add-rounded" width="20" height="20" />
        </button>
      </div>

      <table>
        <thead>
          <tr>
            <th>ID</th>
            <th>Nama Karyawan</th>
            <th>Email</th>
            <th>Nomor HP</th>
            <th>Lokasi Cabang</th>
          </tr>
        </thead>
        <tbody>
          <tr v-if="loading">
            <td colspan="5" class="empty-cell">Memuat data...</td>
          </tr>
          <tr v-else-if="filteredEmployees.length === 0">
            <td colspan="5" class="empty-cell">Tidak ada karyawan ditemukan.</td>
          </tr>
          <tr v-for="emp in filteredEmployees" :key="emp.id">
            <td class="emp-id-cell">{{ emp.id }}</td>
            <td>
              <div class="emp">
                <div class="emp-avatar">{{ initials(emp.name) }}</div>
                <div class="emp-name">{{ emp.name }}</div>
              </div>
            </td>
            <td>{{ emp.email }}</td>
            <td>{{ emp.phone }}</td>
            <td>{{ emp.location }}</td>
          </tr>
        </tbody>
      </table>

      <div class="table-footer">
        <span>Menampilkan {{ filteredEmployees.length }} dari 150 karyawan</span>
        <div class="pager">
          <button disabled>
            <Icon icon="material-symbols:chevron-left-rounded" width="18" height="18" />
          </button>
          <button>
            <Icon icon="material-symbols:chevron-right-rounded" width="18" height="18" />
          </button>
        </div>
      </div>
    </section>
  </div>
</template>

<style scoped>
.karyawan {
  --green-900: #173d31;
  --ink: #1c2521;
  --ink-soft: #5b6864;
  --line: #e7e7e2;
  --bg: #ffffff;
  --card: #ffffff;
}
.karyawan * {
  box-sizing: border-box;
}

.panel {
  background: var(--card);
  border: 1px solid var(--line);
  border-radius: 16px;
}
.table-panel {
  padding: 22px 0 0;
}
.table-head {
  display: flex;
  justify-content: flex-end;
  align-items: center;
  gap: 10px;
  padding: 0 24px 22px;
  flex-wrap: wrap;
}
.search {
  display: flex;
  align-items: center;
  gap: 8px;
  background: var(--bg);
  border: 1px solid var(--line);
  padding: 10px 16px;
  border-radius: 10px;
  min-width: 280px;
}
.search svg,
.search .iconify {
  width: 18px;
  height: 18px;
  color: var(--ink-soft);
  flex-shrink: 0;
}
.search input {
  border: none;
  background: none;
  outline: none;
  font-size: 14px;
  width: 100%;
  font-family: inherit;
  color: var(--ink);
}
.icon-btn-solid {
  width: 44px;
  height: 44px;
  border-radius: 10px;
  background: var(--green-900);
  border: none;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  flex-shrink: 0;
  transition: background 0.15s ease;
}
.icon-btn-solid:hover {
  background: #0f2b22;
}
.icon-btn-solid svg,
.icon-btn-solid .iconify {
  color: #fff;
}

table {
  width: 100%;
  border-collapse: collapse;
}
thead tr {
  background: var(--green-900);
}
thead th {
  color: #dfe9e3;
  font-size: 11.5px;
  font-weight: 700;
  letter-spacing: 0.06em;
  text-align: left;
  padding: 14px 24px;
  text-transform: uppercase;
}
tbody td {
  padding: 18px 24px;
  font-size: 15px;
  border-bottom: 1px solid var(--line);
  vertical-align: middle;
  color: var(--ink);
}
tbody tr:last-child td {
  border-bottom: none;
}
.empty-cell {
  text-align: center;
  color: var(--ink-soft);
  padding: 32px;
}
.emp-id-cell {
  color: var(--ink-soft);
}
.emp {
  display: flex;
  align-items: center;
  gap: 12px;
}
.emp-avatar {
  width: 36px;
  height: 36px;
  border-radius: 50%;
  background: #e9e8e3;
  color: #4b5450;
  font-weight: 700;
  font-size: 12px;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}
.emp-name {
  font-weight: 700;
  font-size: 15px;
}

.table-footer {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 16px 24px;
  font-size: 13px;
  color: var(--ink-soft);
  border-top: 1px solid var(--line);
  background: #f6f5f1;
}
.pager {
  display: flex;
  gap: 8px;
}
.pager button {
  width: 34px;
  height: 34px;
  border-radius: 8px;
  border: 1px solid var(--line);
  background: #fff;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
}
.pager button svg,
.pager button .iconify {
  color: var(--ink-soft);
}
.pager button:disabled {
  opacity: 0.4;
  cursor: not-allowed;
}

@media (max-width: 700px) {
  .table-head {
    justify-content: stretch;
  }
  .search {
    min-width: 0;
    flex: 1;
  }
}
</style>