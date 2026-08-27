<script setup>
import { ref, computed, onMounted } from 'vue'
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

// 🔽 TAMBAHAN: toggle show/hide password
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
    const res = await api.get('/users', { params: { page, per_page: 10 } })
    employees.value = res.data.data || []
    totalEmployees.value = res.data.total || 0
    currentPage.value = res.data.current_page || page
    lastPage.value = res.data.last_page || 1
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

function openAddModal() {
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

function closeModal() {
  if (saving.value) return
  showModal.value = false
}

async function submitNewEmployee() {
  saving.value = true
  try {
    await api.post('/users', {
      name: form.value.name,
      email: form.value.email,
      password: form.value.password,
      no_hp: form.value.no_hp,
      role: form.value.role,
      home_location_id: form.value.home_location_id,
    })
    showModal.value = false
    await fetchEmployees(currentPage.value)
  } catch (err) {
    console.error('Gagal menambahkan karyawan:', err)
    window.alert('Gagal menambahkan karyawan. Silakan cek kembali data yang dimasukkan.')
  } finally {
    saving.value = false
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
</script>

<template>
  <div class="karyawan">
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
          </tr>
        </thead>
        <tbody>
          <tr v-if="loading">
            <td colspan="5" class="empty-cell">Memuat data...</td>
          </tr>
          <tr v-else-if="filteredEmployees.length === 0">
            <td colspan="5" class="empty-cell">Tidak ada karyawan ditemukan.</td>
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
          </tr>
        </tbody>
      </table>

      <div class="table-footer">
        <span>Menampilkan {{ filteredEmployees.length }} dari {{ totalEmployees }} karyawan</span>
        <div class="pager">
          <button :disabled="currentPage === 1" @click="prevPage">
            <Icon icon="material-symbols:chevron-left-rounded" width="18" height="18" />
          </button>
          <div style="display:flex;align-items:center;padding:0 8px;font-weight:600;color:var(--ink-soft);">
            Halaman {{ currentPage }} / {{ lastPage }}
          </div>
          <button :disabled="currentPage === lastPage" @click="nextPage">
            <Icon icon="material-symbols:chevron-right-rounded" width="18" height="18" />
          </button>
        </div>
      </div>
    </section>

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
}
.karyawan * {
  box-sizing: border-box;
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
  justify-content: space-between;
  align-items: center;
  padding: 16px 24px;
  font-size: 13px;
  color: var(--ink-soft);
  border-top: 1px solid var(--line);
  background: var(--bg);
}
.pager {
  display: flex;
  gap: 8px;
}
.pager button {
  width: 34px;
  height: 34px;
  border-radius: 8px;
  border: 1px solid var(--line);
  background: #fff;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
}
.pager button svg,
.pager button .iconify {
  color: var(--ink-soft);
}
.pager button:disabled {
  opacity: 0.4;
  cursor: not-allowed;
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
  overflow-y: auto;
  background: #fff;
  border: 1px solid var(--line);
  border-radius: 18px;
  box-shadow: 0 20px 50px rgba(0, 0, 0, 0.25);
  font-family: 'Inter', system-ui, -apple-system, sans-serif;
}
.modal {
  scrollbar-width: thin;
  scrollbar-color: rgba(0,0,0,0.16) transparent;
}
.modal::-webkit-scrollbar {
  width: 8px;
}
.modal::-webkit-scrollbar-track {
  background: transparent;
}
.modal::-webkit-scrollbar-thumb {
  background: rgba(0,0,0,0.12);
  border-radius: 8px;
}
.modal::-webkit-scrollbar-thumb:hover {
  background: rgba(0,0,0,0.18);
}
.modal-head {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 22px 24px;
  background: var(--bg);
  border-bottom: 1px solid var(--line);
  border-radius: 18px 18px 0 0;
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
  padding: 24px;
  display: flex;
  flex-direction: column;
  gap: 20px;
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
  border: 1px solid var(--line);
  border-radius: 10px;
  padding: 12px 14px;
  font-size: 14px;
  font-family: inherit;
  color: var(--ink);
  outline: none;
  background: #fff;
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
  padding: 18px 24px;
  border-top: 1px solid var(--line);
  background: var(--bg);
  border-radius: 0 0 18px 18px;
}
.btn-cancel {
  padding: 12px 20px;
  border-radius: 10px;
  border: 1px solid var(--line);
  background: #fff;
  color: var(--ink);
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
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
  background: var(--blue-900);
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