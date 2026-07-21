<script setup>
import { ref, computed, onMounted } from 'vue'
import { Icon } from '@iconify/vue'
import api from '../api'

/*
  View ini cuma berisi KONTEN halaman (filter, kartu statistik, chart,
  insight, tabel). Sidebar & topbar sudah ditangani MainLayout.vue lewat
  router-view, jadi tidak diulang di sini — ikut pola project satunya
  (lihat layouts/MainLayout.vue di sana).
*/

const locationLabel = ref('Semua Lokasi')

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
const weeklyAverageLabel = ref('')
const insight = ref({ summary: '', topPerformerLabel: '', needAttentionLabel: '' })
const employees = ref([])
const loading = ref(false)

const statusMeta = {
  checkout: { label: 'Check Out', cls: 'checkout' },
  checkin: { label: 'Check In', cls: 'checkin' },
  working: { label: 'Sedang Bekerja', cls: 'working dot' },
  absent: { label: 'Belum Hadir', cls: 'absent' },
}

const chartDayLabels = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min']
const highlightIndex = computed(() => chartDayLabels.length - 1) // default: hari terakhir

const periods = [
  { key: 'hari', label: 'Hari Ini' },
  { key: 'minggu', label: 'Minggu Ini' },
  { key: 'bulan', label: 'Bulan Ini' },
]
const activePeriod = ref('hari')

const searchQuery = ref('')

const filteredEmployees = computed(() => {
  const q = searchQuery.value.trim().toLowerCase()
  if (!q) return employees.value
  return employees.value.filter((e) => e.name.toLowerCase().includes(q))
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

async function fetchDashboard(period = 'hari') {
  loading.value = true
  try {
    // TODO: sesuaikan endpoint dengan API yang disediakan tim backend
    const res = await api.get('/dashboard', { params: { period } })
    const data = res.data
    currentDate.value = data.currentDate
    locationLabel.value = data.locationLabel
    stats.value = data.stats
    weeklyAverageLabel.value = data.weeklyAverageLabel
    insight.value = data.insight
    employees.value = data.employees
  } catch (err) {
    console.error('Gagal mengambil data dashboard:', err)
  } finally {
    loading.value = false
  }
}

async function searchEmployees(query) {
  try {
    // TODO: kalau pencarian dilakukan di server, panggil endpoint terpisah di sini
    const res = await api.get('/dashboard/employees', { params: { q: query } })
    employees.value = res.data.employees
  } catch (err) {
    console.error('Gagal mencari karyawan:', err)
  }
}

function onSearchInput() {
  searchEmployees(searchQuery.value)
}

function selectPeriod(key) {
  activePeriod.value = key
  fetchDashboard(key)
}

function handleDownloadPdf() {
  // TODO: panggil endpoint generate laporan PDF
  alert('Mengunduh Laporan PDF...')
}

onMounted(() => {
  fetchDashboard('hari')
})
</script>

<template>
  <div class="dashboard">
    <div class="filterbar">
      <div class="filterbar-left">
        <div class="select">
          <span>{{ locationLabel }}</span>
          <Icon icon="material-symbols:keyboard-arrow-down-rounded" width="18" height="18" />
        </div>
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
          <a class="link">Lihat Detail ›</a>
        </div>
        <div class="chart-wrap">
          <div class="chart-ticks">
            <div v-for="(d, idx) in chartDayLabels" :key="idx" class="tick-col">
              <div v-if="idx === highlightIndex" class="tick-tooltip">
                <span>Hari</span>
                <span>Ini</span>
              </div>
              <div class="tick" :class="{ active: idx === highlightIndex }"></div>
            </div>
          </div>
        </div>
        <div class="chart-days">
          <span v-for="(d, idx) in chartDayLabels" :key="idx">{{ d }}</span>
        </div>
      </div>

      <div class="panel insight">
        <h2>Insight Operasional</h2>
        <p class="desc">{{ insight.summary }}</p>

        <div class="insight-item">
          <div class="ic"><Icon icon="material-symbols:star-rounded" width="18" height="18" /></div>
          <div>
            <div class="lbl">TOP PERFORMER</div>
            <div class="val">{{ insight.topPerformerLabel }}</div>
          </div>
        </div>

        <div class="insight-item">
          <div class="ic">
            <Icon icon="material-symbols:warning-outline-rounded" width="18" height="18" />
          </div>
          <div>
            <div class="lbl">NEED ATTENTION</div>
            <div class="val">{{ insight.needAttentionLabel }}</div>
          </div>
        </div>

        <button class="insight-cta" @click="handleDownloadPdf">Unduh Laporan PDF</button>
      </div>
    </section>

    <section class="panel table-panel">
      <div class="table-head">
        <h2>Aktivitas Absensi Hari Ini</h2>
        <div class="table-tools">
          <div class="search">
            <Icon icon="material-symbols:search-rounded" width="18" height="18" />
            <input
              type="text"
              v-model="searchQuery"
              @input="onSearchInput"
              placeholder="Cari nama karyawan..."
            />
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
        <span
          >Menampilkan {{ filteredEmployees.length }} dari {{ stats.totalEmployees }} karyawan</span
        >
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
.dashboard {
  --green-900: #173d31;
  --green-50: #f2f7f4;
  --gold: #eaa93d;
  --gold-dark: #d99524;
  --red: #dc4646;
  --red-bg: #fdeaea;
  --amber-bg: #fdf1d6;
  --amber-text: #a9721a;
  --mint-bg: #e1f3ea;
  --mint-text: #1c7a52;
  --ink: #1c2521;
  --ink-soft: #5b6864;
  --line: #e7e7e2;
  --bg: #ffffff;
  --card: #ffffff;
}
.dashboard * {
  box-sizing: border-box;
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
  display: flex;
  align-items: center;
  gap: 8px;
  background: #fff;
  border: 2px solid var(--line);
  padding: 10px 14px;
  border-radius: 10px;
  font-size: 14px;
  font-weight: 500;
  cursor: pointer;
  min-width: 150px;
  justify-content: space-between;
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
  border: 2px solid var(--line);
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
  color: #5b6864;
  cursor: pointer;
}
.segmented button.active {
  background: var(--green-900);
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
  border: 2px solid var(--line);
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
  background: var(--green-50);
  display: flex;
  align-items: center;
  justify-content: center;
}
.stat-icon svg,
.stat-icon .iconify {
  width: 19px;
  height: 19px;
  stroke: var(--green-900);
  color: var(--green-900);
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
  color: #1c7a52;
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
  background: var(--green-900);
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
  grid-template-columns: 1.65fr 1fr;
  gap: 18px;
  margin-bottom: 20px;
  align-items: stretch;
}
.panel {
  background: var(--card);
  border: 2px solid var(--line);
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
.link {
  font-size: 13px;
  font-weight: 600;
  color: var(--green-900);
  cursor: pointer;
  text-decoration: none;
  white-space: nowrap;
}
.trend-panel {
  display: flex;
  flex-direction: column;
}
.chart-wrap {
  flex: 1;
  display: flex;
  align-items: flex-end;
  margin-top: 22px;
  min-height: 40px;
}
.chart-ticks {
  display: flex;
  width: 100%;
  align-items: flex-end;
}
.tick-col {
  flex: 1;
  display: flex;
  justify-content: center;
  position: relative;
}
.tick-tooltip {
  position: absolute;
  bottom: 100%;
  left: 50%;
  transform: translateX(-50%);
  margin-bottom: 12px;
  background: #1c2521;
  color: #fff;
  border-radius: 9px;
  padding: 8px 12px;
  font-size: 11px;
  font-weight: 600;
  line-height: 1.35;
  text-align: center;
  white-space: nowrap;
  display: flex;
  flex-direction: column;
  align-items: center;
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
.tick {
  width: 72%;
  max-width: 92px;
  height: 6px;
  border-radius: 4px;
  background: #ecece6;
}
.tick.active {
  background: var(--green-900);
}
.chart-days {
  display: flex;
  margin-top: 8px;
  font-size: 12.5px;
  color: var(--ink-soft);
  font-weight: 500;
}
.chart-days span {
  flex: 1;
  text-align: center;
}

.insight {
  background: linear-gradient(165deg, var(--green-900), #0f2b22);
  color: #fff;
  border: none;
  display: flex;
  flex-direction: column;
  position: relative;
  overflow: hidden;
}
.insight::after {
  content: '';
  position: absolute;
  right: -40px;
  bottom: -40px;
  width: 140px;
  height: 140px;
  border-radius: 50%;
  border: 2px solid rgba(255, 255, 255, 0.12);
  pointer-events: none;
}
.insight h2 {
  font-size: 16px;
  font-weight: 700;
  margin: 0 0 12px;
  color: #fff;
}
.insight p.desc {
  font-size: 13.5px;
  line-height: 1.55;
  color: #cfe0d7;
  margin: 0 0 18px;
}
.insight-item {
  background: rgba(255, 255, 255, 0.07);
  border-radius: 12px;
  padding: 12px 14px;
  display: flex;
  gap: 12px;
  align-items: flex-start;
  margin-bottom: 12px;
}
.insight-item .ic {
  width: 30px;
  height: 30px;
  border-radius: 8px;
  background: rgba(255, 255, 255, 0.12);
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}
.insight-item .ic svg,
.insight-item .ic .iconify {
  width: 16px;
  height: 16px;
  stroke: #eaa93d;
  color: #eaa93d;
}
.insight-item .lbl {
  font-size: 10.5px;
  font-weight: 700;
  letter-spacing: 0.05em;
  color: #a9c2b6;
  margin-bottom: 2px;
}
.insight-item .val {
  font-size: 13.5px;
  font-weight: 600;
  color: #fff;
}
.insight-cta {
  margin-top: auto;
  background: var(--gold);
  color: #3b2a05;
  border: none;
  padding: 13px;
  border-radius: 11px;
  font-size: 14px;
  font-weight: 700;
  cursor: pointer;
  transition: background 0.15s ease;
}
.insight-cta:hover {
  background: var(--gold-dark);
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
  align-items: left;
}
.search {
  display: flex;
  align-items: center;
  gap: 8px;
  background: var(--bg);
  border: 2px solid var(--line);
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
  border: 2px solid var(--line);
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
  background: var(--green-900);
}
thead th {
  color: #dfe9e3;
  font-size: 11.5px;
  font-weight: 700;
  letter-spacing: 0.06em;
  padding: 13px 24px;
  text-transform: uppercase;
  text-align: left; /* default semua ke kiri */
}
/* Nama Karyawan */
thead th:nth-child(1) {
  text-align: left;
}

/* Lokasi Cabang */
thead th:nth-child(2) {
  text-align: left;
}

/* Jam Check In */
thead th:nth-child(3) {
  text-align: left;
}

/* Jam Check Out */
thead th:nth-child(4) {
  text-align: left;
}

/* Status */
thead th:nth-child(5) {
  text-align: center;
}
tbody td {
  padding: 16px 24px;
  font-size: 14px;
  border-bottom: 2px solid var(--line);
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
  justify-content: space-between;
  align-items: center;
  padding: 16px 24px;
  font-size: 13px;
  color: var(--ink-soft);
  border-top: 2px solid var(--line);
  background: #f6f5f1;
}
.pager {
  display: flex;
  gap: 8px;
}
.pager button {
  width: 32px;
  height: 32px;
  border-radius: 8px;
  border: 2px solid var(--line);
  background: #fff;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
}
.pager button svg,
.pager button .iconify {
  width: 14px;
  height: 14px;
  stroke: var(--ink-soft);
  color: var(--ink-soft);
}
.pager button:disabled {
  opacity: 0.4;
  cursor: not-allowed;
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