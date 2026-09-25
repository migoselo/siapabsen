<script setup>
/**
 * DataAbsensiView.vue
 * Diperbarui dengan Hierarchy Drill-Down (Pilih Lokasi Dulu) dan Base Components.
 */
import { ref, computed, watch, onMounted, onBeforeUnmount } from 'vue'
import { Icon } from '@iconify/vue'
import { useRoute, useRouter } from 'vue-router'
import api from '../api'

// Import Base Components
import BaseSummaryCard from '../components/BaseSummaryCard.vue'
import BaseButton from '../components/BaseButton.vue'
import BaseSearch from '../components/BaseSearch.vue'
import BaseTable from '../components/BaseTable.vue'

/* ------------------------------------------------------------------ */
/* State & Fetch Data API                                              */
/* ------------------------------------------------------------------ */
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
const route = useRoute()
const router = useRouter()

/* ------------------------------------------------------------------ */
/* Logika Drill-Down Lokasi                                            */
/* ------------------------------------------------------------------ */
const selectedLocation = ref(null)

const locationColumns = [
  { key: 'name', label: 'Nama Lokasi / Cabang' },
  { key: 'address', label: 'Alamat' },
]

const attendanceColumns = [
  { key: 'date', label: 'Tanggal' },
  { key: 'employee', label: 'Nama Karyawan' },
  { key: 'checkIn', label: 'Check In' },
  { key: 'checkOut', label: 'Check Out' },
  { key: 'status', label: 'Status' },
]

function goToLocation(loc) {
  selectedLocation.value = loc
  filter.value.location_id = loc.id
  fetchAttendance(1)
}

function openLocation(loc) {
  router.push({
    name: 'DataAbsensi',
    query: { location_id: String(loc.id) },
  })
  goToLocation(loc)
}

function resetLocation() {
  selectedLocation.value = null
  filter.value.location_id = ''
  records.value = []
  searchQuery.value = ''
  router.replace({ name: 'DataAbsensi' })
}

/* ------------------------------------------------------------------ */
/* Konfigurasi Kalender & Filter Periode                               */
/* ------------------------------------------------------------------ */
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
    const otherDate =
      activeDateField.value === 'start' ? customEndDate.value : customStartDate.value
    const disabledByRange =
      activeDateField.value === 'start'
        ? Boolean(otherDate && value > otherDate)
        : Boolean(otherDate && value < otherDate)
    const disabled = value > todayDateValue.value || disabledByRange

    return {
      day: date.getDate(),
      value,
      isCurrentMonth: date.getMonth() === month,
      isToday: value === formatDateInput(new Date()),
      isSelected:
        value === (activeDateField.value === 'start' ? customStartDate.value : customEndDate.value),
      disabled,
    }
  })
})

/* ------------------------------------------------------------------ */
/* Computed Properties untuk Data Absensi                              */
/* ------------------------------------------------------------------ */
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
  onTime: periodFilteredRecords.value.filter((record) => record.check_in_time && !isLate(record))
    .length,
  late: periodFilteredRecords.value.filter((record) => isLate(record)).length,
  missed: periodFilteredRecords.value.filter((record) => !record.check_in_time).length,
  overtime: periodFilteredRecords.value.filter((record) => isOvertime(record)).length,
}))

/* ------------------------------------------------------------------ */
/* Helper Functions                                                    */
/* ------------------------------------------------------------------ */
function formatTime(value) {
  return value
    ? new Date(value).toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit' })
    : '--:--'
}

function initials(name) {
  if (!name) return '-'
  return name
    .split(' ')
    .map((word) => word[0])
    .slice(0, 2)
    .join('')
    .toUpperCase()
}

function statusFor(record) {
  const status = String(record.status || '').toLowerCase()
  if (status === 'lupa_absen') return { label: 'Lupa Checkout', theme: 'danger' }
  if (status === 'alpha' || !record.check_in_time) return { label: 'Alpha', theme: 'danger' }
  if (status === 'lembur' || status === 'overtime') return { label: 'Lembur', theme: 'info' }
  if (status === 'telat' || status === 'terlambat') return { label: 'Terlambat', theme: 'warning' }
  return { label: 'Tepat Waktu', theme: 'success' }
}

function getStatusStyle(theme) {
  const styles = {
    success: { background: '#dcf8e5', color: '#15924f' },
    warning: { background: '#fff0c7', color: '#9a6900' },
    danger: { background: '#fde0e2', color: '#c91f2d' },
    info: { background: '#dce6ff', color: '#2f3b69' },
  }
  return styles[theme] || styles.success
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

/* ------------------------------------------------------------------ */
/* Kalender Methods                                                    */
/* ------------------------------------------------------------------ */
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

  if (filter.value.period === 'all') return { startDate: '', endDate: '' }
  if (filter.value.period === 'today') return { startDate: todayValue, endDate: todayValue }

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

/* ------------------------------------------------------------------ */
/* Fetching & Pagination                                               */
/* ------------------------------------------------------------------ */
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
  try {
    const params = { page, per_page: perPage.value }
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
  if (page !== currentPage.value) fetchAttendance(page)
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

function closeMenus() {
  showCalendar.value = false
}

onMounted(async () => {
  await fetchLocations()
  const locationId = route.query.location_id
  if (locationId) {
    const location = locations.value.find((item) => String(item.id) === String(locationId))
    if (location) goToLocation(location)
  }
  document.addEventListener('click', closeMenus)
})

onBeforeUnmount(() => {
  document.removeEventListener('click', closeMenus)
})
</script>

<template>
  <div class="attendance-page">
    <!-- Header Drill Down -->
    <div class="filter-header">
      <div class="breadcrumb-wrap">
        <BaseButton
          v-if="selectedLocation"
          variant="ghost"
          icon="material-symbols:arrow-back-rounded"
          @click="resetLocation"
          title="Kembali"
          style="padding: 10px"
        />
        <div v-if="!selectedLocation" class="table-heading">
          <h2>Pilih Lokasi Kantor</h2>
          <p>Pilih lokasi kantor terlebih dahulu untuk melihat data absensi harian.</p>
        </div>
        <div v-else class="selected-office-heading">
          <span>Data Absensi Lokasi</span>
          <h2>{{ selectedLocation.name }}</h2>
        </div>
      </div>
    </div>

    <!-- Tabel Lokasi (Ditampilkan jika belum ada lokasi yang dipilih) -->
    <BaseTable
      v-if="!selectedLocation"
      :columns="locationColumns"
      :data="locations"
      has-actions
      empty-text="Data lokasi belum tersedia."
    >
      <template #cell-name="{ item }"
        ><strong>{{ item.name }}</strong></template
      >
      <template #cell-address="{ item }"
        ><span>{{ item.address || '-' }}</span></template
      >
      <template #actions="{ item }">
        <button
          type="button"
          class="detail-link-btn"
          @click="openLocation(item)"
        >
          Lihat Absen
        </button>
      </template>
    </BaseTable>

    <!-- Dashboard & Tabel Data (Ditampilkan setelah lokasi dipilih) -->
    <template v-else>
      <section class="summary-grid">
        <BaseSummaryCard
          tag="TOTAL"
          title="Tepat Waktu"
          :value="summary.onTime"
          subtitle="Check-in dan check-out tercatat"
          icon="material-symbols:groups-outline"
          theme="green"
        />
        <BaseSummaryCard
          tag="STATUS"
          title="Terlambat"
          :value="summary.late"
          subtitle="Check-in mulai pukul 09.00"
          icon="material-symbols:schedule-outline"
          theme="amber"
        />
        <BaseSummaryCard
          tag="ALERT"
          title="Lupa Absen"
          :value="summary.missed"
          subtitle="Belum melakukan check-in"
          icon="material-symbols:person-off-outline"
          theme="red"
        />
        <BaseSummaryCard
          tag="SHIFT"
          title="Lembur"
          :value="summary.overtime"
          subtitle="Sesuai penanda lembur"
          icon="material-symbols:logout-rounded"
          theme="blue"
        />
      </section>

      <section class="panel table-panel">
        <div class="filter-bar">
          <!-- Custom Period Filter tetap dipertahankan karena behavior kalender spesifik -->
          <div class="period-filter" @click.stop>
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
                        <Icon
                          icon="material-symbols:calendar-today-outline"
                          width="16"
                          height="16"
                        />
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
                        <Icon
                          icon="material-symbols:calendar-today-outline"
                          width="16"
                          height="16"
                        />
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
                          <Icon
                            icon="material-symbols:chevron-left-rounded"
                            width="20"
                            height="20"
                          />
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

          <div class="search-wrap">
            <BaseSearch v-model="searchQuery" placeholder="Cari nama karyawan ..." width="240px" />
          </div>

          <div class="export-wrap">
            <BaseButton
              variant="primary"
              icon="material-symbols:download-rounded"
              @click="handleExport"
              >Export ke Excel</BaseButton
            >
          </div>
        </div>

        <!-- Tabel Rekap Data Absensi Berdasarkan Base Components -->
        <BaseTable
          :columns="attendanceColumns"
          :data="filteredRecords"
          has-actions
          empty-text="Belum ada data absensi untuk periode ini."
        >
          <template #cell-date="{ item }">
            {{
              item.check_in_time ? new Date(item.check_in_time).toLocaleDateString('id-ID') : '-'
            }}
          </template>

          <template #cell-employee="{ item }">
            <div class="employee">
              <div class="employee-avatar">{{ initials(item.employee?.name) }}</div>
              <strong>{{ item.employee?.name || '—' }}</strong>
            </div>
          </template>

          <template #cell-checkIn="{ item }">
            {{ formatTime(item.check_in_time) }}
          </template>

          <template #cell-checkOut="{ item }">
            {{ formatTime(item.check_out_time) }}
          </template>

          <template #cell-status="{ item }">
            <span class="status-badge" :style="getStatusStyle(statusFor(item).theme)">
              {{ statusFor(item).label }}
            </span>
          </template>

          <template #actions="{ item }">
            <router-link :to="{ name: 'DetailAbsen', params: { id: item.id } }" class="detail-link">
              Lihat Detail
            </router-link>
          </template>
        </BaseTable>

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

            <span class="total-records-info">{{ totalRecords }} catatan</span>
          </div>
        </div>
      </section>
    </template>
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

/* Header Drill Down */
.filter-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  padding: 0 0 24px 0;
}
.breadcrumb-wrap {
  display: flex;
  align-items: center;
  gap: 12px;
}
.table-heading h2 {
  margin: 0;
  color: var(--blue-900);
  font-size: 18px;
  font-weight: 700;
}
.table-heading p {
  margin: 4px 0 0;
  color: var(--ink-soft);
  font-size: 13px;
}
.selected-office-heading span {
  display: block;
  margin-bottom: 3px;
  color: var(--ink-soft);
  font-size: 12px;
}
.selected-office-heading h2 {
  margin: 0;
  color: var(--blue-900);
  font-size: 18px;
  font-weight: 700;
}

.panel {
  background: var(--card);
  border: 1px solid var(--line);
  border-radius: 16px;
}
.table-panel {
  position: relative;
  padding: 0;
  overflow: visible;
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
  grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
  gap: 14px;
  margin-bottom: 20px;
}

.filter-bar {
  display: flex;
  align-items: flex-end;
  justify-content: space-between;
  gap: 10px;
  padding: 18px 24px;
  margin: 0;
  background: var(--card);
  border-bottom: 1px solid var(--line);
  flex-wrap: wrap;
  border-radius: 15px 15px 0 0;
}

.detail-link-btn {
  display: inline-flex;
  align-items: center;
  color: #2f3b69;
  font-weight: 700;
  background: none;
  border: none;
  cursor: pointer;
  font-size: 14px;
}
.detail-link-btn:hover {
  text-decoration: underline;
}

/* Custom Period Filter */
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

.search-wrap {
  flex: 1;
  display: flex;
  justify-content: flex-end;
}
.export-wrap {
  margin-left: 12px;
}

/* Table Cells Formatting */
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
  font-size: 14px;
  color: var(--ink);
  font-weight: 700;
}
.status-badge {
  display: inline-flex;
  padding: 6px 12px;
  border-radius: 999px;
  font-size: 11px;
  font-weight: 700;
  white-space: nowrap;
}
.detail-link {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  color: var(--blue-900);
  font-weight: 700;
  text-decoration: none;
  font-size: 14px;
}
.detail-link:hover {
  text-decoration: underline;
}

/* Pagination Controls */
.table-footer {
  display: flex;
  justify-content: flex-end;
  align-items: center;
  padding: 12px 24px;
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
  font-family: inherit;
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
  font-family: inherit;
}
.per-page-select select:focus {
  border-color: var(--blue-900);
}
.total-records-info {
  font-size: 13px;
  font-weight: 600;
  color: var(--ink-soft);
  white-space: nowrap;
}

@media (max-width: 760px) {
  .search-wrap {
    justify-content: flex-start;
    width: 100%;
    margin-top: 10px;
  }
  .export-wrap {
    width: 100%;
    margin-left: 0;
    margin-top: 10px;
    display: flex;
    justify-content: stretch;
  }
  .export-wrap :deep(.base-btn) {
    width: 100%;
    justify-content: center;
  }
}
</style>
