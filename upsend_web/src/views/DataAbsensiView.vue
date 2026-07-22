<script setup>
import { ref, onMounted } from 'vue'
import { Icon } from '@iconify/vue'
import api from '../api'

const records = ref([])
const loading = ref(false)

const currentPage = ref(1)
const lastPage = ref(1)
const totalRecords = ref(0)
const perPage = ref(20)

const locations = ref([])
const filter = ref({ date: '', location_id: '' })

async function fetchLocations() {
  try {
    const res = await api.get('/locations')
    locations.value = res.data || []
  } catch (err) {
    console.error('Gagal mengambil lokasi:', err)
  }
}

async function fetchAttendance(page = 1) {
  loading.value = true
  try {
    const params = {
      page,
      per_page: perPage.value,
    }
    if (filter.value.date) params.date = filter.value.date
    if (filter.value.location_id) params.location_id = filter.value.location_id

    const res = await api.get('/attendances', { params })
    records.value = res.data.data || []
    totalRecords.value = res.data.total || 0
    currentPage.value = res.data.current_page || page
    lastPage.value = res.data.last_page || 1
  } catch (err) {
    console.error('Gagal mengambil data absensi:', err)
  } finally {
    loading.value = false
  }
}

function prevPage() {
  const previous = currentPage.value - 1
  if (previous < 1) return
  fetchAttendance(previous)
}

function nextPage() {
  const next = currentPage.value + 1
  if (next > lastPage.value) return
  fetchAttendance(next)
}

function applyFilters() {
  fetchAttendance(1)
}

onMounted(() => {
  fetchLocations()
  fetchAttendance()
})
</script>

<template>
  <div class="attendance-page">
      <div class="filter-bar">
        <div class="filters">
          <input type="date" v-model="filter.date" @change="applyFilters" />
          <select v-model="filter.location_id" @change="applyFilters">
            <option value="">Semua Lokasi</option>
            <option v-for="loc in locations" :key="loc.id" :value="loc.id">{{ loc.name }}</option>
          </select>
        </div>
      </div>

    <section class="panel table-panel">
      <table>
        <thead>
          <tr>
            <th>Nama</th>
            <th>Lokasi</th>
            <th>Waktu Check In</th>
            <th>Waktu Check Out</th>
            <th>Detail</th>
          </tr>
        </thead>
        <tbody>
          <tr v-if="loading">
            <td colspan="5" class="empty-cell">Memuat data absensi...</td>
          </tr>
          <tr v-else-if="records.length === 0">
            <td colspan="5" class="empty-cell">Belum ada data absensi.</td>
          </tr>
          <tr v-for="record in records" :key="record.id">
            <td>{{ record.employee?.name || '—' }}</td>
            <td>{{ record.location?.name || '—' }}</td>
            <td>{{ record.check_in_time ? new Date(record.check_in_time).toLocaleString() : '--:--' }}</td>
            <td>{{ record.check_out_time ? new Date(record.check_out_time).toLocaleString() : '--:--' }}</td>
            <td>
              <router-link
                :to="{ name: 'DetailAbsen', params: { id: record.id } }"
                class="detail-link"
              >
                Lihat Detail
              </router-link>
            </td>
          </tr>
        </tbody>
      </table>

      <div class="table-footer">
        <span>Menampilkan {{ records.length }} dari {{ totalRecords }} catatan</span>
        <div class="pager">
          <button type="button" :disabled="currentPage === 1" @click="prevPage">
            <Icon icon="material-symbols:chevron-left-rounded" width="18" height="18" />
          </button>
          <div style="display:flex;align-items:center;padding:0 8px;font-weight:600;color:var(--ink-soft);">
            Halaman {{ currentPage }} / {{ lastPage }}
          </div>
          <button type="button" :disabled="currentPage === lastPage" @click="nextPage">
            <Icon icon="material-symbols:chevron-right-rounded" width="18" height="18" />
          </button>
        </div>
      </div>
    </section>
  </div>
</template>

<style scoped>
.attendance-page {
  --green-900: #173d31;
  --ink: #1c2521;
  --ink-soft: #5b6864;
  --line: #e7e7e2;
  --bg: #ffffff;
  --card: #ffffff;
}
.attendance-page * {
  box-sizing: border-box;
}
.panel {
  background: var(--card);
  border: 1px solid var(--line);
  border-radius: 16px;
}
.filter-bar {
  display: flex;
  justify-content: flex-start;
  padding: 0 0 18px;
  margin-bottom: 12px;
}
.table-panel {
  padding: 0;
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
  font-size: 13px;
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

.filters {
  display: flex;
  gap: 12px;
  align-items: center;
  background: var(--bg);
  border: 1px solid var(--line);
  padding: 9px 14px;
  border-radius: 10px;
  flex-wrap: wrap;
}
.filters input[type="date"],
.filters select {
  height: 38px;
  padding: 8px 12px;
  border: 1px solid var(--line);
  border-radius: 10px;
  background: #fff;
  font-size: 14px;
  color: var(--ink);
}
.filters input[type="date"] {
  min-width: 160px;
}
.filters select {
  min-width: 180px;
}

.table-footer {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 16px 24px;
  font-size: 13px;
  color: var(--ink-soft);
  border-top: 1px solid var(--line);
}
.pager {
  display: flex;
  gap: 8px;
}
.pager button {
  padding: 10px 12px;
  min-width: 44px;
  height: 44px;
  border-radius: 12px;
  border: 1px solid var(--line);
  background: #fff;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  transition: background 0.12s ease, border-color 0.12s ease;
  box-shadow: 0 6px 14px rgba(15, 43, 34, 0.04);
}
.pager button:hover:not(:disabled) {
  background: #fbfbf9;
}
.pager button svg,
.pager button .iconify {
  color: var(--ink-soft);
}
.pager button:disabled {
  opacity: 0.45;
  cursor: not-allowed;
}
  .detail-link {
    display: inline-flex;
    align-items: center;
    gap: 6px;
    color: var(--green-900);
    font-weight: 700;
    text-decoration: none;
  }
  .detail-link:hover {
    text-decoration: underline;
  }
</style>
