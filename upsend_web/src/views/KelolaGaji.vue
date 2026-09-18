<script setup>
import { computed, onMounted, onBeforeUnmount, ref } from 'vue'
import { useRouter } from 'vue-router'
import { Icon } from '@iconify/vue'
import api from '../api'

const router = useRouter()

const employees = ref([])
const officeLocations = ref([])
const loading = ref(false)
const search = ref('')
const lokasiKerja = ref('Semua Kantor')
const divisi = ref('Semua Divisi')
const status = ref('Semua Status')
const grade = ref('Semua Level')
const selectedMonth = ref(new Date().toISOString().slice(0, 7))
const page = ref(1)
const perPage = ref(20)
const pageInput = ref(1)

/* ------------------------------------------------------------------ */
/* Kontrol Custom Dropdown & Custom Month Picker                       */
/* ------------------------------------------------------------------ */
const showMonthMenu = ref(false)
const showLokasiMenu = ref(false)
const showDivisiMenu = ref(false)
const showGradeMenu = ref(false)
const showStatusMenu = ref(false)

const pickerYear = ref(Number(selectedMonth.value.split('-')[0]))

const monthList = [
  'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
  'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
]

const formattedMonthLabel = computed(() => {
  if (!selectedMonth.value) return 'Pilih Bulan'
  const [y, m] = selectedMonth.value.split('-')
  const monthName = monthList[Number(m) - 1] || ''
  return `${monthName} ${y}`
})

function toggleMonthMenu() {
  showMonthMenu.value = !showMonthMenu.value
  showLokasiMenu.value = false
  showDivisiMenu.value = false
  showGradeMenu.value = false
  showStatusMenu.value = false
}

function toggleLokasiMenu() {
  showLokasiMenu.value = !showLokasiMenu.value
  showMonthMenu.value = false
  showDivisiMenu.value = false
  showGradeMenu.value = false
  showStatusMenu.value = false
}

function toggleDivisiMenu() {
  showDivisiMenu.value = !showDivisiMenu.value
  showMonthMenu.value = false
  showLokasiMenu.value = false
  showGradeMenu.value = false
  showStatusMenu.value = false
}

function toggleGradeMenu() {
  showGradeMenu.value = !showGradeMenu.value
  showMonthMenu.value = false
  showLokasiMenu.value = false
  showDivisiMenu.value = false
  showStatusMenu.value = false
}

function toggleStatusMenu() {
  showStatusMenu.value = !showStatusMenu.value
  showMonthMenu.value = false
  showLokasiMenu.value = false
  showDivisiMenu.value = false
  showGradeMenu.value = false
}

function closeAllMenus() {
  showMonthMenu.value = false
  showLokasiMenu.value = false
  showDivisiMenu.value = false
  showGradeMenu.value = false
  showStatusMenu.value = false
}

function handleOutsideClick(e) {
  if (!e.target.closest('.custom-select')) {
    closeAllMenus()
  }
}

/* Logika Kalender Custom */
function changeYear(delta) {
  pickerYear.value += delta
}

function isCurrentSelectedMonth(monthIdx) {
  const [y, m] = selectedMonth.value.split('-')
  return Number(y) === pickerYear.value && Number(m) === monthIdx + 1
}

function selectMonth(monthIdx) {
  const mStr = String(monthIdx + 1).padStart(2, '0')
  selectedMonth.value = `${pickerYear.value}-${mStr}`
  showMonthMenu.value = false
  applyMonthFilter()
}

function selectThisMonth() {
  const now = new Date()
  const y = now.getFullYear()
  const m = String(now.getMonth() + 1).padStart(2, '0')
  pickerYear.value = y
  selectedMonth.value = `${y}-${m}`
  showMonthMenu.value = false
  applyMonthFilter()
}

/* Logika Pilihan Filter Dropdown */
function selectLokasi(val) {
  lokasiKerja.value = val
  showLokasiMenu.value = false
  resetPage()
}

function selectDivisi(val) {
  divisi.value = val
  showDivisiMenu.value = false
  resetPage()
}

function selectGrade(val) {
  grade.value = val
  showGradeMenu.value = false
  resetPage()
}

function selectStatus(val) {
  status.value = val
  showStatusMenu.value = false
  resetPage()
}

/* ------------------------------------------------------------------ */
/* Helper & Data Formatting                                            */
/* ------------------------------------------------------------------ */
const rupiah = (value) => `Rp ${Math.round(Number(value || 0)).toLocaleString('id-ID')}`
const initials = (name) =>
  (name || '')
    .split(' ')
    .map((part) => part[0])
    .slice(0, 2)
    .join('')
    .toUpperCase()

const normalizeEmployee = (item) => {
  const potongan = Number(item.total_deduction || 0)
  const totalIncome = Number(item.total_income || 0)
  const netSalary = Number(item.net_salary ?? totalIncome - potongan)

  return {
    id: item.user_id || item.user?.id || item.id,
    payrollId: item.id,
    name: item.user?.name || 'Karyawan',
    code: item.user?.employee_id || item.employee_id || '-',
    position: item.user?.role || 'Karyawan',
    kantor: item.user?.home_location?.name || 'Belum diatur',
    divisi: item.user?.home_location?.name || 'Belum diatur',
    lokasiKerja: item.user?.home_location?.name || 'Belum diatur',
    pokok: Number(item.basic_salary || 0),
    tetap: Number(item.transport_allowance || 0) + Number(item.attendance_allowance || 0),
    variabel: Number(item.meal_allowance || 0) + Number(item.other_allowance || 0),
    potongan,
    netSalary,
    status: 'Aktif',
    period: item.payroll_period || item.period || '',
  }
}

const divisions = computed(() => ['Semua Divisi', ...new Set(employees.value.map((e) => e.divisi))])
const locations = computed(() => [
  'Semua Kantor',
  ...officeLocations.value.map((location) => location.name).filter(Boolean),
])

const filtered = computed(() =>
  employees.value.filter((employee) => {
    const query = search.value.trim().toLowerCase()
    const matchesSearch =
      !query ||
      [employee.name, employee.code, employee.position].some((val) =>
        String(val || '').toLowerCase().includes(query),
      )
    const matchesLokasi =
      lokasiKerja.value === 'Semua Kantor' || employee.lokasiKerja === lokasiKerja.value
    const matchesDivisi = divisi.value === 'Semua Divisi' || employee.divisi === divisi.value
    const matchesStatus = status.value === 'Semua Status' || employee.status === status.value
    const matchesGrade =
      grade.value === 'Semua Level' || grade.value === 'Grade 0' || employee.position != null
    return matchesSearch && matchesDivisi && matchesLokasi && matchesStatus && matchesGrade
  }),
)

const totalRecords = computed(() => filtered.value.length)
const lastPage = computed(() => Math.max(1, Math.ceil(totalRecords.value / perPage.value)))
const pageItems = computed(() =>
  filtered.value.slice((page.value - 1) * perPage.value, page.value * perPage.value),
)

const totalBudget = computed(() =>
  employees.value.reduce(
    (sum, employee) => sum + employee.netSalary,
    0,
  ),
)

async function fetchPayrolls() {
  loading.value = true
  try {
    const res = await api.get('/payrolls', {
      params: {
        per_page: perPage.value,
        month: selectedMonth.value,
        payroll_period: `${selectedMonth.value}-01`,
      },
    })
    const list = Array.isArray(res.data?.data) ? res.data.data : []
    employees.value = list.map(normalizeEmployee)
    page.value = 1
    pageInput.value = 1
  } catch (error) {
    console.error('Gagal mengambil data payroll:', error)
    employees.value = []
  } finally {
    loading.value = false
  }
}

async function fetchLocations() {
  try {
    const res = await api.get('/locations')
    officeLocations.value = Array.isArray(res.data) ? res.data : []
  } catch (error) {
    console.error('Gagal mengambil data lokasi kerja:', error)
    officeLocations.value = []
  }
}

function resetPage() {
  page.value = 1
  pageInput.value = 1
}

function applyMonthFilter() {
  resetPage()
  fetchPayrolls()
}

function prevPage() {
  if (page.value > 1) {
    page.value--
    pageInput.value = page.value
  }
}

function nextPage() {
  if (page.value < lastPage.value) {
    page.value++
    pageInput.value = page.value
  }
}

function goToInputPage() {
  let p = Number(pageInput.value)
  if (isNaN(p) || p < 1) p = 1
  if (p > lastPage.value) p = lastPage.value
  page.value = p
  pageInput.value = p
}

function statusBadgeClass(statusStr) {
  if (statusStr === 'Aktif') return 'on-time'
  if (statusStr === 'Menunggu Review') return 'late'
  return 'missed'
}

function handleExport() {
  window.alert('Fitur ekspor gaji belum tersedia.')
}

function handleCreateNewSalary() {
  router.push({ name: 'GajiForm' })
}

function handleEditSalary(employeeId) {
  router.push({ name: 'GajiForm', params: { employeeId } })
}

onMounted(() => {
  fetchPayrolls()
  fetchLocations()
  document.addEventListener('click', handleOutsideClick)
})

onBeforeUnmount(() => {
  document.removeEventListener('click', handleOutsideClick)
})
</script>

<template>
  <div class="salary-page">
    <!-- Section Summary / Dashboard -->
    <section class="summary-grid">
      <div class="summary-card">
        <div class="summary-top">
          <div class="summary-icon green">
            <Icon icon="material-symbols:account-balance-wallet-outline" />
          </div>
          <span class="summary-tag green">ANGGARAN</span>
        </div>
        <span class="summary-label">Total Anggaran Bulanan</span>
        <strong>{{ rupiah(totalBudget) }}</strong>
        <small>+3.2% vs bulan lalu</small>
      </div>

      <div class="summary-card">
        <div class="summary-top">
          <div class="summary-icon blue">
            <Icon icon="material-symbols:groups-outline" />
          </div>
          <span class="summary-tag blue">KARYAWAN</span>
        </div>
        <span class="summary-label">Karyawan Bergaji</span>
        <strong class="blue-text">{{ employees.length }} Orang</strong>
        <small>Seluruh data payroll aktif</small>
      </div>

      <div class="summary-card">
        <div class="summary-top">
          <div class="summary-icon amber">
            <Icon icon="material-symbols:payments-outline" />
          </div>
          <span class="summary-tag amber">RATA-RATA</span>
        </div>
        <span class="summary-label">Rata-rata THP Netto</span>
        <strong class="amber-text">{{ rupiah(totalBudget / employees.length) }}</strong>
        <small>Estimasi penghasilan bersih</small>
      </div>
    </section>

    <!-- Section Table Panel -->
    <section class="panel table-panel">
      <!-- Filter Bar -->
      <div class="filter-bar">
        <div class="filters">
          <!-- Custom Month Picker -->
          <div class="custom-select month-picker" @click.stop="toggleMonthMenu">
            <Icon icon="material-symbols:calendar-month-outline-rounded" width="18" height="18" />
            <span>{{ formattedMonthLabel }}</span>
            <Icon icon="material-symbols:keyboard-arrow-down-rounded" width="18" height="18" />

            <!-- Pop-up Month Picker Custom -->
            <div v-if="showMonthMenu" class="month-picker-menu" @click.stop>
              <div class="month-picker-header">
                <button type="button" class="nav-btn" @click="changeYear(-1)">
                  <Icon icon="material-symbols:chevron-left-rounded" width="20" height="20" />
                </button>
                <span class="year-label">{{ pickerYear }}</span>
                <button type="button" class="nav-btn" @click="changeYear(1)">
                  <Icon icon="material-symbols:chevron-right-rounded" width="20" height="20" />
                </button>
              </div>

              <div class="month-grid">
                <button
                  v-for="(m, idx) in monthList"
                  :key="m"
                  type="button"
                  class="month-item"
                  :class="{ active: isCurrentSelectedMonth(idx) }"
                  @click="selectMonth(idx)"
                >
                  {{ m }}
                </button>
              </div>

              <div class="month-picker-footer">
                <button type="button" class="btn-text" @click="selectThisMonth">Bulan Ini</button>
              </div>
            </div>
          </div>

          <!-- Custom Dropdown Lokasi Kerja -->
          <div class="custom-select" @click.stop="toggleLokasiMenu">
            <span>{{ lokasiKerja }}</span>
            <Icon icon="material-symbols:keyboard-arrow-down-rounded" width="18" height="18" />

            <div v-if="showLokasiMenu" class="select-menu">
              <button
                v-for="item in locations"
                :key="item"
                type="button"
                class="select-item"
                :class="{ active: lokasiKerja === item }"
                @click.stop="selectLokasi(item)"
              >
                {{ item }}
              </button>
            </div>
          </div>

          <!-- Custom Dropdown Divisi -->
          <div class="custom-select" @click.stop="toggleDivisiMenu">
            <span>{{ divisi }}</span>
            <Icon icon="material-symbols:keyboard-arrow-down-rounded" width="18" height="18" />

            <div v-if="showDivisiMenu" class="select-menu">
              <button
                v-for="item in divisions"
                :key="item"
                type="button"
                class="select-item"
                :class="{ active: divisi === item }"
                @click.stop="selectDivisi(item)"
              >
                {{ item }}
              </button>
            </div>
          </div>

          <!-- Custom Dropdown Level / Grade -->
          <div class="custom-select" @click.stop="toggleGradeMenu">
            <span>{{ grade }}</span>
            <Icon icon="material-symbols:keyboard-arrow-down-rounded" width="18" height="18" />

            <div v-if="showGradeMenu" class="select-menu">
              <button
                type="button"
                class="select-item"
                :class="{ active: grade === 'Semua Level' }"
                @click.stop="selectGrade('Semua Level')"
              >
                Semua Level
              </button>
              <button
                v-for="item in [3, 4, 5, 6]"
                :key="item"
                type="button"
                class="select-item"
                :class="{ active: grade === `Grade ${item}` }"
                @click.stop="selectGrade(`Grade ${item}`)"
              >
                Grade {{ item }}
              </button>
            </div>
          </div>

          <!-- Custom Dropdown Status -->
          <div class="custom-select" @click.stop="toggleStatusMenu">
            <span>{{ status }}</span>
            <Icon icon="material-symbols:keyboard-arrow-down-rounded" width="18" height="18" />

            <div v-if="showStatusMenu" class="select-menu">
              <button
                v-for="st in ['Semua Status', 'Aktif', 'Menunggu Review', 'Perlu Update']"
                :key="st"
                type="button"
                class="select-item"
                :class="{ active: status === st }"
                @click.stop="selectStatus(st)"
              >
                {{ st }}
              </button>
            </div>
          </div>
        </div>

        <div class="search">
          <Icon icon="material-symbols:search-rounded" width="18" height="18" />
          <input
            type="text"
            v-model="search"
            @input="resetPage"
            placeholder="Cari nama, NIK, atau posisi..."
          />
        </div>

        <div class="actions-group">
          <button class="add-btn" type="button" @click="handleCreateNewSalary">
            <Icon icon="material-symbols:add-rounded" width="18" height="18" /> Tetapkan Gaji Baru
          </button>
          <button class="export-btn" type="button" @click="handleExport">
            <Icon icon="material-symbols:download-rounded" /> Ekspor ke Excel
          </button>
        </div>
      </div>

      <!-- Tabel -->
      <table>
        <thead>
          <tr>
            <th>Karyawan</th>
            <th>Gaji Pokok</th>
            <th>Tunj. Tetap</th>
            <th>Tunj. Variabel</th>
            <th>Potongan</th>
            <th>Take Home Pay</th>
            <th>Status</th>
            <th>Aksi</th>
          </tr>
        </thead>
        <tbody>
          <tr v-if="pageItems.length === 0">
            <td colspan="8" class="empty-cell">Tidak ada karyawan yang cocok dengan filter ini.</td>
          </tr>
          <tr v-for="employee in pageItems" :key="employee.id">
            <td>
              <div class="employee">
                <div class="employee-avatar">{{ initials(employee.name) }}</div>
                <div>
                  <strong>{{ employee.name }}</strong>
                  <small>{{ employee.code }} · {{ employee.position }}</small>
                </div>
              </div>
            </td>
            <td>{{ rupiah(employee.pokok) }}</td>
            <td>{{ rupiah(employee.tetap) }}</td>
            <td>{{ rupiah(employee.variabel) }}</td>
            <td class="red-text">- {{ rupiah(employee.potongan) }}</td>
            <td>
              <strong class="pay-text">{{ rupiah(employee.netSalary) }}</strong>
            </td>
            <td>
              <span class="status-badge" :class="statusBadgeClass(employee.status)">
                {{ employee.status }}
              </span>
            </td>
            <td>
              <button class="action-btn" title="Edit gaji" @click="handleEditSalary(employee.id)">
                <Icon icon="material-symbols:edit-outline" width="18" height="18" />
              </button>
            </td>
          </tr>
        </tbody>
      </table>

      <!-- Table Footer / Pagination -->
      <div class="table-footer">
        <div class="table-footer-content">
          <div class="pager">
            <button
              type="button"
              class="pager-btn"
              :disabled="page === 1"
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
              :disabled="page === lastPage"
              @click="nextPage"
              title="Halaman Berikutnya"
            >
              <Icon icon="material-symbols:chevron-right-rounded" width="18" height="18" />
            </button>
          </div>

          <div class="per-page-select">
            <select v-model="perPage" @change="resetPage">
              <option :value="10">10 baris</option>
              <option :value="20">20 baris</option>
              <option :value="50">50 baris</option>
            </select>
          </div>

          <span class="total-records-info">{{ totalRecords }} data</span>
        </div>
      </div>
    </section>
  </div>
</template>

<style scoped>
.salary-page {
  --blue-900: #2f3b69;
  --ink: #1c1c19;
  --ink-soft: #667085;
  --line: #d9dde5;
  --bg: #f7f8fa;
  --card: #ffffff;
  font-family: 'Plus Jakarta Sans', sans-serif;
}
.salary-page * {
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

/* Dashboard / Summary Grid */
.summary-grid {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
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
.summary-icon svg,
.summary-icon .iconify {
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
  font-size: 26px;
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
.summary-card .blue-text {
  color: var(--blue-900);
}

/* Filter Bar */
.filter-bar {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 18px 14px;
  background: var(--card);
  border-bottom: 1px solid var(--line);
  flex-wrap: wrap;
  border-radius: 15px 15px 0 0;
}
.filters {
  display: flex;
  gap: 8px;
  align-items: center;
  flex-wrap: wrap;
}

/* Custom Select & Month Picker Styles */
.custom-select {
  position: relative;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 8px;
  height: 40px;
  background: var(--card);
  border: 1px solid var(--line);
  padding: 0 12px;
  border-radius: 10px;
  font-size: 14px;
  font-weight: 600;
  color: var(--ink);
  cursor: pointer;
  min-width: 150px;
  user-select: none;
}

.custom-select.month-picker {
  min-width: 170px;
  gap: 10px;
}

.custom-select svg,
.custom-select .iconify {
  color: var(--ink-soft);
  flex-shrink: 0;
}

.select-menu {
  position: absolute;
  z-index: 50;
  top: calc(100% + 6px);
  left: 0;
  width: 200px;
  background: #ffffff;
  border: 1px solid var(--line);
  border-radius: 10px;
  box-shadow: 0 12px 28px rgba(0, 0, 0, 0.12);
  padding: 6px 0;
  max-height: 280px;
  overflow-y: auto;
}

.select-item {
  width: 100%;
  border: none;
  background: transparent;
  text-align: left;
  padding: 10px 16px;
  font-size: 14px;
  color: var(--ink);
  cursor: pointer;
  transition: background 0.15s ease;
}

.select-item:hover {
  background: #f4f5f8;
}

.select-item.active {
  background: #f4f5f8;
  color: var(--blue-900);
  font-weight: 700;
}

/* Custom Month Picker Menu */
.month-picker-menu {
  position: absolute;
  z-index: 50;
  top: calc(100% + 6px);
  left: 0;
  width: 240px;
  background: #ffffff;
  border: 1px solid var(--line);
  border-radius: 12px;
  box-shadow: 0 12px 28px rgba(0, 0, 0, 0.12);
  padding: 14px;
}

.month-picker-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 12px;
}

.year-label {
  font-weight: 700;
  font-size: 15px;
  color: var(--ink);
}

.nav-btn {
  background: transparent;
  border: none;
  border-radius: 6px;
  color: var(--ink-soft);
  cursor: pointer;
  display: grid;
  place-items: center;
  padding: 2px;
}

.nav-btn:hover {
  background: #f4f5f8;
  color: var(--blue-900);
}

.month-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 8px;
}

.month-item {
  border: none;
  background: #f7f8fa;
  padding: 8px 0;
  border-radius: 8px;
  font-size: 13px;
  font-weight: 600;
  color: var(--ink);
  cursor: pointer;
  transition: all 0.15s ease;
}

.month-item:hover {
  background: #e8ebf5;
  color: var(--blue-900);
}

.month-item.active {
  background: var(--blue-900);
  color: #ffffff;
  font-weight: 700;
}

.month-picker-footer {
  display: flex;
  justify-content: flex-end;
  margin-top: 10px;
  padding-top: 8px;
  border-top: 1px solid var(--line);
}

.btn-text {
  background: none;
  border: none;
  font-size: 12px;
  font-weight: 700;
  color: var(--blue-900);
  cursor: pointer;
  padding: 2px 4px;
}

.btn-text:hover {
  text-decoration: underline;
}

.search {
  height: 40px;
  border: 1px solid var(--line);
  border-radius: 10px;
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 0 14px;
  width: 220px;
  margin-left: auto;
  background: var(--bg);
}
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
  background: transparent;
}

.actions-group {
  display: flex;
  align-items: center;
  gap: 8px;
}

.add-btn {
  height: 40px;
  display: inline-flex;
  align-items: center;
  gap: 6px;
  padding: 0 16px;
  border: 0;
  border-radius: 8px;
  background: #e3b726;
  color: #000;
  font-size: 14px;
  font-weight: 700;
  cursor: pointer;
  white-space: nowrap;
}
.add-btn:hover {
  background: #e4bd3b;
}

.export-btn {
  height: 40px;
  display: inline-flex;
  align-items: center;
  gap: 6px;
  padding: 0 16px;
  border: 1px solid var(--line);
  border-radius: 8px;
  background: #232c4f;
  color: #fff;
  font-size: 14px;
  font-weight: 700;
  cursor: pointer;
  white-space: nowrap;
}
.export-btn:hover {
  background: #2f3b69;
}

/* Table Style */
table {
  width: 100%;
  border-collapse: collapse;
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
  padding: 13px 20px;
  text-transform: uppercase;
}
tbody td {
  padding: 14px 20px;
  font-size: 14px;
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
.employee small {
  display: block;
  color: var(--ink-soft);
  font-size: 12px;
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

.red-text {
  color: #c91f2d;
  font-weight: 600;
}
.pay-text {
  color: var(--blue-900);
  font-size: 14px;
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

.action-btn {
  background: transparent;
  border: none;
  color: var(--ink-soft);
  cursor: pointer;
  padding: 4px;
  border-radius: 6px;
  display: grid;
  place-items: center;
}
.action-btn:hover {
  background: var(--bg);
  color: var(--blue-900);
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
  appearance: textfield;
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
}

.total-records-info {
  font-size: 13px;
  font-weight: 600;
  color: var(--ink-soft);
  white-space: nowrap;
}

@media (max-width: 800px) {
  .summary-grid {
    grid-template-columns: 1fr;
  }
  .search {
    margin-left: 0;
    width: 100%;
  }
  .actions-group {
    width: 100%;
    justify-content: flex-end;
  }
  .table-panel {
    overflow-x: auto;
  }
  table {
    min-width: 850px;
  }
}
</style>