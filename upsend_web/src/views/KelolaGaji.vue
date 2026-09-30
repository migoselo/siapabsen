<script setup>
import { computed, onMounted, onBeforeUnmount, ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { Icon } from '@iconify/vue'
import api from '../api'

// Import Base Components
import BaseSummaryCard from '../components/BaseSummaryCard.vue'
import BaseSelect from '../components/BaseSelect.vue'
import BaseSearch from '../components/BaseSearch.vue'
import BaseButton from '../components/BaseButton.vue'
import BaseTable from '../components/BaseTable.vue'
import TableActions from '../components/TableActions.vue'
import BasePagination from '../components/BasePagination.vue'

const router = useRouter()
const route = useRoute()
const authUser = JSON.parse(localStorage.getItem('auth_user') || 'null')
const isSuperAdmin = ['super_admin', 'superadmin'].includes(authUser?.role)

const employees = ref([])
const companies = ref([])
const officeLocations = ref([])
const loadingCompanies = ref(false)
const loadingLocations = ref(false)
const loading = ref(false)
const search = ref('')

// Filter States
const divisi = ref('Semua Divisi')
const status = ref('Semua Status')
const grade = ref('Semua Level')
const selectedMonth = ref(new Date().toISOString().slice(0, 7))
const page = ref(1)
const perPage = ref(20)
const pageInput = ref(1)

// Drill-Down States
const companyId = computed(() => String(route.query.company_id || '').trim())
const locationId = computed(() => String(route.query.location_id || '').trim())
const showAllLocations = computed(() => route.query.all_locations === '1')
const selectedCompany = computed(
  () => companies.value.find((company) => String(company.id) === companyId.value) || null,
)
const selectedBranch = computed(
  () => officeLocations.value.find((location) => String(location.id) === locationId.value) || null,
)

// State pencarian khusus cabang
const branchSearch = ref('')

// Computed untuk menyaring daftar cabang berdasarkan pencarian
const filteredOfficeLocations = computed(() => {
  const query = branchSearch.value.trim().toLowerCase()
  if (!query) return officeLocations.value

  return officeLocations.value.filter((location) => {
    return (
      location.name?.toLowerCase().includes(query) ||
      location.address?.toLowerCase().includes(query)
    )
  })
})

/* ------------------------------------------------------------------ */
/* Konfigurasi Tabel BaseComponent                                    */
/* ------------------------------------------------------------------ */
const companyColumns = [
  { key: 'name', label: 'Nama Perusahaan/Cabang' },
  { key: 'address', label: 'Alamat' },
]

const payrollColumns = [
  { key: 'karyawan', label: 'Karyawan' },
  { key: 'pokok', label: 'Gaji Pokok' },
  { key: 'tetap', label: 'Tunj. Tetap' },
  { key: 'variabel', label: 'Tunj. Variabel' },
  { key: 'potongan', label: 'Potongan' },
  { key: 'netSalary', label: 'Take Home Pay' },
  { key: 'status', label: 'Status' },
]

const gradeOptions = ['Semua Level', 'Grade 3', 'Grade 4', 'Grade 5', 'Grade 6']
const statusOptions = ['Semua Status', 'Aktif', 'Menunggu Review', 'Perlu Update']

/* ------------------------------------------------------------------ */
/* Kontrol Custom Month Picker                                        */
/* ------------------------------------------------------------------ */
const showMonthMenu = ref(false)
const pickerYear = ref(Number(selectedMonth.value.split('-')[0]))

const monthList = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'Mei',
  'Jun',
  'Jul',
  'Agu',
  'Sep',
  'Okt',
  'Nov',
  'Des',
]

const formattedMonthLabel = computed(() => {
  if (!selectedMonth.value) return 'Pilih Bulan'
  const [y, m] = selectedMonth.value.split('-')
  const monthName = monthList[Number(m) - 1] || ''
  return `${monthName} ${y}`
})

function toggleMonthMenu() {
  showMonthMenu.value = !showMonthMenu.value
}

function closeAllMenus() {
  showMonthMenu.value = false
}

function handleOutsideClick(e) {
  if (!e.target.closest('.month-picker-wrap')) {
    closeAllMenus()
  }
}

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

/* ------------------------------------------------------------------ */
/* Helper & Data Formatting                                           */
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
    divisi: item.user?.division?.name || item.division_name || 'Belum diatur',
    lokasiKerja: item.user?.home_location?.name || 'Belum diatur',
    pokok: Number(item.basic_salary || 0),
    tetap: Number(item.transport_allowance || 0) + Number(item.attendance_allowance || 0),
    variabel:
      Number(item.meal_allowance || 0) +
      Number(item.performance_allowance || 0) +
      Number(item.holiday_allowance || 0) +
      Number(item.other_allowance || 0),
    potongan,
    netSalary,
    status: 'Aktif',
    period: item.payroll_period || item.period || '',
  }
}

const divisions = computed(() => ['Semua Divisi', ...new Set(employees.value.map((e) => e.divisi))])

const filtered = computed(() =>
  employees.value.filter((employee) => {
    const query = search.value.trim().toLowerCase()
    const matchesSearch =
      !query ||
      [employee.name, employee.code, employee.position].some((val) =>
        String(val || '')
          .toLowerCase()
          .includes(query),
      )
    const matchesDivisi = divisi.value === 'Semua Divisi' || employee.divisi === divisi.value
    const matchesStatus = status.value === 'Semua Status' || employee.status === status.value
    const matchesGrade =
      grade.value === 'Semua Level' || grade.value === 'Grade 0' || employee.position != null
    return matchesSearch && matchesDivisi && matchesStatus && matchesGrade
  }),
)

const currentPayrolls = computed(() => {
  return isShowingPayroll.value ? filtered.value : []
})

const isShowingPayroll = computed(
  () =>
    Boolean(selectedCompany.value) &&
    (Boolean(selectedBranch.value) ||
      showAllLocations.value ||
      (!loadingLocations.value && officeLocations.value.length === 0)),
)

/* Dashboard Stats Dinamis berdasarkan View saat ini */
const viewStats = computed(() => {
  if (isShowingPayroll.value) {
    const total = currentPayrolls.value.reduce((s, e) => s + e.netSalary, 0)
    return { budget: total, count: currentPayrolls.value.length }
  } else {
    return { budget: 0, count: 0 }
  }
})

// Pagination
const totalRecords = computed(() => {
  if (isShowingPayroll.value) return currentPayrolls.value.length
  if (selectedCompany.value && !selectedBranch.value) return filteredOfficeLocations.value.length
  return companies.value.length
})

const lastPage = computed(() => Math.max(1, Math.ceil(totalRecords.value / perPage.value)))
const pageItems = computed(() => {
  if (!isShowingPayroll.value) return []
  return currentPayrolls.value.slice((page.value - 1) * perPage.value, page.value * perPage.value)
})

/* ------------------------------------------------------------------ */
/* Fetch Data                                                         */
/* ------------------------------------------------------------------ */
let selectionRequest = 0

async function fetchPayrolls(tenantId, selectedLocationId = null, requestId = selectionRequest) {
  if (!tenantId) {
    employees.value = []
    return
  }

  loading.value = true
  try {
    const params = {
      month: selectedMonth.value,
      payroll_period: `${selectedMonth.value}-01`,
      tenant_id: tenantId,
      per_page: 1000,
    }
    if (selectedLocationId) params.location_id = selectedLocationId

    const res = await api.get('/payrolls', { params })
    const list = Array.isArray(res.data?.data) ? res.data.data : []
    if (requestId === selectionRequest) {
      employees.value = list.map(normalizeEmployee)
      resetPage()
    }
  } catch (error) {
    console.error('Gagal mengambil data payroll:', error)
    if (requestId === selectionRequest) employees.value = []
  } finally {
    if (requestId === selectionRequest) loading.value = false
  }
}

async function fetchCompanies() {
  loadingCompanies.value = true
  try {
    const res = await api.get('/tenants')
    companies.value = Array.isArray(res.data) ? res.data : []
  } catch (error) {
    console.error('Gagal mengambil data perusahaan:', error)
    companies.value = []
  } finally {
    loadingCompanies.value = false
  }
}

async function fetchLocations(tenantId, requestId) {
  loadingLocations.value = true
  try {
    const res = await api.get('/locations', { params: { tenant_id: tenantId } })
    if (requestId === selectionRequest) {
      officeLocations.value = Array.isArray(res.data) ? res.data : []
    }
  } catch (error) {
    console.error('Gagal mengambil data cabang:', error)
    if (requestId === selectionRequest) officeLocations.value = []
  } finally {
    if (requestId === selectionRequest) loadingLocations.value = false
  }
}

async function syncSelection() {
  const requestId = ++selectionRequest
  employees.value = []
  officeLocations.value = []
  loading.value = false
  resetPage()

  if (!selectedCompany.value) return

  const tenantId = selectedCompany.value.id
  await fetchLocations(tenantId, requestId)
  if (requestId !== selectionRequest) return

  const location = officeLocations.value.find((item) => String(item.id) === locationId.value)
  if (location) {
    await fetchPayrolls(tenantId, location.id, requestId)
  } else if (showAllLocations.value || officeLocations.value.length === 0) {
    await fetchPayrolls(tenantId, null, requestId)
  }
}

function goToCompany(company) {
  router.push({ query: { company_id: String(company.id) } })
}

function goToBranch(location) {
  router.push({
    query: {
      company_id: companyId.value,
      location_id: String(location.id),
    },
  })
}

function goToAllCompanyUsers() {
  router.push({
    query: {
      company_id: companyId.value,
      all_locations: '1',
    },
  })
}

function goBackToCompanies() {
  if (!isSuperAdmin) return
  router.push({ query: {} })
}

function goBackToCompany() {
  router.push({ query: { company_id: companyId.value } })
}

function resetPage() {
  page.value = 1
  pageInput.value = 1
}

function applyMonthFilter() {
  resetPage()
  if (isShowingPayroll.value && selectedCompany.value) {
    fetchPayrolls(selectedCompany.value.id, selectedBranch.value?.id || null)
  }
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

watch([companyId, locationId, showAllLocations], syncSelection)

onMounted(async () => {
  await fetchCompanies()

  if (!isSuperAdmin && !route.query.company_id && companies.value.length > 0) {
    goToCompany(companies.value[0])
    return
  }

  await syncSelection()
  document.addEventListener('click', handleOutsideClick)
})

onBeforeUnmount(() => {
  document.removeEventListener('click', handleOutsideClick)
})
</script>

<template>
  <div class="salary-page">
    <!-- Section Summary / Dashboard (BaseSummaryCard) -->
    <section v-if="isShowingPayroll" class="summary-grid">
      <BaseSummaryCard
        tag="ANGGARAN"
        title="Total Anggaran Bulanan"
        :value="rupiah(viewStats.budget)"
        subtitle="Dari data di lokasi ini"
        icon="material-symbols:account-balance-wallet-outline"
        theme="green"
      />
      <BaseSummaryCard
        tag="KARYAWAN"
        title="Karyawan Bergaji"
        :value="`${viewStats.count} Orang`"
        subtitle="Seluruh data payroll aktif"
        icon="material-symbols:groups-outline"
        theme="blue"
      />
      <BaseSummaryCard
        tag="RATA-RATA"
        title="Rata-rata THP Netto"
        :value="rupiah(viewStats.budget / (viewStats.count || 1))"
        subtitle="Estimasi penghasilan bersih"
        icon="material-symbols:payments-outline"
        theme="amber"
      />
    </section>

    <!-- Section Table Panel -->
    <section class="panel table-panel">
      <!-- LEVEL 1: Header / Filter Pilih Perusahaan -->
      <div v-if="!selectedCompany" class="branch-table-header">
        <div class="table-heading">
          <h2>Pilih Perusahaan</h2>
          <p>Pilih perusahaan untuk melihat daftar cabang.</p>
        </div>
      </div>

      <!-- LEVEL 2: Header / Filter Pilih Cabang (Konsisten dengan Role & Akses) -->
      <div v-else-if="!isShowingPayroll" class="branch-table-header">
        <div class="breadcrumb-wrap">
          <button
            v-if="isSuperAdmin"
            type="button"
            class="back-btn"
            @click="goBackToCompanies()"
            title="Kembali"
          >
            <Icon icon="material-symbols:arrow-back-rounded" width="22" height="22" />
          </button>
          <div class="selected-office-heading">
            <h2>{{ selectedCompany.name }}</h2>
          </div>
        </div>

        <div class="branch-header-actions">
          <button
            v-if="officeLocations.length"
            type="button"
            class="detail-link-btn"
            @click="goToAllCompanyUsers"
          >
            Lihat Gaji Semua Cabang
          </button>

          <!-- Input Search Cabang -->
          <BaseSearch v-model="branchSearch" placeholder="Cari cabang..." width="260px" />
        </div>
      </div>

      <!-- LEVEL 3: Header Filter Payroll Karyawan -->
      <div v-else class="filter-bar">
        <div class="filter-header">
          <div class="breadcrumb-wrap">
            <button
              type="button"
              class="back-btn"
              @click="selectedBranch ? goBackToCompany() : goBackToCompanies()"
              title="Kembali"
            >
              <Icon icon="material-symbols:arrow-back-rounded" width="22" height="22" />
            </button>
            <div class="selected-office-heading">
              <h2>{{ selectedBranch?.name || selectedCompany.name }}</h2>
            </div>
          </div>
        </div>

        <div class="filter-controls">
          <div class="filters">
            <!-- Custom Month Picker -->
            <div class="month-picker-wrap" @click.stop="toggleMonthMenu">
              <Icon
                icon="material-symbols:calendar-month-outline-rounded"
                width="18"
                height="18"
                class="icon-left"
              />
              <span>{{ formattedMonthLabel }}</span>
              <Icon
                icon="material-symbols:keyboard-arrow-down-rounded"
                width="18"
                height="18"
                class="icon-right"
              />
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

            <!-- BaseSelects -->
            <BaseSelect v-model="divisi" :options="divisions" @change="resetPage" />
            <BaseSelect v-model="grade" :options="gradeOptions" @change="resetPage" />
            <BaseSelect v-model="status" :options="statusOptions" @change="resetPage" />
          </div>

          <div class="actions-group">
            <BaseButton
              variant="primary"
              icon="material-symbols:add-rounded"
              @click="handleCreateNewSalary"
            >
              Gaji Baru
            </BaseButton>
            <BaseButton
              variant="ghost"
              icon="material-symbols:download-rounded"
              @click="handleExport"
            >
              Ekspor
            </BaseButton>
          </div>

          <div class="search-wrap">
            <BaseSearch
              v-model="search"
              @update:modelValue="resetPage"
              placeholder="Cari nama, NIK, atau kantor..."
              width="260px"
            />
          </div>
        </div>
      </div>

      <!-- Level 1: Tabel Perusahaan -->
      <BaseTable
        v-if="!selectedCompany"
        :columns="companyColumns"
        :data="companies"
        :loading="loadingCompanies"
        has-actions
        empty-text="Belum ada perusahaan."
      >
        <template #cell-name="{ item }">
          <strong>{{ item.name }}</strong>
        </template>
        <template #cell-address="{ item }">
          <span>{{ item.address || '-' }}</span>
        </template>
        <template #actions="{ item }">
          <button type="button" class="detail-link-btn" @click="goToCompany(item)">
            Pilih Perusahaan
          </button>
        </template>
      </BaseTable>

      <!-- Level 2: Tabel Cabang -->
      <BaseTable
        v-else-if="!isShowingPayroll"
        :columns="companyColumns"
        :data="filteredOfficeLocations"
        :loading="loadingLocations"
        has-actions
        empty-text="Belum ada cabang di perusahaan ini."
      >
        <template #cell-name="{ item }">
          <strong>{{ item.name }}</strong>
        </template>
        <template #cell-address="{ item }">
          <span>{{ item.address || '-' }}</span>
        </template>
        <template #actions="{ item }">
          <button type="button" class="detail-link-btn" @click="goToBranch(item)">
            Pilih Cabang
          </button>
        </template>
      </BaseTable>

      <!-- Level 3: Tabel Payroll -->
      <BaseTable
        v-else
        :columns="payrollColumns"
        :data="pageItems"
        :loading="loading"
        has-actions
        empty-text="Belum ada data gaji di lokasi ini."
      >
        <template #cell-karyawan="{ item }">
          <div class="employee">
            <div class="employee-avatar">{{ initials(item.name) }}</div>
            <div>
              <strong>{{ item.name }}</strong>
              <small>{{ item.code }} · {{ item.position }}</small>
            </div>
          </div>
        </template>
        <template #cell-pokok="{ item }">{{ rupiah(item.pokok) }}</template>
        <template #cell-tetap="{ item }">{{ rupiah(item.tetap) }}</template>
        <template #cell-variabel="{ item }">{{ rupiah(item.variabel) }}</template>
        <template #cell-potongan="{ item }">
          <span class="red-text">- {{ rupiah(item.potongan) }}</span>
        </template>
        <template #cell-netSalary="{ item }">
          <strong class="pay-text">{{ rupiah(item.netSalary) }}</strong>
        </template>
        <template #cell-status="{ item }">
          <span class="status-badge" :class="statusBadgeClass(item.status)">{{ item.status }}</span>
        </template>
        <template #actions="{ item }">
          <TableActions show-edit @edit="handleEditSalary(item.id)" />
        </template>
      </BaseTable>

      <!-- Table Footer / Pagination -->
      <BasePagination
        v-model:page="page"
        v-model:per-page="perPage"
        v-model:page-input="pageInput"
        :total-records="totalRecords"
        :last-page="lastPage"
        :loading="loading"
        @prev="prevPage"
        @next="nextPage"
        @change-per-page="resetPage"
        @submit-page="goToInputPage"
      />
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

/* Summary Grid */
.summary-grid {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 14px;
  margin-bottom: 20px;
}

/* Branch Table Header (Khusus Level 1 & Level 2) */
.branch-table-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
  padding: 18px 24px;
  background: var(--card);
  border-bottom: 1px solid var(--line);
  border-radius: 15px 15px 0 0;
  flex-wrap: wrap;
}

.branch-header-actions {
  display: flex;
  align-items: center;
  gap: 16px;
}

/* Filter Bar (Level 3 Payroll) */
.filter-bar {
  display: flex;
  flex-direction: column;
  gap: 16px;
  padding: 18px 24px;
  background: var(--card);
  border-bottom: 1px solid var(--line);
  border-radius: 15px 15px 0 0;
}
.filter-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
}
.filter-controls {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  flex-wrap: wrap;
}
.filters {
  display: flex;
  gap: 8px;
  align-items: center;
  flex-wrap: wrap;
}
.actions-group {
  display: flex;
  align-items: center;
  gap: 8px;
}

/* Drill-Down Header Styles */
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
.selected-office-heading h2 {
  margin: 0;
  color: var(--blue-900);
  font-size: 18px;
  font-weight: 700;
}
.back-btn {
  background: #ffffff;
  border: 1px solid #e4e7ec;
  border-radius: 10px;
  width: 40px;
  height: 40px;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  color: #2c3345;
  transition: background 0.2s;
}
.back-btn:hover {
  background: #f4f5f8;
}

/* Custom Month Picker */
.month-picker-wrap {
  position: relative;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 10px;
  height: 40px;
  background: var(--card);
  border: 1px solid var(--line);
  padding: 0 12px;
  border-radius: 10px;
  font-size: 14px;
  font-weight: 600;
  color: var(--ink);
  cursor: pointer;
  min-width: 170px;
  user-select: none;
}
.month-picker-wrap .icon-left,
.month-picker-wrap .icon-right {
  color: var(--ink-soft);
  flex-shrink: 0;
}
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

/* Cell Table Styles */
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

.detail-link-btn {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  color: var(--blue-900);
  font-weight: 700;
  background: none;
  border: none;
  cursor: pointer;
  font-size: 14px;
}
.detail-link-btn:hover {
  text-decoration: underline;
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

/* Table Footer / Pagination */
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

@media (max-width: 800px) {
  .summary-grid {
    grid-template-columns: 1fr;
  }
  .filter-header,
  .filter-controls,
  .branch-table-header {
    flex-direction: column;
    align-items: stretch;
  }
  .search-wrap {
    width: 100%;
  }
  .actions-group {
    width: 100%;
    justify-content: flex-end;
  }
}
</style>
