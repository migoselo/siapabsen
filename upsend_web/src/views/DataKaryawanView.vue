<script setup>
import { ref, computed, onMounted, watch, onBeforeUnmount } from 'vue'
import { Icon } from '@iconify/vue'
import api from '../api'

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
  window.alert(message)
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

async function submitNewEmployee() {
  const name = String(form.value.name || '').trim()
  const email = String(form.value.email || '').trim()
  const password = String(form.value.password || '')

  if (!name || !email || (!editingEmployeeId.value && password.length < 6)) {
    window.alert(editingEmployeeId.value
      ? 'Nama dan email wajib diisi.'
      : 'Nama, email, dan password minimal 6 karakter wajib diisi.')
    return
  }

  saving.value = true
  try {
    const payload = {
      name,
      email,
      ...(editingEmployeeId.value || password ? { password } : {}),
      no_hp: form.value.no_hp ? String(form.value.no_hp).trim() : null,
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
      window.alert(detail || err.response?.data?.message || `Gagal ${actionText} data karyawan.`)
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
      window.alert('Gagal menghapus karyawan. Silakan coba lagi.')
    }
  } finally {
    deletingId.value = null
  }
}

async function fetchLocations() {
  try {
    const res = await api.get('/locations')
    locations.value = res.data || []
  } catch (err) {
    console.error('Gagal mengambil lokasi:', err)
  }
}

onMounted(() => {
  fetchEmployees()
})

onBeforeUnmount(() => {
  if (toastTimer) clearTimeout(toastTimer)
})
</script>

<template>
  <div class="karyawan">
    <div v-if="toast.show" class="toast" :class="toast.type">
      <Icon
        :icon="toast.type === 'success' ? 'material-symbols:check-circle-rounded' : 'material-symbols:error-rounded'"
        width="18"
        height="18"
      />
      <span>{{ toast.message }}</span>
    </div>

    <section class="panel table-panel">
      <div class="table-head">
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

      <table>
        <thead>
          <tr>
            <th>ID</th>
            <th>Nama Karyawan</th>
            <th>Email</th>
            <th>Nomor HP</th>
            <th>Lokasi Cabang</th>
            <th class="action-column">Aksi</th>
          </tr>
        </thead>
        <tbody>
          <tr v-if="loading && employees.length === 0">
            <td colspan="6" class="empty-cell">Memuat data...</td>
          </tr>
          <tr v-else-if="filteredEmployees.length === 0">
            <td colspan="6" class="empty-cell">Tidak ada karyawan ditemukan.</td>
          </tr>
          <tr v-for="emp in filteredEmployees" :key="emp.id">
            <td class="emp-id-cell">{{ emp.id }}</td>
            <td>
              <div class="emp">
                <div class="emp-avatar">{{ initials(emp.name) }}</div>
                <div class="emp-name">{{ emp.name }}</div>
              </div>
            </td>
            <td>{{ emp.email }}</td>
            <td>{{ emp.no_hp || '-' }}</td>
            <td>{{ emp.homeLocation?.name || emp.home_location?.name || emp.location?.name || emp.home_location || '-' }}</td>
            <td class="action-cell">
              <div class="action-actions">
                <button type="button" class="action-btn edit-btn" @click="openEditModal(emp)">
                  <Icon icon="material-symbols:edit-outline-rounded" width="16" height="16" />
                  Edit
                </button>
                <button
                  type="button"
                  class="action-btn delete-btn"
                  @click="deleteEmployee(emp)"
                  :disabled="deletingId === emp.id"
                >
                  <Icon icon="material-symbols:delete-outline-rounded" width="16" height="16" />
                  {{ deletingId === emp.id ? 'Menghapus...' : 'Delete' }}
                </button>
              </div>
            </td>
          </tr>
        </tbody>
      </table>

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
              <label>Nama</label>
              <input type="text" v-model="form.name" placeholder="Nama lengkap" />
            </div>
            <div class="field">
              <label>Email</label>
              <input type="email" v-model="form.email" placeholder="Email" />
            </div>
            <div class="field">
              <label>Password</label>
              <div class="input-eye-wrap">
                <input
                  :type="showPassword ? 'text' : 'password'"
                  v-model="form.password"
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
              <label>Nomor HP</label>
              <input
                type="text"
                inputmode="numeric"
                v-model="form.no_hp"
                @input="form.no_hp = form.no_hp.replace(/\D/g, '')"
                placeholder="Nomor HP"
              />
            </div>
            <div class="field-row">
              <div class="field">
                <label>Peran</label>
                <select v-model="form.role">
                  <option value="karyawan">Karyawan</option>
                  <option value="admin">Admin</option>
                </select>
              </div>
              <div class="field">
                <label>Lokasi Cabang</label>
                <select v-model="form.home_location_id">
                  <option value="" disabled>Pilih lokasi</option>
                  <option v-for="loc in locations" :key="loc.id" :value="loc.id">{{ loc.name }}</option>
                </select>
              </div>
            </div>
          </div>

          <div class="modal-footer">
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
  padding: 22px 0 0;
}
.table-head {
  display: flex;
  justify-content: flex-end;
  align-items: center;
  gap: 10px;
  padding: 0 24px 22px;
  flex-wrap: wrap;
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
  font-family: inherit;
}
.btn-cancel:hover {
  background: #eef0f7;
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
  font-family:inherit;
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

/* 🔽 TAMBAHAN: wrapper input password + tombol mata */
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

.toast {
  position: fixed;
  right: 24px;
  bottom: 24px;
  z-index: 1000;
  display: inline-flex;
  align-items: center;
  gap: 8px;
  padding: 12px 16px;
  border-radius: 12px;
  font-size: 14px;
  font-weight: 600;
  color: white;
  box-shadow: 0 10px 30px rgba(17, 24, 39, 0.15);
  animation: toastIn 0.2s ease;
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
    transform: translateY(10px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

@media (max-width: 700px) {
  .table-head {
    justify-content: stretch;
  }
  .search {
    min-width: 0;
    flex: 1;
  }
}
</style>