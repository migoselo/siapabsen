<script setup>
import { computed, onMounted, onBeforeUnmount, ref } from 'vue'
import { useRouter } from 'vue-router'
import { Icon } from '@iconify/vue'
import api from '../api'

// Import Base Components
import BaseSummaryCard from '../components/BaseSummaryCard.vue'
import BaseSelect from '../components/BaseSelect.vue'
import BaseSearch from '../components/BaseSearch.vue'
import BaseButton from '../components/BaseButton.vue'
import BaseTable from '../components/BaseTable.vue'
import TableActions from '../components/TableActions.vue'

const router = useRouter()

const employees = ref([])
const officeLocations = ref([])
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
const selectedCompany = ref(null)
const selectedBranch = ref(null)

/* ------------------------------------------------------------------ */
/* Konfigurasi Tabel BaseComponent                                     */
/* ------------------------------------------------------------------ */
const companyColumns = [
  { key: 'name', label: 'Nama Perusahaan/Cabang' },
  { key: 'address', label: 'Alamat' },
  { key: 'count', label: 'Karyawan Bergaji' },
  { key: 'budget', label: 'Total Anggaran Gaji' }
]

const payrollColumns = [
  { key: 'karyawan', label: 'Karyawan' },
  { key: 'pokok', label: 'Gaji Pokok' },
  { key: 'tetap', label: 'Tunj. Tetap' },
  { key: 'variabel', label: 'Tunj. Variabel' },
  { key: 'potongan', label: 'Potongan' },
  { key: 'netSalary', label: 'Take Home Pay' },
  { key: 'status', label: 'Status' }
]

const gradeOptions = ['Semua Level', 'Grade 3', 'Grade 4', 'Grade 5', 'Grade 6']
const statusOptions = ['Semua Status', 'Aktif', 'Menunggu Review', 'Perlu Update']

/* ------------------------------------------------------------------ */
/* Kontrol Custom Month Picker                                         */
/* ------------------------------------------------------------------ */
const showMonthMenu = ref(false)
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
        String(val || '').toLowerCase().includes(query),
      )
    const matchesDivisi = divisi.value === 'Semua Divisi' || employee.divisi === divisi.value
    const matchesStatus = status.value === 'Semua Status' || employee.status === status.value
    const matchesGrade =
      grade.value === 'Semua Level' || grade.value === 'Grade 0' || employee.position != null
    return matchesSearch && matchesDivisi && matchesStatus && matchesGrade
  }),
)

/* ------------------------------------------------------------------ */
/* Logika Hierarchy Drill-Down (Tree Perusahaan)                       */
/* ------------------------------------------------------------------ */
function resetDrillDown() {
  selectedCompany.value = null
  selectedBranch.value = null
}

function goToCompany(node) {
  selectedCompany.value = node
  selectedBranch.value = null
}

function goToBranch(node) {
  selectedBranch.value = node
}

function goBackToCompanies() {
  resetDrillDown()
}

function goBackToCompany() {
  selectedBranch.value = null
}

function splitHierarchyLabel(label) {
  const value = String(label || '').trim()
  if (!value) return []
  const separators = [' / ', ' > ', ' - ', ' | ']
  for (const separator of separators) {
    if (value.includes(separator)) {
      return value.split(separator).map((part) => part.trim()).filter(Boolean)
    }
  }
  return [value]
}

const companyTree = computed(() => {
  const roots = []
  const nodes = new Map()

  const addNode = (path, address = '-') => {
    let parent = null
    path.forEach((segment, index) => {
      const key = path.slice(0, index + 1).join(' / ')
      if (!nodes.has(key)) {
        const node = { id: key, name: segment, address, children: [], employees: [], count: 0, budget: 0 }
        if (parent) parent.children.push(node)
        else roots.push(node)
        nodes.set(key, node)
      }
      parent = nodes.get(key)
    })
    return parent
  }

  (officeLocations.value || []).forEach((company) => {
    const name = String(company?.name || '').trim()
    const address = String(company?.address || company?.alamat || '-').trim()
    if (!name) return
    const path = splitHierarchyLabel(name)
    addNode(path, address)
  })

  filtered.value.forEach((emp) => {
    const companyName = emp.lokasiKerja || 'Tanpa Perusahaan'
    const path = splitHierarchyLabel(companyName)
    const exactKey = path.join(' / ')
    const target = nodes.get(exactKey) || nodes.get(path[path.length - 1]) || addNode(path)
    
    if (target) {
      target.employees.push(emp)
    }
  })

  const assignStats = (node) => {
    node.count = node.employees.length
    node.budget = node.employees.reduce((sum, e) => sum + e.netSalary, 0)
    node.children.forEach((child) => {
      assignStats(child)
      node.count += child.count || 0
      node.budget += child.budget || 0
    })
  }

  roots.forEach(assignStats)
  return roots
})

const currentCompanyChildren = computed(() => {
  if (!selectedCompany.value) return companyTree.value
  return selectedCompany.value.children || []
})

const currentPayrolls = computed(() => {
  if (selectedBranch.value) return selectedBranch.value.employees || []
  if (selectedCompany.value) {
    if ((selectedCompany.value.children || []).length) return []
    return selectedCompany.value.employees || []
  }
  return []
})

const isShowingPayroll = computed(() => {
  return selectedBranch.value != null || (selectedCompany.value != null && currentCompanyChildren.value.length === 0)
})

/* Dashboard Stats Dinamis berdasarkan View saat ini */
const viewStats = computed(() => {
  if (isShowingPayroll.value) {
    const total = currentPayrolls.value.reduce((s, e) => s + e.netSalary, 0)
    return { budget: total, count: currentPayrolls.value.length }
  } else if (selectedCompany.value && !selectedBranch.value) {
    return { budget: selectedCompany.value.budget, count: selectedCompany.value.count }
  } else {
    const totalBudget = companyTree.value.reduce((s, c) => s + (c.budget || 0), 0)
    const totalCount = companyTree.value.reduce((s, c) => s + (c.count || 0), 0)
    return { budget: totalBudget, count: totalCount }
  }
})

// Pagination
const totalRecords = computed(() => isShowingPayroll.value ? currentPayrolls.value.length : 0)
const lastPage = computed(() => Math.max(1, Math.ceil(totalRecords.value / perPage.value)))
const pageItems = computed(() => {
  if (!isShowingPayroll.value) return []
  return currentPayrolls.value.slice((page.value - 1) * perPage.value, page.value * perPage.value)
})

/* ------------------------------------------------------------------ */
/* Fetch Data                                                          */
/* ------------------------------------------------------------------ */
async function fetchPayrolls() {
  loading.value = true
  try {
    const res = await api.get('/payrolls', {
      params: { month: selectedMonth.value, payroll_period: `${selectedMonth.value}-01` },
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

function handleExport() { window.alert('Fitur ekspor gaji belum tersedia.') }
function handleCreateNewSalary() { router.push({ name: 'GajiForm' }) }
function handleEditSalary(employeeId) { router.push({ name: 'GajiForm', params: { employeeId } }) }

onMounted(() => {
  fetchPayrolls()
  fetchLocations()
  document.addEventListener('click', handleOutsideClick)
})
onBeforeUnmount(() => { document.removeEventListener('click', handleOutsideClick) })
</script>

<template>
  <div class="salary-page">
    
    <!-- Section Summary / Dashboard (BaseSummaryCard) -->
    <section v-if="selectedCompany" class="summary-grid">
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
      <!-- Filter Bar -->
      <div class="filter-bar">
        
        <!-- Baris Navigasi & Pencarian (Drill Down Header) -->
        <div class="filter-header">
          <div class="breadcrumb-wrap">
            <button v-if="selectedCompany || selectedBranch" type="button" class="back-btn" @click="selectedBranch ? goBackToCompany() : goBackToCompanies()" title="Kembali">
              <Icon icon="material-symbols:arrow-back-rounded" width="22" height="22" />
            </button>
            <div v-if="!selectedCompany" class="table-heading">
              <h2>Pilih Kantor</h2>
              <p>Pilih kantor terlebih dahulu untuk mengelola gaji.</p>
            </div>
            <div v-else class="selected-office-heading">
              <span>Kantor terpilih</span>
              <h2>{{ selectedBranch?.name || selectedCompany.name }}</h2>
            </div>
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

        <!-- Baris Filter Dropdown & Aksi -->
        <div class="filter-controls">
          <div class="filters">
            <!-- Custom Month Picker -->
            <div class="month-picker-wrap" @click.stop="toggleMonthMenu">
              <Icon icon="material-symbols:calendar-month-outline-rounded" width="18" height="18" class="icon-left" />
              <span>{{ formattedMonthLabel }}</span>
              <Icon icon="material-symbols:keyboard-arrow-down-rounded" width="18" height="18" class="icon-right" />
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
                  <button v-for="(m, idx) in monthList" :key="m" type="button" class="month-item" :class="{ active: isCurrentSelectedMonth(idx) }" @click="selectMonth(idx)">{{ m }}</button>
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
            <BaseButton variant="primary" icon="material-symbols:add-rounded" @click="handleCreateNewSalary">
              Gaji Baru
            </BaseButton>
            <BaseButton variant="ghost" icon="material-symbols:download-rounded" @click="handleExport">
              Ekspor
            </BaseButton>
          </div>
        </div>
      </div>

      <!-- TABEL DAFTAR PERUSAHAAN / CABANG (Level 1 & 2) -->
      <BaseTable 
        v-if="!isShowingPayroll"
        :columns="companyColumns" 
        :data="!selectedCompany ? companyTree : currentCompanyChildren" 
        has-actions 
        empty-text="Kantor atau lokasi tidak ditemukan."
      >
        <template #cell-name="{ item }">
          <strong>{{ item.name }}</strong>
        </template>
        
        <template #cell-count="{ item }">
          <span class="count-badge">{{ item.count || 0 }} Orang</span>
        </template>
        
        <template #cell-budget="{ item }">
          <strong>{{ rupiah(item.budget) }}</strong>
        </template>
        
        <template #actions="{ item }">
          <button type="button" class="detail-link-btn" @click="!selectedCompany ? goToCompany(item) : goToBranch(item)">
            Lihat Gaji
          </button>
        </template>
      </BaseTable>

      <!-- TABEL DAFTAR KARYAWAN & GAJI (Level 3 - Payroll) -->
      <BaseTable 
        v-else
        :columns="payrollColumns" 
        :data="pageItems" 
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
        <template #cell-potongan="{ item }"><span class="red-text">- {{ rupiah(item.potongan) }}</span></template>
        <template #cell-netSalary="{ item }"><strong class="pay-text">{{ rupiah(item.netSalary) }}</strong></template>
        <template #cell-status="{ item }">
          <span class="status-badge" :class="statusBadgeClass(item.status)">{{ item.status }}</span>
        </template>
        <template #actions="{ item }">
          <TableActions show-edit @edit="handleEditSalary(item.id)" />
        </template>
      </BaseTable>

      <!-- Table Footer / Pagination (Hanya tampil saat mode Payroll) -->
      <div v-if="isShowingPayroll" class="table-footer">
        <div class="table-footer-content">
          <div class="pager">
            <button type="button" class="pager-btn" :disabled="page === 1" @click="prevPage" title="Halaman Sebelumnya">
              <Icon icon="material-symbols:chevron-left-rounded" width="18" height="18" />
            </button>
            <div class="page-input-wrapper">
              <span>Halaman</span>
              <input type="number" v-model.number="pageInput" @keydown.enter="goToInputPage" @blur="goToInputPage" min="1" :max="lastPage" class="page-input" />
              <span>dari {{ lastPage }}</span>
            </div>
            <button type="button" class="pager-btn" :disabled="page === lastPage" @click="nextPage" title="Halaman Berikutnya">
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

/* Filter Bar Layout */
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

/* Drill-Down Header Styles (Sesuai DataKaryawanView_3) */
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

/* Custom Month Picker Styles Wrapper */
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
.month-picker-wrap .icon-left, .month-picker-wrap .icon-right {
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
  display: flex; align-items: center; justify-content: space-between; margin-bottom: 12px;
}
.year-label { font-weight: 700; font-size: 15px; color: var(--ink); }
.nav-btn {
  background: transparent; border: none; border-radius: 6px; color: var(--ink-soft); cursor: pointer; display: grid; place-items: center; padding: 2px;
}
.nav-btn:hover { background: #f4f5f8; color: var(--blue-900); }
.month-grid { display: grid; grid-template-columns: repeat(3, 1fr); gap: 8px; }
.month-item {
  border: none; background: #f7f8fa; padding: 8px 0; border-radius: 8px; font-size: 13px; font-weight: 600; color: var(--ink); cursor: pointer; transition: all 0.15s ease;
}
.month-item:hover { background: #e8ebf5; color: var(--blue-900); }
.month-item.active { background: var(--blue-900); color: #ffffff; font-weight: 700; }
.month-picker-footer {
  display: flex; justify-content: flex-end; margin-top: 10px; padding-top: 8px; border-top: 1px solid var(--line);
}
.btn-text {
  background: none; border: none; font-size: 12px; font-weight: 700; color: var(--blue-900); cursor: pointer; padding: 2px 4px;
}
.btn-text:hover { text-decoration: underline; }

/* Kustomisasi Cell Table Khusus */
.employee {
  display: flex;
  align-items: center;
  gap: 12px;
}
.employee small {
  display: block; color: var(--ink-soft); font-size: 12px;
}
.employee-avatar {
  width: 36px; height: 36px; border-radius: 50%; background: #e2e5f0; color: var(--blue-900);
  font-size: 12px; font-weight: 700; display: grid; place-items: center; flex-shrink: 0;
}

.count-badge {
  display: inline-flex; font-size: 12px; color: var(--ink-soft); background: #e9edf7;
  border-radius: 999px; padding: 4px 10px; font-weight: 700;
}

.detail-link-btn {
  display: inline-flex; align-items: center; gap: 6px; color: var(--blue-900); font-weight: 700;
  background: none; border: none; cursor: pointer; font-size: 14px;
}
.detail-link-btn:hover { text-decoration: underline; }

.red-text { color: #c91f2d; font-weight: 600; }
.pay-text { color: var(--blue-900); font-size: 14px; }
.status-badge {
  display: inline-flex; padding: 6px 12px; border-radius: 999px; font-size: 11px;
  font-weight: 700; white-space: nowrap;
}
.status-badge.on-time { background: #dcf8e5; color: #15924f; }
.status-badge.late { background: #fff0c7; color: #9a6900; }
.status-badge.missed { background: #fde0e2; color: #c91f2d; }

/* Table Footer / Pagination */
.table-footer {
  display: flex; justify-content: flex-end; align-items: center; padding: 12px 20px;
  font-size: 13px; color: var(--ink-soft); border-top: 1px solid var(--line);
  background: var(--bg); border-radius: 0 0 15px 15px;
}
.table-footer-content { display: flex; align-items: center; gap: 16px; }
.pager { display: flex; align-items: center; gap: 6px; }
.pager-btn {
  width: 32px; height: 32px; border-radius: 6px; border: 1px solid var(--line);
  background: var(--card); display: inline-flex; align-items: center; justify-content: center;
  cursor: pointer; transition: all 0.15s ease; color: var(--ink-soft);
}
.pager-btn:hover:not(:disabled) { background: #fff; border-color: var(--blue-900); color: var(--blue-900); }
.pager-btn:disabled { opacity: 0.4; cursor: not-allowed; }
.page-input-wrapper { display: flex; align-items: center; gap: 6px; font-weight: 600; color: var(--ink-soft); font-size: 13px; }
.page-input {
  width: 44px; height: 32px; text-align: center; border: 1px solid var(--line);
  border-radius: 6px; background: var(--card); color: var(--ink); font-weight: 700;
  font-size: 13px; outline: none; appearance: textfield; -moz-appearance: textfield;
}
.page-input::-webkit-outer-spin-button, .page-input::-webkit-inner-spin-button { -webkit-appearance: none; margin: 0; }
.page-input:focus { border-color: var(--blue-900); box-shadow: 0 0 0 2px rgba(47, 59, 105, 0.12); }
.per-page-select select {
  height: 32px; padding: 0 10px; border: 1px solid var(--line); border-radius: 6px;
  background: var(--card); color: var(--ink); font-size: 13px; font-weight: 600; cursor: pointer; outline: none;
}
.total-records-info { font-size: 13px; font-weight: 600; color: var(--ink-soft); white-space: nowrap; }

@media (max-width: 800px) {
  .summary-grid { grid-template-columns: 1fr; }
  .filter-header, .filter-controls { flex-direction: column; align-items: stretch; }
  .search-wrap { width: 100%; }
  .actions-group { width: 100%; justify-content: flex-end; }
}
</style>