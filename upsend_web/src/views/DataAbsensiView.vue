<script setup>
import { ref, computed, onMounted, onBeforeUnmount } from 'vue'
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
const searchQuery = ref('')
const showLocationMenu = ref(false)

const locationLabel = computed(() => {
  if (!filter.value.location_id) return 'Semua Lokasi'
  const location = locations.value.find((item) => item.id === Number(filter.value.location_id))
  return location?.name || 'Semua Lokasi'
})

const filteredRecords = computed(() => {
  const query = searchQuery.value.trim().toLowerCase()
  if (!query) return records.value
  return records.value.filter((record) => record.employee?.name?.toLowerCase().includes(query))
})

function isLate(record) {
  if (!record.check_in_time) return false
  const checkIn = new Date(record.check_in_time)
  return checkIn.getHours() >= 9
}

function isOvertime(record) {
  const status = String(record.status || '').toLowerCase()
  return record.is_overtime === true
    || status === 'overtime'
    || status === 'lembur'
}

const summary = computed(() => ({
  total: totalRecords.value,
  onTime: records.value.filter((record) => record.check_in_time && !isLate(record)).length,
  late: records.value.filter((record) => isLate(record)).length,
  missed: records.value.filter((record) => !record.check_in_time).length,
  overtime: records.value.filter((record) => isOvertime(record)).length,
}))

function formatTime(value) {
  return value ? new Date(value).toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit' }) : '--:--'
}

function initials(name) {
  if (!name) return '-'
  return name.split(' ').map((word) => word[0]).slice(0, 2).join('').toUpperCase()
}

function statusFor(record) {
  if (!record.check_in_time) return { label: 'Lupa Absen', className: 'missed' }
  if (isOvertime(record)) return { label: 'Lembur', className: 'overtime' }
  if (isLate(record)) return { label: 'Terlambat', className: 'late' }
  return { label: 'Tepat Waktu', className: 'on-time' }
}

function handleExport() {
  window.alert('Fitur ekspor belum tersedia di backend.')
}

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
  records.value = []
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

function toggleLocationMenu() {
  showLocationMenu.value = !showLocationMenu.value
}

function closeLocationMenu() {
  showLocationMenu.value = false
}

function selectLocation(id) {
  filter.value.location_id = id
  showLocationMenu.value = false
  applyFilters()
}

onMounted(() => {
  fetchLocations()
  fetchAttendance()
  document.addEventListener('click', closeLocationMenu)
})

onBeforeUnmount(() => {
  document.removeEventListener('click', closeLocationMenu)
})
</script>

<template>
  <div class="attendance-page">
    <section class="summary-grid">
      <div class="summary-card"><div class="summary-top"><div class="summary-icon green"><Icon icon="material-symbols:groups-outline" /></div><span class="summary-tag green">TOTAL</span></div><span class="summary-label">Tepat Waktu</span><strong>{{ summary.onTime }}</strong><small>Check-in dan check-out tercatat</small></div>
      <div class="summary-card"><div class="summary-top"><div class="summary-icon amber"><Icon icon="material-symbols:schedule-outline" /></div><span class="summary-tag amber">STATUS</span></div><span class="summary-label">Terlambat</span><strong class="amber-text">{{ summary.late }}</strong><small>Check-in mulai pukul 09.00</small></div>
      <div class="summary-card"><div class="summary-top"><div class="summary-icon red"><Icon icon="material-symbols:person-off-outline" /></div><span class="summary-tag red">ALERT</span></div><span class="summary-label">Lupa Absen</span><strong class="red-text">{{ summary.missed }}</strong><small>Belum melakukan check-in</small></div>
      <div class="summary-card"><div class="summary-top"><div class="summary-icon blue"><Icon icon="material-symbols:logout-rounded" /></div><span class="summary-tag blue">SHIFT</span></div><span class="summary-label">Lembur</span><strong class="blue-text">{{ summary.overtime }}</strong><small>Sesuai penanda lembur</small></div>
    </section>

    <section class="panel table-panel">
      <div class="filter-bar">
        <div class="filter-title"><span>Tanggal</span><input type="date" v-model="filter.date" @change="applyFilters" /></div>
        <div class="location-select" @click.stop="toggleLocationMenu">
          <span>{{ locationLabel }}</span>
          <Icon icon="material-symbols:keyboard-arrow-down-rounded" width="18" height="18" />
          <div v-if="showLocationMenu" class="location-menu">
            <button type="button" class="location-item" @click.stop="selectLocation('')">Semua Lokasi</button>
            <button
              v-for="loc in locations"
              :key="loc.id"
              type="button"
              class="location-item"
              @click.stop="selectLocation(String(loc.id))"
            >
              {{ loc.name }}
            </button>
          </div>
        </div>
        <div class="search">
          <Icon icon="material-symbols:search-rounded" width="18" height="18" />
          <input
            type="text"
            v-model="searchQuery"
            @input="onSearchInput"
            placeholder="Cari nama karyawan ..."
          />
        </div>
        <button class="export-btn" type="button" @click="handleExport"><Icon icon="material-symbols:download-rounded" /> Export ke Excel</button>
      </div>
      <table>
        <thead>
          <tr>
            <th>Tanggal</th><th>Nama Karyawan</th><th>Lokasi</th><th>Check In</th><th>Check Out</th><th>Status</th><th>Detail</th>
          </tr>
        </thead>
        <tbody>
          <tr v-if="loading">
            <td colspan="7" class="empty-cell">Memuat data absensi...</td>
          </tr>
          <tr v-else-if="filteredRecords.length === 0">
            <td colspan="7" class="empty-cell">Belum ada data absensi.</td>
          </tr>
          <tr v-for="record in filteredRecords" :key="record.id">
            <td>{{ record.check_in_time ? new Date(record.check_in_time).toLocaleDateString('id-ID') : '-' }}</td>
            <td>
              <div class="employee">
                <div class="employee-avatar">{{ initials(record.employee?.name) }}</div>
                <strong>{{ record.employee?.name || '—' }}</strong>
              </div>
            </td>
            <td>{{ record.location?.name || '—' }}</td>
            <td>{{ formatTime(record.check_in_time) }}</td>
            <td>{{ formatTime(record.check_out_time) }}</td>
            <td><span class="status-badge" :class="statusFor(record).className">{{ statusFor(record).label }}</span></td>
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
        <span>Menampilkan {{ filteredRecords.length }} dari {{ totalRecords }} catatan</span>
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
  --blue-900: #2f3b69;
  --ink: #1c1c19;
  --ink-soft: #667085;
  --line: #d9dde5;
  --bg: #f7f8fa;
  --card: #ffffff;
  font-family: 'Plus Jakarta Sans', sans-serif;
}
.attendance-page * {
  box-sizing: border-box;
  font-family: 'Plus Jakarta Sans', sans-serif;
}
.panel {
  background: var(--card);
  border: 1px solid var(--line);
  border-radius: 16px;
}
.table-panel { position: relative; }
.table-panel::after { content: ''; position: absolute; inset: -1px; border: 1px solid var(--line); border-radius: 16px; pointer-events: none; z-index: 25; }
.summary-grid {
  display: grid;
  grid-template-columns: repeat(4, minmax(0, 1fr));
  gap: 14px;
  margin-bottom: 20px;
}
.summary-card {
  min-height: 146px;
  padding: 18px;
  background: var(--card);
  border: 1px solid var(--line);
  border-radius: 14px;
  box-shadow: 0 5px 12px rgba(47, 59, 105, 0.04);
}
.summary-top { display: flex; justify-content: space-between; align-items: flex-start; margin-bottom: 16px; }
.summary-icon { width: 32px; height: 32px; border-radius: 7px; display: grid; place-items: center; }
.summary-icon svg { width: 18px; height: 18px; }
.summary-icon.green { background: #e0f5e9; color: #17a057; }
.summary-icon.amber { background: #fff2d9; color: #efb34f; }
.summary-icon.red { background: #fde7e8; color: #d91e2e; }
.summary-icon.blue { background: #e8ebf5; color: var(--blue-900); }
.summary-tag { padding: 4px 7px; border-radius: 4px; font-size: 9px; font-weight: 800; }
.summary-tag.green { color: #15924f; background: #e5f5e9; }
.summary-tag.amber { color: #b17a18; background: #fff0d3; }
.summary-tag.red { color: var(--red, #d91e2e); background: #fdebed; }
.summary-tag.blue { color: var(--blue-900); background: #e8ebf5; }
.summary-label { display: block; color: var(--ink-soft); font-size: 14px; margin-bottom: 4px; }
.summary-card strong { display: block; color: #17a057; font-size: 30px; line-height: 1.1; margin-bottom: 9px; }
.summary-card small { color: var(--ink-soft); font-size: 11px; }
.summary-card .amber-text { color: #efb34f; }
.summary-card .red-text { color: #c91f2d; }
.summary-card .blue-text { color: var(--blue-900); }
.filter-bar {
  display: flex;
  align-items: flex-end;
  gap: 10px;
  padding: 18px 14px;
  margin: 0;
  background: var(--card);
  border-bottom: 1px solid var(--line);
  flex-wrap: wrap;
  border-radius: 15px 15px 0 0;
}
.table-panel {
  padding: 0;
  overflow: visible;
}
.filter-title { display: flex; flex-direction: column; gap: 5px; }
.filter-title span { color: var(--ink-soft); font-size: 11px; }
.location-select,
.filter-title input,
.search { height: 38px; border: 1px solid var(--line); border-radius: 8px; background: var(--card); color: var(--ink); }
.location-select { position: relative; display: flex; align-items: center; justify-content: space-between; gap: 8px; width: max-content; min-width: 170px; max-width: none; min-height: 40px; padding: 10px 16px; border-radius: 10px; font-size: 14px; line-height: 1.2; cursor: pointer; }
.location-select > span { white-space: nowrap; }
.location-select > .iconify { flex-shrink: 0; color: var(--ink-soft); }
.location-menu { position: absolute; z-index: 20; top: calc(100% + 7px); left: 0; width: max-content; min-width: 100%; max-height: 300px; overflow-y: auto; padding: 6px 0; background: var(--card); border: 1px solid var(--line); border-radius: 10px; box-shadow: 0 14px 28px rgba(47, 59, 105, 0.14); }
.location-item { display: block; width: 100%; padding: 10px 16px; border: 0; background: transparent; color: var(--ink); text-align: left; white-space: nowrap; font: inherit; font-size: 14px; cursor: pointer; }
.location-item:hover { background: #eef0f7; color: var(--blue-900); }
.filter-title input { padding: 8px 11px; font-size: 13px; font-family: inherit; }
.filter-title input { width: 150px; min-width: 150px; }
.search { display: flex; align-items: center; gap: 8px; padding: 10px 16px; width: 280px; min-width: 280px; margin-left: auto; background: var(--bg); }
.search svg, .search .iconify { width: 18px; height: 18px; color: var(--ink-soft); flex-shrink: 0; }
.search input { border: 0; outline: 0; width: 100%; color: var(--ink); font-size: 14px; font-family: inherit; background: transparent; }
.export-btn { height: 40px; margin-left: 0; display: inline-flex; align-items: center; gap: 6px; padding: 0 16px; border: 0; border-radius: 8px; background: #f2bd48; color: #392d0d; font-size: 14px; font-weight: 700; cursor: pointer; white-space: nowrap; }
.export-btn svg { width: 16px; height: 16px; }
table {
  width: 100%;
  border-collapse: collapse;
  overflow: hidden;
  border-radius: 0;
}
thead tr {
  background: var(--blue-900);
}
thead th {
  color: #eef0f7;
  font-size: 11.5px;
  font-weight: 700;
  letter-spacing: 0.06em;
  text-align: left;
  padding: 13px 24px;
  text-transform: uppercase;
}
thead th:first-child,
thead th:last-child { border-radius: 0; }
tbody td {
  padding: 14px 24px;
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
.employee { display: flex; align-items: center; gap: 12px; }
.employee-avatar { width: 36px; height: 36px; border-radius: 50%; background: #e2e5f0; color: var(--blue-900); font-size: 12px; font-weight: 700; display: grid; place-items: center; flex-shrink: 0; }
.employee strong { font-size: 15px; }
.status-badge { display: inline-flex; padding: 6px 12px; border-radius: 999px; font-size: 11px; font-weight: 700; white-space: nowrap; }
.status-badge.on-time { background: #dcf8e5; color: #15924f; }
.status-badge.late { background: #fff0c7; color: #9a6900; }
.status-badge.missed { background: #fde0e2; color: #c91f2d; }
.status-badge.overtime { background: #dce6ff; color: var(--blue-900); }

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
  background: var(--card);
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
  background: var(--bg);
  border-radius: 0 0 15px 15px;
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
  display: inline-flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  transition: background 0.12s ease, border-color 0.12s ease;
  box-shadow: 0 6px 14px rgba(47, 59, 105, 0.08);
}
.pager button:hover:not(:disabled) {
  background: var(--bg);
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
    color: var(--blue-900);
    font-weight: 700;
    text-decoration: none;
  }
  .detail-link:hover {
    text-decoration: underline;
  }
@media (max-width: 700px) {
  .summary-grid { grid-template-columns: repeat(2, minmax(0, 1fr)); }
  .search { margin-left: 0; width: 100%; min-width: 0; }
  .export-btn { margin-left: 0; }
  .table-panel { overflow-x: auto; }
  table { min-width: 760px; }
}
</style>
