<script setup>
import { ref, computed, watch, onMounted, onBeforeUnmount } from 'vue'
import { Icon } from '@iconify/vue'
import api from '../api'

const locations = ref([])
const selectedLocationId = ref('')
const showLocationMenu = ref(false)

const locationLabel = computed(() => {
  if (!selectedLocationId.value) return 'Semua Lokasi'
  const location = locations.value.find((loc) => loc.id === Number(selectedLocationId.value))
  return location?.name ?? 'Semua Lokasi'
})

const stats = ref({
  totalEmployees: 0,
  totalGrowthLabel: '',
  checkedIn: 0,
  checkedInPercent: 0,
  notCheckedIn: 0,
  notCheckedInNote: '',
  checkedOut: 0,
  checkedOutExtraCount: 0,
})

const currentDate = ref('')
const weeklyAverageLabel = ref('Data tren belum tersedia')
const chartData = ref([])
const employees = ref([])
const loading = ref(false)

const statusMeta = {
  checkout: { label: 'Check Out', cls: 'checkout' },
  checkin: { label: 'Check In', cls: 'checkin' },
  working: { label: 'Sedang Bekerja', cls: 'working dot' },
  absent: { label: 'Belum Hadir', cls: 'absent' },
}

const chartDayLabels = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min']
const selectedTrendDate = ref('')

const highlightIndex = computed(() => {
  const todayStr = new Date().toLocaleDateString('sv-SE')
  const todayIndex = chartData.value.findIndex((item) => item.date === todayStr)

  return todayIndex >= 0 ? todayIndex : chartData.value.length - 1
})

const selectedIndex = computed(() => {
  if (!selectedTrendDate.value) return -1
  return chartData.value.findIndex((item) => item.date === selectedTrendDate.value)
})

const chartMax = computed(() => {
  const values = chartData.value.map((item) => item.count ?? 0)
  return values.length ? Math.max(...values, 1) : 1
})

const periods = [
  { key: 'hari', label: 'Hari Ini' },
  { key: 'minggu', label: 'Minggu Ini' },
  { key: 'bulan', label: 'Bulan Ini' },
]
const activePeriod = ref('hari')
const activityPeriodLabel = computed(() => {
  if (selectedTrendDate.value) {
    const todayStr = new Date().toLocaleDateString('sv-SE')
    if (selectedTrendDate.value === todayStr) {
      return 'Hari Ini'
    }
    return selectedTrendDate.value
  }

  return periods.find((period) => period.key === activePeriod.value)?.label ?? 'Hari Ini'
})

const searchQuery = ref('')

// Pagination state
const currentPage = ref(1)
const lastPage = ref(1)
const perPage = ref(20)
const pageInput = ref(1)

const filteredEmployees = computed(() => {
  const q = searchQuery.value.trim().toLowerCase()
  let result = employees.value

  if (q) {
    result = result.filter((e) => e.name.toLowerCase().includes(q))
  }

  lastPage.value = Math.ceil(result.length / perPage.value) || 1

  const start = (currentPage.value - 1) * perPage.value
  return result.slice(start, start + perPage.value)
})

function initials(name) {
  if (!name) return ''
  return name
    .split(' ')
    .map((w) => w[0])
    .slice(0, 2)
    .join('')
    .toUpperCase()
}

function formatCurrentDate() {
  currentDate.value = new Date().toLocaleDateString('id-ID', {
    weekday: 'long',
    day: 'numeric',
    month: 'long',
    year: 'numeric',
  })
}

async function fetchLocations() {
  try {
    const res = await api.get('/locations')
    locations.value = res.data
  } catch (err) {
    console.error('Gagal mengambil daftar lokasi:', err)
  }
}

async function fetchDashboard() {
  loading.value = true
  try {
    const params = {
      period: activePeriod.value,
      ...(selectedLocationId.value ? { location_id: selectedLocationId.value } : {}),
    }
    const [summaryRes, attendanceRes, trendRes] = await Promise.all([
      api.get('/dashboard/summary', { params }),
      api.get('/dashboard/today-attendance', { params }),
      api.get('/dashboard/weekly-trend', { params }),
    ])

    const summary = summaryRes.data
    const emps = attendanceRes.data.employees
    const trend = trendRes.data

    const total = summary.total_karyawan_aktif
    const checkedIn = summary.hadir_hari_ini
    const checkedOutList = emps.filter((e) => e.status === 'checkout')

    stats.value = {
      totalEmployees: total,
      totalGrowthLabel: `${summary.total_lokasi} lokasi aktif`,
      checkedIn,
      checkedInPercent: total > 0 ? Math.round((checkedIn / total) * 100) : 0,
      notCheckedIn: Math.max(total - checkedIn, 0),
      notCheckedInNote: `${summary.pending_review} menunggu review`,
      checkedOut: checkedOutList.length,
      checkedOutExtraCount: Math.max(checkedOutList.length - 3, 0),
    }

    weeklyAverageLabel.value = trend.weeklyAverageLabel
    chartData.value = trend.chartData
    employees.value = emps
    selectedTrendDate.value = ''
  } catch (err) {
    console.error('Gagal mengambil data dashboard:', err)
  } finally {
    loading.value = false
  }
}

async function selectTrendDay(item) {
  if (!item?.date) return

  selectedTrendDate.value = item.date
  loading.value = true
  try {
    const params = {
      date: item.date,
      ...(selectedLocationId.value ? { location_id: selectedLocationId.value } : {}),
    }
    const response = await api.get('/dashboard/today-attendance', { params })
    employees.value = response.data.employees || []
  } catch (err) {
    console.error('Gagal mengambil data kehadiran tanggal terpilih:', err)
  } finally {
    loading.value = false
  }
}

function toggleLocationMenu() {
  showLocationMenu.value = !showLocationMenu.value
}

function closeLocationMenu() {
  showLocationMenu.value = false
}

function selectLocation(id) {
  selectedLocationId.value = id
  showLocationMenu.value = false
  fetchDashboard()
}

function selectPeriod(key) {
  activePeriod.value = key
  fetchDashboard()
}

function prevPage() {
  if (currentPage.value > 1) {
    currentPage.value--
    pageInput.value = currentPage.value
  }
}

function nextPage() {
  if (currentPage.value < lastPage.value) {
    currentPage.value++
    pageInput.value = currentPage.value
  }
}

function goToInputPage() {
  let page = Number(pageInput.value)
  if (isNaN(page) || page < 1) page = 1
  if (page > lastPage.value) page = lastPage.value
  currentPage.value = page
  pageInput.value = page
}

function changePerPage() {
  currentPage.value = 1
  pageInput.value = 1
}

watch([selectedTrendDate, selectedLocationId, searchQuery], () => {
  currentPage.value = 1
  pageInput.value = 1
})

onMounted(() => {
  formatCurrentDate()
  fetchLocations()
  fetchDashboard()
  document.addEventListener('click', closeLocationMenu)
})

onBeforeUnmount(() => {
  document.removeEventListener('click', closeLocationMenu)
})
</script>

<template>
  <div class="dashboard">
    <div class="filterbar">
      <div class="filterbar-left">
        <div class="segmented">
          <button
            v-for="p in periods"
            :key="p.key"
            :class="{ active: activePeriod === p.key }"
            @click="selectPeriod(p.key)"
          >
            {{ p.label }}
          </button>
        </div>
        <div class="select" @click.stop="toggleLocationMenu">
          <span>{{ locationLabel }}</span>
          <Icon icon="material-symbols:keyboard-arrow-down-rounded" width="18" height="18" />

          <div v-if="showLocationMenu" class="select-menu">
            <button type="button" class="select-item" @click.stop="selectLocation('')">
              Semua Lokasi
            </button>
            <button
              v-for="loc in locations"
              :key="loc.id"
              type="button"
              class="select-item"
              @click.stop="selectLocation(String(loc.id))"
            >
              {{ loc.name }}
            </button>
          </div>
        </div>
      </div>
      <div class="date-pill">
        <Icon icon="material-symbols:calendar-today-outline" width="16" height="16" />
        {{ currentDate }}
      </div>
    </div>

    <section class="stats">
      <div class="stat-card">
        <div class="stat-top">
          <div class="stat-icon">
            <Icon icon="material-symbols:groups-outline" width="20" height="20" />
          </div>
          <span class="tag">TOTAL</span>
        </div>
        <div class="stat-label">Total Karyawan</div>
        <div class="stat-value">{{ stats.totalEmployees }}</div>
        <div class="stat-sub up">{{ stats.totalGrowthLabel }}</div>
      </div>

      <div class="stat-card">
        <div class="stat-top">
          <div class="stat-icon">
            <Icon icon="material-symbols:login-rounded" width="20" height="20" />
          </div>
          <span class="tag">STATUS</span>
        </div>
        <div class="stat-label">Sudah Check In</div>
        <div class="stat-value">{{ stats.checkedIn }}</div>
        <div class="progress"><span :style="{ width: stats.checkedInPercent + '%' }"></span></div>
        <div class="stat-sub">{{ stats.checkedInPercent }}% Kehadiran</div>
      </div>

      <div class="stat-card alert">
        <div class="stat-top">
          <div class="stat-icon">
            <Icon icon="material-symbols:person-cancel-outline" width="20" height="20" />
          </div>
          <span class="tag alert">ALERT</span>
        </div>
        <div class="stat-label">Belum Check In</div>
        <div class="stat-value danger">{{ stats.notCheckedIn }}</div>
        <div class="stat-sub">{{ stats.notCheckedInNote }}</div>
      </div>

      <div class="stat-card">
        <div class="stat-top">
          <div class="stat-icon">
            <Icon icon="material-symbols:logout-rounded" width="20" height="20" />
          </div>
          <span class="tag">SHIFT</span>
        </div>
        <div class="stat-label">Sudah Check Out</div>
        <div class="stat-value">{{ stats.checkedOut }}</div>
        <div class="mini-avatars">
          <div class="dots"><span></span><span></span><span></span></div>
          <span class="stat-sub">&nbsp;+{{ stats.checkedOutExtraCount }} Orang lainnya</span>
        </div>
      </div>
    </section>

    <section class="middle-row">
      <div class="panel trend-panel">
        <div class="panel-head">
          <div>
            <h2>Tren Kehadiran 7 Hari Terakhir</h2>
            <p>{{ weeklyAverageLabel }}</p>
          </div>
        </div>
        <div class="chart-wrap">
          <div class="chart-ticks">
            <div
              v-for="(item, idx) in chartData"
              :key="item.date"
              class="tick-col clickable"
              role="button"
              tabindex="0"
              :aria-label="`Lihat kehadiran ${item.label}`"
              @click="selectTrendDay(item)"
              @keydown.enter="selectTrendDay(item)"
              @keydown.space.prevent="selectTrendDay(item)"
            >
              <div
                v-if="idx === selectedIndex || (selectedIndex === -1 && idx === highlightIndex)"
                class="tick-tooltip"
              >
                <template v-if="item.date === new Date().toLocaleDateString('sv-SE')">
                  <span>Hari</span>
                  <span>Ini</span>
                </template>
                <template v-else>
                  <span>{{ item.date }}</span>
                </template>
              </div>
              <div class="tick-value">{{ item.count ?? 0 }}</div>
              <div
                class="tick"
                :class="{
                  active: idx === selectedIndex || (selectedIndex === -1 && idx === highlightIndex),
                }"
                :style="{ height: (((item.count ?? 0) / chartMax) * 100 || 10) + '%' }"
              ></div>
              <div class="tick-label">{{ item.label }}</div>
            </div>
          </div>
        </div>
      </div>
    </section>

    <section class="panel table-panel">
      <div class="table-head">
        <h2>Aktivitas Absensi ({{ activityPeriodLabel }})</h2>
        <div class="table-tools">
          <div class="search">
            <Icon icon="material-symbols:search-rounded" width="18" height="18" />
            <input type="text" v-model="searchQuery" placeholder="Cari nama karyawan..." />
          </div>
          <div class="icon-btn">
            <Icon icon="material-symbols:filter-list-rounded" width="18" height="18" />
          </div>
        </div>
      </div>

      <table>
        <thead>
          <tr>
            <th>Nama Karyawan</th>
            <th>Lokasi Cabang</th>
            <th>Jam Check In</th>
            <th>Jam Check Out</th>
            <th>Status</th>
          </tr>
        </thead>
        <tbody>
          <tr v-if="loading">
            <td colspan="5" style="text-align: center; color: var(--ink-soft); padding: 32px">
              Memuat data...
            </td>
          </tr>
          <tr v-else-if="filteredEmployees.length === 0">
            <td colspan="5" style="text-align: center; color: var(--ink-soft); padding: 32px">
              Tidak ada karyawan ditemukan.
            </td>
          </tr>
          <tr v-for="emp in filteredEmployees" :key="emp.id">
            <td>
              <div class="emp">
                <div class="emp-avatar">{{ initials(emp.name) }}</div>
                <div>
                  <div class="emp-name">{{ emp.name }}</div>
                  <div class="emp-id">ID: {{ emp.id }}</div>
                </div>
              </div>
            </td>
            <td>{{ emp.location }}</td>
            <td>
              <span v-if="emp.checkIn">{{ emp.checkIn }}</span>
              <span v-else class="dash">--:--</span>
            </td>
            <td>
              <span v-if="emp.status === 'working'" class="badge working dot">Sedang Bekerja</span>
              <span v-else-if="emp.checkOut">{{ emp.checkOut }}</span>
              <span v-else class="dash">--:--</span>
            </td>
            <td>
              <span class="badge" :class="statusMeta[emp.status]?.cls">{{
                statusMeta[emp.status]?.label
              }}</span>
            </td>
          </tr>
        </tbody>
      </table>

      <div class="table-footer">
        <div class="table-footer-content">
          <div class="pager">
            <button
              type="button"
              class="pager-btn"
              :disabled="currentPage === 1 || loading"
              @click="prevPage"
              title="Halaman Sebelumnya"
            >
              <Icon icon="material-symbols:chevron-left-rounded" width="18" height="18" />
            </button>

            <div class="page-input-wrapper">
              <span>Halaman</span>
              <input
                type="number"
                v-model.number="pageInput"
                @keydown.enter="goToInputPage"
                @blur="goToInputPage"
                min="1"
                :max="lastPage"
                class="page-input"
              />
              <span>dari {{ lastPage }}</span>
            </div>

            <button
              type="button"
              class="pager-btn"
              :disabled="currentPage === lastPage || loading"
              @click="nextPage"
              title="Halaman Berikutnya"
            >
              <Icon icon="material-symbols:chevron-right-rounded" width="18" height="18" />
            </button>
          </div>

          <div class="per-page-select">
            <select v-model="perPage" @change="changePerPage" :disabled="loading">
              <option :value="10">10 baris</option>
              <option :value="20">20 baris</option>
              <option :value="50">50 baris</option>
              <option :value="100">100 baris</option>
            </select>
          </div>

          <span class="total-records-info">{{ employees.length }} catatan</span>
        </div>
      </div>
    </section>
  </div>
</template>

<style scoped>
.dashboard {
  --blue-900: #2f3b69;
  --blue-50: #eef0f7;
  --gold: #f6c453;
  --gold-dark: #e7ae3e;
  --red: #d91e2e;
  --red-bg: #fdebed;
  --amber-bg: #fff0c7;
  --amber-text: #9a6900;
  --mint-bg: #ddf5ec;
  --mint-text: #177a5b;
  --ink: #1c1c19;
  --ink-soft: #667085;
  --line: #d9dde5;
  --bg: #f7f8fa;
  --card: #ffffff;
  font-family: 'Plus Jakarta Sans', sans-serif;
}
.dashboard * {
  box-sizing: border-box;
  font-family: 'Plus Jakarta Sans', sans-serif;
}
.dashboard button,
.dashboard input,
.dashboard select,
.dashboard textarea {
  font-family: 'Plus Jakarta Sans', sans-serif;
}

.filterbar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 20px;
  flex-wrap: wrap;
  gap: 12px;
}
.filterbar-left {
  display: flex;
  align-items: center;
  gap: 16px;
  flex-wrap: wrap;
}
.select {
  position: relative;
  display: flex;
  align-items: center;
  gap: 8px;
  background: #fff;
  border: 1px solid var(--line);
  padding: 10px 14px;
  border-radius: 10px;
  font-size: 14px;
  font-weight: 500;
  cursor: pointer;
  min-width: 150px;
  justify-content: space-between;
}
.select-menu {
  position: absolute;
  z-index: 20;
  top: calc(100% + 8px);
  left: 0;
  width: 100%;
  background: #fff;
  border: 1px solid var(--line);
  border-radius: 12px;
  box-shadow: 0 16px 30px rgba(0, 0, 0, 0.08);
  padding: 6px 0;
}
.select-item {
  width: 100%;
  border: none;
  background: transparent;
  text-align: left;
  padding: 10px 14px;
  font-size: 14px;
  color: var(--ink);
  cursor: pointer;
}
.select-item:hover {
  background: var(--blue-50);
}
.select svg,
.select .iconify {
  width: 14px;
  height: 14px;
  stroke: var(--ink-soft);
  color: var(--ink-soft);
}
.segmented {
  display: flex;
  background: #fff;
  border: 1px solid var(--line);
  border-radius: 10px;
  padding: 4px;
  gap: 2px;
}
.segmented button {
  border: none;
  background: none;
  padding: 9px 16px;
  border-radius: 8px;
  font-size: 14px;
  font-weight: 600;
  color: var(--ink-soft);
  cursor: pointer;
}
.segmented button.active {
  background: var(--blue-900);
  color: #fff;
}
.date-pill {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 14px;
  font-weight: 600;
  color: var(--ink);
}
.date-pill svg,
.date-pill .iconify {
  width: 16px;
  height: 16px;
  stroke: var(--ink-soft);
  color: var(--ink-soft);
}

.stats {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 18px;
  margin-bottom: 20px;
}
.stat-card {
  background: var(--card);
  border: 1px solid var(--line);
  border-radius: 16px;
  padding: 20px 20px 18px;
}
.stat-top {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 22px;
}
.stat-icon {
  width: 38px;
  height: 38px;
  border-radius: 10px;
  background: var(--blue-50);
  display: flex;
  align-items: center;
  justify-content: center;
}
.stat-icon svg,
.stat-icon .iconify {
  width: 19px;
  height: 19px;
  stroke: var(--blue-900);
  color: var(--blue-900);
}
.stat-card.alert .stat-icon {
  background: var(--red-bg);
}
.stat-card.alert .stat-icon svg,
.stat-card.alert .stat-icon .iconify {
  stroke: var(--red);
  color: var(--red);
}
.tag {
  font-size: 10.5px;
  font-weight: 700;
  letter-spacing: 0.05em;
  color: var(--ink-soft);
  background: var(--bg);
  padding: 4px 9px;
  border-radius: 6px;
}
.tag.alert {
  color: var(--red);
  background: var(--red-bg);
}
.stat-label {
  font-size: 13.5px;
  color: var(--ink-soft);
  margin-bottom: 6px;
  font-weight: 500;
}
.stat-value {
  font-size: 30px;
  font-weight: 800;
  letter-spacing: -0.02em;
  margin-bottom: 10px;
}
.stat-value.danger {
  color: var(--red);
}
.stat-sub {
  font-size: 12.5px;
  color: var(--ink-soft);
  font-weight: 500;
}
.stat-sub.up {
  color: var(--blue-900);
}
.progress {
  height: 6px;
  background: var(--bg);
  border-radius: 6px;
  overflow: hidden;
  margin-bottom: 8px;
}
.progress > span {
  display: block;
  height: 100%;
  background: var(--blue-900);
}
.mini-avatars {
  display: flex;
  align-items: center;
  gap: 6px;
}
.mini-avatars .dots {
  display: flex;
}
.mini-avatars .dots span {
  width: 20px;
  height: 20px;
  border-radius: 50%;
  border: 2px solid #fff;
  margin-left: -7px;
}
.mini-avatars .dots span:first-child {
  margin-left: 0;
  background: #f0c98a;
}
.mini-avatars .dots span:nth-child(2) {
  background: #8ad0c4;
}
.mini-avatars .dots span:nth-child(3) {
  background: #c9c9c9;
}

.middle-row {
  display: grid;
  grid-template-columns: 1fr;
  gap: 18px;
  margin-bottom: 20px;
  align-items: stretch;
}
.panel {
  background: var(--card);
  border: 1px solid var(--line);
  border-radius: 16px;
  padding: 22px 24px;
}
.panel-head {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 6px;
}
.panel-head h2 {
  font-size: 16px;
  font-weight: 700;
  margin: 0 0 4px;
}
.panel-head p {
  font-size: 13px;
  color: var(--ink-soft);
  margin: 0;
}
.chart-wrap {
  margin-top: 22px;
  height: 190px;
}
.chart-ticks {
  display: flex;
  width: 100%;
  height: 100%;
}
.tick-col {
  flex: 1;
  display: flex;
  flex-direction: column;
  justify-content: flex-end;
  align-items: center;
  position: relative;
}
.tick-col.clickable {
  cursor: pointer;
  border-radius: 10px;
}
.tick-col.clickable:hover .tick {
  background: var(--blue-900);
  transform: translateY(-2px);
}
.tick-col.clickable:focus-visible {
  outline: 2px solid var(--blue-900);
  outline-offset: 4px;
}
.tick-value {
  font-size: 12px;
  color: var(--ink-soft);
  margin-bottom: 8px;
}
.tick {
  width: 72%;
  max-width: 92px;
  border-radius: 4px;
  background: #e1e4eb;
  position: relative;
  transition:
    background 0.15s ease,
    transform 0.15s ease;
}
.tick.active {
  background: var(--blue-900);
}
.tick-label {
  margin-top: 10px;
  font-size: 12px;
  color: var(--ink-soft);
}
.tick-tooltip {
  position: relative;
  background: #1c2521;
  color: #fff;
  border-radius: 9px;
  padding: 8px 12px;
  margin-bottom: 12px;
  font-size: 11px;
  font-weight: 600;
  line-height: 1.35;
  text-align: center;
}
.tick-tooltip::after {
  content: '';
  position: absolute;
  left: 50%;
  bottom: -14px;
  width: 1px;
  height: 14px;
  background: #d8d6cf;
  transform: translateX(-50%);
}

.table-panel {
  padding: 22px 0 0;
}
.table-head {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 0 24px 18px;
  flex-wrap: wrap;
  gap: 12px;
}
.table-head h2 {
  font-size: 16px;
  font-weight: 700;
  margin: 0;
}
.table-tools {
  display: flex;
  gap: 10px;
  align-items: center;
}
.search {
  display: flex;
  align-items: center;
  gap: 8px;
  background: var(--bg);
  border: 1px solid var(--line);
  padding: 9px 14px;
  border-radius: 10px;
  min-width: 230px;
}
.search svg,
.search .iconify {
  width: 15px;
  height: 15px;
  stroke: var(--ink-soft);
  color: var(--ink-soft);
  flex-shrink: 0;
}
.search input {
  border: none;
  background: none;
  outline: none;
  font-size: 13.5px;
  width: 100%;
  font-family: inherit;
  color: var(--ink);
}
.icon-btn {
  width: 38px;
  height: 38px;
  border-radius: 10px;
  background: var(--bg);
  border: 1px solid var(--line);
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  flex-shrink: 0;
}
.icon-btn svg,
.icon-btn .iconify {
  width: 16px;
  height: 16px;
  stroke: var(--ink-soft);
  color: var(--ink-soft);
}

table {
  width: 100%;
  border-collapse: collapse;
}
thead tr {
  background: var(--blue-900);
}
thead th {
  color: #dfe9e3;
  font-size: 11.5px;
  font-weight: 700;
  letter-spacing: 0.06em;
  text-align: left;
  padding: 13px 24px;
  text-transform: uppercase;
}
tbody td {
  padding: 16px 24px;
  font-size: 14px;
  border-bottom: 1px solid var(--line);
  vertical-align: middle;
  color: var(--ink);
}
tbody tr:last-child td {
  border-bottom: none;
}
.emp {
  display: flex;
  align-items: center;
  gap: 12px;
}
.emp-avatar {
  width: 38px;
  height: 38px;
  border-radius: 50%;
  background: #e9e8e3;
  color: #4b5450;
  font-weight: 700;
  font-size: 12.5px;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}
.emp-name {
  font-weight: 700;
  font-size: 14px;
}
.emp-id {
  font-size: 12px;
  color: var(--ink-soft);
}
.dash {
  color: var(--red);
  font-weight: 600;
}
.badge {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  font-size: 12px;
  font-weight: 700;
  padding: 6px 12px;
  border-radius: 20px;
}
.badge.dot::before {
  content: '';
  width: 6px;
  height: 6px;
  border-radius: 50%;
  background: var(--amber-text);
}
.badge.checkout {
  background: var(--mint-bg);
  color: var(--mint-text);
}
.badge.checkin {
  background: var(--mint-bg);
  color: var(--mint-text);
}
.badge.working {
  background: var(--amber-bg);
  color: var(--amber-text);
}
.badge.absent {
  background: var(--red-bg);
  color: var(--red);
}

.table-footer {
  display: flex;
  justify-content: flex-end;
  align-items: center;
  padding: 12px 20px;
  font-size: 13px;
  color: var(--ink-soft);
  border-top: 1px solid var(--line);
  background: var(--bg);
  border-radius: 0 0 15px 15px;
}

.table-footer-content {
  display: flex;
  align-items: center;
  gap: 16px;
}

.pager {
  display: flex;
  align-items: center;
  gap: 6px;
}

.pager-btn {
  width: 32px;
  height: 32px;
  border-radius: 6px;
  border: 1px solid var(--line);
  background: var(--card);
  display: inline-flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  transition: all 0.15s ease;
  color: var(--ink-soft);
}

.pager-btn:hover:not(:disabled) {
  background: #fff;
  border-color: var(--blue-900);
  color: var(--blue-900);
}

.pager-btn:disabled {
  opacity: 0.4;
  cursor: not-allowed;
}

.page-input-wrapper {
  display: flex;
  align-items: center;
  gap: 6px;
  font-weight: 600;
  color: var(--ink-soft);
  font-size: 13px;
}

.page-input {
  font-family: 'Plus Jakarta Sans', sans-serif;
  width: 44px;
  height: 32px;
  text-align: center;
  border: 1px solid var(--line);
  border-radius: 6px;
  background: var(--card);
  color: var(--ink);
  font-weight: 700;
  font-size: 13px;
  outline: none;
  -moz-appearance: textfield;
}

.page-input::-webkit-outer-spin-button,
.page-input::-webkit-inner-spin-button {
  -webkit-appearance: none;
  margin: 0;
}

.page-input:focus {
  border-color: var(--blue-900);
  box-shadow: 0 0 0 2px rgba(47, 59, 105, 0.12);
}

.per-page-select select {
  height: 32px;
  padding: 0 10px;
  border: 1px solid var(--line);
  border-radius: 6px;
  background: var(--card);
  color: var(--ink);
  font-size: 13px;
  font-weight: 600;
  cursor: pointer;
  outline: none;
  font-family: 'Plus Jakarta Sans', sans-serif !important;
}

.per-page-select select:focus {
  border-color: var(--blue-900);
}

.per-page-select select option {
  font-family: 'Plus Jakarta Sans', sans-serif !important;
  font-size: 13px;
  font-weight: 600;
  color: var(--ink);
  background: var(--card);
}

.total-records-info {
  font-size: 13px;
  font-weight: 600;
  color: var(--ink-soft);
  white-space: nowrap;
}

@media (max-width: 1100px) {
  .stats {
    grid-template-columns: repeat(2, 1fr);
  }
  .middle-row {
    grid-template-columns: 1fr;
  }
}
@media (max-width: 600px) {
  .stats {
    grid-template-columns: 1fr;
  }
}
</style>
