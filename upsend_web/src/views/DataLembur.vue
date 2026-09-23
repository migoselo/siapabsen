<script setup>
/**
 * DataLembur.vue
 * Halaman "Data Lembur" — daftar & approval pengajuan lembur karyawan.
 * Diperbarui dengan Hierarchy Drill-Down dan Base Components.
 */
import { ref, reactive, computed, watch, onMounted, onUnmounted } from 'vue'
import { Icon } from '@iconify/vue'
import api from '../api'
import DetailLembur from './DetailLembur.vue'

// Import Base Components
import BaseSummaryCard from '../components/BaseSummaryCard.vue'
import BaseSelect from '../components/BaseSelect.vue'
import BaseSearch from '../components/BaseSearch.vue'
import BaseButton from '../components/BaseButton.vue'
import BaseTable from '../components/BaseTable.vue'
import TableActions from '../components/TableActions.vue'

/* ------------------------------------------------------------------ */
/* Konfigurasi Tabel (BaseTable)                                       */
/* ------------------------------------------------------------------ */
const companyColumns = [
  { key: 'name', label: 'Nama Perusahaan/Cabang' },
  { key: 'address', label: 'Alamat' },
  { key: 'count', label: 'Total Pengajuan Lembur' }
]

const requestColumns = [
  { key: 'requester', label: 'Pemohon' },
  { key: 'datetime', label: 'Tanggal & Waktu' },
  { key: 'duration', label: 'Durasi' },
  { key: 'reason', label: 'Alasan' }
]

/* ------------------------------------------------------------------ */
/* Departemen — dikelola admin lewat modal                             */
/* ------------------------------------------------------------------ */
const defaultDepartments = [
  { id: 'd1', name: 'Engineering' },
  { id: 'd2', name: 'Marketing' },
  { id: 'd3', name: 'Finance' },
  { id: 'd4', name: 'Creative' },
  { id: 'd5', name: 'HR' },
  { id: 'd6', name: 'Operations' },
]

const storageAvailable = (() => {
  try {
    const testKey = '__siaphadir_test__'
    window.localStorage.setItem(testKey, '1')
    window.localStorage.removeItem(testKey)
    return true
  } catch {
    return false
  }
})()

function loadFromStorage(key, fallback) {
  if (!storageAvailable) return JSON.parse(JSON.stringify(fallback))
  try {
    const raw = window.localStorage.getItem(key)
    return raw ? JSON.parse(raw) : JSON.parse(JSON.stringify(fallback))
  } catch {
    return JSON.parse(JSON.stringify(fallback))
  }
}

const departments = reactive(loadFromStorage('siaphadir_departments_lembur', defaultDepartments))
const departmentOptions = computed(() => {
  return [
    { label: 'Semua Departemen', value: '' },
    ...departments.map((d) => ({ label: d.name, value: d.id }))
  ]
})

const storageWarning = ref(
  !storageAvailable ? 'Penyimpanan lokal tidak tersedia. Perubahan hanya berlaku selama sesi ini.' : '',
)

function persistSettings() {
  if (!storageAvailable) return
  try {
    window.localStorage.setItem('siaphadir_departments_lembur', JSON.stringify(departments))
    storageWarning.value = ''
  } catch (error) {
    console.error('Gagal menyimpan pengaturan ke localStorage:', error)
    storageWarning.value = 'Gagal menyimpan perubahan ke penyimpanan lokal.'
  }
}

let idCounter = 0
function nextId(prefix) {
  idCounter += 1
  return `${prefix}${Date.now()}${idCounter}`
}

const newDepartmentName = ref('')
function addDepartment() {
  const name = newDepartmentName.value.trim()
  if (!name) return
  departments.push({ id: nextId('d'), name })
  newDepartmentName.value = ''
  persistSettings()
}
function removeDepartment(id) {
  const idx = departments.findIndex((d) => d.id === id)
  if (idx > -1) departments.splice(idx, 1)
  persistSettings()
}
function departmentName(id) {
  return departments.find((d) => d.id === id)?.name || '-'
}

/* ------------------------------------------------------------------ */
/* Data API, Drill-Down & Fetching                                     */
/* ------------------------------------------------------------------ */
const apiLoading = ref(false)
const apiError = ref('')
const requests = reactive([])
const officeLocations = ref([])

const selectedCompany = ref(null)
const selectedBranch = ref(null)

function mkReq(name, position, departmentId, locationName, date, startTime, endTime, durationHours, reason, status, requestId) {
  return reactive({
    id: requestId ?? nextId('req'),
    requester: { name, position, departmentId, locationName, avatarUrl: '' },
    date,
    startTime,
    endTime,
    durationHours,
    durationLabel: `${durationHours}.0 Jam`,
    reason,
    status,
  })
}

function parseDurationHours(value, startTime, endTime) {
  if (typeof value === 'number' && Number.isFinite(value)) return value
  if (typeof value === 'string' && value.trim() !== '') {
    const match = value.match(/(\d+(?:[.,]\d+)?)/)
    if (match) return Number(match[1].replace(',', '.'))
  }
  if (startTime && endTime) {
    const start = new Date(`2000-01-01T${startTime}:00`)
    const end = new Date(`2000-01-01T${endTime}:00`)
    if (!Number.isNaN(start.getTime()) && !Number.isNaN(end.getTime())) {
      const diffHours = (end.getTime() - start.getTime()) / (1000 * 60 * 60)
      if (diffHours > 0) return diffHours
    }
  }
  return 1
}

function isOvertimeRow(row = {}) {
  const rawType = String(row?.type ?? row?.leaveTypeName ?? row?.leave_type?.name ?? row?.leaveType?.name ?? '').trim().toLowerCase()
  if (rawType.includes('lembur') || rawType.includes('overtime')) return true
  if (row?.start_time || row?.end_time || row?.startTime || row?.endTime) return true
  return false
}

function normalizeOvertimeApiRequest(payload) {
  const name = payload.requester?.name || payload.employee?.name || payload.user?.name || 'Unknown'
  const position = payload.requester?.position || payload.employee?.position || payload.user?.role || '-'
  const departmentId = payload.requester?.departmentId || payload.employee?.departmentId || payload.departmentId || payload.department_id || 'd1'
  const locationName = payload.requester?.locationName || payload.employee?.home_location?.name || payload.user?.home_location?.name || 'Tanpa Perusahaan'
  
  const startTime = payload.startTime || payload.start_time || '18:00'
  const endTime = payload.endTime || payload.end_time || '21:00'
  const date = payload.startDate || payload.start_date || payload.createdAt || payload.created_at || new Date().toISOString().slice(0, 10)
  const durationHours = parseDurationHours(payload.durationHours ?? payload.totalHours ?? payload.duration_hours, startTime, endTime)

  return mkReq(
    name, position, departmentId, locationName, date, startTime, endTime, durationHours,
    payload.reason || 'Tidak ada keterangan',
    String(payload.status || 'pending').toLowerCase(),
    payload.id ?? null
  )
}

function extractRowsFromPayload(payload) {
  if (Array.isArray(payload)) return payload
  if (Array.isArray(payload?.data)) return payload.data
  if (Array.isArray(payload?.items)) return payload.items
  if (Array.isArray(payload?.results)) return payload.results
  return []
}

async function fetchLocations() {
  try {
    const res = await api.get('/locations')
    officeLocations.value = Array.isArray(res.data) ? res.data : []
  } catch (err) {
    console.error('Gagal mengambil data lokasi kerja:', err)
  }
}

async function fetchOvertimeRequests() {
  try {
    apiLoading.value = true
    apiError.value = ''
    let rows = []
    
    const firstPage = await api.get('/admin/leave-requests', { params: { page: 1, per_page: 50 } })
    const payload = firstPage?.data || {}
    rows = [...extractRowsFromPayload(payload)]
    const lastPage = Number(payload?.last_page || 1)
    
    if (lastPage > 1) {
      for (let page = 2; page <= lastPage; page++) {
        const { data } = await api.get('/admin/leave-requests', { params: { page, per_page: 50 } })
        rows.push(...extractRowsFromPayload(data))
      }
    }

    const overtimeRows = rows.filter((row) => isOvertimeRow(row))
    requests.splice(0, requests.length, ...overtimeRows.map(normalizeOvertimeApiRequest))
  } catch (error) {
    console.error('Gagal memuat data lembur dari API:', error)
    apiError.value = 'Gagal memuat data lembur dari server.'
  } finally {
    apiLoading.value = false
  }
}

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

function splitHierarchyLabel(label) {
  const value = String(label || '').trim()
  if (!value) return []
  const separators = [' / ', ' > ', ' - ', ' | ']
  for (const separator of separators) {
    if (value.includes(separator)) return value.split(separator).map((p) => p.trim()).filter(Boolean)
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
        const node = { id: key, name: segment, address, children: [], requests: [], count: 0 }
        if (parent) parent.children.push(node)
        else roots.push(node)
        nodes.set(key, node)
      }
      parent = nodes.get(key)
    })
    return parent
  }

  (officeLocations.value || []).forEach((loc) => {
    if (!loc?.name) return
    addNode(splitHierarchyLabel(loc.name), loc.address || '-')
  })

  // Memasukkan pengajuan lembur ke dalam cabang
  requests.forEach((req) => {
    const locName = req.requester.locationName || 'Tanpa Perusahaan'
    const path = splitHierarchyLabel(locName)
    const exactKey = path.join(' / ')
    const target = nodes.get(exactKey) || nodes.get(path[path.length - 1]) || addNode(path)
    if (target) target.requests.push(req)
  })

  const assignCounts = (node) => {
    node.count = node.requests.length
    node.children.forEach((child) => {
      assignCounts(child)
      node.count += child.count || 0
    })
  }

  roots.forEach(assignCounts)
  return roots
})

const currentCompanyChildren = computed(() => {
  if (!selectedCompany.value) return companyTree.value
  return selectedCompany.value.children || []
})

const currentRequests = computed(() => {
  if (selectedBranch.value) return selectedBranch.value.requests || []
  if (selectedCompany.value) {
    if ((selectedCompany.value.children || []).length) return []
    return selectedCompany.value.requests || []
  }
  return []
})

const isShowingRequests = computed(() => {
  return selectedBranch.value != null || (selectedCompany.value != null && currentCompanyChildren.value.length === 0)
})

/* ------------------------------------------------------------------ */
/* Dashboard Statistik & Filters                                       */
/* ------------------------------------------------------------------ */
const totalOvertimeHours = computed(() => {
  const total = currentRequests.value.reduce((sum, req) => sum + Number(req.durationHours || 0), 0)
  return `${Number(total).toLocaleString('id-ID')} Jam`
})

const topOvertimeEmployee = computed(() => {
  if (currentRequests.value.length === 0) return null
  const summaryMap = {}
  currentRequests.value.forEach((req) => {
    const name = req.requester.name
    if (!summaryMap[name]) {
      summaryMap[name] = { name, department: departmentName(req.requester.departmentId), totalHours: 0 }
    }
    summaryMap[name].totalHours += req.durationHours
  })
  const sorted = Object.values(summaryMap).sort((a, b) => b.totalHours - a.totalHours)
  return sorted[0] || null
})

const tabs = [
  { key: 'pending', label: 'Menunggu' },
  { key: 'approved', label: 'Diterima' },
  { key: 'rejected', label: 'Ditolak' },
]
const activeTab = ref('pending')
const searchQuery = ref('')
const departmentFilter = ref('')
const currentPage = ref(1)
const perPage = ref(20)
const pageInput = ref(1)

function countByStatus(status) {
  return currentRequests.value.filter((r) => r.status === status).length
}

const filteredRequests = computed(() => {
  return currentRequests.value.filter((r) => {
    if (r.status !== activeTab.value) return false
    if (departmentFilter.value && r.requester.departmentId !== departmentFilter.value) return false
    if (searchQuery.value.trim() && !r.requester.name.toLowerCase().includes(searchQuery.value.trim().toLowerCase())) return false
    return true
  })
})

const totalPages = computed(() => Math.max(1, Math.ceil(filteredRequests.value.length / perPage.value)))
const paginatedRequests = computed(() => {
  const start = (currentPage.value - 1) * perPage.value
  return filteredRequests.value.slice(start, start + perPage.value)
})

watch([activeTab, departmentFilter, searchQuery, selectedCompany, selectedBranch], () => {
  currentPage.value = 1
  pageInput.value = 1
})

function goToInputPage() {
  let page = Number(pageInput.value)
  if (isNaN(page) || page < 1) page = 1
  if (page > totalPages.value) page = totalPages.value
  pageInput.value = page
  currentPage.value = page
}

function changePerPage() {
  currentPage.value = 1
  pageInput.value = 1
}

/* ------------------------------------------------------------------ */
/* Detail, Approval & Ekspor Laporan                                   */
/* ------------------------------------------------------------------ */
const selectedRequestForDetail = ref(null)
function openDetail(req) { selectedRequestForDetail.value = req }
function closeDetail() { selectedRequestForDetail.value = null }

async function updateRequestStatus(id, status) {
  try {
    await api.patch(`/admin/leave-requests/${id}/status`, { status })
    const request = requests.find((item) => item.id === id)
    if (request) request.status = status
    if (selectedRequestForDetail.value?.id === id) closeDetail()
  } catch (error) {
    console.error('Gagal memperbarui status pengajuan:', error)
  }
}
function approveRequest(id) { return updateRequestStatus(id, 'approved') }
function rejectRequest(id) { return updateRequestStatus(id, 'rejected') }

const dateFmt = new Intl.DateTimeFormat('id-ID', { day: '2-digit', month: 'short', year: 'numeric' })
function initials(name) { return name.split(' ').map((w) => w[0]).slice(0, 2).join('').toUpperCase() }

const detailRequestForView = computed(() => {
  const r = selectedRequestForDetail.value
  if (!r) return null
  return {
    id: r.id,
    employee: { name: r.requester.name, position: r.requester.position, department: departmentName(r.requester.departmentId), employeeId: '-', email: '-', avatarUrl: '' },
    date: r.date, startTime: r.startTime, endTime: r.endTime, durationLabel: r.durationLabel, reason: r.reason, status: r.status,
  }
})

/* Ekspor logik */
function exportRows() {
  return filteredRequests.value.map((r) => ({
    Pemohon: r.requester.name,
    Jabatan: r.requester.position,
    Departemen: departmentName(r.requester.departmentId),
    Tanggal: dateFmt.format(new Date(r.date)),
    'Jam Mulai': r.startTime,
    'Jam Selesai': r.endTime,
    Durasi: r.durationLabel,
    Alasan: r.reason,
    Status: r.status === 'pending' ? 'Menunggu' : r.status === 'approved' ? 'Diterima' : 'Ditolak',
  }))
}

function exportCSV() {
  const rows = exportRows()
  if (!rows.length) return
  const headers = Object.keys(rows[0])
  const escapeCsv = (val) => `"${String(val).replace(/"/g, '""')}"`
  const lines = [headers.join(','), ...rows.map((row) => headers.map((h) => escapeCsv(row[h])).join(','))]
  const blob = new Blob(['\ufeff' + lines.join('\n')], { type: 'text/csv;charset=utf-8;' })
  downloadBlob(blob, `lembur-${activeTab.value}-${Date.now()}.csv`)
}

async function exportPDF() {
  const rows = exportRows()
  if (!rows.length) return
  try {
    const { default: jsPDF } = await import('jspdf')
    const { default: autoTable } = await import('jspdf-autotable')
    const doc = new jsPDF({ orientation: 'landscape' })
    doc.text('Data Lembur Karyawan', 14, 15)
    autoTable(doc, {
      head: [Object.keys(rows[0])],
      body: rows.map((row) => Object.values(row)),
      startY: 22, styles: { fontSize: 10 }
    })
    doc.save(`lembur-${activeTab.value}-${Date.now()}.pdf`)
  } catch (error) {
    console.error('Gagal ekspor PDF', error)
  }
}
function downloadBlob(blob, filename) {
  const url = URL.createObjectURL(blob)
  const a = document.createElement('a')
  a.href = url
  a.download = filename
  a.click()
  URL.revokeObjectURL(url)
}

const showExportMenu = ref(false)
const showManageModal = ref(false)

function handleOutsideClick(e) {
  if (!e.target.closest?.('.export-menu')) showExportMenu.value = false
}

onMounted(() => {
  fetchLocations()
  fetchOvertimeRequests()
  document.addEventListener('click', handleOutsideClick)
})
onUnmounted(() => document.removeEventListener('click', handleOutsideClick))
</script>

<template>
  <div class="data-lembur">
    <DetailLembur
      v-if="selectedRequestForDetail"
      :request="detailRequestForView"
      @back="closeDetail"
      @approve="({ id }) => approveRequest(id)"
      @reject="({ id }) => rejectRequest(id)"
    />

    <template v-else>
      <div v-if="storageWarning" class="storage-warning">
        <Icon icon="material-symbols:warning-outline" width="18" /> {{ storageWarning }}
      </div>

      <!-- Dashboard Statistik hanya dirender jika lokasi/perusahaan telah dipilih -->
      <div v-if="isShowingRequests" class="stats-grid">
        <BaseSummaryCard 
          tag="BULAN INI" title="Total Jam Lembur" :value="totalOvertimeHours"
          subtitle="Akumulasi seluruh departemen" icon="material-symbols:schedule-outline" theme="amber"
        />
        <BaseSummaryCard 
          v-if="topOvertimeEmployee"
          tag="TOP" title="Karyawan Lembur Tertinggi" :value="topOvertimeEmployee.name"
          :subtitle="`${topOvertimeEmployee.department} • ${topOvertimeEmployee.totalHours} Jam`"
          icon="material-symbols:person-outline" theme="green"
        />
        <BaseSummaryCard 
          tag="RATA-RATA" title="Durasi / Hari" value="2.4 Jam"
          subtitle="Efisiensi waktu kerja ekstra" icon="material-symbols:timer-outline" theme="red"
        />
      </div>

      <div class="card">
        
        <!-- Header Drill Down Navigasi -->
        <div class="filter-header">
          <div class="breadcrumb-wrap">
            <button v-if="selectedCompany || selectedBranch" type="button" class="back-btn" @click="selectedBranch ? resetDrillDown() : resetDrillDown()" title="Kembali">
              <Icon icon="material-symbols:arrow-back-rounded" width="22" height="22" />
            </button>
            <div v-if="!selectedCompany" class="table-heading">
              <h2>Pilih Kantor</h2>
              <p>Pilih kantor terlebih dahulu untuk mengelola data lembur.</p>
            </div>
            <div v-else class="selected-office-heading">
              <span>Kantor terpilih</span>
              <h2>{{ selectedBranch?.name || selectedCompany.name }}</h2>
            </div>
          </div>
        </div>

        <div v-if="isShowingRequests" class="card-toolbar">
          <div class="tabs">
            <button
              v-for="tab in tabs" :key="tab.key"
              class="tab" :class="{ 'tab-active': activeTab === tab.key }"
              @click="activeTab = tab.key"
            >
              {{ tab.label }}
              <span class="tab-count" :class="{ 'tab-count-active': activeTab === tab.key }">
                {{ countByStatus(tab.key) }}
              </span>
            </button>
          </div>
          
          <div class="toolbar-actions">
            <BaseSearch v-model="searchQuery" placeholder="Cari nama karyawan..." width="240px" />
            <div class="export-menu">
              <BaseButton variant="primary" icon="material-symbols:download" @click.stop="showExportMenu = !showExportMenu">
                Ekspor Laporan
              </BaseButton>
              <div v-if="showExportMenu" class="dropdown">
                <button @click="(exportCSV(), showExportMenu = false)">Ekspor CSV</button>
                <button @click="(exportPDF(), showExportMenu = false)">Ekspor PDF</button>
              </div>
            </div>
          </div>
        </div>

        <div v-if="isShowingRequests" class="filters-row">
          <div class="filters">
            <BaseSelect v-model="departmentFilter" :options="departmentOptions" placeholder="Semua Departemen" />
            <BaseButton variant="ghost" icon="material-symbols:tune" @click="showManageModal = true">
              Kelola Departemen
            </BaseButton>
          </div>
        </div>

        <!-- Tabel Perusahaan/Cabang -->
        <BaseTable 
          v-if="!isShowingRequests"
          :columns="companyColumns"
          :data="!selectedCompany ? companyTree : currentCompanyChildren"
          has-actions
          empty-text="Kantor atau lokasi tidak ditemukan."
        >
          <template #cell-name="{ item }"><strong>{{ item.name }}</strong></template>
          <template #cell-count="{ item }"><span class="badge duration-badge">{{ item.count || 0 }} Pengajuan</span></template>
          <template #actions="{ item }">
            <button type="button" class="detail-link-btn" @click="!selectedCompany ? goToCompany(item) : goToBranch(item)">
              Lihat Lembur
            </button>
          </template>
        </BaseTable>

        <!-- Tabel Pengajuan Lembur -->
        <BaseTable 
          v-else
          :columns="requestColumns"
          :data="paginatedRequests"
          has-actions
          empty-text="Tidak ada permintaan lembur yang cocok dengan filter saat ini."
        >
          <template #cell-requester="{ item }">
            <div class="requester">
              <div class="avatar-sm avatar-fallback">{{ initials(item.requester.name) }}</div>
              <div>
                <p class="requester-name">{{ item.requester.name }}</p>
                <p class="requester-sub">{{ item.requester.position }} • {{ departmentName(item.requester.departmentId) }}</p>
              </div>
            </div>
          </template>
          <template #cell-datetime="{ item }">
            <p class="duration-main">{{ dateFmt.format(new Date(item.date)) }}</p>
            <p class="duration-sub">{{ item.startTime }} — {{ item.endTime }}</p>
          </template>
          <template #cell-duration="{ item }">
            <span class="badge duration-badge">{{ item.durationLabel }}</span>
          </template>
          <template #cell-reason="{ item }">
            <p class="reason-text" :title="item.reason">{{ item.reason }}</p>
          </template>
          <template #actions="{ item }">
            <TableActions 
              v-if="item.status === 'pending'"
              show-approve show-reject show-view
              @approve="approveRequest(item.id)"
              @reject="rejectRequest(item.id)"
              @view="openDetail(item)"
            />
            <div v-else class="status-action">
              <span class="badge" :style="item.status === 'approved' ? { background: '#E9F9EF', color: '#1B8A5A' } : { background: '#FDEEEE', color: '#C53030' }">
                {{ item.status === 'approved' ? 'Diterima' : 'Ditolak' }}
              </span>
              <TableActions show-view @view="openDetail(item)" />
            </div>
          </template>
        </BaseTable>

        <!-- Pagination (Hanya untuk daftar lembur) -->
        <div v-if="isShowingRequests" class="table-footer">
          <div class="table-footer-content">
            <div class="pager">
              <button class="pager-btn" :disabled="currentPage === 1" @click="currentPage--"><Icon icon="material-symbols:chevron-left-rounded" width="18" /></button>
              <div class="page-input-wrapper">
                <span>Halaman</span>
                <input type="number" v-model.number="pageInput" @keydown.enter="goToInputPage" @blur="goToInputPage" min="1" :max="totalPages" class="page-input" />
                <span>dari {{ totalPages }}</span>
              </div>
              <button class="pager-btn" :disabled="currentPage === totalPages" @click="currentPage++"><Icon icon="material-symbols:chevron-right-rounded" width="18" /></button>
            </div>
            <div class="per-page-select">
              <select v-model="perPage" @change="changePerPage">
                <option :value="10">10 baris</option>
                <option :value="20">20 baris</option>
                <option :value="50">50 baris</option>
              </select>
            </div>
            <span class="total-records-info">{{ filteredRequests.length }} permintaan</span>
          </div>
        </div>

      </div>

      <!-- Modal Kelola Departemen -->
      <div v-if="showManageModal" class="modal-overlay" @click.self="showManageModal = false">
        <div class="modal">
          <div class="modal-header">
            <h2>Kelola Departemen Lembur</h2>
            <button class="icon-btn-plain" @click="showManageModal = false"><Icon icon="material-symbols:close" width="18" /></button>
          </div>
          <div class="modal-body">
            <div v-for="d in departments" :key="d.id" class="manage-row">
              <input v-model="d.name" class="manage-input" @change="persistSettings" />
              <button class="icon-btn-plain" @click="removeDepartment(d.id)"><Icon icon="material-symbols:delete-outline" width="18" /></button>
            </div>
            <div class="manage-add-row">
              <input v-model="newDepartmentName" placeholder="Nama departemen baru" class="manage-input" @keydown.enter.prevent="addDepartment" />
              <BaseButton variant="primary" @click="addDepartment">Tambah</BaseButton>
            </div>
          </div>
        </div>
      </div>
    </template>
  </div>
</template>

<style scoped>
@import url('https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap');

.data-lembur {
  --accent: #252f58;
  --ink-dark: #2c3345;
  --ink-soft: #667085;
  --line: #e4e7ec;
  font-family: 'Plus Jakarta Sans', sans-serif;
  font-size: 14px;
  color: var(--ink-dark);
}
.data-lembur button, .data-lembur input, .data-lembur select { font-family: inherit; }

.storage-warning {
  display: flex; align-items: center; gap: 8px; background: #fff3e6; color: #c05621;
  border: 1px solid #f6d9b3; border-radius: 10px; padding: 10px 14px; font-size: 13px; font-weight: 600; margin-bottom: 16px;
}

.stats-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(240px, 1fr)); gap: 14px; margin-bottom: 20px; }

.card { background: #fff; border: 1px solid var(--line); border-radius: 12px; overflow: visible; box-shadow: 0 1px 2px rgba(16, 24, 20, 0.05); }

/* Drill-Down Header Navigation */
.filter-header { display: flex; align-items: center; justify-content: space-between; gap: 12px; padding: 18px 24px; border-bottom: 1px solid var(--line); }
.breadcrumb-wrap { display: flex; align-items: center; gap: 12px; }
.back-btn {
  background: #ffffff; border: 1px solid var(--line); border-radius: 10px; width: 40px; height: 40px;
  display: flex; align-items: center; justify-content: center; cursor: pointer; color: var(--ink-dark); transition: background 0.2s;
}
.back-btn:hover { background: #f4f5f8; }
.table-heading h2 { margin: 0; color: #2f3b69; font-size: 18px; font-weight: 700; }
.table-heading p { margin: 4px 0 0; color: var(--ink-soft); font-size: 13px; }
.selected-office-heading span { display: block; margin-bottom: 3px; color: var(--ink-soft); font-size: 12px; }
.selected-office-heading h2 { margin: 0; color: #2f3b69; font-size: 18px; font-weight: 700; }

.card-toolbar { display: flex; flex-wrap: wrap; align-items: center; justify-content: space-between; gap: 12px; padding: 16px 24px 0; }
.tabs { display: flex; align-items: center; gap: 24px; border-bottom: 1px solid var(--line); width: 100%; margin-bottom: 8px;}
.tab { background: none; border: none; border-bottom: 2px solid transparent; padding: 0 0 12px; font-size: 15px; font-weight: 600; color: var(--ink-soft); display: flex; align-items: center; gap: 8px; cursor: pointer; transform: translateY(1px); }
.tab-active { color: var(--accent); border-bottom-color: var(--accent); }
.tab-count { font-size: 12px; font-weight: 700; background: #f1f2f5; color: var(--ink-soft); border-radius: 999px; padding: 1px 8px; }
.tab-count-active { background: var(--accent); color: #fff; }

.toolbar-actions { display: flex; align-items: center; justify-content: space-between; width: 100%; padding-bottom: 16px;}
.export-menu { position: relative; }
.dropdown { position: absolute; right: 0; top: calc(100% + 8px); background: #fff; border: 1px solid var(--line); border-radius: 10px; box-shadow: 0 8px 24px rgba(20, 25, 45, 0.12); min-width: 170px; overflow: hidden; z-index: 20; }
.dropdown button { display: block; width: 100%; text-align: left; background: none; border: none; padding: 10px 14px; font-size: 14px; color: var(--ink-dark); cursor: pointer; }
.dropdown button:hover { background: #f4f5f8; }

.filters-row { display: flex; flex-wrap: wrap; align-items: center; justify-content: space-between; gap: 12px; padding: 0 24px 16px; }
.filters { display: flex; align-items: center; gap: 10px; flex-wrap: wrap; }

/* Custom Cell Styles */
.requester { display: flex; align-items: center; gap: 12px; }
.avatar-fallback { background: #e2e5f0; color: var(--accent); display: flex; align-items: center; justify-content: center; font-size: 11px; font-weight: 700; width: 36px; height: 36px; border-radius: 50%; }
.requester-name { margin: 0; font-weight: 700; color: var(--ink-dark); }
.requester-sub { margin: 2px 0 0; font-size: 13px; color: var(--ink-soft); }
.badge { display: inline-block; font-size: 12px; font-weight: 700; padding: 4px 10px; border-radius: 6px; }
.duration-badge { background: #eaf0ff; color: #2a4365; }
.duration-main { margin: 0; font-weight: 600; color: var(--ink-dark); }
.duration-sub { margin: 2px 0 0; font-size: 12px; color: var(--ink-soft); }
.reason-text { margin: 0; color: var(--ink-soft); max-width: 260px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }

.status-action { display: flex; align-items: center; gap: 12px; justify-content: flex-end;}
.detail-link-btn { display: inline-flex; align-items: center; color: #2f3b69; font-weight: 700; background: none; border: none; cursor: pointer; font-size: 14px; }
.detail-link-btn:hover { text-decoration: underline; }

.table-footer { display: flex; justify-content: flex-end; align-items: center; padding: 16px 24px; font-size: 13px; color: var(--ink-soft); }
.table-footer-content { display: flex; align-items: center; gap: 16px; }
.pager { display: flex; align-items: center; gap: 6px; }
.pager-btn { width: 32px; height: 32px; border-radius: 6px; border: 1px solid var(--line); background: #fff; display: inline-flex; align-items: center; justify-content: center; cursor: pointer; color: var(--ink-soft); }
.pager-btn:hover:not(:disabled) { background: #fafbfc; border-color: var(--accent); color: var(--accent); }
.pager-btn:disabled { opacity: 0.4; cursor: not-allowed; }
.page-input-wrapper { display: flex; align-items: center; gap: 6px; font-weight: 600; color: var(--ink-soft); font-size: 13px; }
.page-input { width: 44px; height: 32px; text-align: center; border: 1px solid var(--line); border-radius: 6px; font-weight: 700; font-size: 13px; outline: none; }
.page-input:focus { border-color: var(--accent); }
.per-page-select select { height: 32px; padding: 0 10px; border: 1px solid var(--line); border-radius: 6px; font-size: 13px; font-weight: 600; cursor: pointer; outline: none; }

.modal-overlay { position: fixed; inset: 0; background: rgba(20, 25, 45, 0.45); display: flex; align-items: center; justify-content: center; padding: 16px; z-index: 50; }
.modal { background: #fff; border-radius: 16px; width: 100%; max-width: 520px; }
.modal-header { display: flex; align-items: center; justify-content: space-between; padding: 18px 24px; border-bottom: 1px solid var(--line); }
.modal-header h2 { font-size: 16px; margin: 0; }
.icon-btn-plain { background: none; border: none; color: var(--ink-soft); cursor: pointer; display: flex; align-items: center; }
.icon-btn-plain:hover { color: var(--ink-dark); }
.modal-body { padding: 20px 24px; display: flex; flex-direction: column; gap: 10px; }
.manage-row { display: flex; align-items: center; gap: 10px; border: 1px solid var(--line); border-radius: 10px; padding: 8px 10px; }
.manage-input { flex: 1; border: none; font-size: 14px; color: var(--ink-dark); outline: none; }
.manage-add-row { display: flex; gap: 8px; padding-top: 6px; }
.manage-add-row .manage-input { border: 1px solid var(--line); border-radius: 10px; padding: 8px 10px; }

@media (max-width: 640px) {
  .toolbar-actions { flex-direction: column; align-items: stretch; }
  .export-menu { text-align: right; }
}
</style>