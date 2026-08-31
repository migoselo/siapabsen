<script setup>
/**
 * DataIzinCuti.vue
 * Halaman "Data Izin dan Cuti" — daftar & approval pengajuan cuti/izin karyawan.
 * Dirender di dalam <router-view> milik Layout.vue, jadi TIDAK membuat topbar/profil
 * sendiri — judul halaman & profil admin sudah ditangani oleh Layout.
 */
import { ref, reactive, computed, watch, onMounted, onUnmounted } from 'vue'
import { Icon } from '@iconify/vue'
import DetailIzinCuti from './DetailIzinCuti.vue'

/* ------------------------------------------------------------------ */
/* Palet warna untuk badge jenis cuti (dikelola admin)                 */
/* ------------------------------------------------------------------ */
const colorPalette = [
  { key: 'blue', label: 'Biru', bg: '#EAF0FF', text: '#2A4365' },
  { key: 'red', label: 'Merah', bg: '#FDEEEE', text: '#C53030' },
  { key: 'purple', label: 'Ungu', bg: '#F3EAFE', text: '#6B46C1' },
  { key: 'orange', label: 'Oranye', bg: '#FFF3E6', text: '#C05621' },
  { key: 'green', label: 'Hijau', bg: '#E9F9EF', text: '#1B8A5A' },
  { key: 'gray', label: 'Abu-abu', bg: '#F1F2F5', text: '#4A5568' },
]
const colorByKey = (key) => colorPalette.find((c) => c.key === key) || colorPalette[5]

/* ------------------------------------------------------------------ */
/* Jenis cuti & departemen — dikelola admin lewat modal                */
/* ------------------------------------------------------------------ */
const defaultLeaveTypes = [
  { id: 'lt1', name: 'Cuti Tahunan', colorKey: 'blue' },
  { id: 'lt2', name: 'Sakit', colorKey: 'red' },
  { id: 'lt3', name: 'Izin Khusus', colorKey: 'purple' },
  { id: 'lt4', name: 'Cuti Melahirkan', colorKey: 'orange' },
  { id: 'lt5', name: 'Tanpa Keterangan', colorKey: 'gray' },
]
const defaultDepartments = [
  { id: 'd1', name: 'Engineering' },
  { id: 'd2', name: 'Marketing' },
  { id: 'd3', name: 'Finance' },
  { id: 'd4', name: 'Creative' },
  { id: 'd5', name: 'HR' },
  { id: 'd6', name: 'Operations' },
]

/* FIX: cek ketersediaan localStorage SEKALI di awal, bukan berasumsi selalu ada.
   Di beberapa environment (mode private browsing, iframe sandbox/preview, storage
   dimatikan di pengaturan browser) localStorage bisa melempar error bahkan saat
   hanya diakses. Sebelumnya error ini ditelan diam-diam oleh try/catch sehingga
   data yang baru ditambahkan terlihat "hilang" setelah reload/remount tanpa
   ada pemberitahuan apa pun ke pengguna. */
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

const leaveTypes = reactive(
  loadFromStorage('siaphadir_leave_types', defaultLeaveTypes).map((lt) => ({
    ...lt,
    ...colorByKey(lt.colorKey),
  })),
)
const departments = reactive(loadFromStorage('siaphadir_departments', defaultDepartments))

/* FIX: beri tahu pengguna (banner kecil) kalau penyimpanan gagal, alih-alih
   hanya console.error yang tidak terlihat oleh pengguna. Perubahan tetap
   langsung tampil di layar karena state reactive sudah diperbarui duluan
   sebelum persistSettings() dipanggil — hanya penyimpanan permanennya yang
   mungkin gagal. */
const storageWarning = ref(
  !storageAvailable
    ? 'Penyimpanan lokal browser tidak tersedia. Perubahan hanya berlaku selama sesi ini dan tidak akan tersimpan setelah halaman dimuat ulang.'
    : '',
)

function persistSettings() {
  if (!storageAvailable) return
  try {
    window.localStorage.setItem(
      'siaphadir_leave_types',
      JSON.stringify(leaveTypes.map(({ id, name, colorKey }) => ({ id, name, colorKey }))),
    )
    window.localStorage.setItem(
      'siaphadir_departments',
      JSON.stringify(departments.map(({ id, name }) => ({ id, name }))),
    )
    storageWarning.value = ''
  } catch (error) {
    console.error('Gagal menyimpan pengaturan ke localStorage:', error)
    storageWarning.value =
      'Gagal menyimpan perubahan ke penyimpanan lokal. Perubahan hanya berlaku sementara.'
  }
}

function applyColor(lt) {
  Object.assign(lt, colorByKey(lt.colorKey))
  persistSettings()
}

/* FIX: id generator yang tidak bisa bentrok walau tombol "Tambah" diklik
   berkali-kali secara berurutan dalam milidetik yang sama (Date.now() saja
   bisa menghasilkan id yang identik dalam kasus itu). */
let idCounter = 0
function nextId(prefix) {
  idCounter += 1
  return `${prefix}${Date.now()}${idCounter}`
}

const newLeaveTypeName = ref('')
function addLeaveType() {
  const name = newLeaveTypeName.value.trim()
  if (!name) return
  leaveTypes.push({ id: nextId('lt'), name, colorKey: 'gray', ...colorByKey('gray') })
  newLeaveTypeName.value = ''
  persistSettings()
}
function removeLeaveType(id) {
  const idx = leaveTypes.findIndex((lt) => lt.id === id)
  if (idx > -1) leaveTypes.splice(idx, 1)
  persistSettings()
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

function leaveTypeById(id) {
  return leaveTypes.find((lt) => lt.id === id)
}
function departmentName(id) {
  return departments.find((d) => d.id === id)?.name || '-'
}

/* ------------------------------------------------------------------ */
/* Data pengajuan cuti (ganti dengan fetch API di proyekmu)            */
/* ------------------------------------------------------------------ */
const requests = reactive([
  mkReq(
    'Bambang Kusuma',
    'Senior Developer',
    'd1',
    'lt1',
    '2023-10-12',
    '2023-10-15',
    4,
    'Acara keluarga tahunan di luar kota bersama seluruh anggota keluarga besar.',
  ),
  mkReq(
    'Dewi Sartika',
    'Marketing Specialist',
    'd2',
    'lt2',
    '2023-10-14',
    '2023-10-14',
    1,
    'Demam dan butuh istirahat total (surat dokter terlampir).',
  ),
  mkReq(
    'Andi Saputra',
    'Accountant',
    'd3',
    'lt3',
    '2023-10-18',
    '2023-10-19',
    2,
    'Urusan administrasi perbankan mendesak.',
  ),
  mkReq(
    'Siti Aminah',
    'Lead Designer',
    'd4',
    'lt1',
    '2023-10-25',
    '2023-10-30',
    4,
    'Cuti akhir bulan untuk refreshment.',
  ),
  mkReq(
    'Rian Hidayat',
    'Backend Engineer',
    'd1',
    'lt2',
    '2023-10-16',
    '2023-10-17',
    2,
    'Sakit tifus, perlu rawat jalan.',
  ),
  mkReq(
    'Putri Wulandari',
    'HR Officer',
    'd5',
    'lt1',
    '2023-10-20',
    '2023-10-22',
    3,
    'Menghadiri pernikahan saudara di Yogyakarta.',
  ),
  mkReq(
    'Fajar Nugraha',
    'Operations Staff',
    'd6',
    'lt3',
    '2023-10-11',
    '2023-10-11',
    1,
    'Mengurus dokumen kependudukan.',
  ),
  mkReq(
    'Maya Anggraini',
    'Content Writer',
    'd2',
    'lt4',
    '2023-11-01',
    '2023-12-10',
    30,
    'Cuti melahirkan anak pertama.',
  ),
  mkReq(
    'Budi Santoso',
    'Finance Staff',
    'd3',
    'lt1',
    '2023-10-23',
    '2023-10-24',
    2,
    'Liburan keluarga ke Bali.',
  ),
  mkReq(
    'Nadia Ramadhani',
    'UI Designer',
    'd4',
    'lt2',
    '2023-10-13',
    '2023-10-13',
    1,
    'Migrain berat, disarankan istirahat oleh dokter.',
  ),
  mkReq(
    'Yusuf Firmansyah',
    'DevOps Engineer',
    'd1',
    'lt3',
    '2023-10-19',
    '2023-10-19',
    1,
    'Mengurus perpanjangan SIM.',
  ),
  mkReq(
    'Lina Marlina',
    'Marketing Lead',
    'd2',
    'lt1',
    '2023-10-27',
    '2023-10-28',
    2,
    'Cuti tahunan bersama keluarga.',
    'approved',
  ),
  mkReq(
    'Agus Prasetyo',
    'Accountant',
    'd3',
    'lt5',
    '2023-10-09',
    '2023-10-09',
    1,
    'Tidak hadir tanpa keterangan sebelumnya.',
    'rejected',
  ),
  mkReq(
    'Sri Wahyuni',
    'Creative Director',
    'd4',
    'lt1',
    '2023-10-30',
    '2023-11-02',
    3,
    'Menghadiri workshop desain di luar kota.',
    'approved',
  ),
])

function mkReq(
  name,
  position,
  departmentId,
  leaveTypeId,
  start,
  end,
  workDays,
  reason,
  status = 'pending',
) {
  return reactive({
    id: crypto.randomUUID ? crypto.randomUUID() : nextId('req'),
    requester: { name, position, departmentId, avatarUrl: '' },
    leaveTypeId,
    startDate: start,
    endDate: end,
    workDaysLabel: workDays === 1 ? '1 Hari' : `${workDays} Hari Kerja`,
    reason,
    status, // 'pending' | 'approved' | 'rejected'
  })
}

/* ------------------------------------------------------------------ */
/* Statistik ringkas                                                   */
/* ------------------------------------------------------------------ */
const pendingCount = computed(() => requests.filter((r) => r.status === 'pending').length)
const newSinceYesterday = ref(8) // ganti dengan angka dari API kalau tersedia
const avgApprovalTime = ref('1.2 Jam')

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
const leaveTypeFilter = ref('')
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
    if (leaveTypeFilter.value && r.leaveTypeId !== leaveTypeFilter.value) return false
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

watch([activeTab, leaveTypeFilter, departmentFilter, searchQuery], () => {
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
  // TODO: panggil API PATCH /leave-requests/:id { status: 'approved', comment }
  if (selectedRequest.value?.id === id) closeDetail()
}
function rejectRequest(id, comment = '') {
  const r = requests.find((x) => x.id === id)
  if (r) r.status = 'rejected'
  // TODO: panggil API PATCH /leave-requests/:id { status: 'rejected', comment }
  if (selectedRequest.value?.id === id) closeDetail()
}

/* ------------------------------------------------------------------ */
/* Tampilan detail — dibuka lewat tombol "Lihat Detail" di kolom Aksi  */
/* ------------------------------------------------------------------ */
const selectedRequest = ref(null)
function openDetail(req) {
  selectedRequest.value = req
}
function closeDetail() {
  selectedRequest.value = null
}
/* Menyesuaikan bentuk data `req` di tabel ini ke bentuk yang diharapkan
   oleh <DetailIzinCuti>. Field employeeId/email/attachments/leaveBalance
   belum ada di data list — isi dari API sesungguhnya kalau sudah tersedia. */
const detailRequestForView = computed(() => {
  const r = selectedRequest.value
  if (!r) return null
  return {
    id: r.id,
    employee: {
      name: r.requester.name,
      position: r.requester.position,
      department: departmentName(r.requester.departmentId),
      employeeId: r.requester.employeeId || '-',
      email: r.requester.email || '-',
      avatarUrl: r.requester.avatarUrl || '',
    },
    leaveTypeName: leaveTypeById(r.leaveTypeId)?.name || '-',
    workDaysLabel: r.workDaysLabel,
    startDate: r.startDate,
    endDate: r.endDate,
    reason: r.reason,
    attachments: r.attachments || [],
    leaveBalance: r.leaveBalance || { used: 0, total: 12 },
    status: r.status,
  }
})

/* ------------------------------------------------------------------ */
/* Helper tampilan                                                     */
/* ------------------------------------------------------------------ */
function initials(name) {
  return name
    .split(' ')
    .map((w) => w[0])
    .slice(0, 2)
    .join('')
    .toUpperCase()
}

const dateFmt = new Intl.DateTimeFormat('id-ID', {
  day: '2-digit',
  month: 'short',
  year: 'numeric',
})
function formatDuration(req) {
  const start = dateFmt.format(new Date(req.startDate))
  if (req.startDate === req.endDate) return start
  const end = dateFmt.format(new Date(req.endDate))
  return `${start} — ${end}`
}

/* ------------------------------------------------------------------ */
/* Ekspor CSV & PDF (mengekspor data pada tab & filter yang aktif)     */
/* ------------------------------------------------------------------ */
function exportRows() {
  return filteredRequests.value.map((r) => ({
    Pemohon: r.requester.name,
    Jabatan: r.requester.position,
    Departemen: departmentName(r.requester.departmentId),
    'Jenis Cuti': leaveTypeById(r.leaveTypeId)?.name || '',
    'Tanggal Mulai': dateFmt.format(new Date(r.startDate)),
    'Tanggal Selesai': dateFmt.format(new Date(r.endDate)),
    Durasi: r.workDaysLabel,
    Alasan: r.reason,
    Status: r.status === 'pending' ? 'Menunggu' : r.status === 'approved' ? 'Diterima' : 'Ditolak',
  }))
}

function exportCSV() {
  const rows = exportRows()
  if (rows.length === 0) return
  const headers = Object.keys(rows[0])
  const escapeCsv = (val) => `"${String(val).replace(/"/g, '""')}"`
  const lines = [
    headers.join(','),
    ...rows.map((row) => headers.map((h) => escapeCsv(row[h])).join(',')),
  ]
  const blob = new Blob(['\ufeff' + lines.join('\n')], { type: 'text/csv;charset=utf-8;' })
  downloadBlob(blob, `data-izin-cuti-${activeTab.value}-${todayStamp()}.csv`)
}

const exportError = ref('')

async function exportPDF() {
  const rows = exportRows()
  if (rows.length === 0) return
  exportError.value = ''
  try {
    /* FIX: versi jspdf-autotable saat ini (v3+) tidak lagi otomatis menempelkan
       .autoTable ke instance jsPDF hanya dengan mengimpornya sebagai side-effect
       (`await import('jspdf-autotable')`). Library ini sekarang mengekspor
       fungsi `autoTable` secara terpisah dan harus dipanggil sebagai
       `autoTable(doc, options)`, bukan `doc.autoTable(options)`. Memanggil
       `doc.autoTable(...)` yang lama akan melempar
       "doc.autoTable is not a function" dan gagal tanpa pesan yang jelas
       ke pengguna karena tidak dibungkus try/catch sebelumnya. */
    const { default: jsPDF } = await import('jspdf')
    const { default: autoTable } = await import('jspdf-autotable')

    const doc = new jsPDF({ orientation: 'landscape' })
    doc.setFontSize(16)
    doc.text('Data Izin dan Cuti', 14, 15)
    doc.setFontSize(14)
    doc.text(`Status: ${tabs.find((t) => t.key === activeTab.value)?.label}`, 14, 21)
    const headers = Object.keys(rows[0])
    const body = rows.map((row) => headers.map((h) => row[h]))

    autoTable(doc, {
      head: [headers],
      body,
      startY: 26,
      styles: { fontSize: 12, cellPadding: 2 },
      headStyles: { fillColor: [37, 47, 88] }, // samakan dengan --sidebar-accent
    })

    doc.save(`data-izin-cuti-${activeTab.value}-${todayStamp()}.pdf`)
  } catch (error) {
    console.error('Gagal membuat PDF:', error)
    exportError.value =
      'Gagal membuat file PDF. Pastikan paket "jspdf" dan "jspdf-autotable" sudah terpasang di proyek ini.'
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

/* ------------------------------------------------------------------ */
/* Menu ekspor & modal kelola                                          */
/* ------------------------------------------------------------------ */
const showExportMenu = ref(false)
const showManageModal = ref(false)
const manageTab = ref('leaveTypes')

function handleOutsideClick(e) {
  if (!e.target.closest?.('.export-menu')) showExportMenu.value = false
}
onMounted(() => document.addEventListener('click', handleOutsideClick))
onUnmounted(() => document.removeEventListener('click', handleOutsideClick))
</script>

<template>
  <div class="izin-cuti">
    <!-- Tampilan detail — muncul menggantikan daftar saat tombol "Lihat Detail" diklik -->
    <DetailIzinCuti
      v-if="selectedRequest"
      :request="detailRequestForView"
      @back="closeDetail"
      @approve="({ id, comment }) => approveRequest(id, comment)"
      @reject="({ id, comment }) => rejectRequest(id, comment)"
    />

    <template v-else>
      <!-- FIX: banner peringatan bila localStorage tidak tersedia / gagal, supaya
           pengguna tahu kenapa perubahan tidak "tersimpan" alih-alih dibiarkan
           gagal diam-diam -->
      <div v-if="storageWarning" class="storage-warning">
        <Icon icon="material-symbols:warning-outline" width="18" />
        {{ storageWarning }}
      </div>

      <!-- Stat cards -->
      <div class="stats-grid">
        <div class="stat-card">
          <div class="stat-top">
            <div class="stat-icon">
              <Icon icon="material-symbols:pending-actions-outline" width="22" />
            </div>
            <span class="trend trend-up">
              <Icon icon="material-symbols:arrow-upward" width="12" /> 12%
            </span>
          </div>
          <p class="stat-label">Permintaan tertunda</p>
          <p class="stat-value">{{ pendingCount }}</p>
          <p class="stat-sub">{{ newSinceYesterday }} baru sejak kemarin</p>
        </div>

        <div class="stat-card">
          <div class="stat-top">
            <div class="stat-icon"><Icon icon="material-symbols:timer-outline" width="22" /></div>
            <span class="trend trend-down">
              <Icon icon="material-symbols:arrow-downward" width="12" /> 4m
            </span>
          </div>
          <p class="stat-label">Rata-rata waktu persetujuan</p>
          <p class="stat-value">{{ avgApprovalTime }}</p>
          <p class="stat-sub">Performa seluruh perusahaan</p>
        </div>
      </div>

      <!-- Main card -->
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

        <!-- FIX: tampilkan pesan error ekspor PDF ke pengguna, bukan hanya di console -->
        <p v-if="exportError" class="export-error">{{ exportError }}</p>

        <div class="filters-row">
          <div class="filters">
            <select v-model="leaveTypeFilter" class="select">
              <option value="">Semua Jenis Cuti</option>
              <option v-for="lt in leaveTypes" :key="lt.id" :value="lt.id">{{ lt.name }}</option>
            </select>
            <select v-model="departmentFilter" class="select">
              <option value="">Semua Departemen</option>
              <option v-for="d in departments" :key="d.id" :value="d.id">{{ d.name }}</option>
            </select>
            <button class="btn-ghost" @click="showManageModal = true">
              <Icon icon="material-symbols:tune" width="16" /> Kelola Jenis & Departemen
            </button>
          </div>
        </div>

        <div class="table-wrap">
          <table class="table">
            <thead>
              <tr>
                <th>Pemohon</th>
                <th>Jenis Cuti</th>
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
                <td>
                  <span
                    class="badge"
                    :style="{
                      background: leaveTypeById(req.leaveTypeId)?.bg,
                      color: leaveTypeById(req.leaveTypeId)?.text,
                    }"
                  >
                    {{ leaveTypeById(req.leaveTypeId)?.name }}
                  </span>
                </td>
                <td class="nowrap">
                  <p class="duration-main">{{ formatDuration(req) }}</p>
                  <p class="duration-sub">{{ req.workDaysLabel }}</p>
                </td>
                <td class="col-reason">
                  <p class="reason-text" :title="req.reason">{{ req.reason }}</p>
                </td>
                <td>
                  <div class="actions">
                    <!-- 1. Tombol Tolak & Terima (Hanya muncul jika status masih 'pending') -->
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

                    <!-- Status badge jika sudah disetujui/ditolak -->
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

                    <!-- 2. Tombol Lihat Detail (Selalu berada di urutan paling kanan) -->
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
                  Tidak ada permintaan yang cocok dengan filter saat ini.
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

      <!-- Modal kelola jenis cuti & departemen -->
      <div v-if="showManageModal" class="modal-overlay" @click.self="showManageModal = false">
        <div class="modal">
          <div class="modal-header">
            <h2>Kelola Jenis Cuti & Departemen</h2>
            <button class="icon-btn-plain" @click="showManageModal = false">
              <Icon icon="material-symbols:close" width="18" />
            </button>
          </div>

          <div class="modal-tabs">
            <button
              class="modal-tab"
              :class="{ 'modal-tab-active': manageTab === 'leaveTypes' }"
              @click="manageTab = 'leaveTypes'"
            >
              Jenis Cuti
            </button>
            <button
              class="modal-tab"
              :class="{ 'modal-tab-active': manageTab === 'departments' }"
              @click="manageTab = 'departments'"
            >
              Departemen
            </button>
          </div>

          <div v-if="manageTab === 'leaveTypes'" class="modal-body">
            <div v-for="lt in leaveTypes" :key="lt.id" class="manage-row">
              <span class="badge" :style="{ background: lt.bg, color: lt.text }">{{
                lt.name
              }}</span>
              <input v-model="lt.name" class="manage-input" @change="persistSettings" />
              <select v-model="lt.colorKey" class="manage-select" @change="applyColor(lt)">
                <option v-for="c in colorPalette" :key="c.key" :value="c.key">{{ c.label }}</option>
              </select>
              <button class="icon-btn-plain" @click="removeLeaveType(lt.id)">
                <Icon icon="material-symbols:delete-outline" width="18" />
              </button>
            </div>

            <div class="manage-add-row">
              <input
                v-model="newLeaveTypeName"
                placeholder="Nama jenis cuti baru"
                class="manage-input"
                @keydown.enter.prevent="addLeaveType"
              />
              <button type="button" class="btn-primary" @click="addLeaveType">Tambah</button>
            </div>
          </div>

          <div v-else class="modal-body">
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

.izin-cuti {
  --accent: var(--sidebar-accent, #252f58);
  --ink-dark: var(--ink-dark, #2c3345);
  --ink-soft: var(--ink-soft, #667085);
  --line: var(--line, #e4e7ec);
  font-family: 'Plus Jakarta Sans', 'Inter', system-ui, sans-serif;
  font-size: 14px;
  color: var(--ink-dark);
}

/* Browser tidak mewariskan font-family ke elemen form secara default (button,
   input, select punya font sistem sendiri) — dipaksa ikut di sini supaya semua
   teks di halaman ini, termasuk tombol dan dropdown, konsisten Plus Jakarta Sans. */
.izin-cuti button,
.izin-cuti input,
.izin-cuti select {
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

/* Stat cards */
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

/* Main card */
.card {
  background: #fff;
  border: 1px solid #eaecf0;
  border-radius: 12px;
  overflow: hidden;
  box-shadow: 0 1px 2px rgba(16, 24, 40, 0.05);
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

/* Table */
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
.nowrap {
  white-space: nowrap;
}
.duration-main {
  margin: 0;
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

/* Pagination */
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

/* Modal */
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
.modal-tabs {
  display: flex;
  gap: 16px;
  padding: 14px 24px 0;
  border-bottom: 1px solid var(--line);
}
.modal-tab {
  background: none;
  border: none;
  border-bottom: 2px solid transparent;
  padding-bottom: 12px;
  font-size: 15px;
  font-weight: 600;
  color: var(--ink-soft);
  cursor: pointer;
}
.modal-tab-active {
  color: var(--accent);
  border-bottom-color: var(--accent);
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
.manage-select {
  font-size: 14px;
  border: 1px solid var(--line);
  border-radius: 6px;
  padding: 4px 6px;
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
