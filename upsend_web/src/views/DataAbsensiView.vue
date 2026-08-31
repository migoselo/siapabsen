<script setup>
import { ref, computed, watch, onMounted, onBeforeUnmount } from 'vue'
import { Icon } from '@iconify/vue'
import api from '../api'

const records = ref([])
const loading = ref(false)

const currentPage = ref(1)
const lastPage = ref(1)
const totalRecords = ref(0)
const perPage = ref(20)
const pageInput = ref(1)

const locations = ref([])
const filter = ref({ period: 'all', startDate: '', endDate: '', location_id: '' })
const searchQuery = ref('')
const showLocationMenu = ref(false)

const periodOptions = [
  { value: 'all', label: 'Semua' },
  { value: 'today', label: 'Hari Ini' },
  { value: 'week', label: 'Minggu Ini' },
  { value: 'month', label: 'Bulan Ini' },
  { value: 'custom', label: 'Custom' },
]
const quickPeriodOptions = periodOptions.slice(0, 4)
const customPreviousPeriod = ref('all')
const customStartDate = ref('')
const customEndDate = ref('')
const showCustomPanel = ref(false)
const activeDateField = ref('start')
const showCalendar = ref(false)
const visibleMonth = ref(new Date())
const weekdayLabels = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab']
const monthFormatter = new Intl.DateTimeFormat('id-ID', { month: 'long', year: 'numeric' })

const calendarMonthLabel = computed(() => monthFormatter.format(visibleMonth.value))
const todayDateValue = computed(() => formatDateInput(new Date()))
const calendarDays = computed(() => {
  const year = visibleMonth.value.getFullYear()
  const month = visibleMonth.value.getMonth()
  const firstDay = new Date(year, month, 1).getDay()

  return Array.from({ length: 42 }, (_, index) => {
    const date = new Date(year, month, index - firstDay + 1)
    const value = formatDateInput(date)
    const otherDate = activeDateField.value === 'start' ? customEndDate.value : customStartDate.value
    const disabledByRange = activeDateField.value === 'start'
      ? Boolean(otherDate && value > otherDate)
      : Boolean(otherDate && value < otherDate)
    const disabled = value > todayDateValue.value || disabledByRange

    return {
      day: date.getDate(),
      value,
      isCurrentMonth: date.getMonth() === month,
      isToday: value === formatDateInput(new Date()),
      isSelected: value === (activeDateField.value === 'start' ? customStartDate.value : customEndDate.value),
      disabled,
    }
  })
})

const locationLabel = computed(() => {
  if (!filter.value.location_id) return 'Semua Lokasi'
  const location = locations.value.find((item) => item.id === Number(filter.value.location_id))
  return location?.name || 'Semua Lokasi'
})

const periodFilteredRecords = computed(() => {
  const dateRange = dateRangeForPeriod()
  return records.value.filter((record) => {
    if (!dateRange.startDate || !dateRange.endDate) return true
    const recordDate = String(
      record.date || record.attendance_date || record.check_in_time || '',
    ).slice(0, 10)
    return recordDate >= dateRange.startDate && recordDate <= dateRange.endDate
  })
})

const filteredRecords = computed(() => {
  const query = searchQuery.value.trim().toLowerCase()
  if (!query) return periodFilteredRecords.value
  return periodFilteredRecords.value.filter((record) =>
    record.employee?.name?.toLowerCase().includes(query),
  )
  return result.slice(0, perPage.value)
})

function isLate(record) {
  if (!record.check_in_time) return false
  const checkIn = new Date(record.check_in_time)
  return checkIn.getHours() >= 9
}

function isOvertime(record) {
  const status = String(record.status || '').toLowerCase()
  return record.is_overtime === true || status === 'overtime' || status === 'lembur'
}

const summary = computed(() => ({
  total: totalRecords.value,
  onTime: periodFilteredRecords.value.filter((record) => record.check_in_time && !isLate(record)).length,
  late: periodFilteredRecords.value.filter((record) => isLate(record)).length,
  missed: periodFilteredRecords.value.filter((record) => !record.check_in_time).length,
  overtime: periodFilteredRecords.value.filter((record) => isOvertime(record)).length,
}))

function formatTime(value) {
  return value
    ? new Date(value).toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit' })
    : '--:--'
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

function formatDateInput(date) {
  const year = date.getFullYear()
  const month = String(date.getMonth() + 1).padStart(2, '0')
  const day = String(date.getDate()).padStart(2, '0')
  return `${year}-${month}-${day}`
}

function formatDateDisplay(value) {
  if (!value) return 'dd / mm / yyyy'
  const [year, month, day] = value.split('-')
  return `${day} / ${month} / ${year}`
}

function parseDateInput(value) {
  if (!value) return new Date()
  const [year, month, day] = value.split('-').map(Number)
  return new Date(year, month - 1, day)
}

function openCalendar(field) {
  activeDateField.value = field
  const value = field === 'start' ? customStartDate.value : customEndDate.value
  visibleMonth.value = parseDateInput(value)
  showCalendar.value = true
}

function changeCalendarMonth(offset) {
  visibleMonth.value = new Date(
    visibleMonth.value.getFullYear(),
    visibleMonth.value.getMonth() + offset,
    1,
  )
}

function selectCalendarDate(day) {
  if (day.disabled || !day.isCurrentMonth) return
  if (activeDateField.value === 'start') {
    customStartDate.value = day.value
  } else {
    customEndDate.value = day.value
  }
  showCalendar.value = false
}

function dateRangeForPeriod() {
  const today = new Date()
  const todayValue = formatDateInput(today)

  if (filter.value.period === 'all') {
    return { startDate: '', endDate: '' }
  }

  if (filter.value.period === 'today') {
    return { startDate: todayValue, endDate: todayValue }
  }

  if (filter.value.period === 'week') {
    const start = new Date(today)
    const day = start.getDay()
    const daysSinceMonday = day === 0 ? 6 : day - 1
    start.setDate(today.getDate() - daysSinceMonday)
    const end = new Date(start)
    end.setDate(start.getDate() + 6)
    return { startDate: formatDateInput(start), endDate: formatDateInput(end) }
  }

  if (filter.value.period === 'month') {
    return {
      startDate: formatDateInput(new Date(today.getFullYear(), today.getMonth(), 1)),
      endDate: formatDateInput(new Date(today.getFullYear(), today.getMonth() + 1, 0)),
    }
  }

  return { startDate: filter.value.startDate, endDate: filter.value.endDate }
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
  // Jangan kosongkan records.value di sini agar tinggi tabel tidak anjlok
  try {
    const params = {
      page,
      per_page: perPage.value,
    }
    const dateRange = dateRangeForPeriod()
    if (dateRange.startDate && dateRange.endDate) {
      params.start_date = dateRange.startDate
      params.end_date = dateRange.endDate
      if (filter.value.period === 'today') params.date = dateRange.startDate
    }
    if (filter.value.location_id) params.location_id = filter.value.location_id

    const res = await api.get('/attendances', { params })
    records.value = res.data.data || []
    totalRecords.value = res.data.total || 0
    currentPage.value = res.data.current_page || page
    lastPage.value = res.data.last_page || 1
    pageInput.value = currentPage.value
  } catch (err) {
    console.error('Gagal mengambil data absensi:', err)
  } finally {
    loading.value = false
  }
}

watch(currentPage, (newPage) => {
  pageInput.value = newPage
})

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

function goToInputPage() {
  let page = Number(pageInput.value)
  if (isNaN(page) || page < 1) page = 1
  if (page > lastPage.value) page = lastPage.value
  pageInput.value = page
  if (page !== currentPage.value) {
    fetchAttendance(page)
  }
}

function changePerPage() {
  fetchAttendance(1)
}

function applyFilters() {
  if (
    filter.value.period === 'custom' &&
    (!filter.value.startDate ||
      !filter.value.endDate ||
      filter.value.startDate > filter.value.endDate ||
      filter.value.startDate > todayDateValue.value ||
      filter.value.endDate > todayDateValue.value)
  )
    return
  fetchAttendance(1)
}

function selectPeriod(period) {
  if (period === 'custom') {
    customPreviousPeriod.value =
      filter.value.period === 'custom' ? customPreviousPeriod.value : filter.value.period
    customStartDate.value = filter.value.startDate
    customEndDate.value = filter.value.endDate
    filter.value.period = period
    showCustomPanel.value = true
    return
  }

  filter.value.period = period
  showCustomPanel.value = false
  if (period !== 'custom') applyFilters()
}

function cancelCustomPeriod() {
  filter.value.period = customPreviousPeriod.value
  customStartDate.value = filter.value.startDate
  customEndDate.value = filter.value.endDate
  showCustomPanel.value = false
}

function saveCustomPeriod() {
  if (
    !customStartDate.value ||
    !customEndDate.value ||
    customStartDate.value > customEndDate.value ||
    customStartDate.value > todayDateValue.value ||
    customEndDate.value > todayDateValue.value
  )
    return
  filter.value.startDate = customStartDate.value
  filter.value.endDate = customEndDate.value
  filter.value.period = 'custom'
  showCalendar.value = false
  showCustomPanel.value = false
  fetchAttendance(1)
}

function toggleLocationMenu() {
  showLocationMenu.value = !showLocationMenu.value
}

function closeLocationMenu() {
  showLocationMenu.value = false
  showCalendar.value = false
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
      <div class="summary-card">
        <div class="summary-top">
          <div class="summary-icon green"><Icon icon="material-symbols:groups-outline" /></div>
          <span class="summary-tag green">TOTAL</span>
        </div>
        <span class="summary-label">Tepat Waktu</span><strong>{{ summary.onTime }}</strong
        ><small>Check-in dan check-out tercatat</small>
      </div>
      <div class="summary-card">
        <div class="summary-top">
          <div class="summary-icon amber"><Icon icon="material-symbols:schedule-outline" /></div>
          <span class="summary-tag amber">STATUS</span>
        </div>
        <span class="summary-label">Terlambat</span
        ><strong class="amber-text">{{ summary.late }}</strong
        ><small>Check-in mulai pukul 09.00</small>
      </div>
      <div class="summary-card">
        <div class="summary-top">
          <div class="summary-icon red"><Icon icon="material-symbols:person-off-outline" /></div>
          <span class="summary-tag red">ALERT</span>
        </div>
        <span class="summary-label">Lupa Absen</span
        ><strong class="red-text">{{ summary.missed }}</strong
        ><small>Belum melakukan check-in</small>
      </div>
      <div class="summary-card">
        <div class="summary-top">
          <div class="summary-icon blue"><Icon icon="material-symbols:logout-rounded" /></div>
          <span class="summary-tag blue">SHIFT</span>
        </div>
        <span class="summary-label">Lembur</span
        ><strong class="blue-text">{{ summary.overtime }}</strong
        ><small>Sesuai penanda lembur</small>
      </div>
    </section>

    <section class="panel table-panel">
      <div class="filter-bar">
        <div class="period-filter">
          <span>Periode</span>
          <div class="period-controls">
            <div class="period-segmented">
              <button
                v-for="option in quickPeriodOptions"
                :key="option.value"
                type="button"
                :class="{ active: filter.period === option.value }"
                @click="selectPeriod(option.value)"
              >
                {{ option.label }}
              </button>
            </div>
            <div class="custom-period">
              <button
                type="button"
                class="custom-period-button"
                :class="{ active: filter.period === 'custom' }"
                @click="selectPeriod('custom')"
              >
                <Icon icon="material-symbols:calendar-today-outline" width="16" height="16" />
                Custom
              </button>
              <div v-if="showCustomPanel" class="custom-date-range">
                <div class="date-range-fields">
                  <label>
                    <span>Dari</span>
                    <button
                      type="button"
                      class="date-field"
                      :class="{ focused: activeDateField === 'start' && showCalendar }"
                      @click.stop="openCalendar('start')"
                    >
                      {{ formatDateDisplay(customStartDate) }}
                      <Icon icon="material-symbols:calendar-today-outline" width="16" height="16" />
                    </button>
                  </label>
                  <span class="range-separator">-</span>
                  <label>
                    <span>Sampai</span>
                    <button
                      type="button"
                      class="date-field"
                      :class="{ focused: activeDateField === 'end' && showCalendar }"
                      @click.stop="openCalendar('end')"
                    >
                      {{ formatDateDisplay(customEndDate) }}
                      <Icon icon="material-symbols:calendar-today-outline" width="16" height="16" />
                    </button>
                  </label>
                  <div
                    v-if="showCalendar"
                    class="calendar-popup"
                    :class="{ 'calendar-for-end': activeDateField === 'end' }"
                    @click.stop
                  >
                    <div class="calendar-header">
                      <button
                        type="button"
                        aria-label="Bulan sebelumnya"
                        @click="changeCalendarMonth(-1)"
                      >
                        <Icon icon="material-symbols:chevron-left-rounded" width="20" height="20" />
                      </button>
                      <strong>{{ calendarMonthLabel }}</strong>
                      <button
                        type="button"
                        aria-label="Bulan berikutnya"
                        @click="changeCalendarMonth(1)"
                      >
                        <Icon
                          icon="material-symbols:chevron-right-rounded"
                          width="20"
                          height="20"
                        />
                      </button>
                    </div>
                    <div class="calendar-weekdays">
                      <span v-for="weekday in weekdayLabels" :key="weekday">{{ weekday }}</span>
                    </div>
                    <div class="calendar-grid">
                      <button
                        v-for="day in calendarDays"
                        :key="day.value"
                        type="button"
                        class="calendar-day"
                        :class="{
                          muted: !day.isCurrentMonth,
                          today: day.isToday,
                          selected: day.isSelected,
                        }"
                        :disabled="day.disabled"
                        @click="selectCalendarDate(day)"
                      >
                        {{ day.day }}
                      </button>
                    </div>
                  </div>
                </div>
                <div class="custom-date-actions">
                  <button type="button" class="cancel-button" @click="cancelCustomPeriod">
                    Batal
                  </button>
                  <button
                    type="button"
                    class="save-button"
                    :disabled="
                      !customStartDate || !customEndDate || customStartDate > customEndDate
                    "
                    @click="saveCustomPeriod"
                  >
                    Simpan
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>
        <div class="location-select" @click.stop="toggleLocationMenu">
          <span>{{ locationLabel }}</span>
          <Icon icon="material-symbols:keyboard-arrow-down-rounded" width="18" height="18" />
          <div v-if="showLocationMenu" class="location-menu">
            <button type="button" class="location-item" @click.stop="selectLocation('')">
              Semua Lokasi
            </button>
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
        <button class="export-btn" type="button" @click="handleExport">
          <Icon icon="material-symbols:download-rounded" /> Export ke Excel
        </button>
      </div>
      <table>
        <thead>
          <tr>
            <th>Tanggal</th>
            <th>Nama Karyawan</th>
            <th>Lokasi</th>
            <th>Check In</th>
            <th>Check Out</th>
            <th>Status</th>
            <th>Detail</th>
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
            <td>
              {{
                record.check_in_time
                  ? new Date(record.check_in_time).toLocaleDateString('id-ID')
                  : '-'
              }}
            </td>
            <td>
              <div class="employee">
                <div class="employee-avatar">{{ initials(record.employee?.name) }}</div>
                <strong>{{ record.employee?.name || '—' }}</strong>
              </div>
            </td>
            <td>{{ record.location?.name || '—' }}</td>
            <td>{{ formatTime(record.check_in_time) }}</td>
            <td>{{ formatTime(record.check_out_time) }}</td>
            <td>
              <span class="status-badge" :class="statusFor(record).className">{{
                statusFor(record).label
              }}</span>
            </td>
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
        <div class="table-footer-content">
          <!-- Kontrol Pagination -->
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
              <span>dari  {{ lastPage }}</span>
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

          <!-- Dropdown Per Page / Rows -->
          <div class="per-page-select">
            <select v-model="perPage" @change="changePerPage" :disabled="loading">
              <option :value="10">10 baris</option>
              <option :value="20">20 baris</option>
              <option :value="50">50 baris</option>
              <option :value="100">100 baris</option>
            </select>
          </div>

          <!-- Informasi Total Records -->
          <span class="total-records-info">{{ totalRecords }} catatan</span>
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
.table-panel {
  position: relative;
}
.table-panel::after {
  content: '';
  position: absolute;
  inset: -1px;
  border: 1px solid var(--line);
  border-radius: 16px;
  pointer-events: none;
  z-index: 25;
}
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
.summary-top {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 16px;
}
.summary-icon {
  width: 32px;
  height: 32px;
  border-radius: 7px;
  display: grid;
  place-items: center;
}
.summary-icon svg {
  width: 18px;
  height: 18px;
}
.summary-icon.green {
  background: #e0f5e9;
  color: #17a057;
}
.summary-icon.amber {
  background: #fff2d9;
  color: #efb34f;
}
.summary-icon.red {
  background: #fde7e8;
  color: #d91e2e;
}
.summary-icon.blue {
  background: #e8ebf5;
  color: var(--blue-900);
}
.summary-tag {
  padding: 4px 7px;
  border-radius: 4px;
  font-size: 9px;
  font-weight: 800;
}
.summary-tag.green {
  color: #15924f;
  background: #e5f5e9;
}
.summary-tag.amber {
  color: #b17a18;
  background: #fff0d3;
}
.summary-tag.red {
  color: var(--red, #d91e2e);
  background: #fdebed;
}
.summary-tag.blue {
  color: var(--blue-900);
  background: #e8ebf5;
}
.summary-label {
  display: block;
  color: var(--ink-soft);
  font-size: 14px;
  margin-bottom: 4px;
}
.summary-card strong {
  display: block;
  color: #17a057;
  font-size: 30px;
  line-height: 1.1;
  margin-bottom: 9px;
}
.summary-card small {
  color: var(--ink-soft);
  font-size: 11px;
}
.summary-card .amber-text {
  color: #efb34f;
}
.summary-card .red-text {
  color: #c91f2d;
}
.summary-card .blue-text {
  color: var(--blue-900);
}
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
.period-filter {
  display: flex;
  flex-direction: column;
  gap: 5px;
}
.period-filter > span {
  color: var(--ink-soft);
  font-size: 11px;
}
.period-controls {
  display: flex;
  align-items: center;
  gap: 8px;
}
.period-segmented {
  display: flex;
  align-items: center;
  gap: 2px;
  padding: 4px;
  border: 1px solid var(--line);
  border-radius: 10px;
  background: var(--card);
}
.period-segmented button {
  height: 32px;
  padding: 0 16px;
  border: 0;
  border-radius: 8px;
  background: transparent;
  color: var(--ink-soft);
  font: inherit;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
}
.period-segmented button.active {
  background: var(--blue-900);
  color: #fff;
}
.custom-period {
  position: relative;
}
.custom-period-button {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  height: 40px;
  padding: 0 13px;
  border: 1px solid var(--line);
  border-radius: 10px;
  background: var(--card);
  color: var(--ink-soft);
  font: inherit;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
}
.custom-period-button.active {
  border-color: var(--blue-900);
  background: var(--blue-900);
  color: #fff;
}
.location-select,
.search {
  height: 38px;
  border: 1px solid var(--line);
  border-radius: 8px;
  background: var(--card);
  color: var(--ink);
}
.location-select {
  position: relative;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 8px;
  width: max-content;
  min-width: 150px;
  min-height: 40px;
  padding: 10px 14px;
  border-radius: 10px;
  font-size: 14px;
  font-weight: 600;
  line-height: 1.2;
  cursor: pointer;
}
.location-select > span {
  white-space: nowrap;
}
.location-select > .iconify {
  width: 14px;
  height: 14px;
  flex-shrink: 0;
  color: var(--ink-soft);
}
.location-menu {
  position: absolute;
  z-index: 30;
  top: calc(100% + 8px);
  left: 0;
  width: 100%;
  max-height: 300px;
  overflow-y: auto;
  padding: 6px 0;
  background: var(--card);
  border: 1px solid var(--line);
  border-radius: 12px;
  box-shadow: 0 16px 30px rgba(0, 0, 0, 0.08);
}
.location-item {
  display: block;
  width: 100%;
  padding: 10px 14px;
  border: 0;
  background: transparent;
  color: var(--ink);
  text-align: left;
  font: inherit;
  font-size: 14px;
  cursor: pointer;
}
.location-item:hover {
  background: #eef0f7;
}
.custom-date-range {
  position: absolute;
  z-index: 40;
  top: calc(100% + 14px);
  left: 0;
  display: flex;
  flex-wrap: wrap;
  align-items: flex-end;
  gap: 12px;
  min-width: 356px;
  padding: 16px;
  border: 1px solid var(--line);
  border-radius: 12px;
  background: var(--card);
  box-shadow: 0 16px 30px rgba(0, 0, 0, 0.1);
}
.date-range-fields {
  position: relative;
  display: flex;
  align-items: flex-end;
  gap: 12px;
  width: 100%;
}
.custom-date-range label {
  display: flex;
  flex-direction: column;
  gap: 5px;
}
.custom-date-range label span {
  color: var(--ink-soft);
  font-size: 12px;
  font-weight: 600;
}
.date-field {
  display: inline-flex;
  align-items: center;
  justify-content: space-between;
  gap: 10px;
  width: 148px;
  min-width: 148px;
  height: 40px;
  padding: 0 11px;
  border: 1px solid var(--line);
  border-radius: 9px;
  background: var(--card);
  color: var(--ink);
  font: inherit;
  font-size: 13px;
  cursor: pointer;
}
.date-field.focused {
  border-color: var(--blue-900);
  box-shadow: 0 0 0 3px rgba(47, 59, 105, 0.12);
}
.date-field .iconify {
  flex-shrink: 0;
  color: var(--ink-soft);
}
.range-separator {
  padding-bottom: 11px;
  color: var(--ink-soft);
  font-size: 14px;
  font-weight: 600;
}
.custom-date-actions {
  display: flex;
  justify-content: flex-end;
  gap: 8px;
  width: 100%;
  margin-top: 4px;
}
.custom-date-actions button {
  height: 34px;
  padding: 0 14px;
  border-radius: 8px;
  font: inherit;
  font-size: 13px;
  font-weight: 600;
  cursor: pointer;
}
.cancel-button {
  border: 1px solid var(--line);
  background: var(--card);
  color: var(--ink-soft);
}
.save-button {
  border: 1px solid var(--blue-900);
  background: var(--blue-900);
  color: #fff;
}
.save-button:disabled {
  opacity: 0.45;
  cursor: not-allowed;
}
.calendar-popup {
  position: absolute;
  z-index: 50;
  top: calc(100% + 10px);
  left: 0;
  width: 328px;
  padding: 14px;
  border: 1px solid var(--line);
  border-radius: 14px;
  background: var(--card);
  box-shadow: 0 18px 36px rgba(28, 28, 25, 0.16);
}
.calendar-popup.calendar-for-end {
  left: auto;
  right: 0;
}
.calendar-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 14px;
}
.calendar-header strong {
  color: var(--ink);
  font-size: 15px;
  text-transform: capitalize;
}
.calendar-header button {
  display: grid;
  place-items: center;
  width: 32px;
  height: 32px;
  border: 0;
  border-radius: 8px;
  background: transparent;
  color: var(--ink-soft);
  cursor: pointer;
}
.calendar-header button:hover {
  background: var(--bg);
  color: var(--blue-900);
}
.calendar-weekdays,
.calendar-grid {
  display: grid;
  grid-template-columns: repeat(7, 1fr);
  gap: 4px;
}
.calendar-weekdays {
  margin-bottom: 6px;
}
.calendar-weekdays span {
  color: var(--ink-soft);
  font-size: 11px;
  font-weight: 700;
  text-align: center;
}
.calendar-weekdays span:first-child,
.calendar-weekdays span:last-child {
  color: #c65a5a;
}
.calendar-day {
  display: grid;
  place-items: center;
  width: 100%;
  aspect-ratio: 1;
  border: 0;
  border-radius: 8px;
  background: transparent;
  color: var(--ink);
  font: inherit;
  font-size: 12px;
  cursor: pointer;
}
.calendar-day:hover:not(:disabled) {
  background: #eef0f7;
  color: var(--blue-900);
}
.calendar-day.muted {
  color: #b7bcc7;
}
.calendar-day.today {
  box-shadow: inset 0 0 0 1px var(--blue-900);
}
.calendar-day.selected {
  background: var(--blue-900);
  color: #fff;
  font-weight: 700;
}
.calendar-day:disabled {
  color: #d5d8df;
  cursor: not-allowed;
}
.search {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 10px 16px;
  width: 280px;
  min-width: 280px;
  margin-left: auto;
  background: var(--bg);
}
.search svg,
.search .iconify {
  width: 18px;
  height: 18px;
  color: var(--ink-soft);
  flex-shrink: 0;
}
.search input {
  border: 0;
  outline: 0;
  width: 100%;
  color: var(--ink);
  font-size: 14px;
  font-family: inherit;
  background: transparent;
}
.export-btn {
  height: 40px;
  margin-left: 0;
  display: inline-flex;
  align-items: center;
  gap: 6px;
  padding: 0 16px;
  border: 0;
  border-radius: 8px;
  background: #2f3b69;
  color: #fff;
  font-size: 14px;
  font-weight: 700;
  cursor: pointer;
  white-space: nowrap;
}
.export-btn svg {
  width: 16px;
  height: 16px;
}
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
thead th:last-child {
  border-radius: 0;
}
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
.employee {
  display: flex;
  align-items: center;
  gap: 12px;
}
.employee-avatar {
  width: 36px;
  height: 36px;
  border-radius: 50%;
  background: #e2e5f0;
  color: var(--blue-900);
  font-size: 12px;
  font-weight: 700;
  display: grid;
  place-items: center;
  flex-shrink: 0;
}
.employee strong {
  font-size: 15px;
}
.status-badge {
  display: inline-flex;
  padding: 6px 12px;
  border-radius: 999px;
  font-size: 11px;
  font-weight: 700;
  white-space: nowrap;
}
.status-badge.on-time {
  background: #dcf8e5;
  color: #15924f;
}
.status-badge.late {
  background: #fff0c7;
  color: #9a6900;
}
.status-badge.missed {
  background: #fde0e2;
  color: #c91f2d;
}
.status-badge.overtime {
  background: #dce6ff;
  color: var(--blue-900);
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
.filters input[type='date'],
.filters select {
  height: 38px;
  padding: 8px 12px;
  border: 1px solid var(--line);
  border-radius: 10px;
  background: var(--card);
  font-size: 14px;
  color: var(--ink);
}
.filters input[type='date'] {
  min-width: 160px;
}
.filters select {
  min-width: 180px;
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

.per-page-select select option {
  font-family: 'Plus Jakarta Sans', sans-serif;
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
  .summary-grid {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }
  .custom-date-range {
    left: auto;
    right: 0;
    min-width: min(356px, calc(100vw - 32px));
  }
  .date-range-fields {
    gap: 8px;
  }
  .date-range-fields label {
    flex: 1;
  }
  .date-field {
    width: 100%;
    min-width: 0;
  }
  .calendar-popup {
    left: auto;
    right: 0;
    width: min(328px, calc(100vw - 32px));
  }
  .search {
    margin-left: 0;
    width: 100%;
    min-width: 0;
  }
  .export-btn {
    margin-left: 0;
  }
  .table-panel {
    overflow-x: auto;
  }
  table {
    min-width: 760px;
  }
}
</style>
