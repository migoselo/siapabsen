<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { Icon } from '@iconify/vue'
import api from '../api'

/* ------------------------------------------------------------------ */
/* State Management & Mock Data                                       */
/* ------------------------------------------------------------------ */
// Flow Perusahaan
const companies = ref([])
const selectedCompany = ref(null)
const loading = ref(false)
const saving = ref(false)

// Flow Shift & Divisi
const activeTab = ref('shift') // 'shift' | 'divisi'
const searchQuery = ref('')
const currentPage = ref(1)
const perPage = ref(10)
const pageInput = ref(1)

const divisions = ref([])
const shifts = ref([])

/* ------------------------------------------------------------------ */
/* Helper Functions                                                    */
/* ------------------------------------------------------------------ */
function getDivisionNames(ids) {
  if (!ids || !Array.isArray(ids) || ids.length === 0) return '-'
  if (ids.length === divisions.value.length) return 'Semua Divisi'
  
  return divisions.value
    .filter(d => ids.includes(d.id))
    .map(d => d.name)
    .join(', ')
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
const filteredCompanies = computed(() => {
  const query = searchQuery.value.trim().toLowerCase()
  if (!query) return companies.value
  return companies.value.filter((company) =>
    `${company.name} ${company.address || ''}`.toLowerCase().includes(query),
  )
})

const filteredData = computed(() => {
  const query = searchQuery.value.trim().toLowerCase()
  if (activeTab.value === 'shift') {
    return shifts.value.filter(s => 
      !query || 
      s.name.toLowerCase().includes(query) || 
      getDivisionNames(s.divisionIds).toLowerCase().includes(query)
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
/* API Data Fetching                                                   */
/* ------------------------------------------------------------------ */
async function fetchCompanies() {
  // Mock Fetching Perusahaan
  loading.value = true
  setTimeout(() => {
    companies.value = [
      { id: 1, location_id: 101, name: 'PT Maju Bersama', address: 'Jl. Sudirman No. 1', users_count: 120 },
      { id: 2, location_id: 102, name: 'PT Teknologi Jaya', address: 'Jl. Thamrin No. 2', users_count: 85 },
    ]
    loading.value = false
  }, 500)
}

function selectCompany(company) {
  selectedCompany.value = company
  searchQuery.value = ''
  fetchDataForCompany()
}

function fetchDataForCompany() {
  if (!selectedCompany.value) return
  loading.value = true
  
  // Mock Data spesifik per perusahaan
  setTimeout(() => {
    divisions.value = [
      { id: 'd1', name: 'Engineering', description: 'Tim pengembang' },
      { id: 'd2', name: 'Marketing', description: 'Tim pemasaran' }
    ]
    shifts.value = [
      { id: 's1', name: 'Shift Pagi', clockIn: '08:00', clockOut: '17:00', divisionIds: ['d1', 'd2'], status: 'Aktif' },
      { id: 's2', name: 'Shift Malam', clockIn: '20:00', clockOut: '05:00', divisionIds: ['d1'], status: 'Tidak Aktif' }
    ]
    loading.value = false
  }, 400)
}

/* ------------------------------------------------------------------ */
/* Modal Form & Custom Dropdown State                                  */
/* ------------------------------------------------------------------ */
const showModal = ref(false)
const modalMode = ref('add') // 'add' | 'edit'
const formData = ref({})

const showStatusMenu = ref(false)
const showClockInMenu = ref(false)
const showClockOutMenu = ref(false)

const hoursList = Array.from({ length: 24 }, (_, i) => i.toString().padStart(2, '0'))
const minutesList = Array.from({ length: 60 }, (_, i) => i.toString().padStart(2, '0'))

function selectTime(field, type, value) {
  let [h, m] = (formData.value[field] || '00:00').split(':')
  if (type === 'h') h = value
  else m = value
  formData.value[field] = `${h}:${m}`
}

function handleOutsideClick(e) {
  if (!e.target.closest?.('.custom-select')) {
    showStatusMenu.value = false
    showClockInMenu.value = false
    showClockOutMenu.value = false
  }
}

onMounted(() => {
  fetchCompanies()
  document.addEventListener('click', handleOutsideClick)
})

onUnmounted(() => {
  document.removeEventListener('click', handleOutsideClick)
})

function openModal(mode, item = null) {
  modalMode.value = mode
  if (activeTab.value === 'shift') {
    formData.value = item 
      ? { ...item, divisionIds: [...(item.divisionIds || [])] } 
      : { name: '', clockIn: '08:00', clockOut: '17:00', divisionIds: [], status: 'Aktif' }
  } else {
    formData.value = item ? { ...item } : { name: '', description: '' }
  }
  showModal.value = true
}

function closeModal() {
  showModal.value = false
  showStatusMenu.value = false
  showClockInMenu.value = false
  showClockOutMenu.value = false
  formData.value = {}
}

function toggleAllDivisions(e) {
  if (e.target.checked) {
    formData.value.divisionIds = divisions.value.map(d => d.id)
  } else {
    formData.value.divisionIds = []
  }
}

function saveForm() {
  if (activeTab.value === 'shift') {
    if (!formData.value.divisionIds || formData.value.divisionIds.length === 0) {
      alert('Harap pilih minimal satu divisi untuk shift ini.')
      return
    }
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
    const usedInShift = shifts.value.some(s => s.divisionIds.includes(id))
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
    
    <!-- TAMPILAN 1: LIST PERUSAHAAN (Jika Belum Dipilih) -->
    <section v-if="!selectedCompany" class="panel table-panel">
      <div class="filter-bar">
        <div class="breadcrumb-wrap">
          <div class="table-heading">
            <h2>Pilih Perusahaan</h2>
            <p>Pilih perusahaan untuk mengatur divisi dan jam kerja.</p>
          </div>
        </div>
        <div class="search">
          <Icon icon="material-symbols:search-rounded" width="18" height="18" />
          <input v-model="searchQuery" type="text" placeholder="Cari perusahaan..." />
        </div>
      </div>
      
      <table class="table">
        <thead>
          <tr>
            <th>Nama Perusahaan</th>
            <th>Alamat</th>
            <th>Jumlah Karyawan</th>
            <th class="action-column">Aksi</th>
          </tr>
        </thead>
        <tbody>
          <tr v-if="loading"><td colspan="4" class="empty-cell">Memuat data...</td></tr>
          <tr v-else-if="filteredCompanies.length === 0"><td colspan="4" class="empty-cell">Data perusahaan tidak ditemukan.</td></tr>
          <tr v-for="company in filteredCompanies" :key="`${company.id}-${company.location_id}`">
            <td><strong class="text-dark">{{ company.name }}</strong></td>
            <td><span class="text-soft">{{ company.address || '-' }}</span></td>
            <td><span class="badge badge-divisi">{{ company.users_count || 0 }} Orang</span></td>
            <td class="action-column">
              <button type="button" class="btn-primary" @click="selectCompany(company)">Kelola Shift</button>
            </td>
          </tr>
        </tbody>
      </table>
    </section>

    <!-- TAMPILAN 2: PENGATURAN SHIFT/DIVISI (Jika Sudah Memilih Perusahaan) -->
    <template v-else>
      <div class="company-context">
        <button type="button" class="back-btn" @click="selectedCompany = null; divisions = []; shifts = []">
          <Icon icon="material-symbols:arrow-back-rounded" width="18" /> 
        </button>
        <span class="company-name-display">{{ selectedCompany.name }}</span>
      </div>

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
              :class="{ 'tab-active': activeTab === 'divisi' }" 
              @click="changeTab('divisi')"
            >
              Daftar Divisi
              <span class="tab-count" :class="{ 'tab-count-active': activeTab === 'divisi' }">{{ divisions.length }}</span>
            </button>
            <button 
              class="tab" 
              :class="{ 'tab-active': activeTab === 'shift' }" 
              @click="changeTab('shift')"
            >
              Pengaturan Shift
              <span class="tab-count" :class="{ 'tab-count-active': activeTab === 'shift' }">{{ shifts.length }}</span>
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
              <tr v-if="loading"><td :colspan="activeTab === 'shift' ? 7 : 4" class="empty-row">Memuat data...</td></tr>
              <tr v-else-if="paginatedData.length === 0">
                <td :colspan="activeTab === 'shift' ? 7 : 4" class="empty-row">
                  Tidak ada data yang ditemukan.
                </td>
              </tr>

              <!-- Render Baris Shift -->
              <template v-if="activeTab === 'shift' && !loading">
                <tr v-for="shift in paginatedData" :key="shift.id">
                  <td>
                    <strong class="text-dark">{{ shift.name }}</strong>
                  </td>
                  <td>
                    <span class="badge badge-divisi">{{ getDivisionNames(shift.divisionIds) }}</span>
                  </td>
                  <td><span class="time-box in">{{ shift.clockIn?.slice(0, 5) }}</span></td>
                  <td><span class="time-box out">{{ shift.clockOut?.slice(0, 5) }}</span></td>
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
              <template v-else-if="activeTab === 'divisi' && !loading">
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
            <button type="button" class="icon-btn-plain" @click="closeModal">
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
                <!-- Custom Clock In -->
                <div class="form-group">
                  <label>Jam Masuk (Clock In)</label>
                  <div class="custom-select time-select" @click.stop="showClockInMenu = !showClockInMenu; showClockOutMenu = false; showStatusMenu = false">
                    <Icon icon="material-symbols:schedule-outline" width="18" class="time-icon-left" />
                    <span class="time-text">{{ formData.clockIn }}</span>
                    <Icon icon="material-symbols:keyboard-arrow-down-rounded" width="18" />

                    <div v-if="showClockInMenu" class="time-dropdown-menu" @click.stop>
                      <div class="time-columns">
                        <div class="time-col">
                          <div class="time-col-title">Jam</div>
                          <button type="button" v-for="h in hoursList" :key="'in-h'+h"
                            class="time-item"
                            :class="{ active: formData.clockIn.split(':')[0] === h }"
                            @click="selectTime('clockIn', 'h', h)">
                            {{ h }}
                          </button>
                        </div>
                        <div class="time-col">
                          <div class="time-col-title">Menit</div>
                          <button type="button" v-for="m in minutesList" :key="'in-m'+m"
                            class="time-item"
                            :class="{ active: formData.clockIn.split(':')[1] === m }"
                            @click="selectTime('clockIn', 'm', m)">
                            {{ m }}
                          </button>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>

                <!-- Custom Clock Out -->
                <div class="form-group">
                  <label>Jam Pulang (Clock Out)</label>
                  <div class="custom-select time-select" @click.stop="showClockOutMenu = !showClockOutMenu; showClockInMenu = false; showStatusMenu = false">
                    <Icon icon="material-symbols:schedule-outline" width="18" class="time-icon-left" />
                    <span class="time-text">{{ formData.clockOut }}</span>
                    <Icon icon="material-symbols:keyboard-arrow-down-rounded" width="18" />

                    <div v-if="showClockOutMenu" class="time-dropdown-menu" @click.stop>
                      <div class="time-columns">
                        <div class="time-col">
                          <div class="time-col-title">Jam</div>
                          <button type="button" v-for="h in hoursList" :key="'out-h'+h"
                            class="time-item"
                            :class="{ active: formData.clockOut.split(':')[0] === h }"
                            @click="selectTime('clockOut', 'h', h)">
                            {{ h }}
                          </button>
                        </div>
                        <div class="time-col">
                          <div class="time-col-title">Menit</div>
                          <button type="button" v-for="m in minutesList" :key="'out-m'+m"
                            class="time-item"
                            :class="{ active: formData.clockOut.split(':')[1] === m }"
                            @click="selectTime('clockOut', 'm', m)">
                            {{ m }}
                          </button>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              </div>

              <!-- Multi-select Divisi -->
              <div class="form-group">
                <label>Pilih Divisi Terkait</label>
                <div class="checkbox-group">
                  <label class="checkbox-label font-bold">
                    <input 
                      type="checkbox" 
                      :checked="formData.divisionIds?.length === divisions.length && divisions.length > 0"
                      @change="toggleAllDivisions" 
                    />
                    Pilih Semua Divisi
                  </label>
                  <div class="divider"></div>
                  <label v-for="d in divisions" :key="d.id" class="checkbox-label">
                    <input type="checkbox" v-model="formData.divisionIds" :value="d.id" />
                    {{ d.name }}
                  </label>
                  <div v-if="divisions.length === 0" class="form-hint">Belum ada divisi yang dibuat.</div>
                </div>
                <span class="form-hint" v-if="formData.divisionIds?.length === 0 && divisions.length > 0">
                  Harap pilih minimal satu divisi.
                </span>
              </div>

              <!-- Custom Dropdown Status Shift -->
              <div class="form-group">
                <label>Status Shift</label>
                <div class="custom-select" @click.stop="showStatusMenu = !showStatusMenu; showClockInMenu = false; showClockOutMenu = false">
                  <span>{{ formData.status }}</span>
                  <Icon icon="material-symbols:keyboard-arrow-down-rounded" width="18" height="18" />

                  <div v-if="showStatusMenu" class="select-menu">
                    <button
                      type="button"
                      class="select-item"
                      :class="{ active: formData.status === 'Aktif' }"
                      @click.stop="formData.status = 'Aktif'; showStatusMenu = false"
                    >
                      Aktif
                    </button>
                    <button
                      type="button"
                      class="select-item"
                      :class="{ active: formData.status === 'Tidak Aktif' }"
                      @click.stop="formData.status = 'Tidak Aktif'; showStatusMenu = false"
                    >
                      Tidak Aktif
                    </button>
                  </div>
                </div>
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
    </template>
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

/* Panel Perusahaan */
.panel {
  background: var(--card);
  border: 1px solid var(--line);
  border-radius: 12px;
  padding: 24px;
  box-shadow: 0 1px 2px rgba(16, 24, 40, 0.05);
}
.filter-bar {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20px;
}
.table-heading h2 {
  font-size: 18px;
  margin: 0 0 4px;
  color: var(--ink-dark);
}
.table-heading p {
  margin: 0;
  color: var(--ink-soft);
  font-size: 14px;
}
.search {
  position: relative;
}
.search svg {
  position: absolute;
  left: 12px;
  top: 50%;
  transform: translateY(-50%);
  color: var(--ink-soft);
}
.search input {
  padding: 10px 14px 10px 36px;
  border: 1px solid var(--line);
  border-radius: 8px;
  width: 260px;
  font-size: 14px;
}
.search input:focus {
  border-color: var(--blue-900);
  outline: none;
}
.company-context {
  display: flex;
  align-items: center;
  gap: 16px;
  margin-bottom: 20px;
}
.company-name-display {
  font-size: 18px;
  font-weight: 700;
  color: var(--ink-dark);
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
  transform: translateY(1px);
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
  white-space: nowrap;
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
.action-column { text-align: right; width: 1%; white-space: nowrap; }
.col-actions { text-align: right; width: 1%; white-space: nowrap; }
.table tbody tr { border-bottom: 1px solid #f1f2f5; }
.table tbody tr:hover { background: #fafbfc; }
.table td {
  padding: 14px 24px;
  vertical-align: middle;
}
.text-dark { color: var(--ink-dark); font-weight: 600; }
.text-soft { color: var(--ink-soft); font-size: 13px; }
.empty-cell { text-align: center; color: var(--ink-soft); padding: 40px; }

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
.back-btn {
  width: 36px;
  height: 36px;
  border-radius: 10px;
  border: none;
  background: none;
  color: var(--ink-dark);
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
}
.back-btn:hover {
  background: var(--surface-soft);
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
  overflow: visible;
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
.form-hint { color: var(--ink-soft); font-size: 12px; }
.textarea-input { resize: vertical; min-height: 80px; font-family: inherit; }

.modal-footer {
  display: flex; justify-content: flex-end; gap: 12px;
  margin-top: 8px; padding-top: 20px;
  border-top: 1px solid var(--line);
}

/* Checkbox Styles (Multi Select Divisi) */
.checkbox-group {
  display: flex;
  flex-direction: column;
  gap: 10px;
  padding: 14px;
  border: 1px solid var(--line);
  border-radius: 8px;
  background: #ffffff;
  max-height: 180px;
  overflow-y: auto;
}
.checkbox-label {
  display: flex;
  align-items: center;
  gap: 10px;
  font-size: 13px;
  color: var(--ink-dark);
  cursor: pointer;
}
.checkbox-label input[type="checkbox"] {
  width: 16px;
  height: 16px;
  cursor: pointer;
  accent-color: var(--blue-900);
}
.checkbox-label.font-bold {
  font-weight: 700;
  color: var(--blue-900);
}
.divider {
  height: 1px;
  background: var(--line);
  margin: 4px 0;
}

/* Custom Select Dropdown (Digunakan untuk Status & Time) */
.custom-select {
  position: relative;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 8px;
  background: #ffffff;
  border: 1px solid var(--line);
  padding: 10px 14px;
  border-radius: 8px;
  font-size: 14px;
  font-weight: 500;
  color: var(--ink-dark);
  cursor: pointer;
  user-select: none;
  transition: border 0.2s;
}
.custom-select:focus-within,
.custom-select:active {
  border-color: var(--blue-900);
  box-shadow: 0 0 0 3px rgba(47, 59, 105, 0.1);
}
.custom-select svg,
.custom-select .iconify {
  color: var(--ink-soft);
  flex-shrink: 0;
}
.select-menu {
  position: absolute;
  z-index: 60;
  top: calc(100% + 6px);
  left: 0;
  width: 100%;
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
  color: var(--ink-dark);
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

/* Custom Time Dropdown */
.time-select {
  padding-left: 38px;
}
.time-icon-left {
  position: absolute;
  left: 12px;
  color: var(--ink-soft);
  pointer-events: none;
}
.time-text {
  flex: 1;
  font-family: monospace;
  font-size: 15px;
  color: var(--ink-dark);
}
.time-dropdown-menu {
  position: absolute;
  z-index: 70;
  top: calc(100% + 6px);
  left: 0;
  width: 100%;
  background: #ffffff;
  border: 1px solid var(--line);
  border-radius: 10px;
  box-shadow: 0 12px 28px rgba(0, 0, 0, 0.12);
  padding: 10px;
  cursor: default;
}
.time-columns {
  display: flex;
  gap: 8px;
  height: 200px;
}
.time-col {
  flex: 1;
  display: flex;
  flex-direction: column;
  overflow-y: auto;
  gap: 2px;
  padding-right: 4px;
}
.time-col::-webkit-scrollbar {
  width: 4px;
}
.time-col::-webkit-scrollbar-thumb {
  background: var(--line);
  border-radius: 4px;
}
.time-col-title {
  font-size: 11px;
  font-weight: 700;
  color: var(--ink-soft);
  text-align: center;
  padding-bottom: 6px;
  position: sticky;
  top: 0;
  background: #ffffff;
  z-index: 2;
}
.time-item {
  background: transparent;
  border: none;
  padding: 6px 0;
  text-align: center;
  font-size: 14px;
  color: var(--ink-dark);
  border-radius: 6px;
  cursor: pointer;
  transition: all 0.15s;
}
.time-item:hover {
  background: #f4f5f8;
}
.time-item.active {
  background: var(--blue-900);
  color: #ffffff;
  font-weight: 700;
}

@media (max-width: 640px) {
  .card-toolbar { flex-direction: column; align-items: stretch; }
  .toolbar-actions { justify-content: space-between; width: 100%; }
  .search-box input { width: 100%; }
  .form-row { grid-template-columns: 1fr; }
}
</style>