<script setup>
/**
 * DataLembur.vue
 * Halaman "Data Lembur" — daftar & approval pengajuan lembur karyawan.
 * Dirender di dalam <router-view> milik Layout.vue.
 */
import { ref, reactive, computed, watch, onMounted, onUnmounted } from 'vue'
import { Icon } from '@iconify/vue'
import api from '../api'
import DetailLembur from './DetailLembur.vue'

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

const storageWarning = ref(
  !storageAvailable
    ? 'Penyimpanan lokal browser tidak tersedia. Perubahan hanya berlaku selama sesi ini.'
    : '',
)

function persistSettings() {
  if (!storageAvailable) return
  try {
    window.localStorage.setItem(
      'siaphadir_departments_lembur',
      JSON.stringify(departments.map(({ id, name }) => ({ id, name }))),
    )
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
/* Data pengajuan lembur                                              */
/* ------------------------------------------------------------------ */
const apiLoading = ref(false)
const apiError = ref('')

const fallbackOvertimeRequests = [
  mkReq('Bambang Kusuma', 'Senior Developer', 'd1', '2023-10-12', '18:00', '22:00', 4, 'Critical deployment for the Q4 release candidate.'),
  mkReq('Dewi Sartika', 'Marketing Specialist', 'd2', '2023-10-14', '17:00', '20:00', 3, 'Menyelesaikan laporan kampanye marketing bulanan.'),
  mkReq('Budi Santoso', 'Finance Staff', 'd3', '2023-10-15', '16:00', '22:00', 6, 'Audit penutupan buku keuangan bulanan.'),
  mkReq('Andi Saputra', 'Accountant', 'd3', '2023-10-18', '18:30', '21:30', 3, 'Rekonsiliasi data keuangan kuartal ketiga.'),
  mkReq('Siti Aminah', 'Lead Designer', 'd4', '2023-10-25', '17:00', '21:00', 4, 'Revisi aset UI/UX untuk klien prioritas.'),
]

const requests = reactive([])

function mkReq(name, position, departmentId, date, startTime, endTime, durationHours, reason, status = 'pending') {
  return reactive({
    id: crypto.randomUUID ? crypto.randomUUID() : nextId('req'),
    requester: { name, position, departmentId, avatarUrl: '' },
    date,
    startTime,
    endTime,
    durationHours,
    durationLabel: `${durationHours}.0 Jam`,
    reason,
    status, // 'pending' | 'approved' | 'rejected'
  })
}

function isOvertimeRow(row = {}) {
  const rawType = String(
    row?.type ?? row?.leaveTypeName ?? row?.leave_type?.name ?? row?.leaveType?.name ?? '',
  ).trim().toLowerCase()

  if (rawType.includes('lembur') || rawType.includes('overtime')) return true
  if (row?.start_time || row?.end_time || row?.startTime || row?.endTime) return true

  return false
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

function normalizeOvertimeApiRequest(item) {
  const payload = item || {}
  const name = payload.requester?.name || payload.employee?.name || payload.user?.name || 'Unknown'
  const position = payload.requester?.position || payload.employee?.position || payload.user?.role || '-'
  const departmentId =
    payload.requester?.departmentId ||
    payload.employee?.departmentId ||
    payload.departmentId ||
    payload.department_id ||
    'd1'

  const startTime = payload.startTime || payload.start_time || '18:00'
  const endTime = payload.endTime || payload.end_time || '21:00'
  const date = payload.startDate || payload.start_date || payload.createdAt || payload.created_at || new Date().toISOString().slice(0, 10)
  const durationHours = parseDurationHours(payload.durationHours ?? payload.totalHours ?? payload.duration_hours, startTime, endTime)

  return mkReq(
    name,
    position,
    departmentId,
    date,
    startTime,
    endTime,
    durationHours,
    payload.reason || 'Tidak ada keterangan',
    String(payload.status || 'pending').toLowerCase(),
  )
}

async function fetchOvertimeRequests() {
  try {
    apiLoading.value = true
    apiError.value = ''

    let rows = []

    try {
      const firstPage = await api.get('/admin/leave-requests', {
        params: { page: 1, per_page: 50 },
      })
      const payload = firstPage?.data || {}
      const firstBatch = Array.isArray(payload?.data) ? payload.data : Array.isArray(payload) ? payload : []
      rows = [...firstBatch]

      const lastPage = Number(payload?.last_page || 1)
      if (lastPage > 1) {
        for (let page = 2; page <= lastPage; page += 1) {
          const { data } = await api.get('/admin/leave-requests', {
            params: { page, per_page: 50 },
          })
          const batch = Array.isArray(data?.data) ? data.data : Array.isArray(data) ? data : []
          rows.push(...batch)
        }
      }
    } catch {
      const { data } = await api.get('/leave-requests')
      rows = Array.isArray(data) ? data : []
    }

    const overtimeRows = rows.filter((row) => isOvertimeRow(row))
    requests.splice(0, requests.length, ...overtimeRows.map(normalizeOvertimeApiRequest))

    if (requests.length === 0 && overtimeRows.length === 0) {
      requests.splice(0, requests.length, ...fallbackOvertimeRequests.map((item) => ({ ...item })))
    }
  } catch (error) {
    console.error('Gagal memuat data lembur dari API:', error)
    apiError.value = 'Gagal memuat data lembur dari server. Menampilkan data cadangan.'
    requests.splice(0, requests.length, ...fallbackOvertimeRequests.map((item) => ({ ...item })))
  } finally {
    apiLoading.value = false
  }
}

/* ------------------------------------------------------------------ */
/* Statistik ringkas lembur & Karyawan Tertinggi                       */
/* ------------------------------------------------------------------ */
const pendingCount = computed(() => requests.filter((r) => r.status === 'pending').length)
const totalOvertimeHours = computed(() => {
  const total = requests.reduce((sum, req) => sum + Number(req.durationHours || 0), 0)
  return `${Number(total).toLocaleString('id-ID')} Jam`
})

const topOvertimeEmployee = computed(() => {
  if (requests.length === 0) return null
  
  const summaryMap = {}
  requests.forEach((req) => {
    const name = req.requester.name
    if (!summaryMap[name]) {
      summaryMap[name] = {
        name,
        department: departmentName(req.requester.departmentId),
        totalHours: 0,
        avatarUrl: req.requester.avatarUrl
      }
    }
    summaryMap[name].totalHours += req.durationHours
  })

  const sorted = Object.values(summaryMap).sort((a, b) => b.totalHours - a.totalHours)
  return sorted[0] || null
})

/* ------------------------------------------------------------------ */
/* Tabs, pencarian, filter, pagination                                 */
/* ------------------------------------------------------------------ */
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

watch(currentPage, (newPage) => {
  pageInput.value = newPage
})

function countByStatus(status) {
  return requests.filter((r) => r.status === status).length
}

const filteredRequests = computed(() => {
  return requests.filter((r) => {
    if (r.status !== activeTab.value) return false
    if (departmentFilter.value && r.requester.departmentId !== departmentFilter.value) return false
    if (searchQuery.value.trim()) {
      const q = searchQuery.value.trim().toLowerCase()
      if (!r.requester.name.toLowerCase().includes(q)) return false
    }
    return true
  })
})

const totalPages = computed(() => Math.max(1, Math.ceil(filteredRequests.value.length / perPage.value)))

const paginatedRequests = computed(() => {
  const start = (currentPage.value - 1) * perPage.value
  return filteredRequests.value.slice(start, start + perPage.value)
})

watch([activeTab, departmentFilter, searchQuery], () => {
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
/* Aksi approve / reject                                               */
/* ------------------------------------------------------------------ */
function approveRequest(id, comment = '') {
  const r = requests.find((x) => x.id === id)
  if (r) r.status = 'approved'
  if (selectedRequest.value?.id === id) closeDetail()
}
function rejectRequest(id, comment = '') {
  const r = requests.find((x) => x.id === id)
  if (r) r.status = 'rejected'
  if (selectedRequest.value?.id === id) closeDetail()
}

/* ------------------------------------------------------------------ */
/* Tampilan detail lembur                                              */
/* ------------------------------------------------------------------ */
const selectedRequest = ref(null)
function openDetail(req) {
  selectedRequest.value = req
}
function closeDetail() {
  selectedRequest.value = null
}

const detailRequestForView = computed(() => {
  const r = selectedRequest.value
  if (!r) return null
  return {
    id: r.id,
    employee: {
      name: r.requester.name,
      position: r.requester.position,
      department: departmentName(r.requester.departmentId),
      employeeId: 'EMP-' + Math.floor(1000 + Math.random() * 9000),
      email: `${r.requester.name.toLowerCase().replace(/\s+/g, '.')}@company.com`,
      avatarUrl: r.requester.avatarUrl || '',
    },
    date: r.date,
    startTime: r.startTime,
    endTime: r.endTime,
    durationLabel: r.durationLabel,
    reason: r.reason,
    status: r.status,
  }
})

/* ------------------------------------------------------------------ */
/* Helper & Ekspor Laporan                                             */
/* ------------------------------------------------------------------ */
function initials(name) {
  return name.split(' ').map((w) => w[0]).slice(0, 2).join('').toUpperCase()
}

const dateFmt = new Intl.DateTimeFormat('id-ID', { day: '2-digit', month: 'short', year: 'numeric' })

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
  if (rows.length === 0) return
  const headers = Object.keys(rows[0])
  const escapeCsv = (val) => `"${String(val).replace(/"/g, '""')}"`
  const lines = [headers.join(','), ...rows.map((row) => headers.map((h) => escapeCsv(row[h])).join(','))]
  const blob = new Blob(['\ufeff' + lines.join('\n')], { type: 'text/csv;charset=utf-8;' })
  downloadBlob(blob, `data-lembur-${activeTab.value}-${todayStamp()}.csv`)
}

const exportError = ref('')

async function exportPDF() {
  const rows = exportRows()
  if (rows.length === 0) return
  exportError.value = ''
  try {
    const { default: jsPDF } = await import('jspdf')
    const { default: autoTable } = await import('jspdf-autotable')

    const doc = new jsPDF({ orientation: 'landscape' })
    doc.setFontSize(16)
    doc.text('Data Lembur Karyawan', 14, 15)
    doc.setFontSize(14)
    doc.text(`Status: ${tabs.find((t) => t.key === activeTab.value)?.label}`, 14, 21)
    const headers = Object.keys(rows[0])
    const body = rows.map((row) => headers.map((h) => row[h]))

    autoTable(doc, {
      head: [headers],
      body,
      startY: 26,
      styles: { fontSize: 12, cellPadding: 2 },
      headStyles: { fillColor: [37, 47, 88] },
    })

    doc.save(`data-lembur-${activeTab.value}-${todayStamp()}.pdf`)
  } catch (error) {
    console.error('Gagal membuat PDF:', error)
    exportError.value = 'Gagal membuat file PDF. Pastikan jspdf & jspdf-autotable terpasang.'
  }
}

function downloadBlob(blob, filename) {
  const url = URL.createObjectURL(blob)
  const a = document.createElement('a')
  a.href = url
  a.download = filename
  document.body.appendChild(a)
  a.click()
  a.remove()
  URL.revokeObjectURL(url)
}

function todayStamp() {
  const d = new Date()
  return `${d.getFullYear()}${String(d.getMonth() + 1).padStart(2, '0')}${String(d.getDate()).padStart(2, '0')}`
}

const showExportMenu = ref(false)
const showManageModal = ref(false)

function handleOutsideClick(e) {
  if (!e.target.closest?.('.export-menu')) showExportMenu.value = false
}
onMounted(() => {
  fetchOvertimeRequests()
  document.addEventListener('click', handleOutsideClick)
})
onUnmounted(() => document.removeEventListener('click', handleOutsideClick))
</script>

<template>
  <div class="data-lembur">
    <DetailLembur
      v-if="selectedRequest"
      :request="detailRequestForView"
      @back="closeDetail"
      @approve="({ id, comment }) => approveRequest(id, comment)"
      @reject="({ id, comment }) => rejectRequest(id, comment)"
    />

    <template v-else>
      <div v-if="storageWarning" class="storage-warning">
        <Icon icon="material-symbols:warning-outline" width="18" />
        {{ storageWarning }}
      </div>

      <div class="stats-grid">
        <div class="stat-card">
          <div class="stat-top">
            <div class="stat-icon"><Icon icon="material-symbols:schedule-outline" width="22" /></div>
            <span class="trend trend-up">
              <Icon icon="material-symbols:arrow-upward" width="12" /> 12%
            </span>
          </div>
          <p class="stat-label">Total Jam Lembur (Bulan Ini)</p>
          <p class="stat-value">{{ totalOvertimeHours }}</p>
          <p class="stat-sub">Akumulasi seluruh departemen</p>
        </div>

        <div class="stat-card" v-if="topOvertimeEmployee">
          <div class="stat-top">
            <div class="stat-icon stat-icon-green">
              <Icon icon="material-symbols:chair-alt-outline" width="22" />
            </div>
          </div>
          <p class="stat-label">Karyawan Lembur Tertinggi</p>
          <div class="top-employee-row">
            <div class="avatar-sm avatar-fallback-green">
              {{ initials(topOvertimeEmployee.name) }}
            </div>
            <div>
              <p class="top-employee-name">{{ topOvertimeEmployee.name }}</p>
              <p class="top-employee-sub">{{ topOvertimeEmployee.department }} • {{ topOvertimeEmployee.totalHours }} Jam</p>
            </div>
          </div>
        </div>

        <div class="stat-card">
          <div class="stat-top">
            <div class="stat-icon"><Icon icon="material-symbols:timer-outline" width="22" /></div>
            <span class="trend trend-down">
              <Icon icon="material-symbols:arrow-downward" width="12" /> 2%
            </span>
          </div>
          <p class="stat-label">Rata-rata Durasi / Hari</p>
          <p class="stat-value">2.4 Jam</p>
          <p class="stat-sub">Efisiensi waktu kerja ekstra</p>
        </div>
      </div>

      <div class="card">
        <div class="card-toolbar">
          <div class="tabs">
            <button
              v-for="tab in tabs"
              :key="tab.key"
              class="tab"
              :class="{ 'tab-active': activeTab === tab.key }"
              @click="activeTab = tab.key"
            >
              {{ tab.label }}
              <span class="tab-count" :class="{ 'tab-count-active': activeTab === tab.key }">
                {{ countByStatus(tab.key) }}
              </span>
            </button>
          </div>

          <div class="toolbar-actions">
            <div class="search-box">
              <Icon icon="material-symbols:search" width="18" class="search-icon" />
              <input v-model="searchQuery" type="text" placeholder="Cari nama karyawan..." />
            </div>

            <div class="export-menu">
              <button class="btn-primary" @click.stop="showExportMenu = !showExportMenu">
                <Icon icon="material-symbols:download" width="16" /> Ekspor Laporan
              </button>
              <div v-if="showExportMenu" class="dropdown">
                <button @click="(exportCSV(), (showExportMenu = false))">Ekspor sebagai CSV</button>
                <button @click="(exportPDF(), (showExportMenu = false))">Ekspor sebagai PDF</button>
              </div>
            </div>
          </div>
        </div>

        <p v-if="exportError" class="export-error">{{ exportError }}</p>

        <div class="filters-row">
          <div class="filters">
            <select v-model="departmentFilter" class="select">
              <option value="">Semua Departemen</option>
              <option v-for="d in departments" :key="d.id" :value="d.id">{{ d.name }}</option>
            </select>
            <button class="btn-ghost" @click="showManageModal = true">
              <Icon icon="material-symbols:tune" width="16" /> Kelola Departemen
            </button>
          </div>
        </div>

        <div class="table-wrap">
          <table class="table">
            <thead>
              <tr>
                <th>Pemohon</th>
                <th>Tanggal & Waktu</th>
                <th>Durasi</th>
                <th>Alasan</th>
                <th class="col-actions">Aksi</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="req in paginatedRequests" :key="req.id">
                <td>
                  <div class="requester">
                    <img
                      v-if="req.requester.avatarUrl"
                      :src="req.requester.avatarUrl"
                      class="avatar-sm"
                    />
                    <div v-else class="avatar-sm avatar-fallback">
                      {{ initials(req.requester.name) }}
                    </div>
                    <div>
                      <p class="requester-name">{{ req.requester.name }}</p>
                      <p class="requester-sub">
                        {{ req.requester.position }} •
                        {{ departmentName(req.requester.departmentId) }}
                      </p>
                    </div>
                  </div>
                </td>
                <td class="nowrap">
                  <p class="duration-main">{{ dateFmt.format(new Date(req.date)) }}</p>
                  <p class="duration-sub">{{ req.startTime }} — {{ req.endTime }}</p>
                </td>
                <td>
                  <span class="badge duration-badge">{{ req.durationLabel }}</span>
                </td>
                <td class="col-reason">
                  <p class="reason-text" :title="req.reason">{{ req.reason }}</p>
                </td>
                <td class="col-actions">
                  <div class="actions">
                    <!-- URUTAN AKSI: Reject (Tolak) -> Accept (Terima) -> View (Lihat Detail) -->
                    <template v-if="req.status === 'pending'">
                      <button
                        class="icon-btn icon-btn-reject separator-right"
                        title="Tolak"
                        @click="rejectRequest(req.id)"
                      >
                        <Icon icon="material-symbols:close" width="16" />
                      </button>

                      <button
                        class="icon-btn icon-btn-approve separator-right"
                        title="Terima"
                        @click="approveRequest(req.id)"
                      >
                        <Icon icon="material-symbols:check" width="16" />
                      </button>
                    </template>

                    <span
                      v-else
                      class="badge"
                      :style="
                        req.status === 'approved'
                          ? { background: '#E9F9EF', color: '#1B8A5A' }
                          : { background: '#FDEEEE', color: '#C53030' }
                      "
                    >
                      {{ req.status === 'approved' ? 'Diterima' : 'Ditolak' }}
                    </span>

                    <button
                      class="icon-btn icon-btn-view"
                      title="Lihat Detail"
                      @click="openDetail(req)"
                    >
                      <Icon icon="material-symbols:visibility-outline" width="16" />
                    </button>
                  </div>
                </td>
              </tr>

              <tr v-if="paginatedRequests.length === 0">
                <td colspan="5" class="empty-row">
                  Tidak ada permintaan lembur yang cocok dengan filter saat ini.
                </td>
              </tr>
            </tbody>
          </table>
        </div>

                <div class="table-footer">
          <div class="table-footer-content">
            <div class="pager">
              <button
                type="button"
                class="pager-btn"
                :disabled="currentPage === 1"
                @click="currentPage--"
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
                  :max="totalPages"
                  class="page-input"
                />
                <span>dari {{ totalPages }}</span>
              </div>

              <button
                type="button"
                class="pager-btn"
                :disabled="currentPage === totalPages"
                @click="currentPage++"
                title="Halaman Berikutnya"
              >
                <Icon icon="material-symbols:chevron-right-rounded" width="18" height="18" />
              </button>
            </div>

            <div class="per-page-select">
              <select v-model="perPage" @change="changePerPage">
                <option :value="10">10 baris</option>
                <option :value="20">20 baris</option>
                <option :value="50">50 baris</option>
                <option :value="100">100 baris</option>
              </select>
            </div>

            <span class="total-records-info">{{ filteredRequests.length }} permintaan</span>
          </div>
        </div>
      </div>

      <div v-if="showManageModal" class="modal-overlay" @click.self="showManageModal = false">
        <div class="modal">
          <div class="modal-header">
            <h2>Kelola Departemen Lembur</h2>
            <button class="icon-btn-plain" @click="showManageModal = false">
              <Icon icon="material-symbols:close" width="18" />
            </button>
          </div>

          <div class="modal-body">
            <div v-for="d in departments" :key="d.id" class="manage-row">
              <input v-model="d.name" class="manage-input" @change="persistSettings" />
              <button class="icon-btn-plain" @click="removeDepartment(d.id)">
                <Icon icon="material-symbols:delete-outline" width="18" />
              </button>
            </div>

            <div class="manage-add-row">
              <input
                v-model="newDepartmentName"
                placeholder="Nama departemen baru"
                class="manage-input"
                @keydown.enter.prevent="addDepartment"
              />
              <button type="button" class="btn-primary" @click="addDepartment">Tambah</button>
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
  --accent: var(--sidebar-accent, #252f58);
  --ink-dark: var(--ink-dark, #2c3345);
  --ink-soft: var(--ink-soft, #667085);
  --line: var(--line, #e4e7ec);
  font-family: 'Plus Jakarta Sans', sans-serif;
  font-size: 14px;
  color: var(--ink-dark);
}

.data-lembur button,
.data-lembur input,
.data-lembur select {
  font-family: inherit;
}

.storage-warning {
  display: flex;
  align-items: center;
  gap: 8px;
  background: #fff3e6;
  color: #c05621;
  border: 1px solid #f6d9b3;
  border-radius: 10px;
  padding: 10px 14px;
  font-size: 13px;
  font-weight: 600;
  margin-bottom: 16px;
}

.export-error {
  margin: 0;
  padding: 0 24px 12px;
  font-size: 13px;
  font-weight: 600;
  color: #c53030;
}

.stats-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(260px, 1fr));
  gap: 16px;
  margin-bottom: 20px;
}
.stat-card {
  background: #fff;
  border: 1px solid #eaecf0;
  border-radius: 12px;
  padding: 20px;
  box-shadow: 0 1px 2px rgba(16, 24, 40, 0.05);
}
.stat-top {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  margin-bottom: 16px;
}
.stat-icon {
  width: 44px;
  height: 44px;
  border-radius: 12px;
  background: #eaf0ff;
  color: #2a4365;
  display: flex;
  align-items: center;
  justify-content: center;
}
.stat-icon-green {
  background: #e6f7f6;
  color: #0f766e;
}
.trend {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  font-size: 11px;
  font-weight: 700;
  padding: 4px 8px;
  border-radius: 999px;
}
.trend-up {
  color: #c05621;
  background: #fff3e6;
}
.trend-down {
  color: #2a4365;
  background: #eaf0ff;
}
.stat-label {
  font-size: 14px;
  font-weight: 600;
  letter-spacing: 0.6px;
  color: var(--ink-soft);
  margin: 0 0 4px;
}
.stat-value {
  font-size: 32px;
  font-weight: 800;
  margin: 0 0 4px;
  color: var(--ink-dark);
}
.stat-sub {
  font-size: 13px;
  color: var(--ink-soft);
  margin: 0;
}

.top-employee-row {
  display: flex;
  align-items: center;
  gap: 12px;
  margin-top: 8px;
}
.avatar-fallback-green {
  background: #e6f7f6;
  color: #0f766e;
  width: 40px;
  height: 40px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 13px;
  font-weight: 700;
  flex-shrink: 0;
}
.top-employee-name {
  margin: 0 0 2px 0;
  font-weight: 700;
  color: var(--ink-dark);
  font-size: 15px;
}
.top-employee-sub {
  margin: 0;
  font-size: 13px;
  color: var(--ink-soft);
}

.card {
  background: #fff;
  border: 1px solid #eaecf0;
  border-radius: 12px;
  overflow: hidden;
  box-shadow: 0 1px 2px rgba(16, 24, 20, 0.05);
}
.card-toolbar {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  padding: 16px 24px 0;
}
.tabs {
  display: flex;
  align-items: center;
  gap: 24px;
}
.tab {
  background: none;
  border: none;
  border-bottom: 2px solid transparent;
  padding: 0 0 12px;
  font-size: 15px;
  font-weight: 600;
  color: var(--ink-soft);
  display: flex;
  align-items: center;
  gap: 8px;
  cursor: pointer;
}
.tab-active {
  color: var(--accent);
  border-bottom-color: var(--accent);
}
.tab-count {
  font-size: 12px;
  font-weight: 700;
  background: #f1f2f5;
  color: var(--ink-soft);
  border-radius: 999px;
  padding: 1px 8px;
}
.tab-count-active {
  background: var(--accent);
  color: #fff;
}
.toolbar-actions {
  display: flex;
  align-items: center;
  gap: 12px;
}
.search-box {
  position: relative;
}
.search-icon {
  position: absolute;
  left: 10px;
  top: 50%;
  transform: translateY(-50%);
  color: var(--ink-soft);
}
.search-box input {
  padding: 9px 12px 9px 36px;
  font-size: 15px;
  border: 1px solid var(--line);
  border-radius: 8px;
  width: 220px;
}
.search-box input:focus {
  outline: 2px solid rgba(37, 47, 88, 0.15);
  border-color: var(--accent);
}

.btn-primary {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  background: #2F3B69;
  color: #ffffff;
  font-size: 15px;
  font-weight: 700;
  border: none;
  border-radius: 8px;
  padding: 9px 16px;
  cursor: pointer;
}
.btn-ghost {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  background: none;
  border: 1px solid var(--line);
  border-radius: 8px;
  padding: 8px 12px;
  font-size: 15px;
  font-weight: 600;
  color: var(--ink-soft);
  cursor: pointer;
}
.btn-ghost:hover {
  background: #f4f5f8;
}

.export-menu {
  position: relative;
}
.dropdown {
  position: absolute;
  right: 0;
  top: calc(100% + 8px);
  background: #fff;
  border: 1px solid var(--line);
  border-radius: 10px;
  box-shadow: 0 8px 24px rgba(20, 25, 45, 0.12);
  min-width: 170px;
  overflow: hidden;
  z-index: 20;
}
.dropdown button {
  display: block;
  width: 100%;
  text-align: left;
  background: none;
  border: none;
  padding: 10px 14px;
  font-size: 14px;
  color: var(--ink-dark);
  cursor: pointer;
}
.dropdown button:hover {
  background: #f4f5f8;
}

.filters-row {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  padding: 16px 24px;
}
.filters {
  display: flex;
  align-items: center;
  gap: 10px;
  flex-wrap: wrap;
}
.select {
  font-size: 15px;
  border: 1px solid var(--line);
  border-radius: 8px;
  padding: 8px 10px;
  color: var(--ink-dark);
  background: #fff;
}
.pagination-label {
  font-size: 13px;
  color: var(--ink-soft);
  margin: 0;
}

.table-wrap {
  overflow-x: auto;
  border-top: 1px solid #eaecf0;
  border-bottom: 1px solid #eaecf0;
}
.table {
  width: 100%;
  border-collapse: collapse;
  font-size: 14px;
}
.table thead tr {
  background-color: #2f3b69;
  border: none;
}
.table th {
  text-align: left;
  padding: 14px 24px;
  font-size: 12px;
  font-weight: 700;
  letter-spacing: 0.8px;
  text-transform: uppercase;
  color: #ffffff;
}
.col-actions {
  text-align: left;
  width: 1%;
  white-space: nowrap;
}
.table tbody tr {
  border-bottom: 1px solid #f1f2f5;
}
.table tbody tr:last-child {
  border-bottom: none;
}
.table tbody tr:hover {
  background: #fafbfc;
}
.table td {
  padding: 14px 24px;
  vertical-align: middle;
  border-bottom: 1px solid #f1f2f5;
}
.requester {
  display: flex;
  align-items: center;
  gap: 12px;
}
.avatar-sm {
  width: 36px;
  height: 36px;
  border-radius: 50%;
  object-fit: cover;
  flex-shrink: 0;
}
.avatar-fallback {
  background: #e2e5f0;
  color: var(--accent);
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 11px;
  font-weight: 700;
}
.requester-name {
  margin: 0;
  font-weight: 700;
  color: var(--ink-dark);
}
.requester-sub {
  margin: 2px 0 0;
  font-size: 14px;
  color: var(--ink-soft);
}
.badge {
  display: inline-block;
  font-size: 12px;
  font-weight: 700;
  padding: 4px 10px;
  border-radius: 6px;
  line-height: 1.4;
}
.duration-badge {
  background: #eaf0ff;
  color: #2a4365;
}
.nowrap {
  white-space: nowrap;
}
.duration-main {
  margin: 0;
  font-weight: 600;
  color: var(--ink-dark);
}
.duration-sub {
  margin: 2px 0 0;
  font-size: 12px;
  color: var(--ink-soft);
}
.col-reason {
  max-width: 260px;
}
.reason-text {
  margin: 0;
  color: var(--ink-soft);
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
.actions {
  display: flex;
  align-items: center;
  justify-content: flex-start;
  gap: 8px;
}
.icon-btn {
  width: 30px;
  height: 30px;
  border-radius: 50%;
  border: none;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
}
.icon-btn-view {
  background: #eaf0ff;
  color: #2a4365;
}
.icon-btn-view:hover {
  background: #dbe6ff;
}
.icon-btn-reject {
  background: #fdeeee;
  color: #e53e3e;
}
.icon-btn-reject:hover {
  background: #fbdada;
}
.separator-right {
  margin-right: 12px;
}
.icon-btn-approve {
  background: #38a169;
  color: #fff;
}
.icon-btn-approve:hover {
  background: #2f855a;
}
.empty-row {
  text-align: center;
  padding: 48px 24px;
  color: var(--ink-soft);
}

.table-footer {
  display: flex;
  justify-content: flex-end;
  align-items: center;
  padding: 16px 24px;
  font-size: 13px;
  color: var(--ink-soft);
  border-top: 1px solid var(--line);
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
  background: #fff;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  transition: all 0.15s ease;
  color: var(--ink-soft);
}
.pager-btn:hover:not(:disabled) {
  background: #fafbfc;
  border-color: var(--accent);
  color: var(--accent);
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
  font-family: inherit;
  width: 44px;
  height: 32px;
  text-align: center;
  border: 1px solid var(--line);
  border-radius: 6px;
  background: #fff;
  color: var(--ink-dark);
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
  border-color: var(--accent);
  box-shadow: 0 0 0 2px rgba(37, 47, 88, 0.12);
}

.per-page-select select {
  height: 32px;
  padding: 0 10px;
  border: 1px solid var(--line);
  border-radius: 6px;
  background: #fff;
  color: var(--ink-dark);
  font-size: 13px;
  font-weight: 600;
  cursor: pointer;
  outline: none;
  font-family: inherit;
}
.per-page-select select:focus {
  border-color: var(--accent);
}

.total-records-info {
  font-size: 13px;
  font-weight: 600;
  color: var(--ink-soft);
  white-space: nowrap;
}

.modal-overlay {
  position: fixed;
  inset: 0;
  background: rgba(20, 25, 45, 0.45);
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 16px;
  z-index: 30;
}
.modal {
  background: #fff;
  border-radius: 16px;
  width: 100%;
  max-width: 520px;
  max-height: 85vh;
  overflow-y: auto;
}
.modal-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 18px 24px;
  border-bottom: 1px solid var(--line);
}
.modal-header h2 {
  font-size: 16px;
  margin: 0;
}
.icon-btn-plain {
  background: none;
  border: none;
  color: var(--ink-soft);
  cursor: pointer;
  display: flex;
  align-items: center;
}
.icon-btn-plain:hover {
  color: var(--ink-dark);
}
.modal-body {
  padding: 20px 24px;
  display: flex;
  flex-direction: column;
  gap: 10px;
}
.manage-row {
  display: flex;
  align-items: center;
  gap: 10px;
  border: 1px solid var(--line);
  border-radius: 10px;
  padding: 8px 10px;
}
.manage-input {
  flex: 1;
  border: none;
  font-size: 14px;
  color: var(--ink-dark);
}
.manage-input:focus {
  outline: none;
}
.manage-add-row {
  display: flex;
  gap: 8px;
  padding-top: 6px;
}
.manage-add-row .manage-input {
  border: 1px solid var(--line);
  border-radius: 10px;
  padding: 8px 10px;
}

@media (max-width: 640px) {
  .card-toolbar,
  .filters-row,
  .pagination {
    flex-direction: column;
    align-items: stretch;
  }
  .search-box input {
    width: 100%;
  }
}
</style>