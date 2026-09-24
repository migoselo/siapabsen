<script setup>
import { ref, reactive, computed, watch, onMounted } from 'vue'
import { Icon } from '@iconify/vue'
import api from '../api'

// Import Komponen Dialog
import GlobalConfirm from '../components/GlobalConfirm.vue'
import { useConfirm } from '../composables/UseConfirm'
import BaseActionBtn from '../components/BaseActionBtn.vue'

const confirmDialog = useConfirm()

/* ================= Data Dummy Roles ================= */
const roles = ref([
  {
    id: 'ROLE-001',
    name: 'Super Admin',
    hak_akses: 'Semua Akses System',
    deskripsi: 'Akses penuh ke seluruh fitur dan pengaturan aplikasi',
    levels: ['Level 4 - Eksekutif'],
    divisis: ['IT & System Operations'],
  },
  {
    id: 'ROLE-002',
    name: 'HR & People Operations Lead',
    hak_akses: 'Kelola Karyawan, Payroll & KPI',
    deskripsi:
      'Pengelolaan data karyawan, rekapitulasi payroll bulanan, onboarding, dan evaluasi performa tim operasional.',
    levels: ['Level 3 - Manajerial'],
    divisis: ['HR & People Operations'],
  },
  {
    id: 'ROLE-003',
    name: 'Manager Operasional',
    hak_akses: 'Lihat Laporan & Approval',
    deskripsi: 'Melihat laporan harian dan menyetujui pengajuan izin',
    levels: ['Level 3 - Manajerial'],
    divisis: ['Operasional'],
  },
  {
    id: 'ROLE-004',
    name: 'Karyawan',
    hak_akses: 'Absensi & Profile',
    deskripsi: 'Akses melakukan absensi masuk/keluar dan edit profil',
    levels: ['Level 1 - Operasional'],
    divisis: ['Umum'],
  },
])

/* ================= State Tabel & Pagination ================= */
const searchQuery = ref('')
const officeSearchQuery = ref('')
const currentPage = ref(1)
const perPage = ref(20)
const pageInput = ref(1)
const editingRoleId = ref(null)
const offices = ref([])
const officesLoading = ref(false)
const selectedOffice = ref(null)

const filteredOffices = computed(() => {
  const query = officeSearchQuery.value.trim().toLowerCase()
  if (!query) return offices.value
  return offices.value.filter((office) => {
    const name = String(office.name || '').toLowerCase()
    const address = String(office.address || office.alamat || '').toLowerCase()
    return name.includes(query) || address.includes(query)
  })
})

async function fetchOffices() {
  officesLoading.value = true
  try {
    const response = await api.get('/locations')
    offices.value = Array.isArray(response.data) ? response.data : []
  } catch (error) {
    console.error('Gagal mengambil daftar kantor:', error)
    showToast('Daftar kantor tidak dapat dimuat.', 'error')
  } finally {
    officesLoading.value = false
  }
}

function selectOffice(office) {
  selectedOffice.value = office
  currentPage.value = 1
  pageInput.value = 1
}

function backToOfficeList() {
  selectedOffice.value = null
  searchQuery.value = ''
  currentPage.value = 1
  pageInput.value = 1
}

watch(currentPage, (newPage) => {
  pageInput.value = newPage
})

watch([searchQuery], () => {
  currentPage.value = 1
  pageInput.value = 1
})

const filteredRoles = computed(() => {
  const q = searchQuery.value.trim().toLowerCase()
  if (!q) return roles.value
  return roles.value.filter(
    (r) =>
      r.name.toLowerCase().includes(q) ||
      r.hak_akses.toLowerCase().includes(q) ||
      r.deskripsi.toLowerCase().includes(q) ||
      r.id.toLowerCase().includes(q),
  )
})

const lastPage = computed(() => Math.ceil(filteredRoles.value.length / perPage.value) || 1)

const paginatedRoles = computed(() => {
  const start = (currentPage.value - 1) * perPage.value
  return filteredRoles.value.slice(start, start + perPage.value)
})

function prevPage() {
  if (currentPage.value > 1) {
    currentPage.value--
    pageInput.value = currentPage.value
  }
}

function nextPage() {
  if (currentPage.value < lastPage.value) {
    currentPage.value++
    pageInput.value = currentPage.value
  }
}

function goToInputPage() {
  let page = Number(pageInput.value)
  if (isNaN(page) || page < 1) page = 1
  if (page > lastPage.value) page = lastPage.value
  currentPage.value = page
  pageInput.value = page
}

function changePerPage() {
  currentPage.value = 1
  pageInput.value = 1
}

function initials(name) {
  if (!name) return ''
  return name
    .split(' ')
    .map((w) => w[0])
    .slice(0, 2)
    .join('')
    .toUpperCase()
}

/* ================= Toast Notifikasi ================= */
const toast = ref({ show: false, type: 'success', message: '' })
let toastTimer = null

function showToast(message, type = 'success') {
  toast.value = { show: true, type, message }
  if (toastTimer) clearTimeout(toastTimer)
  toastTimer = setTimeout(() => {
    toast.value.show = false
  }, 2600)
}

/* ================= Form & Modal State ================= */
const showModal = ref(false)
const roleName = ref('')
const roleDescription = ref('')

// Hak Akses (Permissions) Structure
const permissions = reactive({
  ess: {
    profil: [
      { id: 'ess_profile_view', label: 'Lihat Profil Mandiri', checked: true },
      { id: 'ess_profile_edit', label: 'Ajukan Perubahan Data Pribadi', checked: true },
      { id: 'ess_profile_tax', label: 'Edit NIK & Nomor Rekening Pajak', checked: false },
      {
        id: 'ess_payslip_download',
        label: 'Unduh Slip Gaji Digital (PDF terenkripsi)',
        checked: true,
      },
      { id: 'ess_directory_view', label: 'Akses Direktori Kontak Lengkap Pegawai', checked: false },
    ],
    presensi: [
      {
        id: 'ess_clock_in_out',
        label: 'Clock-in / Clock-out (GPS Geolocation & Selfie)',
        checked: true,
      },
      {
        id: 'ess_leave_request',
        label: 'Pengajuan Cuti Tahunan, Khusus & Izin Sakit',
        checked: true,
      },
      { id: 'ess_overtime_history', label: 'Lihat Riwayat Jam Kerja & Lembur', checked: true },
      { id: 'ess_shift_swap', label: 'Permohonan Tukar Shift Rekan Kerja', checked: true },
    ],
    reimbursement: [
      { id: 'ess_reimburse_claim', label: 'Ajukan Klaim Rawat Jalan & Kacamata', checked: true },
      { id: 'ess_reimburse_cancel', label: 'Batalkan Pengajuan Klaim Mandiri', checked: false },
      {
        id: 'ess_reimburse_status',
        label: 'Pantau Status Pencairan Dana Reimbursement',
        checked: true,
      },
    ],
  },
  admin: {
    karyawan: [
      { id: 'adm_emp_view', label: 'Lihat Master Database Seluruh Pegawai', checked: true },
      { id: 'adm_emp_add', label: 'Tambah & Onboard Karyawan Baru', checked: true },
      { id: 'adm_emp_edit', label: 'Edit Kontrak, Grade, & Jabatan Organisasi', checked: true },
      {
        id: 'adm_emp_offboard',
        label: 'Nonaktifkan / Offboarding / Resignasi Karyawan',
        checked: false,
      },
      { id: 'adm_org_chart', label: 'Kelola Bagan Struktur Organisasi & Divisi', checked: true },
    ],
    payroll: [
      { id: 'adm_payroll_view', label: 'Lihat Laporan Rekapitulasi Gaji Tim', checked: true },
      {
        id: 'adm_payroll_approve',
        label: 'Hitung & Finalisasi Approval Payroll Bulanan',
        checked: false,
      },
      {
        id: 'adm_payroll_export',
        label: 'Ekspor File Disposisi Bank Transfer (BCA/Mandiri)',
        checked: false,
      },
      {
        id: 'adm_payroll_config',
        label: 'Konfigurasi Formula Tunjangan, PPh 21 & BPJS',
        checked: true,
      },
    ],
    kpi: [
      { id: 'adm_kpi_create', label: 'Buat Periode Review KPI & OKR Perusahaan', checked: true },
      {
        id: 'adm_kpi_evaluate',
        label: 'Evaluasi Kinerja Staf Bawahan (360 Feedback)',
        checked: true,
      },
      { id: 'adm_kpi_promote', label: 'Setujui Hasil Kenaikan Grade / Promosi', checked: true },
    ],
  },
})

function isGroupAllChecked(groupList) {
  return groupList.every((item) => item.checked)
}

function toggleGroupSelectAll(groupList) {
  const targetState = !isGroupAllChecked(groupList)
  groupList.forEach((item) => {
    item.checked = targetState
  })
}

// Modal Handlers
function openAddModal() {
  editingRoleId.value = null
  roleName.value = ''
  roleDescription.value = ''
  showModal.value = true
}

function openEditModal(role) {
  editingRoleId.value = role.id
  roleName.value = role.name
  roleDescription.value = role.deskripsi
  showModal.value = true
}

function closeModal() {
  showModal.value = false
  editingRoleId.value = null
}

function submitRole() {
  const name = roleName.value.trim()
  const desc = roleDescription.value.trim()

  if (!name) {
    showToast('Nama role wajib diisi.', 'error')
    return
  }

  if (editingRoleId.value) {
    const idx = roles.value.findIndex((r) => r.id === editingRoleId.value)
    if (idx !== -1) {
      roles.value[idx] = {
        ...roles.value[idx],
        name,
        deskripsi: desc || '-',
      }
    }
    showToast('Role berhasil diperbarui.')
  } else {
    const newId = `ROLE-00${roles.value.length + 1}`
    roles.value.push({
      id: newId,
      name,
      hak_akses: 'Custom Access',
      deskripsi: desc || '-',
    })
    showToast('Role berhasil ditambahkan.')
  }

  closeModal()
}

async function deleteRole(role) {
  const isConfirmed = await confirmDialog.showConfirm({
    title: 'Hapus Role',
    message: `Apakah Anda yakin ingin menghapus role "${role.name}"?`,
    type: 'danger',
    confirmText: 'Hapus',
    cancelText: 'Batal',
  })

  if (!isConfirmed) return

  roles.value = roles.value.filter((r) => r.id !== role.id)
  showToast('Role berhasil dihapus.')
}

onMounted(fetchOffices)
</script>

<template>
  <div class="role-akses">
    <!-- Toast Notifikasi & Global Confirm -->
    <Teleport to="body">
      <div v-if="toast.show" class="toast" :class="toast.type">
        <Icon
          :icon="
            toast.type === 'success'
              ? 'material-symbols:check-circle-rounded'
              : 'material-symbols:error-rounded'
          "
          width="18"
          height="18"
        />
        <span>{{ toast.message }}</span>
      </div>
    </Teleport>
    <GlobalConfirm />

    <!-- PILIH KANTOR TERLEBIH DAHULU -->
    <section v-if="!selectedOffice" class="panel table-panel office-panel">
      <div class="office-head">
        <div>
          <h2>Pilih Kantor</h2>
          <p>Pilih kantor terlebih dahulu untuk mengatur role dan hak akses.</p>
        </div>
        <div class="search office-search">
          <Icon icon="material-symbols:search-rounded" width="18" height="18" />
          <input v-model="officeSearchQuery" type="text" placeholder="Cari kantor ..." />
        </div>
      </div>

      <table>
        <thead>
          <tr>
            <th>Nama Kantor</th>
            <th>Alamat</th>
            <th class="action-column">Aksi</th>
          </tr>
        </thead>
        <tbody>
          <tr v-if="officesLoading">
            <td colspan="3" class="empty-cell">Memuat data kantor...</td>
          </tr>
          <tr v-else-if="filteredOffices.length === 0">
            <td colspan="3" class="empty-cell">Tidak ada kantor ditemukan.</td>
          </tr>
          <tr v-for="office in filteredOffices" v-else :key="office.id">
            <td>
              <strong>{{ office.name }}</strong>
            </td>
            <td>{{ office.address || office.alamat || '-' }}</td>
            <td class="action-cell">
              <button type="button" class="detail-link-btn" @click="selectOffice(office)">
                Atur Role
              </button>
            </td>
          </tr>
        </tbody>
      </table>
    </section>

    <!-- TABEL ROLE SETELAH KANTOR DIPILIH -->
    <section v-else class="panel table-panel">
      <div class="role-location-bar">
        <button
          type="button"
          class="back-btn"
          @click="backToOfficeList"
          title="Kembali ke daftar kantor"
        >
          <Icon icon="material-symbols:arrow-back-rounded" width="22" height="22" />
        </button>
        <div>
          <span class="breadcrumb-label">Kantor terpilih</span>
          <h2>{{ selectedOffice.name }}</h2>
        </div>
      </div>

      <div class="table-head">
        <div class="search">
          <Icon icon="material-symbols:search-rounded" width="18" height="18" />
          <input type="text" v-model="searchQuery" placeholder="Cari role ..." />
        </div>
        <button class="icon-btn-solid" @click="openAddModal" title="Tambah Role">
          <Icon icon="material-symbols:add-rounded" width="20" height="20" />
        </button>
      </div>

      <table>
        <thead>
          <tr>
            <th>ID</th>
            <th>ROLE</th>
            <th>HAK AKSES</th>
            <th>DESKRIPSI</th>
            <th class="action-column">AKSI</th>
          </tr>
        </thead>
        <tbody>
          <tr v-if="paginatedRoles.length === 0">
            <td colspan="5" class="empty-cell">Tidak ada role ditemukan.</td>
          </tr>
          <tr v-for="item in paginatedRoles" :key="item.id">
            <td class="role-id-cell">{{ item.id }}</td>
            <td>
              <div class="role-info">
                <div class="role-avatar">{{ initials(item.name) }}</div>
                <div class="role-name">{{ item.name }}</div>
              </div>
            </td>
            <td>{{ item.hak_akses }}</td>
            <td class="deskripsi-cell">{{ item.deskripsi }}</td>
            <td class="action-cell">
              <div class="actions">
                <BaseActionBtn variant="edit" @click="openEditModal(item)" />
                <BaseActionBtn variant="delete" @click="deleteRole(item)" />
              </div>
            </td>
          </tr>
        </tbody>
      </table>

      <!-- Footer Pagination -->
      <div class="table-footer">
        <div class="table-footer-content">
          <div class="pager">
            <button type="button" class="pager-btn" :disabled="currentPage === 1" @click="prevPage">
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
              :disabled="currentPage === lastPage"
              @click="nextPage"
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

          <span class="total-records-info">{{ filteredRoles.length }} role</span>
        </div>
      </div>
    </section>

    <!-- MODAL FORM ROLE & PERMISSIONS -->
    <Teleport to="body">
      <div v-if="showModal" class="modal-overlay" @click.self="closeModal">
        <div class="modal-container">
          <!-- Header Modal -->
          <div class="modal-header">
            <div class="header-title">
              <Icon
                icon="material-symbols:admin-panel-settings-outline"
                width="24"
                height="24"
                class="header-icon"
              />
              <div>
                <h3>{{ editingRoleId ? 'Edit Role' : 'Tambah Role' }}</h3>
                <p>Nama role, deskripsi, dan hak akses</p>
              </div>
            </div>
            <button type="button" class="btn-close" @click="closeModal">
              <Icon icon="material-symbols:close-rounded" width="20" height="20" />
            </button>
          </div>

          <!-- Body Modal -->
          <div class="modal-body">
            <!-- Section 1: Informasi Role -->
            <div class="card-info">
              <div class="card-info-header">
                <span class="card-title">Informasi Role</span>
              </div>

              <div class="form-layout">
                <!-- Nama Role & Deskripsi -->
                <div class="form-row-grid">
                  <div class="field">
                    <label>Nama Role <span class="required">*</span></label>
                    <input
                      type="text"
                      v-model="roleName"
                      placeholder="Contoh: HR & People Operations Lead"
                    />
                  </div>

                  <div class="field">
                    <label>Deskripsi</label>
                    <textarea
                      v-model="roleDescription"
                      rows="1"
                      placeholder="Pengelolaan data karyawan, rekapitulasi payroll bulanan..."
                    ></textarea>
                  </div>
                </div>
              </div>
            </div>

            <!-- Section 2: Konfigurasi Hak Akses -->
            <div class="permissions-section">
              <div class="permissions-header">
                <div>
                  <h4 class="section-title">Hak Akses</h4>
                </div>
                <div class="legend">
                  <span class="legend-item"><span class="dot dot-ess"></span> Mobile ESS</span>
                  <span class="legend-item"><span class="dot dot-admin"></span> HR Web Admin</span>
                </div>
              </div>

              <div class="permissions-grid">
                <!-- KOLOM KIRI: Mobile ESS -->
                <div class="column-card column-ess">
                  <div class="column-header">
                    <div class="column-icon-wrap ess-icon">
                      <Icon icon="material-symbols:smartphone-outline" width="22" height="22" />
                    </div>
                    <div>
                      <h5 class="column-title">Portal Employee Self-Service (ESS)</h5>
                      <p class="column-desc">
                        Hak akses untuk aplikasi mobile & portal mandiri karyawan
                      </p>
                    </div>
                  </div>

                  <!-- Modul 1 -->
                  <div class="module-box">
                    <div class="module-header">
                      <h6>Profil & Kepegawaian</h6>
                      <button
                        type="button"
                        class="btn-toggle-all"
                        @click="toggleGroupSelectAll(permissions.ess.profil)"
                      >
                        {{
                          isGroupAllChecked(permissions.ess.profil) ? 'Batal Semua' : 'Pilih Semua'
                        }}
                      </button>
                    </div>
                    <div class="checkbox-list">
                      <label
                        v-for="item in permissions.ess.profil"
                        :key="item.id"
                        class="custom-checkbox ess-check"
                      >
                        <input type="checkbox" v-model="item.checked" />
                        <span class="checkmark"></span>
                        <span class="label-text">{{ item.label }}</span>
                      </label>
                    </div>
                  </div>

                  <!-- Modul 2 -->
                  <div class="module-box">
                    <div class="module-header">
                      <h6>Presensi, Cuti & Lembur</h6>
                      <button
                        type="button"
                        class="btn-toggle-all"
                        @click="toggleGroupSelectAll(permissions.ess.presensi)"
                      >
                        {{
                          isGroupAllChecked(permissions.ess.presensi)
                            ? 'Batal Semua'
                            : 'Pilih Semua'
                        }}
                      </button>
                    </div>
                    <div class="checkbox-list">
                      <label
                        v-for="item in permissions.ess.presensi"
                        :key="item.id"
                        class="custom-checkbox ess-check"
                      >
                        <input type="checkbox" v-model="item.checked" />
                        <span class="checkmark"></span>
                        <span class="label-text">{{ item.label }}</span>
                      </label>
                    </div>
                  </div>

                  <!-- Modul 3 -->
                  <div class="module-box">
                    <div class="module-header">
                      <h6>Reimbursement & Klaim Medis</h6>
                      <button
                        type="button"
                        class="btn-toggle-all"
                        @click="toggleGroupSelectAll(permissions.ess.reimbursement)"
                      >
                        {{
                          isGroupAllChecked(permissions.ess.reimbursement)
                            ? 'Batal Semua'
                            : 'Pilih Semua'
                        }}
                      </button>
                    </div>
                    <div class="checkbox-list">
                      <label
                        v-for="item in permissions.ess.reimbursement"
                        :key="item.id"
                        class="custom-checkbox ess-check"
                      >
                        <input type="checkbox" v-model="item.checked" />
                        <span class="checkmark"></span>
                        <span class="label-text">{{ item.label }}</span>
                      </label>
                    </div>
                  </div>
                </div>

                <!-- KOLOM KANAN: HR Web Admin -->
                <div class="column-card column-admin">
                  <div class="column-header">
                    <div class="column-icon-wrap admin-icon">
                      <Icon icon="material-symbols:computer-outline" width="22" height="22" />
                    </div>
                    <div>
                      <h5 class="column-title">HR Admin Portal & Backoffice</h5>
                      <p class="column-desc">
                        Hak akses operasional backoffice HR, payroll, & analitik browser
                      </p>
                    </div>
                  </div>

                  <!-- Modul 1 -->
                  <div class="module-box">
                    <div class="module-header">
                      <h6>Manajemen Karyawan & Onboarding</h6>
                      <button
                        type="button"
                        class="btn-toggle-all"
                        @click="toggleGroupSelectAll(permissions.admin.karyawan)"
                      >
                        {{
                          isGroupAllChecked(permissions.admin.karyawan)
                            ? 'Batal Semua'
                            : 'Pilih Semua'
                        }}
                      </button>
                    </div>
                    <div class="checkbox-list">
                      <label
                        v-for="item in permissions.admin.karyawan"
                        :key="item.id"
                        class="custom-checkbox admin-check"
                      >
                        <input type="checkbox" v-model="item.checked" />
                        <span class="checkmark"></span>
                        <span class="label-text">{{ item.label }}</span>
                      </label>
                    </div>
                  </div>

                  <!-- Modul 2 -->
                  <div class="module-box">
                    <div class="module-header">
                      <h6>Penggajian & Kompensasi (Payroll)</h6>
                      <button
                        type="button"
                        class="btn-toggle-all"
                        @click="toggleGroupSelectAll(permissions.admin.payroll)"
                      >
                        {{
                          isGroupAllChecked(permissions.admin.payroll)
                            ? 'Batal Semua'
                            : 'Pilih Semua'
                        }}
                      </button>
                    </div>
                    <div class="checkbox-list">
                      <label
                        v-for="item in permissions.admin.payroll"
                        :key="item.id"
                        class="custom-checkbox admin-check"
                      >
                        <input type="checkbox" v-model="item.checked" />
                        <span class="checkmark"></span>
                        <span class="label-text">{{ item.label }}</span>
                      </label>
                    </div>
                  </div>

                  <!-- Modul 3 -->
                  <div class="module-box">
                    <div class="module-header">
                      <h6>Penilaian Kinerja (KPI & Performance)</h6>
                      <button
                        type="button"
                        class="btn-toggle-all"
                        @click="toggleGroupSelectAll(permissions.admin.kpi)"
                      >
                        {{
                          isGroupAllChecked(permissions.admin.kpi) ? 'Batal Semua' : 'Pilih Semua'
                        }}
                      </button>
                    </div>
                    <div class="checkbox-list">
                      <label
                        v-for="item in permissions.admin.kpi"
                        :key="item.id"
                        class="custom-checkbox admin-check"
                      >
                        <input type="checkbox" v-model="item.checked" />
                        <span class="checkmark"></span>
                        <span class="label-text">{{ item.label }}</span>
                      </label>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <!-- Footer Modal -->
          <div class="modal-footer">
            <button type="button" class="btn-cancel" @click="closeModal">Batal</button>
            <button type="button" class="btn-save" @click="submitRole">
              <Icon icon="material-symbols:save-outline" width="18" height="18" />
              {{ editingRoleId ? 'Simpan Perubahan' : 'Simpan Role' }}
            </button>
          </div>
        </div>
      </div>
    </Teleport>
  </div>
</template>

<style scoped>
.role-akses {
  --blue-900: #2f3b69;
  --blue-dark: #1e293b;
  --mint-primary: #00875a;
  --mint-light: #ecfdf5;
  --ink: #1c1c19;
  --ink-soft: #667085;
  --line: #d9dde5;
  --bg: #f7f8fa;
  --card: #ffffff;
  font-family: 'Plus Jakarta Sans', sans-serif;
}

.role-akses * {
  box-sizing: border-box;
  font-family: 'Plus Jakarta Sans', sans-serif;
}

.panel {
  background: var(--card);
  border: 1px solid var(--line);
  border-radius: 16px;
  overflow: hidden;
}

.table-panel {
  padding: 22px 0 0;
}

.office-panel {
  padding-top: 0;
}

.office-head,
.role-location-bar {
  display: flex;
  align-items: center;
  gap: 14px;
  padding: 22px 24px;
  border-bottom: 1px solid var(--line);
}

.office-head {
  justify-content: space-between;
  flex-wrap: wrap;
}

.office-head h2,
.role-location-bar h2 {
  margin: 0;
  color: var(--blue-900);
  font-size: 18px;
  font-weight: 700;
}

.office-head p {
  margin: 4px 0 0;
  color: var(--ink-soft);
  font-size: 13px;
}

.office-search {
  min-width: 260px;
}

.role-location-bar {
  background: var(--bg);
}

.breadcrumb-label {
  display: block;
  margin-bottom: 3px;
  color: var(--ink-soft);
  font-size: 12px;
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

.table-head {
  display: flex;
  justify-content: flex-end;
  align-items: center;
  gap: 10px;
  padding: 0 24px 22px;
  flex-wrap: wrap;
}

.search {
  display: flex;
  align-items: center;
  gap: 8px;
  background: var(--bg);
  border: 1px solid var(--line);
  padding: 10px 16px;
  border-radius: 10px;
  min-width: 280px;
}

.search input {
  border: none;
  background: none;
  outline: none;
  font-size: 14px;
  width: 100%;
  color: var(--ink);
}

.icon-btn-solid {
  width: 44px;
  height: 44px;
  border-radius: 10px;
  background: var(--blue-900);
  border: none;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  transition: background 0.15s ease;
}

.icon-btn-solid:hover {
  background: #273258;
}
.icon-btn-solid svg,
.icon-btn-solid .iconify {
  color: #fff;
}

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
  padding: 14px 24px;
  text-transform: uppercase;
}

tbody td {
  padding: 18px 24px;
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
  padding: 36px 24px;
  font-size: 14.5px;
}

.role-id-cell {
  color: var(--ink-soft);
}

.role-info {
  display: flex;
  align-items: center;
  gap: 12px;
}

.role-avatar {
  width: 36px;
  height: 36px;
  border-radius: 50%;
  background: #e2e5f0;
  color: #2f3b69;
  font-weight: 700;
  font-size: 12px;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

.role-name {
  font-weight: 700;
  font-size: 15px;
}

.deskripsi-cell {
  color: var(--ink-soft);
  font-size: 14px;
}

.action-column {
  width: 130px;
  text-align: center;
}

.action-cell {
  text-align: center;
}

.detail-link-btn {
  border: none;
  background: none;
  color: var(--blue-900);
  font-size: 14px;
  font-weight: 700;
  cursor: pointer;
}

.detail-link-btn:hover {
  text-decoration: underline;
}

/* Action Buttons (Consistent with Divisi/Shift) */
.actions {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
}

/* Table Footer Pagination */
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
}

.page-input::-webkit-outer-spin-button,
.page-input::-webkit-inner-spin-button {
  -webkit-appearance: none;
  margin: 0;
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

/* Modal Form Styles */
.modal-overlay {
  position: fixed;
  inset: 0;
  background: rgba(15, 23, 42, 0.6);
  backdrop-filter: blur(4px);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
  padding: 24px;
}

.modal-container {
  width: 100%;
  max-width: 1100px;
  max-height: 92vh;
  background: #ffffff;
  border-radius: 20px;
  box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.25);
  display: flex;
  flex-direction: column;
  overflow: hidden;
}

.modal-header {
  padding: 20px 28px;
  background: var(--bg);
  border-bottom: 1px solid var(--line);
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.header-title {
  display: flex;
  align-items: center;
  gap: 12px;
}

.header-icon {
  color: var(--blue-900);
}

.header-title h3 {
  margin: 0;
  font-size: 18px;
  font-weight: 700;
  color: var(--blue-900);
}

.header-title p {
  margin: 2px 0 0;
  font-size: 13px;
  color: var(--ink-soft);
}

.btn-close {
  border: none;
  background: transparent;
  color: var(--ink-soft);
  cursor: pointer;
  padding: 6px;
  border-radius: 8px;
}

.btn-close:hover {
  background: var(--line);
}

.modal-body {
  padding: 24px 28px;
  overflow-y: auto;
  display: flex;
  flex-direction: column;
  gap: 24px;
  flex: 1;
}

/* Card Informasi Role & Input Styles */
.card-info {
  background: #ffffff;
  border: 1px solid var(--line);
  border-radius: 16px;
  padding: 20px;
}

.card-info-header {
  margin-bottom: 16px;
}

.card-title {
  font-weight: 700;
  font-size: 16px;
  color: var(--ink);
}

.form-layout {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.form-row-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 16px;
}

.field {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.field label,
.group-label {
  font-size: 13px;
  font-weight: 600;
  color: var(--ink-soft);
}

.required {
  color: #ef4444;
}

/* Styling Penegasan Border Input (Tegas 1.5px) */
.field input,
.field select,
.field textarea,
.input-with-remove input,
.input-with-remove select {
  border: 1.5px solid #cbd5e1 !important;
  border-radius: 10px;
  padding: 10px 14px;
  font-size: 14px;
  color: var(--ink);
  outline: none;
  background: #ffffff;
  font-family: inherit;
  width: 100%;
  transition: all 0.15s ease;
}

.field input:focus,
.field select:focus,
.field textarea:focus,
.input-with-remove input:focus,
.input-with-remove select:focus {
  border-color: var(--blue-900) !important;
  box-shadow: 0 0 0 3px rgba(47, 59, 105, 0.1);
}

/* Dynamic Inputs Area */
.dynamic-group {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.dynamic-inputs-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
  gap: 12px;
}

.input-with-remove {
  display: flex;
  align-items: center;
  gap: 8px;
}

.btn-remove-field {
  border: none;
  background: #ffe9eb;
  color: #c92d40;
  border-radius: 8px;
  padding: 8px;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  flex-shrink: 0;
}

.btn-remove-field:hover {
  background: #ffd9de;
}

/* Tombol Tambah Komponen ala Gambar Tunjangan */
.btn-add-component {
  width: 100%;
  border: 1px solid #e0e7ff;
  background: #eeefef;
  color: #4338ca;
  font-size: 13.5px;
  font-weight: 600;
  padding: 10px;
  border-radius: 10px;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 6px;
  transition: all 0.15s ease;
}

.btn-add-component:hover {
  background: #e0e7ff;
}

/* Permissions Styling */
.permissions-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-end;
  margin-bottom: 16px;
}

.section-title {
  margin: 0;
  font-size: 16px;
  font-weight: 700;
  color: var(--ink);
}

.section-subtitle {
  margin: 4px 0 0;
  font-size: 13px;
  color: var(--ink-soft);
}

.legend {
  display: flex;
  gap: 16px;
  font-size: 12.5px;
  font-weight: 600;
  color: var(--ink-soft);
}

.legend-item {
  display: flex;
  align-items: center;
  gap: 6px;
}

.dot {
  width: 10px;
  height: 10px;
  border-radius: 50%;
}

.dot-ess {
  background: #4e62af;
}
.dot-admin {
  background: #2c3964;
}

.permissions-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 20px;
}

.column-card {
  border-radius: 16px;
  padding: 20px;
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.column-ess {
  background: #ffffff;
  border: 1.5px solid #4e62af;
}
.column-admin {
  background: #ffffff;
  border: 1.5px solid #2c3964;
}

.column-header {
  display: flex;
  align-items: center;
  gap: 12px;
  padding-bottom: 12px;
  border-bottom: 1px solid var(--line);
}

.column-icon-wrap {
  width: 40px;
  height: 40px;
  border-radius: 10px;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

.ess-icon {
  background: var(--mint-light);
  color: var(--mint-primary);
}
.admin-icon {
  background: #f1f5f9;
  color: var(--blue-dark);
}

.column-title {
  margin: 0;
  font-size: 14.5px;
  font-weight: 700;
  color: var(--ink);
}

.column-desc {
  margin: 2px 0 0;
  font-size: 12px;
  color: var(--ink-soft);
}

.module-box {
  background: #f8fafc;
  border: 1px solid var(--line);
  border-radius: 12px;
  padding: 14px 16px;
}

.module-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 12px;
}

.module-header h6 {
  margin: 0;
  font-size: 13.5px;
  font-weight: 700;
  color: var(--ink);
}

.btn-toggle-all {
  border: none;
  background: none;
  color: #2563eb;
  font-size: 12px;
  font-weight: 600;
  cursor: pointer;
}

.btn-toggle-all:hover {
  text-decoration: underline;
}

.checkbox-list {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.custom-checkbox {
  display: flex;
  align-items: center;
  position: relative;
  cursor: pointer;
  font-size: 18px;
  color: var(--ink);
  user-select: none;
  gap: 14px;
  line-height: 1.4;
  min-height: 26px;
}

.custom-checkbox input {
  position: absolute;
  opacity: 0;
  pointer-events: none;
}

.checkmark {
  position: relative;
  display: inline-block;
  height: 24px;
  width: 24px;
  min-width: 24px;
  background-color: #fff;
  border: 2px solid #cbd5e1;
  border-radius: 8px;
  transition: all 0.15s ease;
  box-sizing: border-box;
  flex-shrink: 0;
}

.ess-check input:checked + .checkmark {
  background-color: #4e62af;
  border-color: #4e62af;
  box-shadow: none;
}
.admin-check input:checked + .checkmark {
  background-color: #2c3964;
  border-color: #2c3964;
  box-shadow: none;
}

.checkmark::after {
  content: '';
  position: absolute;
  left: 7px;
  top: 2px;
  width: 6px;
  height: 12px;
  border: solid white;
  border-width: 0 2px 2px 0;
  transform: rotate(45deg);
  opacity: 0;
  transition: opacity 0.12s ease;
}

.custom-checkbox input:checked + .checkmark::after {
  opacity: 1;
}

.custom-checkbox input:checked ~ .label-text {
  color: var(--ink);
  font-weight: 400;
}

.label-text {
  flex: 1;
  font-size: 15px;
  line-height: 1.5;
}

.modal-footer {
  padding: 16px 28px;
  background: var(--bg);
  border-top: 1px solid var(--line);
  display: flex;
  justify-content: flex-end;
  gap: 12px;
}

.btn-cancel {
  padding: 10px 18px;
  border-radius: 10px;
  border: 1px solid var(--line);
  background: #ffffff;
  color: var(--ink);
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
}

.btn-save {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 12px 22px;
  border-radius: 10px;
  border: none;
  background: #2c3964;
  color: #fff;
  font-size: 14px;
  font-weight: 700;
  cursor: pointer;
  transition: background 0.15s ease;
}
.btn-save:hover {
  background: #273258;
}
.btn-save:disabled,
.btn-cancel:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

/* Toast */
.toast {
  position: fixed;
  top: 24px;
  left: 50%;
  transform: translateX(-50%);
  z-index: 2000;
  display: inline-flex;
  align-items: center;
  gap: 8px;
  padding: 12px 20px;
  border-radius: 12px;
  font-size: 14px;
  font-weight: 600;
  color: white;
  box-shadow: 0 10px 30px rgba(17, 24, 39, 0.2);
  animation: toastIn 0.25s cubic-bezier(0.16, 1, 0.3, 1);
}

.toast.success {
  background: #1f9d67;
}
.toast.error {
  background: #d92d20;
}

@keyframes toastIn {
  from {
    opacity: 0;
    transform: translate(-50%, -20px);
  }
  to {
    opacity: 1;
    transform: translate(-50%, 0);
  }
}

@media (max-width: 868px) {
  .permissions-grid {
    grid-template-columns: 1fr;
  }
  .form-row-grid {
    grid-template-columns: 1fr;
  }
}
</style>
