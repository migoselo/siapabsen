<script setup>
import { ref, computed, onMounted, watch, onBeforeUnmount } from 'vue'
import { useRouter } from 'vue-router'
import { Icon } from '@iconify/vue'
import api from '../api'

const router = useRouter()

const employees = ref([])
const loading = ref(false)
const searchQuery = ref('')
const currentPage = ref(1)
const lastPage = ref(1)
const totalEmployees = ref(0)
const perPage = ref(20)
const pageInput = ref(1)
const toast = ref({ show: false, type: 'success', message: '' })
let toastTimer = null

watch(currentPage, (newPage) => {
  pageInput.value = newPage
})

const showModal = ref(false)
const saving = ref(false)
const locations = ref([])
const divisions = ref([])
const shifts = ref([])
const companies = ref([])
const selectedCompany = ref(null)
const selectedBranch = ref(null)
const form = ref({
  name: '',
  email: '',
  password: '',
  no_hp: '',
  role: 'karyawan',
  home_location_id: '',
  division_id: '',
  shift_id: '',
})

const showPassword = ref(false)

const filteredEmployees = computed(() => {
  const q = searchQuery.value.trim().toLowerCase()
  if (!q) return employees.value
  return employees.value.filter(
    (e) => e.name.toLowerCase().includes(q) || e.email.toLowerCase().includes(q),
  )
})

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

const currentLevelLabel = computed(() => {
  if (!selectedCompany.value) return 'Daftar Perusahaan'
  if (!selectedBranch.value && currentCompanyChildren.value.length) return 'Daftar Cabang / Anak Perusahaan'
  return 'Daftar Karyawan'
})

const currentCompanyChildren = computed(() => {
  if (!selectedCompany.value) return companyTree.value
  return selectedCompany.value.children || []
})

const currentEmployees = computed(() => {
  if (selectedBranch.value) return selectedBranch.value.employees || []

  if (selectedCompany.value) {
    if ((selectedCompany.value.children || []).length) {
      return []
    }
    return selectedCompany.value.employees || []
  }

  return []
})

function splitHierarchyLabel(label) {
  const value = String(label || '').trim()
  if (!value) return []

  const separators = [' / ', ' > ', ' - ', ' | ']
  for (const separator of separators) {
    if (value.includes(separator)) {
      return value
        .split(separator)
        .map((part) => part.trim())
        .filter(Boolean)
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
        const node = {
          id: key,
          name: segment,
          address: address,
          children: [],
          employees: [],
          count: 0,
        }

        if (parent) {
          parent.children.push(node)
        } else {
          roots.push(node)
        }

        nodes.set(key, node)
      }

      parent = nodes.get(key)
    })

    return parent
  }

  ;(companies.value || []).forEach((company) => {
    const name = String(company?.name || '').trim()
    const address = String(company?.address || company?.alamat || '-').trim()
    if (!name) return
    const path = splitHierarchyLabel(name)
    const node = addNode(path, address)
    if (node && company?.id) {
      node.companyId = company.id
    }
  })

  filteredEmployees.value.forEach((emp) => {
    const employeeName = String(emp?.name || '').trim()
    const companyName =
      emp.homeLocation?.name ||
      emp.home_location?.name ||
      emp.location?.name ||
      emp.home_location ||
      'Tanpa Perusahaan'

    if (!employeeName) return

    const path = splitHierarchyLabel(companyName)
    const exactKey = path.join(' / ')
    const target =
      nodes.get(exactKey) ||
      nodes.get(path[path.length - 1]) ||
      addNode(path)

    if (target) {
      target.employees.push({
        id: emp.id,
        name: employeeName,
        email: emp.email || '-',
        no_hp: emp.no_hp || '-',
        division: emp.division?.name || emp.division_name || '-',
        shift: emp.shift
          ? `${emp.shift.name} (${String(emp.shift.work_start_time).slice(0, 5)}-${String(emp.shift.work_end_time).slice(0, 5)})`
          : 'Gunakan jam lokasi',
        raw: emp
      })
      target.count = target.employees.length
    }
  })

  const assignCounts = (node) => {
    if (node.employees.length) {
      node.count = node.employees.length
    }

    node.children.forEach((child) => {
      assignCounts(child)
      node.count = (node.count || 0) + (child.count || 0)
    })
  }

  roots.forEach(assignCounts)

  return roots
})

async function fetchEmployees(page = 1) {
  loading.value = true
  try {
    const res = await api.get('/users', { params: { page, per_page: perPage.value } })
    const employeeList = Array.isArray(res.data?.data) ? res.data.data : []
    employees.value = employeeList
    totalEmployees.value = res.data?.total ?? employeeList.length
    currentPage.value = res.data?.current_page || page
    lastPage.value = res.data?.last_page || 1
  } catch (err) {
    console.error('Gagal mengambil data karyawan:', err)
  } finally {
    loading.value = false
  }
}

function onSearchInput() {}

function prevPage() {
  if (currentPage.value > 1) {
    fetchEmployees(currentPage.value - 1)
  }
}

function nextPage() {
  if (currentPage.value < lastPage.value) {
    fetchEmployees(currentPage.value + 1)
  }
}

function goToInputPage() {
  let page = Number(pageInput.value)
  if (isNaN(page) || page < 1) page = 1
  if (page > lastPage.value) page = lastPage.value
  pageInput.value = page
  if (page !== currentPage.value) {
    fetchEmployees(page)
  }
}

function changePerPage() {
  fetchEmployees(1)
}

function showToast(message, type = 'success') {
  toast.value = { show: true, type, message }
  if (toastTimer) clearTimeout(toastTimer)
  toastTimer = setTimeout(() => {
    toast.value.show = false
  }, 2600)
}

function handleMissingBackendFeature(action) {
  const message =
    `Fitur ${action} sudah dibuat di frontend, tetapi endpoint backend belum tersedia atau belum dihubungkan. ` +
    'Silakan sambungkan API dari backend teman Anda.'
  showToast(message, 'error')
}

function goToEmployeeDetail(employee) {
  if (!employee?.id) return
  router.push(`/dashboard/karyawan/${employee.id}`)
}

function openAddModal() {
  form.value = {
    name: '',
    email: '',
    password: '',
    no_hp: '',
    role: 'karyawan',
    home_location_id: '',
    division_id: '',
    shift_id: '',
  }
  showPassword.value = false
  showModal.value = true
  fetchLocations()
}

function closeModal(force = false) {
  if (saving.value && !force) return
  showModal.value = false
}

async function submitNewEmployee() {
  const name = String(form.value.name || '').trim()
  const email = String(form.value.email || '').trim()
  const password = String(form.value.password || '')
  const no_hp = String(form.value.no_hp || '').trim()

  const nameRegex = /^[a-zA-Z\s'.-]{2,100}$/
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
  const passRegex = /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).{8,64}$/
  const phoneRegex = /^(?:\+62|62|0)8[1-9][0-9]{6,11}$/

  if (!name || !nameRegex.test(name)) {
    showToast('Nama minimal 2 karakter dan hanya boleh berisi huruf.', 'error')
    return
  }

  if (!email || !emailRegex.test(email) || email.length > 254) {
    showToast('Format email tidak valid (contoh: user@domain.com).', 'error')
    return
  }

  if (!passRegex.test(password)) {
    showToast('Password minimal 8 karakter, kombinasi huruf besar, kecil, dan angka.', 'error')
    return
  }

  if (no_hp && !phoneRegex.test(no_hp)) {
    showToast('Nomor HP tidak valid. Gunakan format Indonesia (contoh: 08123456789).', 'error')
    return
  }

  saving.value = true
  try {
    const payload = {
      name,
      email,
      password,
      no_hp: no_hp || null,
      role: form.value.role,
      ...(form.value.home_location_id ? { home_location_id: Number(form.value.home_location_id) } : {}),
      ...(form.value.division_id ? { division_id: Number(form.value.division_id) } : {}),
      ...(form.value.shift_id ? { shift_id: Number(form.value.shift_id) } : {}),
    }

    await api.post('/users', payload)
    closeModal(true)
    await fetchEmployees(currentPage.value)
    showToast('Karyawan berhasil ditambahkan.')
  } catch (err) {
    console.error('Gagal menyimpan karyawan:', err)
    const status = err.response?.status
    if (status === 404 || status === 405 || String(err.message).includes('Network Error')) {
      handleMissingBackendFeature('menyimpan')
    } else {
      const errors = err.response?.data?.errors || {}
      const detail = Object.values(errors).flat().join(' ')
      showToast(detail || err.response?.data?.message || 'Gagal menyimpan data karyawan.', 'error')
    }
  } finally {
    saving.value = false
  }
}

async function fetchLocations() {
  try {
    const res = await api.get('/locations')
    const list = res.data || []
    locations.value = list
    companies.value = list
  } catch (err) {
    console.error('Gagal mengambil lokasi:', err)
  }
}

async function fetchShiftSettings() {
  try {
    const [divisionResponse, shiftResponse] = await Promise.all([
      api.get('/divisions'),
      api.get('/shifts'),
    ])
    divisions.value = divisionResponse.data || []
    shifts.value = shiftResponse.data || []
  } catch (err) {
    console.error('Gagal mengambil pengaturan shift:', err)
  }
}

onMounted(() => {
  fetchEmployees()
  fetchLocations()
  fetchShiftSettings()
})

onBeforeUnmount(() => {
  if (toastTimer) clearTimeout(toastTimer)
})
</script>

<template>
  <div class="karyawan">
    <Teleport to="body">
      <div v-if="toast.show" class="toast" :class="toast.type">
        <Icon
          :icon="toast.type === 'success' ? 'material-symbols:check-circle-rounded' : 'material-symbols:error-rounded'"
          width="18"
          height="18"
        />
        <span>{{ toast.message }}</span>
      </div>
    </Teleport>

    <section class="panel table-panel">
      <!-- Filter Bar & Navigation -->
      <div class="filter-bar">
        <div class="breadcrumb-wrap">
          <!-- Tombol Back Bergaya Sama Seperti DetailAbsen -->
          <button v-if="selectedCompany || selectedBranch" type="button" class="back-btn" @click="selectedBranch ? goBackToCompany() : goBackToCompanies()" title="Kembali">
            <Icon icon="material-symbols:arrow-back-rounded" width="22" height="22" />
          </button>
          <div v-if="!selectedCompany" class="table-heading">
            <h2>Pilih Kantor</h2>
            <p>Pilih kantor terlebih dahulu untuk melihat data karyawan.</p>
          </div>
          <div v-else class="selected-office-heading">
            <span>Kantor terpilih</span>
            <h2>{{ selectedBranch?.name || selectedCompany.name }}</h2>
          </div>
        </div>

        <div class="search">
          <Icon icon="material-symbols:search-rounded" width="18" height="18" />
          <input
            type="text"
            v-model="searchQuery"
            @input="onSearchInput"
            placeholder="Cari kantor..."
          />
        </div>

        <button class="icon-btn-solid" @click="openAddModal" title="Tambah Karyawan">
          <Icon icon="material-symbols:add-rounded" width="20" height="20" />
        </button>
      </div>

      <!-- TABEL DAFTAR PERUSAHAAN / CABANG -->
      <table v-if="!selectedCompany || (selectedCompany && !selectedBranch && currentCompanyChildren.length)">
        <thead>
          <tr>
            <th>Nama Perusahaan</th>
            <th>Alamat</th>
            <th>Jumlah Karyawan</th>
            <th class="action-column">Aksi</th>
          </tr>
        </thead>
        <tbody>
          <tr v-if="loading && employees.length === 0">
            <td colspan="4" class="empty-cell">Memuat data...</td>
          </tr>
          <tr v-else-if="(!selectedCompany && companyTree.length === 0) || (selectedCompany && currentCompanyChildren.length === 0)">
            <td colspan="4" class="empty-cell">Data tidak ditemukan.</td>
          </tr>
          <!-- Mode Level 1: Daftar Perusahaan Root -->
          <template v-if="!selectedCompany">
            <tr v-for="node in companyTree" :key="node.id">
              <td>
                <!-- Tanpa Kotak Icon -->
                <strong>{{ node.name }}</strong>
              </td>
              <td>{{ node.address || '-' }}</td>
              <td>
                <span class="count-badge">{{ node.count || 0 }} Orang</span>
              </td>
              <td class="action-cell">
                <button type="button" class="detail-link-btn" @click="goToCompany(node)">
                  Lihat Karyawan
                </button>
              </td>
            </tr>
          </template>
          <!-- Mode Level 2: Daftar Cabang / Anak Perusahaan -->
          <template v-else-if="selectedCompany && !selectedBranch && currentCompanyChildren.length">
            <tr v-for="node in currentCompanyChildren" :key="node.id">
              <td>
                <!-- Tanpa Kotak Icon -->
                <strong>{{ node.name }}</strong>
              </td>
              <td>{{ node.address || '-' }}</td>
              <td>
                <span class="count-badge">{{ node.count || 0 }} Orang</span>
              </td>
              <td class="action-cell">
                <button type="button" class="detail-link-btn" @click="goToBranch(node)">
                  Lihat Karyawan
                </button>
              </td>
            </tr>
          </template>
        </tbody>
      </table>

      <!-- TABEL DAFTAR KARYAWAN -->
      <table v-else>
        <thead>
          <tr>
            <th>ID</th>
            <th>Nama Karyawan</th>
            <th>Email</th>
            <th>Nomor HP</th>
            <th>Divisi</th>
            <th>Jam Kerja / Shift</th>
            <th class="action-column">Aksi</th>
          </tr>
        </thead>
        <tbody>
          <tr v-if="currentEmployees.length === 0">
            <td colspan="7" class="empty-cell">Belum ada karyawan di lokasi ini.</td>
          </tr>
          <tr v-for="emp in currentEmployees" :key="emp.id">
            <td class="emp-id-cell">{{ emp.id }}</td>
            <td>
              <!-- Tanpa Kotak Avatar -->
              <strong>{{ emp.name }}</strong>
            </td>
            <td>{{ emp.email }}</td>
            <td>{{ emp.no_hp || '-' }}</td>
            <td>{{ emp.division }}</td>
            <td>{{ emp.shift }}</td>
            <td class="action-cell">
              <!-- Hanya Tombol "Lihat" saja -->
              <button type="button" class="detail-link-btn" @click="goToEmployeeDetail(emp)">
                Lihat
              </button>
            </td>
          </tr>
        </tbody>
      </table>

      <!-- Table Footer -->
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

          <span class="total-records-info">{{ totalEmployees }} karyawan</span>
        </div>
      </div>
    </section>

    <!-- Modal Form Tambah Karyawan Baru -->
    <Teleport to="body">
      <div v-if="showModal" class="modal-overlay" @click.self="closeModal">
        <div class="modal">
          <div class="modal-head">
            <div class="modal-title">
              <Icon icon="material-symbols:person-add" width="22" height="22" />
              <h3>Tambah Karyawan Baru</h3>
            </div>
          </div>

          <div class="modal-body">
            <div class="field">
              <label class="required">Nama</label>
              <input type="text" v-model="form.name" maxlength="100" placeholder="Nama lengkap" />
            </div>
            <div class="field">
              <label class="required">Email</label>
              <input type="email" v-model="form.email" maxlength="254" placeholder="Email" />
            </div>
            <div class="field">
              <label class="required">Password</label>
              <div class="input-eye-wrap">
                <input
                  :type="showPassword ? 'text' : 'password'"
                  v-model="form.password"
                  maxlength="64"
                  placeholder="Password"
                />
                <button
                  type="button"
                  class="eye-toggle"
                  @click="showPassword = !showPassword"
                  tabindex="-1"
                >
                  <Icon :icon="showPassword ? 'material-symbols:visibility-off-rounded' : 'material-symbols:visibility-rounded'" width="18" height="18" />
                </button>
              </div>
            </div>
            <div class="field">
              <label class="required">Nomor HP</label>
              <input
                type="text"
                inputmode="numeric"
                v-model="form.no_hp"
                maxlength="15"
                @input="form.no_hp = form.no_hp.replace(/\D/g, '')"
                placeholder="Contoh: 081234567890"
              />
            </div>
            <div class="field-row">
              <div class="field">
                <label class="required">Peran</label>
                <select v-model="form.role">
                  <option value="karyawan">Karyawan</option>
                  <option value="admin">Admin</option>
                </select>
              </div>
              <div class="field">
                <label class="required">Lokasi Cabang</label>
                <select v-model="form.home_location_id">
                  <option value="" disabled>Pilih lokasi</option>
                  <option v-for="loc in locations" :key="loc.id" :value="loc.id">{{ loc.name }}</option>
                </select>
              </div>
            </div>
            <div class="field-row">
              <div class="field">
                <label>Divisi</label>
                <select v-model="form.division_id">
                  <option value="">Tanpa divisi</option>
                  <option v-for="division in divisions" :key="division.id" :value="division.id">
                    {{ division.name }}
                  </option>
                </select>
              </div>
              <div class="field">
                <label>Jam Kerja / Shift</label>
                <select v-model="form.shift_id">
                  <option value="">Gunakan jam lokasi</option>
                  <option
                    v-for="shift in shifts.filter((item) => !form.division_id || item.division_id === Number(form.division_id))"
                    :key="shift.id"
                    :value="shift.id"
                  >
                    {{ shift.name }} ({{ shift.work_start_time.slice(0, 5) }} - {{ shift.work_end_time.slice(0, 5) }})
                  </option>
                </select>
              </div>
            </div>
          </div>

          <div class="modal-footer">
            <button class="btn-cancel" type="button" @click="closeModal" :disabled="saving">Batal</button>
            <button class="btn-save" type="button" @click="submitNewEmployee" :disabled="saving">
              <Icon icon="material-symbols:save-outline" width="18" height="18" />
              {{ saving ? 'Menyimpan...' : 'Simpan Karyawan' }}
            </button>
          </div>
        </div>
      </div>
    </Teleport>
  </div>
</template>

<style scoped>
.karyawan {
  --blue-900: #2f3b69;
  --ink: #1c1c19;
  --ink-soft: #667085;
  --line: #d9dde5;
  --bg: #f7f8fa;
  --card: #ffffff;
  font-family: 'Plus Jakarta Sans', sans-serif;
}
.karyawan * {
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

/* Filter Bar Header */
.filter-bar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  padding: 18px 24px;
  background: var(--card);
  border-bottom: 1px solid var(--line);
  flex-wrap: wrap;
  border-radius: 15px 15px 0 0;
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
.breadcrumb {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 13px;
  color: var(--ink-soft);
}
.breadcrumb-root {
  cursor: pointer;
  color: var(--blue-900);
  font-weight: 700;
}
.breadcrumb-current {
  color: var(--blue-900);
  font-weight: 700;
}
.breadcrumb-separator {
  color: var(--ink-soft);
}

/* Tombol Back Persis DetailAbsenView */
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

.search {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 10px 16px;
  width: 280px;
  border: 1px solid var(--line);
  border-radius: 10px;
  background: var(--bg);
  margin-left: auto;
}
.search svg,
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
  font-family: inherit;
  background: transparent;
}

.icon-btn-solid {
  width: 40px;
  height: 40px;
  border-radius: 10px;
  background: var(--blue-900);
  border: none;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  flex-shrink: 0;
  transition: background 0.15s ease;
}
.icon-btn-solid:hover {
  background: #273258;
}
.icon-btn-solid svg,
.icon-btn-solid .iconify {
  color: #fff;
}

/* Styling Tabel */
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
  padding: 16px 24px;
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
  padding: 32px;
}

.count-badge {
  display: inline-flex;
  font-size: 12px;
  color: var(--ink-soft);
  background: #e9edf7;
  border-radius: 999px;
  padding: 4px 10px;
  font-weight: 700;
}

.emp-id-cell {
  color: var(--ink-soft);
}

.action-column {
  width: 170px;
  text-align: center;
}
.action-cell {
  text-align: center;
}

/* Tombol Detail/Lihat */
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

/* Footer Pagination */
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
  font-family: 'Plus Jakarta Sans', sans-serif;
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
.required {
  color: #d92d20;
  margin-left: 2px;
}
label.required::after {
  content: ' *';
  color: #d92d20;
  font-weight: bold;
}
.modal-overlay {
  position: fixed;
  inset: 0;
  background: rgba(28, 32, 55, 0.55);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
  padding: 24px;
}
.modal {
  width: 100%;
  max-width: 620px;
  max-height: 90vh;
  display: flex;
  flex-direction: column;
  overflow: hidden;
  background: #fff;
  border: 1px solid var(--line);
  border-radius: 20px;
  box-shadow: 0 20px 50px rgba(0, 0, 0, 0.25);
}
.modal-head {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 18px 24px;
  background: var(--bg);
  border-bottom: 1.5px solid #cbd5e1;
  border-radius: 20px 20px 0 0;
  flex-shrink: 0;
}
.modal-title {
  display: flex;
  align-items: center;
  gap: 10px;
}
.modal-title .iconify {
  color: var(--blue-900);
}
.modal-title h3 {
  margin: 0;
  font-size: 18px;
  font-weight: 700;
  color: var(--blue-900);
}
.modal-body {
  padding: 18px 24px 16px;
  display: flex;
  flex-direction: column;
  gap: 14px;
  overflow-y: auto;
  flex: 1;
}
.field {
  display: flex;
  flex-direction: column;
  gap: 8px;
  flex: 1;
}
.field label {
  font-size: 13.5px;
  font-weight: 600;
  color: var(--ink-soft);
}
.field input,
.field select {
  border: 1.5px solid #cbd5e1;
  border-radius: 10px;
  padding: 12px 14px;
  font-size: 14px;
  font-family: inherit;
  color: var(--ink);
  outline: none;
  background: #fff;
}
.field-row {
  display: flex;
  gap: 16px;
}
.modal-footer {
  display: flex;
  align-items: center;
  justify-content: flex-end;
  gap: 12px;
  padding: 16px 24px 18px;
  border-top: 1.5px solid #cbd5e1;
  background: var(--bg);
  border-radius: 0 0 20px 20px;
  flex-shrink: 0;
}
.btn-cancel {
  padding: 12px 20px;
  border-radius: 10px;
  border: 1.5px solid #cbd5e1;
  background: #fff;
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
  background: #2C3964;
  color: #fff;
  font-size: 14px;
  font-weight: 700;
  cursor: pointer;
}
.input-eye-wrap {
  position: relative;
  display: flex;
  align-items: center;
}
.input-eye-wrap input {
  width: 100%;
  padding-right: 42px;
}
.eye-toggle {
  position: absolute;
  right: 10px;
  top: 50%;
  transform: translateY(-50%);
  border: none;
  background: none;
  cursor: pointer;
  padding: 4px;
  color: var(--ink-soft);
}

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
}
.toast.success { background: #1f9d67; }
.toast.error { background: #d92d20; }

@media (max-width: 700px) {
  .filter-bar {
    padding: 14px;
  }
  .search {
    width: 100%;
    margin-left: 0;
  }
  .table-panel {
    overflow-x: auto;
  }
  table {
    min-width: 700px;
  }
}
</style>