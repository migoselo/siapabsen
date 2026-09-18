<script setup>
import { ref, computed } from 'vue'
import { Icon } from '@iconify/vue'

/* ------------------------------------------------------------------ */
/* State Management & Mock Data                                        */
/* ------------------------------------------------------------------ */
const activeTab = ref('shift') // 'shift' | 'divisi'
const searchQuery = ref('')
const currentPage = ref(1)
const perPage = ref(10)
const pageInput = ref(1)

// Data Mock Divisi
const divisions = ref([
  { id: 'd1', name: 'Engineering', description: 'Tim pengembang perangkat lunak dan infrastruktur IT' },
  { id: 'd2', name: 'Marketing', description: 'Tim pemasaran, media sosial, dan campaign' },
  { id: 'd3', name: 'Finance', description: 'Tim keuangan, akuntansi, dan penggajian' },
  { id: 'd4', name: 'Creative', description: 'Tim desain grafis, video, dan konten visual' },
  { id: 'd5', name: 'HR', description: 'Tim sumber daya manusia dan rekrutmen' },
  { id: 'd6', name: 'Operations', description: 'Tim operasional harian dan logistik' },
])

// Data Mock Shift
const shifts = ref([
  { id: 's1', name: 'Shift Pagi Reguler', clockIn: '08:00', clockOut: '17:00', divisionId: 'd1', status: 'Aktif' },
  { id: 's2', name: 'Shift Pagi Reguler', clockIn: '08:00', clockOut: '17:00', divisionId: 'd5', status: 'Aktif' },
  { id: 's3', name: 'Shift Fleksibel', clockIn: '09:00', clockOut: '18:00', divisionId: 'd2', status: 'Aktif' },
  { id: 's4', name: 'Shift Fleksibel', clockIn: '09:00', clockOut: '18:00', divisionId: 'd4', status: 'Aktif' },
  { id: 's5', name: 'Shift Malam (Ops)', clockIn: '20:00', clockOut: '05:00', divisionId: 'd6', status: 'Aktif' },
])

/* ------------------------------------------------------------------ */
/* Helper Functions                                                    */
/* ------------------------------------------------------------------ */
function getDivisionName(id) {
  if (id === 'all') return 'Semua Divisi'
  return divisions.value.find(d => d.id === id)?.name || '-'
}

function calculateDuration(inTime, outTime) {
  if (!inTime || !outTime) return '-'
  const [inH, inM] = inTime.split(':').map(Number)
  const [outH, outM] = outTime.split(':').map(Number)
  let diff = (outH * 60 + outM) - (inH * 60 + inM)
  if (diff < 0) diff += 24 * 60 // Shift lintas hari (misal shift malam)
  const hours = Math.floor(diff / 60)
  return `${hours} Jam`
}

/* ------------------------------------------------------------------ */
/* Computed Properties (Filtering & Pagination)                        */
/* ------------------------------------------------------------------ */
const filteredData = computed(() => {
  const query = searchQuery.value.trim().toLowerCase()
  if (activeTab.value === 'shift') {
    return shifts.value.filter(s => 
      !query || 
      s.name.toLowerCase().includes(query) || 
      getDivisionName(s.divisionId).toLowerCase().includes(query)
    )
  } else {
    return divisions.value.filter(d => 
      !query || 
      d.name.toLowerCase().includes(query)
    )
  }
})

const totalRecords = computed(() => filteredData.value.length)
const totalPages = computed(() => Math.max(1, Math.ceil(totalRecords.value / perPage.value)))
const paginatedData = computed(() => {
  const start = (currentPage.value - 1) * perPage.value
  return filteredData.value.slice(start, start + perPage.value)
})

function changeTab(tab) {
  activeTab.value = tab
  currentPage.value = 1
  pageInput.value = 1
  searchQuery.value = ''
}

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
/* Modal Form (Tambah/Edit)                                            */
/* ------------------------------------------------------------------ */
const showModal = ref(false)
const modalMode = ref('add') // 'add' | 'edit'
const formData = ref({})

function openModal(mode, item = null) {
  modalMode.value = mode
  if (activeTab.value === 'shift') {
    formData.value = item ? { ...item } : { name: '', clockIn: '08:00', clockOut: '17:00', divisionId: 'd1', status: 'Aktif' }
  } else {
    formData.value = item ? { ...item } : { name: '', description: '' }
  }
  showModal.value = true
}

function closeModal() {
  showModal.value = false
  formData.value = {}
}

function saveForm() {
  if (activeTab.value === 'shift') {
    if (modalMode.value === 'add') {
      shifts.value.push({ ...formData.value, id: `s${Date.now()}` })
    } else {
      const idx = shifts.value.findIndex(s => s.id === formData.value.id)
      if (idx !== -1) shifts.value[idx] = { ...formData.value }
    }
  } else {
    if (modalMode.value === 'add') {
      divisions.value.push({ ...formData.value, id: `d${Date.now()}` })
    } else {
      const idx = divisions.value.findIndex(d => d.id === formData.value.id)
      if (idx !== -1) divisions.value[idx] = { ...formData.value }
    }
  }
  closeModal()
}

function deleteData(id) {
  if (!confirm('Apakah Anda yakin ingin menghapus data ini?')) return
  if (activeTab.value === 'shift') {
    shifts.value = shifts.value.filter(s => s.id !== id)
  } else {
    // Validasi sederhana jika divisi dihapus tapi masih dipakai di shift
    const usedInShift = shifts.value.some(s => s.divisionId === id)
    if (usedInShift) {
      alert('Divisi ini tidak bisa dihapus karena sedang digunakan pada data Shift.')
      return
    }
    divisions.value = divisions.value.filter(d => d.id !== id)
  }
}
</script>

<template>
  <div class="shift-divisi-page">
    <!-- Stat Cards Summary -->
    <div class="stats-grid">
      <div class="summary-card">
        <div class="summary-top">
          <div class="summary-icon blue">
            <Icon icon="material-symbols:domain-rounded" />
          </div>
          <span class="summary-tag blue">STRUKTUR</span>
        </div>
        <span class="summary-label">Total Divisi Aktif</span>
        <strong class="blue-text">{{ divisions.length }}</strong>
        <small>Membawahi seluruh karyawan</small>
      </div>

      <div class="summary-card">
        <div class="summary-top">
          <div class="summary-icon amber">
            <Icon icon="material-symbols:nest-clock-farsight-analog-outline" />
          </div>
          <span class="summary-tag amber">JADWAL</span>
        </div>
        <span class="summary-label">Total Shift Diatur</span>
        <strong class="amber-text">{{ shifts.length }}</strong>
        <small>Kebijakan jam kerja terdaftar</small>
      </div>

      <div class="summary-card">
        <div class="summary-top">
          <div class="summary-icon green">
            <Icon icon="material-symbols:timelapse-rounded" />
          </div>
          <span class="summary-tag green">RATA-RATA</span>
        </div>
        <span class="summary-label">Durasi Shift Harian</span>
        <strong class="green-text">9.0 Jam</strong>
        <small>Termasuk jam istirahat</small>
      </div>
    </div>

    <!-- Main Card Panel -->
    <div class="card">
      <div class="card-toolbar">
        <div class="tabs">
          <button 
            class="tab" 
            :class="{ 'tab-active': activeTab === 'shift' }" 
            @click="changeTab('shift')"
          >
            Pengaturan Shift
            <span class="tab-count" :class="{ 'tab-count-active': activeTab === 'shift' }">{{ shifts.length }}</span>
          </button>
          <button 
            class="tab" 
            :class="{ 'tab-active': activeTab === 'divisi' }" 
            @click="changeTab('divisi')"
          >
            Daftar Divisi
            <span class="tab-count" :class="{ 'tab-count-active': activeTab === 'divisi' }">{{ divisions.length }}</span>
          </button>
        </div>

        <div class="toolbar-actions">
          <div class="search-box">
            <Icon icon="material-symbols:search" width="18" class="search-icon" />
            <input 
              v-model="searchQuery" 
              type="text" 
              :placeholder="activeTab === 'shift' ? 'Cari nama shift/divisi...' : 'Cari nama divisi...'" 
            />
          </div>
          <button class="btn-primary" @click="openModal('add')">
            <Icon icon="material-symbols:add-rounded" width="18" /> 
            Tambah {{ activeTab === 'shift' ? 'Shift' : 'Divisi' }}
          </button>
        </div>
      </div>

      <!-- Tabel Data -->
      <div class="table-wrap">
        <table class="table">
          <!-- Tabel Shift -->
          <thead v-if="activeTab === 'shift'">
            <tr>
              <th>Nama Shift</th>
              <th>Divisi Terkait</th>
              <th>Clock In</th>
              <th>Clock Out</th>
              <th>Durasi</th>
              <th>Status</th>
              <th class="col-actions">Aksi</th>
            </tr>
          </thead>
          <!-- Tabel Divisi -->
          <thead v-else>
            <tr>
              <th>ID Divisi</th>
              <th>Nama Divisi</th>
              <th style="width: 50%;">Deskripsi</th>
              <th class="col-actions">Aksi</th>
            </tr>
          </thead>

          <tbody>
            <tr v-if="paginatedData.length === 0">
              <td :colspan="activeTab === 'shift' ? 7 : 4" class="empty-row">
                Tidak ada data yang ditemukan.
              </td>
            </tr>

            <!-- Render Baris Shift -->
            <template v-if="activeTab === 'shift'">
              <tr v-for="shift in paginatedData" :key="shift.id">
                <td>
                  <strong class="text-dark">{{ shift.name }}</strong>
                </td>
                <td>
                  <span class="badge badge-divisi">{{ getDivisionName(shift.divisionId) }}</span>
                </td>
                <td><span class="time-box in">{{ shift.clockIn }}</span></td>
                <td><span class="time-box out">{{ shift.clockOut }}</span></td>
                <td>{{ calculateDuration(shift.clockIn, shift.clockOut) }}</td>
                <td>
                  <span class="badge" :class="shift.status === 'Aktif' ? 'badge-green' : 'badge-gray'">
                    {{ shift.status }}
                  </span>
                </td>
                <td>
                  <div class="actions">
                    <button class="icon-btn" title="Edit" @click="openModal('edit', shift)">
                      <Icon icon="material-symbols:edit-outline" width="16" />
                    </button>
                    <button class="icon-btn icon-btn-danger" title="Hapus" @click="deleteData(shift.id)">
                      <Icon icon="material-symbols:delete-outline" width="16" />
                    </button>
                  </div>
                </td>
              </tr>
            </template>

            <!-- Render Baris Divisi -->
            <template v-else>
              <tr v-for="div in paginatedData" :key="div.id">
                <td><span class="text-soft">{{ div.id.toUpperCase() }}</span></td>
                <td><strong class="text-dark">{{ div.name }}</strong></td>
                <td><span class="text-soft">{{ div.description || '-' }}</span></td>
                <td>
                  <div class="actions">
                    <button class="icon-btn" title="Edit" @click="openModal('edit', div)">
                      <Icon icon="material-symbols:edit-outline" width="16" />
                    </button>
                    <button class="icon-btn icon-btn-danger" title="Hapus" @click="deleteData(div.id)">
                      <Icon icon="material-symbols:delete-outline" width="16" />
                    </button>
                  </div>
                </td>
              </tr>
            </template>
          </tbody>
        </table>
      </div>

      <!-- Pagination Footer -->
      <div class="table-footer">
        <div class="table-footer-content">
          <div class="pager">
            <button class="pager-btn" :disabled="currentPage === 1" @click="currentPage--">
              <Icon icon="material-symbols:chevron-left-rounded" width="18" />
            </button>
            <div class="page-input-wrapper">
              <span>Halaman</span>
              <input type="number" v-model.number="pageInput" @change="goToInputPage" min="1" :max="totalPages" class="page-input" />
              <span>dari {{ totalPages }}</span>
            </div>
            <button class="pager-btn" :disabled="currentPage === totalPages" @click="currentPage++">
              <Icon icon="material-symbols:chevron-right-rounded" width="18" />
            </button>
          </div>
          <div class="per-page-select">
            <select v-model="perPage" @change="changePerPage">
              <option :value="10">10 baris</option>
              <option :value="20">20 baris</option>
              <option :value="50">50 baris</option>
            </select>
          </div>
          <span class="total-records-info">{{ totalRecords }} data</span>
        </div>
      </div>
    </div>

    <!-- Modal Popup Form -->
    <div v-if="showModal" class="modal-overlay" @click.self="closeModal">
      <div class="modal">
        <div class="modal-header">
          <h2>{{ modalMode === 'add' ? 'Tambah' : 'Edit' }} {{ activeTab === 'shift' ? 'Shift' : 'Divisi' }}</h2>
          <button class="icon-btn-plain" @click="closeModal">
            <Icon icon="material-symbols:close" width="20" />
          </button>
        </div>
        
        <form @submit.prevent="saveForm" class="modal-body">
          <!-- Form Shift -->
          <template v-if="activeTab === 'shift'">
            <div class="form-group">
              <label>Nama Shift</label>
              <input v-model="formData.name" type="text" class="form-input" placeholder="Misal: Shift Pagi Reguler" required />
            </div>
            
            <div class="form-row">
              <div class="form-group">
                <label>Jam Masuk (Clock In)</label>
                <input v-model="formData.clockIn" type="time" class="form-input" required />
              </div>
              <div class="form-group">
                <label>Jam Pulang (Clock Out)</label>
                <input v-model="formData.clockOut" type="time" class="form-input" required />
              </div>
            </div>

            <div class="form-group">
              <label>Pilih Divisi Terkait</label>
              <select v-model="formData.divisionId" class="form-input select-input" required>
                <option value="all">Berlaku untuk Semua Divisi</option>
                <option v-for="d in divisions" :key="d.id" :value="d.id">{{ d.name }}</option>
              </select>
            </div>

            <div class="form-group">
              <label>Status Shift</label>
              <select v-model="formData.status" class="form-input select-input">
                <option value="Aktif">Aktif</option>
                <option value="Tidak Aktif">Tidak Aktif</option>
              </select>
            </div>
          </template>

          <!-- Form Divisi -->
          <template v-else>
            <div class="form-group">
              <label>Nama Divisi</label>
              <input v-model="formData.name" type="text" class="form-input" placeholder="Misal: Human Resources" required />
            </div>
            <div class="form-group">
              <label>Deskripsi Divisi</label>
              <textarea v-model="formData.description" class="form-input textarea-input" rows="3" placeholder="Jelaskan peran divisi ini..."></textarea>
            </div>
          </template>

          <div class="modal-footer">
            <button type="button" class="btn-ghost" @click="closeModal">Batal</button>
            <button type="submit" class="btn-primary">Simpan Data</button>
          </div>
        </form>
      </div>
    </div>
  </div>
</template>

<style scoped>
@import url('https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap');

.shift-divisi-page {
  --accent: #252f58;
  --blue-900: #2f3b69;
  --ink-dark: #1c1c19;
  --ink-soft: #667085;
  --line: #d9dde5;
  --bg: #f7f8fa;
  --card: #ffffff;
  font-family: 'Plus Jakarta Sans', sans-serif;
  font-size: 14px;
  color: var(--ink-dark);
}

.shift-divisi-page button,
.shift-divisi-page input,
.shift-divisi-page select,
.shift-divisi-page textarea {
  font-family: inherit;
}

/* Stat cards */
.stats-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(240px, 1fr));
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
.summary-icon svg { width: 18px; height: 18px; }
.summary-icon.green { background: #e0f5e9; color: #17a057; }
.summary-icon.amber { background: #fff2d9; color: #efb34f; }
.summary-icon.blue { background: #e8ebf5; color: var(--blue-900); }
.summary-tag {
  padding: 4px 7px;
  border-radius: 4px;
  font-size: 9px;
  font-weight: 800;
}
.summary-tag.green { color: #15924f; background: #e5f5e9; }
.summary-tag.amber { color: #b17a18; background: #fff0d3; }
.summary-tag.blue { color: var(--blue-900); background: #e8ebf5; }
.summary-label {
  display: block;
  color: var(--ink-soft);
  font-size: 14px;
  margin-bottom: 4px;
}
.summary-card strong {
  display: block;
  font-size: 26px;
  line-height: 1.1;
  margin-bottom: 9px;
  font-weight: 800;
}
.summary-card small { color: var(--ink-soft); font-size: 11px; }
.summary-card .green-text { color: #17a057; }
.summary-card .amber-text { color: #efb34f; }
.summary-card .blue-text { color: var(--blue-900); }

/* Main card */
.card {
  background: var(--card);
  border: 1px solid var(--line);
  border-radius: 12px;
  overflow: visible;
  box-shadow: 0 1px 2px rgba(16, 24, 40, 0.05);
}
.card-toolbar {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  padding: 16px 24px 0;
  border-bottom: 1px solid var(--line);
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
  transform: translateY(1px); /* align border with bottom line */
}
.tab-active {
  color: var(--blue-900);
  border-bottom-color: var(--blue-900);
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
  background: var(--blue-900);
  color: #fff;
}
.toolbar-actions {
  display: flex;
  align-items: center;
  gap: 12px;
  margin-bottom: 12px;
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
  font-size: 14px;
  border: 1px solid var(--line);
  border-radius: 8px;
  width: 240px;
}
.search-box input:focus {
  outline: 2px solid rgba(47, 59, 105, 0.15);
  border-color: var(--blue-900);
}

.btn-primary {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  background: var(--blue-900);
  color: #ffffff;
  font-size: 14px;
  font-weight: 700;
  border: none;
  border-radius: 8px;
  padding: 9px 16px;
  cursor: pointer;
}
.btn-primary:hover { background: #252f58; }

.btn-ghost {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  background: none;
  border: 1px solid var(--line);
  border-radius: 8px;
  padding: 9px 16px;
  font-size: 14px;
  font-weight: 600;
  color: var(--ink-soft);
  cursor: pointer;
}
.btn-ghost:hover { background: #f4f5f8; }

/* Table */
.table-wrap {
  overflow-x: auto;
}
.table {
  width: 100%;
  border-collapse: collapse;
  font-size: 14px;
}
.table thead tr { background-color: var(--blue-900); border: none; }
.table th {
  text-align: left;
  padding: 14px 24px;
  font-size: 12px;
  font-weight: 700;
  letter-spacing: 0.8px;
  text-transform: uppercase;
  color: #ffffff;
}
.col-actions { text-align: right; width: 1%; white-space: nowrap; }
.table tbody tr { border-bottom: 1px solid #f1f2f5; }
.table tbody tr:hover { background: #fafbfc; }
.table td {
  padding: 14px 24px;
  vertical-align: middle;
}
.text-dark { color: var(--ink-dark); font-weight: 600; }
.text-soft { color: var(--ink-soft); font-size: 13px; }

/* Badges & Time Boxes */
.badge {
  display: inline-block;
  font-size: 12px;
  font-weight: 700;
  padding: 4px 10px;
  border-radius: 6px;
}
.badge-divisi { background: #e8ebf5; color: var(--blue-900); }
.badge-green { background: #e9f9ef; color: #1b8a5a; }
.badge-gray { background: #f1f2f5; color: var(--ink-soft); }

.time-box {
  display: inline-block;
  font-family: monospace;
  font-size: 13px;
  font-weight: 700;
  padding: 4px 8px;
  border-radius: 6px;
  border: 1px solid var(--line);
  background: #ffffff;
}
.time-box.in { color: #1b8a5a; }
.time-box.out { color: #c53030; }

.actions {
  display: flex;
  align-items: center;
  justify-content: flex-end;
  gap: 8px;
}
.icon-btn {
  width: 30px;
  height: 30px;
  border-radius: 6px;
  border: none;
  background: transparent;
  color: var(--ink-soft);
  display: grid;
  place-items: center;
  cursor: pointer;
  transition: all 0.2s;
}
.icon-btn:hover { background: #e8ebf5; color: var(--blue-900); }
.icon-btn-danger:hover { background: #fdeeee; color: #c53030; }
.empty-row { text-align: center; padding: 48px 24px; color: var(--ink-soft); }

/* Pagination */
.table-footer {
  display: flex;
  justify-content: flex-end;
  align-items: center;
  padding: 16px 24px;
  font-size: 13px;
  color: var(--ink-soft);
  border-top: 1px solid var(--line);
  background: var(--bg);
  border-radius: 0 0 12px 12px;
}
.table-footer-content { display: flex; align-items: center; gap: 16px; }
.pager { display: flex; align-items: center; gap: 6px; }
.pager-btn {
  width: 32px; height: 32px;
  border-radius: 6px; border: 1px solid var(--line);
  background: #fff;
  display: inline-flex; align-items: center; justify-content: center;
  cursor: pointer; color: var(--ink-soft);
}
.pager-btn:hover:not(:disabled) { border-color: var(--blue-900); color: var(--blue-900); }
.pager-btn:disabled { opacity: 0.4; cursor: not-allowed; }
.page-input-wrapper { display: flex; align-items: center; gap: 6px; font-weight: 600; }
.page-input {
  width: 44px; height: 32px; text-align: center;
  border: 1px solid var(--line); border-radius: 6px;
  font-weight: 700; font-size: 13px; outline: none;
}
.page-input:focus { border-color: var(--blue-900); }
.per-page-select select {
  height: 32px; padding: 0 10px;
  border: 1px solid var(--line); border-radius: 6px;
  font-weight: 600; outline: none; cursor: pointer;
}

/* Modals */
.modal-overlay {
  position: fixed; inset: 0;
  background: rgba(20, 25, 45, 0.5);
  display: flex; align-items: center; justify-content: center;
  padding: 16px; z-index: 50;
}
.modal {
  background: #fff;
  border-radius: 16px;
  width: 100%; max-width: 500px;
  box-shadow: 0 20px 40px rgba(0,0,0,0.1);
  overflow: hidden;
}
.modal-header {
  display: flex; align-items: center; justify-content: space-between;
  padding: 20px 24px; border-bottom: 1px solid var(--line);
}
.modal-header h2 { font-size: 18px; margin: 0; color: var(--ink-dark); }
.icon-btn-plain { background: none; border: none; color: var(--ink-soft); cursor: pointer; }
.icon-btn-plain:hover { color: var(--ink-dark); }
.modal-body { padding: 24px; display: flex; flex-direction: column; gap: 16px; }

.form-row { display: grid; grid-template-columns: 1fr 1fr; gap: 16px; }
.form-group { display: flex; flex-direction: column; gap: 6px; }
.form-group label { font-size: 13px; font-weight: 700; color: var(--ink-dark); }

.form-input {
  padding: 10px 14px;
  border: 1px solid var(--line);
  border-radius: 8px;
  font-size: 14px;
  color: var(--ink-dark);
  outline: none;
  transition: border 0.2s;
}
.form-input:focus { border-color: var(--blue-900); box-shadow: 0 0 0 3px rgba(47, 59, 105, 0.1); }
.select-input { cursor: pointer; appearance: auto; }
.textarea-input { resize: vertical; min-height: 80px; font-family: inherit; }

.modal-footer {
  display: flex; justify-content: flex-end; gap: 12px;
  margin-top: 8px; padding-top: 20px;
  border-top: 1px solid var(--line);
}

@media (max-width: 640px) {
  .card-toolbar { flex-direction: column; align-items: stretch; }
  .toolbar-actions { justify-content: space-between; width: 100%; }
  .search-box input { width: 100%; }
  .form-row { grid-template-columns: 1fr; }
}
</style>