<script setup>
import { ref, computed, onMounted, watch, onBeforeUnmount } from 'vue'
import { useRouter } from 'vue-router'
import { Icon } from '@iconify/vue'
import api from '../api'

const router = useRouter()

/*
  View ini cuma berisi KONTEN halaman (sidebar & topbar sudah ditangani
  MainLayout.vue lewat router-view) — ikut pola yang sama dengan
  DashboardView.vue / LokasiKerjaView.vue.
*/

const employees = ref([])
const loading = ref(false)
const searchQuery = ref('')
const currentPage = ref(1)
const lastPage = ref(1)
const totalEmployees = ref(0)
const perPage = ref(20)
const pageInput = ref(1)
const deletingId = ref(null)
const editingEmployeeId = ref(null)
const toast = ref({ show: false, type: 'success', message: '' })
let toastTimer = null

watch(currentPage, (newPage) => {
  pageInput.value = newPage
})

const showModal = ref(false)
const saving = ref(false)
const locations = ref([])
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
})

const showPassword = ref(false)

const filteredEmployees = computed(() => {
  const q = searchQuery.value.trim().toLowerCase()
  if (!q) return employees.value
  return employees.value.filter(
    (e) => e.name.toLowerCase().includes(q) || e.email.toLowerCase().includes(q),
  )
})

const expandedNodes = ref({})

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

const breadcrumb = computed(() => {
  const items = []
  if (selectedCompany.value) items.push(selectedCompany.value.name)
  if (selectedBranch.value) items.push(selectedBranch.value.name)
  return items
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

function findNodeById(nodes, targetId) {
  for (const node of nodes) {
    if (node.id === targetId) return node
    const childMatch = findNodeById(node.children || [], targetId)
    if (childMatch) return childMatch
  }

  return null
}

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

function toggleNode(nodeId) {
  expandedNodes.value[nodeId] = !(expandedNodes.value[nodeId] ?? true)
}

function isNodeOpen(nodeId) {
  return expandedNodes.value[nodeId] ?? true
}

const companyTree = computed(() => {
  const roots = []
  const nodes = new Map()

  const addNode = (path) => {
    let parent = null

    path.forEach((segment, index) => {
      const key = path.slice(0, index + 1).join(' / ')
      if (!nodes.has(key)) {
        const node = {
          id: key,
          name: segment,
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
    if (!name) return
    const path = splitHierarchyLabel(name)
    const node = addNode(path)
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

function initials(name) {
  if (!name) return ''
  return name.split(' ').map((w) => w[0]).slice(0, 2).join('').toUpperCase()
}

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

function onSearchInput() {
  // Local search only filters current page; backend search can be added later.
}

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

  if (toastTimer) {
    clearTimeout(toastTimer)
  }

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
  editingEmployeeId.value = null
  form.value = {
    name: '',
    email: '',
    password: '',
    no_hp: '',
    role: 'karyawan',
    home_location_id: '',
  }
  showPassword.value = false
  showModal.value = true
  fetchLocations()
}

function openEditModal(employee) {
  editingEmployeeId.value = employee?.id ?? null
  form.value = {
    name: employee?.name || '',
    email: employee?.email || '',
    password: '',
    no_hp: employee?.no_hp || '',
    role: employee?.role || 'karyawan',
    home_location_id: employee?.home_location_id ?? employee?.homeLocation?.id ?? employee?.home_location?.id ?? '',
  }
  showPassword.value = false
  showModal.value = true
  fetchLocations()
}

function closeModal(force = false) {
  if (saving.value && !force) return
  showModal.value = false
  editingEmployeeId.value = null
}

// Redirect ke halaman detail/biodata karyawan
function goToDetail() {
  if (editingEmployeeId.value) {
    closeModal(true)
    router.push(`/dashboard/karyawan/${editingEmployeeId.value}`)
  }
}

async function submitNewEmployee() {
  const name = String(form.value.name || '').trim()
  const email = String(form.value.email || '').trim()
  const password = String(form.value.password || '')
  const no_hp = String(form.value.no_hp || '').trim()

  // REGEX & VALIDASI FORM
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

  // Password wajib saat tambah baru, atau opsional saat edit jika diisi
  if (!editingEmployeeId.value || password) {
    if (!passRegex.test(password)) {
      showToast('Password minimal 8 karakter, kombinasi huruf besar, kecil, dan angka.', 'error')
      return
    }
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
      ...(editingEmployeeId.value || password ? { password } : {}),
      no_hp: no_hp || null,
      role: form.value.role,
      ...(form.value.home_location_id ? { home_location_id: Number(form.value.home_location_id) } : {}),
    }

    const isEditing = !!editingEmployeeId.value
    if (isEditing) {
      try {
        await api.put(`/users/${editingEmployeeId.value}`, payload)
      } catch (err) {
        const status = err.response?.status
        if (status === 404 || status === 405) {
          await api.patch(`/users/${editingEmployeeId.value}`, payload)
        } else {
          throw err
        }
      }
    } else {
      await api.post('/users', payload)
    }

    closeModal(true)
    await fetchEmployees(currentPage.value)
    showToast(isEditing ? 'Data karyawan berhasil diperbarui.' : 'Karyawan berhasil ditambahkan.')
  } catch (err) {
    console.error('Gagal menyimpan karyawan:', err)
    const status = err.response?.status
    const actionText = editingEmployeeId.value ? 'mengubah' : 'menyimpan'

    if (status === 404 || status === 405 || String(err.message).includes('Network Error')) {
      handleMissingBackendFeature(actionText)
    } else {
      const errors = err.response?.data?.errors || {}
      const detail = Object.values(errors).flat().join(' ')
      showToast(detail || err.response?.data?.message || `Gagal ${actionText} data karyawan.`, 'error')
    }
  } finally {
    saving.value = false
  }
}

async function deleteEmployee(employee) {
  if (!employee?.id) return

  const confirmed = window.confirm(`Hapus karyawan "${employee.name}"?`)
  if (!confirmed) return

  deletingId.value = employee.id
  try {
    await api.delete(`/users/${employee.id}`)
    await fetchEmployees(currentPage.value)
    showToast('Karyawan berhasil dihapus.')
  } catch (err) {
    console.error('Gagal menghapus karyawan:', err)
    const status = err.response?.status
    if (status === 404 || status === 405 || String(err.message).includes('Network Error')) {
      handleMissingBackendFeature('menghapus')
    } else {
      showToast('Gagal menghapus karyawan. Silakan coba lagi.', 'error')
    }
  } finally {
    deletingId.value = null
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

onMounted(() => {
  fetchEmployees()
  fetchLocations()
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
      <div class="table-head">
        <div class="page-heading">
          <span class="page-eyebrow">SUPER ADMIN</span>
          <h1>{{ currentLevelLabel }}</h1>
          <p v-if="!selectedCompany">Pilih perusahaan untuk melihat struktur dan data di dalamnya.</p>
          <p v-else-if="!selectedBranch && currentCompanyChildren.length">Pilih cabang atau anak perusahaan untuk melanjutkan.</p>
          <p v-else>Kelola dan lihat detail karyawan di lokasi ini.</p>
        </div>

        <div class="search">
          <Icon icon="material-symbols:search-rounded" width="18" height="18" />
          <input
            type="text"
            v-model="searchQuery"
            @input="onSearchInput"
            placeholder="Cari nama karyawan ..."
          />
        </div>
        <button class="icon-btn-solid" @click="openAddModal">
          <Icon icon="material-symbols:add-rounded" width="20" height="20" />
        </button>
      </div>

      <div v-if="loading && employees.length === 0" class="empty-cell">Memuat data...</div>
      <div v-else-if="companyTree.length === 0" class="empty-cell">Tidak ada perusahaan ditemukan.</div>

      <div v-else class="company-list">
        <div class="drilldown-header">
          <div class="breadcrumb-wrap">
            <button v-if="selectedCompany || selectedBranch" type="button" class="breadcrumb-back" @click="selectedBranch ? goBackToCompany() : goBackToCompanies()">
              <Icon icon="material-symbols:arrow-back-rounded" width="16" height="16" />
              Kembali
            </button>

            <div class="breadcrumb">
              <span class="breadcrumb-root" @click="goBackToCompanies()">Perusahaan</span>
              <template v-if="selectedCompany">
                <span class="breadcrumb-separator">/</span>
                <span class="breadcrumb-current">{{ selectedCompany.name }}</span>
              </template>
              <template v-if="selectedBranch">
                <span class="breadcrumb-separator">/</span>
                <span class="breadcrumb-current">{{ selectedBranch.name }}</span>
              </template>
            </div>
          </div>

          <h3 class="drilldown-title">{{ currentLevelLabel }}</h3>
        </div>

        <div v-if="!selectedCompany" class="company-list-stack">
          <div v-for="node in companyTree" :key="node.id" class="company-card">
            <button type="button" class="company-header" @click="goToCompany(node)">
              <div class="company-header-main">
                <div class="company-badge">
                  <Icon icon="material-symbols:business-rounded" width="18" height="18" />
                </div>
                <span class="company-name">{{ node.name }}</span>
              </div>

              <span class="company-meta">
                <span class="company-count">{{ node.count || 0 }} orang</span>
                <Icon icon="material-symbols:chevron-right-rounded" width="18" height="18" />
              </span>
            </button>
          </div>
        </div>

        <div v-else-if="selectedCompany && !selectedBranch && currentCompanyChildren.length" class="company-list-stack">
          <div v-for="node in currentCompanyChildren" :key="node.id" class="company-card">
            <button type="button" class="company-header" @click="goToBranch(node)">
              <div class="company-header-main">
                <div class="company-badge secondary">
                  <Icon icon="material-symbols:account-tree-rounded" width="18" height="18" />
                </div>
                <span class="company-name">{{ node.name }}</span>
              </div>

              <span class="company-meta">
                <span class="company-count">{{ node.count || 0 }} orang</span>
                <Icon icon="material-symbols:chevron-right-rounded" width="18" height="18" />
              </span>
            </button>
          </div>

          <div v-if="!currentCompanyChildren.length && selectedCompany.employees.length" class="employee-list direct-list">
            <div v-for="emp in selectedCompany.employees" :key="emp.id" class="employee-row">
              <div class="emp">
                <div class="emp-avatar">{{ initials(emp.name) }}</div>
                <div class="emp-meta">
                  <div class="emp-name">{{ emp.name }}</div>
                  <div class="emp-email">{{ emp.email }}</div>
                </div>
              </div>

              <button type="button" class="action-btn detail-btn" @click="goToEmployeeDetail(emp)">
                <Icon icon="material-symbols:visibility-rounded" width="16" height="16" />
                Detail
              </button>
            </div>
          </div>
        </div>

        <div v-else-if="selectedCompany && selectedBranch" class="employee-list direct-list">
          <div v-if="currentEmployees.length">
            <div v-for="emp in currentEmployees" :key="emp.id" class="employee-row">
              <div class="emp">
                <div class="emp-avatar">{{ initials(emp.name) }}</div>
                <div class="emp-meta">
                  <div class="emp-name">{{ emp.name }}</div>
                  <div class="emp-email">{{ emp.email }}</div>
                </div>
              </div>

              <button type="button" class="action-btn detail-btn" @click="goToEmployeeDetail(emp)">
                <Icon icon="material-symbols:visibility-rounded" width="16" height="16" />
                Detail
              </button>
            </div>
          </div>

          <div v-else class="empty-mini">Belum ada karyawan di cabang ini.</div>
        </div>

        <div v-else class="employee-list direct-list">
          <div v-if="selectedCompany && selectedCompany.employees.length">
            <div v-for="emp in selectedCompany.employees" :key="emp.id" class="employee-row">
              <div class="emp">
                <div class="emp-avatar">{{ initials(emp.name) }}</div>
                <div class="emp-meta">
                  <div class="emp-name">{{ emp.name }}</div>
                  <div class="emp-email">{{ emp.email }}</div>
                </div>
              </div>

              <button type="button" class="action-btn detail-btn" @click="goToEmployeeDetail(emp)">
                <Icon icon="material-symbols:visibility-rounded" width="16" height="16" />
                Detail
              </button>
            </div>
          </div>

          <div v-else class="empty-mini">Belum ada karyawan di perusahaan ini.</div>
        </div>
      </div>

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

    <Teleport to="body">
      <div v-if="showModal" class="modal-overlay" @click.self="closeModal">
        <div class="modal">
          <div class="modal-head">
            <div class="modal-title">
              <Icon :icon="editingEmployeeId ? 'material-symbols:edit-rounded' : 'material-symbols:person-add'" width="22" height="22" />
              <h3>{{ editingEmployeeId ? 'Edit Karyawan' : 'Tambah Karyawan Baru' }}</h3>
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
              <label class="required">Password {{ editingEmployeeId ? '(Kosongkan jika tidak diubah)' : '' }}</label>
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
          </div>

          <div class="modal-footer">
            <button
              v-if="editingEmployeeId"
              class="btn-detail"
              type="button"
              @click="goToDetail"
              :disabled="saving"
            >
              <Icon icon="material-symbols:account-box-outline-rounded" width="18" height="18" />
              Lihat Detail Biodata
            </button>
            <button class="btn-cancel" type="button" @click="closeModal" :disabled="saving">Batal</button>
            <button class="btn-save" type="button" @click="submitNewEmployee" :disabled="saving">
              <Icon icon="material-symbols:save-outline" width="18" height="18" />
              {{ saving ? (editingEmployeeId ? 'Menyimpan perubahan...' : 'Menyimpan...') : (editingEmployeeId ? 'Simpan Perubahan' : 'Simpan Karyawan') }}
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
.required {
  color: #d92d20;
  margin-left: 2px;
}

label.required::after {
  content: ' *';
  color: #d92d20;
  font-weight: bold;
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
  padding: 0 0 0;
}
.table-head {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 10px;
  padding: 24px;
  border-bottom: 1px solid var(--line);
  flex-wrap: wrap;
}
.page-heading {
  min-width: 220px;
  flex: 1;
}
.page-eyebrow {
  display: block;
  margin-bottom: 5px;
  color: #8b95aa;
  font-size: 10px;
  font-weight: 800;
  letter-spacing: 0.14em;
}
.page-heading h1 {
  margin: 0;
  color: var(--blue-900);
  font-size: 22px;
  line-height: 1.25;
  font-weight: 800;
}
.page-heading p {
  margin: 6px 0 0;
  color: var(--ink-soft);
  font-size: 12px;
  line-height: 1.5;
}
.action-column {
  width: 170px;
  text-align: center;
}
.action-cell {
  text-align: center;
}
.action-actions {
  display: flex;
  justify-content: center;
  align-items: center;
  gap: 8px;
  flex-wrap: nowrap;
  white-space: nowrap;
}
.action-btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 6px;
  border: none;
  border-radius: 8px;
  padding: 8px 10px;
  font-size: 0.8rem;
  font-weight: 600;
  cursor: pointer;
  transition: 0.2s ease;
  white-space: nowrap;
}
.detail-btn {
  background: #e8f5ec;
  color: #1f7a42;
}
.detail-btn:hover {
  background: #d9f0e1;
}
.edit-btn {
  background: #edf4ff;
  color: #1d4ed8;
}
.edit-btn:hover {
  background: #dfeeff;
}
.delete-btn {
  background: #ffe9eb;
  color: #c92d40;
}
.delete-btn:hover:not(:disabled) {
  background: #ffd9de;
}
.delete-btn:disabled {
  cursor: wait;
  opacity: 0.7;
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
.search svg,
.search .iconify {
  width: 18px;
  height: 18px;
  color: var(--ink-soft);
  flex-shrink: 0;
}
.search input {
  border: none;
  background: none;
  outline: none;
  font-size: 14px;
  width: 100%;
  font-family: inherit;
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
  padding: 32px;
}
.emp-id-cell {
  color: var(--ink-soft);
}
.emp {
  display: flex;
  align-items: center;
  gap: 12px;
}
.emp-avatar {
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
.emp-name {
  font-weight: 700;
  font-size: 15px;
}

.company-list {
  display: flex;
  flex-direction: column;
  gap: 12px;
  padding: 20px 24px 24px;
}

.company-list-stack {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.drilldown-header {
  display: flex;
  flex-direction: column;
  gap: 10px;
  padding: 0 0 4px;
}

.breadcrumb-wrap {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  flex-wrap: wrap;
}

.breadcrumb {
  display: flex;
  align-items: center;
  gap: 8px;
  flex-wrap: wrap;
  font-size: 12px;
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

.breadcrumb-back {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  border: 1px solid var(--line);
  background: #fff;
  color: var(--ink);
  border-radius: 8px;
  padding: 7px 10px;
  cursor: pointer;
  font-weight: 600;
}

.drilldown-title {
  margin: 0;
  color: var(--blue-900);
  font-size: 18px;
  font-weight: 800;
}

.company-card {
  border: 1px solid var(--line);
  border-radius: 14px;
  background: #fff;
  overflow: hidden;
  box-shadow: 0 2px 7px rgba(33, 42, 67, 0.035);
  transition: border-color 0.18s ease, box-shadow 0.18s ease, transform 0.18s ease;
}

.company-card:hover {
  border-color: #b8c2d8;
  box-shadow: 0 8px 18px rgba(33, 42, 67, 0.08);
  transform: translateY(-1px);
}

.company-meta {
  display: inline-flex;
  align-items: center;
  gap: 8px;
}

.company-badge {
  width: 32px;
  height: 32px;
  border-radius: 10px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: #eaf0ff;
  color: var(--blue-900);
}

.company-badge.secondary {
  background: #edf7f1;
  color: #1f7a42;
}

.company-header {
  width: 100%;
  border: none;
  background: transparent;
  min-height: 76px;
  padding: 16px 18px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  cursor: pointer;
  text-align: left;
  color: var(--blue-900);
  font-family: 'Plus Jakarta Sans', sans-serif;
  font-weight: 700;
}

.company-header:hover {
  background: rgba(47, 59, 105, 0.02);
}

.company-header-main {
  display: flex;
  align-items: center;
  gap: 12px;
  min-width: 0;
}

.company-name {
  font-size: 16px;
  line-height: 1.35;
  overflow-wrap: anywhere;
}

.empty-mini {
  padding: 16px 18px;
  color: var(--ink-soft);
  background: #fff;
  border: 1px solid var(--line);
  border-radius: 12px;
}

.company-count {
  font-size: 12px;
  color: var(--ink-soft);
  background: #e9edf7;
  border-radius: 999px;
  padding: 5px 10px;
  font-weight: 700;
}

.company-employee-list {
  border-top: 1px solid var(--line);
  background: #ffffff;
}

.employee-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
  padding: 16px 18px;
  background: #fff;
  border-bottom: 1px solid #edf0f3;
}

.employee-row:last-child {
  border-bottom: none;
}

.direct-list {
  overflow: hidden;
  border: 1px solid var(--line);
  border-radius: 14px;
  background: #fff;
  box-shadow: 0 2px 7px rgba(33, 42, 67, 0.035);
}

.emp-meta {
  display: flex;
  flex-direction: column;
  gap: 3px;
}

.emp-email {
  font-size: 12px;
  color: var(--ink-soft);
}

.table-footer {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 14px 24px;
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
  appearance: textfield;
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
  font-family: 'Plus Jakarta Sans', sans-serif !important;
}

.per-page-select select:focus {
  border-color: var(--blue-900);
}

.per-page-select select option {
  font-family: 'Plus Jakarta Sans', sans-serif !important;
  font-size: 13px;
  font-weight: 600;
  color: var(--ink);
  background: var(--card);
}

.total-records-info {
  font-size: 13px;
  font-weight: 600;
  color: var(--ink-soft);
  white-space: nowrap;
}

/* ================= MODAL ================= */
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
  font-family: 'Plus Jakarta Sans', sans-serif;
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
  scrollbar-width: thin;
  scrollbar-color: rgba(0, 0, 0, 0.12) transparent;
}
.modal-body::-webkit-scrollbar {
  width: 6px;
}
.modal-body::-webkit-scrollbar-track {
  background: transparent;
}
.modal-body::-webkit-scrollbar-thumb {
  background: rgba(0, 0, 0, 0.12);
  border-radius: 6px;
}
.modal-body::-webkit-scrollbar-thumb:hover {
  background: rgba(0, 0, 0, 0.18);
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

.field input[type='password']::-ms-reveal,
.field input[type='password']::-ms-clear {
  display: none;
}

.field input:focus,
.field select:focus {
  border-color: var(--blue-900);
}
.field-row {
  display: flex;
  gap: 16px;
}
.modal-footer {
  display: flex;
  align-items: center;
  justify-content: flex-start;
  gap: 8px;
  padding: 16px 24px 18px;
  border-top: 1.5px solid #cbd5e1;
  background: var(--bg);
  border-radius: 0 0 20px 20px;
  flex-shrink: 0;
}
.modal-footer .btn-detail {
  order: 1;
}
.modal-footer .btn-cancel {
  order: 2;
  margin-left: auto;
}
.modal-footer .btn-save {
  order: 3;
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
  font-family: inherit;
}
.btn-cancel:hover {
  background: #eef0f7;
}

.btn-detail {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  padding: 12px 18px;
  border-radius: 10px;
  border: 1.5px solid #edf4ff;
  background: #edf4ff;
  color: #1d4ed8;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  font-family: inherit;
  transition: all 0.15s ease;
}
.btn-detail:hover {
  background: #d4e8ff;
  border-color: #d4e8ff;
}
.btn-detail:disabled {
  opacity: 0.6;
  cursor: not-allowed;
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
  font-family: inherit;
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

/* Wrapper input password + tombol mata */
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
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 4px;
  color: var(--ink-soft);
}
.eye-toggle:hover {
  color: var(--blue-900);
}

/* Toast Notifikasi Melayang di Atas Tengah */
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

@media (max-width: 700px) {
  .table-head {
    padding: 18px;
    align-items: stretch;
  }
  .page-heading {
    flex-basis: 100%;
  }
  .page-heading h1 {
    font-size: 19px;
  }
  .table-head {
    justify-content: stretch;
  }
  .search {
    min-width: 0;
    flex: 1;
  }
  .company-list {
    padding: 16px;
  }
  .company-header {
    min-height: 68px;
    padding: 14px;
  }
  .company-name {
    font-size: 14px;
  }
  .company-count {
    padding: 4px 7px;
    font-size: 11px;
  }
  .company-meta > .iconify {
    display: none;
  }
  .breadcrumb-wrap {
    align-items: flex-start;
    flex-direction: column-reverse;
  }
  .drilldown-title {
    font-size: 16px;
  }
  .employee-row {
    align-items: flex-start;
    padding: 14px;
  }
  .employee-row .detail-btn {
    padding: 7px;
    font-size: 0;
  }
  .employee-row .detail-btn .iconify {
    width: 18px;
    height: 18px;
  }
  .table-footer {
    padding: 12px 16px;
  }
  .table-footer-content {
    width: 100%;
    justify-content: space-between;
    gap: 8px;
    flex-wrap: wrap;
  }
  .total-records-info {
    order: 3;
    width: 100%;
    text-align: right;
  }
}
</style>