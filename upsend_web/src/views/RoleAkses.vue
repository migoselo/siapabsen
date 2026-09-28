<script setup>
import { computed, onMounted, ref } from 'vue'
import { Icon } from '@iconify/vue'
import api from '../api'
import BaseButton from '../components/BaseButton.vue'
import BaseSearch from '../components/BaseSearch.vue'
import BaseTable from '../components/BaseTable.vue'
import BaseToast from '../components/BaseToast.vue'

const authUser = JSON.parse(localStorage.getItem('auth_user') || 'null')
const isSuperAdmin = ['super_admin', 'superadmin'].includes(authUser?.role)
const companies = ref([])
const selectedCompany = ref(null)
const users = ref([])
const locations = ref([])
const companyQuery = ref('')
const userQuery = ref('')
const loadingCompanies = ref(false)
const loadingUsers = ref(false)
const savingRole = ref(false)
const roleChangeUser = ref(null)
const roleChangeTarget = ref('karyawan')
const loadingPermissionOptions = ref(false)
const permissionOptions = ref([])
const selectedPermissions = ref([])
const toast = ref({ show: false, type: 'success', message: '' })
let requestSequence = 0
let toastTimer = null

const companyColumns = [
  { key: 'company', label: 'Perusahaan' },
  { key: 'locations', label: 'Lokasi' },
  { key: 'accounts', label: 'Akun' },
]

const userColumns = [
  { key: 'account', label: 'Akun' },
  { key: 'role', label: 'Peran' },
  { key: 'location', label: 'Lokasi Kerja' },
  { key: 'status', label: 'Status' },
]

const filteredCompanies = computed(() => {
  const query = companyQuery.value.trim().toLowerCase()
  if (!query) return companies.value
  return companies.value.filter((company) => String(company.name || '').toLowerCase().includes(query))
})

const companyUsers = computed(() =>
  users.value
    .filter((user) => ['admin', 'karyawan', 'employee'].includes(user.role))
    .map((user) => {
      const location = locations.value.find(
        (item) => Number(item.id) === Number(user.home_location_id),
      )
      return {
        ...user,
        roleLabel: user.role === 'admin' ? 'Admin Perusahaan' : 'Karyawan',
        locationName: location?.name || user.home_location?.name || 'Belum ditempatkan',
        statusLabel: user.is_active ? 'Aktif' : 'Belum aktivasi',
        statusClass: user.is_active ? 'active' : 'pending',
      }
    }),
)

const filteredUsers = computed(() => {
  const query = userQuery.value.trim().toLowerCase()
  if (!query) return companyUsers.value
  return companyUsers.value.filter((user) =>
    `${user.name || ''} ${user.email || ''} ${user.roleLabel} ${user.locationName}`
      .toLowerCase()
      .includes(query),
  )
})

const adminCount = computed(() => companyUsers.value.filter((user) => user.role === 'admin').length)
const employeeCount = computed(() => companyUsers.value.filter((user) => user.role !== 'admin').length)

function showToast(message, type = 'error') {
  toast.value = { show: true, type, message }
  if (toastTimer) clearTimeout(toastTimer)
  toastTimer = setTimeout(() => {
    toast.value.show = false
  }, 2800)
}

async function fetchCompanies() {
  loadingCompanies.value = true
  try {
    const response = await api.get('/tenants')
    companies.value = Array.isArray(response.data) ? response.data : []
  } catch (error) {
    showToast(error.response?.data?.message || 'Daftar perusahaan gagal dimuat.')
  } finally {
    loadingCompanies.value = false
  }
}

async function selectCompany(company) {
  selectedCompany.value = company
  userQuery.value = ''
  users.value = []
  locations.value = []
  loadingUsers.value = true
  const currentRequest = ++requestSequence

  try {
    const [userResponse, locationResponse] = await Promise.all([
      api.get('/users', { params: { tenant_id: company.id, per_page: 1000 } }),
      api.get('/locations', { params: { tenant_id: company.id } }),
    ])
    if (currentRequest !== requestSequence) return
    users.value = Array.isArray(userResponse.data?.data) ? userResponse.data.data : []
    locations.value = Array.isArray(locationResponse.data) ? locationResponse.data : []
  } catch (error) {
    if (currentRequest === requestSequence) {
      showToast(error.response?.data?.message || 'Daftar akun perusahaan gagal dimuat.')
    }
  } finally {
    if (currentRequest === requestSequence) loadingUsers.value = false
  }
}

function backToCompanies() {
  requestSequence++
  selectedCompany.value = null
  users.value = []
  locations.value = []
  userQuery.value = ''
}

async function openRoleChange(user) {
  if (!isSuperAdmin || !user || !['admin', 'karyawan', 'employee'].includes(user.role)) return
  roleChangeUser.value = user
  roleChangeTarget.value = user.role === 'admin' ? 'karyawan' : 'admin'
  permissionOptions.value = []
  selectedPermissions.value = []

  if (roleChangeTarget.value === 'admin') {
    loadingPermissionOptions.value = true
    try {
      const response = await api.get('/admin-permissions')
      permissionOptions.value = Array.isArray(response.data) ? response.data : []
      selectedPermissions.value = permissionOptions.value
        .filter((permission) => permission.checked)
        .map((permission) => permission.id)
    } catch (error) {
      roleChangeUser.value = null
      showToast(error.response?.data?.message || 'Daftar hak akses gagal dimuat.')
    } finally {
      loadingPermissionOptions.value = false
    }
  }
}

function closeRoleChange() {
  if (savingRole.value) return
  roleChangeUser.value = null
}

async function saveRoleChange() {
  if (!isSuperAdmin || !roleChangeUser.value || !selectedCompany.value) return

  savingRole.value = true
  try {
    const payload = { role: roleChangeTarget.value }
    if (roleChangeTarget.value === 'admin') payload.permissions = selectedPermissions.value
    await api.put(`/users/${roleChangeUser.value.id}`, payload, {
      params: { tenant_id: selectedCompany.value.id },
    })
    const changedName = roleChangeUser.value.name
    roleChangeUser.value = null
    showToast(`${changedName} sekarang ber-role ${roleChangeTarget.value === 'admin' ? 'Admin Perusahaan' : 'Karyawan'}.`, 'success')
    await selectCompany(selectedCompany.value)
  } catch (error) {
    showToast(error.response?.data?.message || 'Peran akun gagal diperbarui.')
  } finally {
    savingRole.value = false
  }
}

onMounted(fetchCompanies)
</script>

<template>
  <div class="role-access-page">
    <BaseToast :show="toast.show" :type="toast.type" :message="toast.message" />

    <header class="page-heading">
      <div>
        <span class="eyebrow">STRUKTUR AKUN</span>
        <h1>Role & Akses</h1>
        <p>Pilih akun untuk menentukan role dan akses modulnya.</p>
      </div>
    </header>

    <section v-if="!selectedCompany" class="content-section">
      <div class="section-heading">
        <div><h2>Perusahaan</h2><p>Pilih perusahaan untuk melihat akun dan lokasi yang terdaftar.</p></div>
        <BaseSearch v-model="companyQuery" placeholder="Cari perusahaan..." width="min(340px, 100%)" />
      </div>
      <BaseTable
        :columns="companyColumns"
        :data="filteredCompanies"
        :loading="loadingCompanies"
        has-actions
        loading-text="Memuat perusahaan..."
        empty-text="Belum ada perusahaan."
      >
        <template #cell-company="{ item }"><strong class="company-name">{{ item.name }}</strong></template>
        <template #cell-locations="{ item }">{{ item.locations_count ?? 0 }} lokasi</template>
        <template #cell-accounts="{ item }">{{ item.users_count ?? 0 }} akun</template>
        <template #actions="{ item }">
          <button type="button" class="open-company" @click="selectCompany(item)">
            Lihat akun <Icon icon="material-symbols:arrow-forward-rounded" width="17" />
          </button>
        </template>
      </BaseTable>
    </section>

    <template v-else>
      <section class="company-heading">
        <button type="button" class="back-button" title="Kembali ke perusahaan" @click="backToCompanies">
          <Icon icon="material-symbols:arrow-back-rounded" width="20" />
        </button>
        <div><span class="eyebrow">PERUSAHAAN</span><h2>{{ selectedCompany.name }}</h2></div>
        <span class="scope-count">{{ adminCount }} admin · {{ employeeCount }} karyawan</span>
      </section>

      <section class="content-section">
        <div class="section-heading">
          <div><h2>Akun Perusahaan</h2><p>Ubah role per akun. Perubahan tidak memengaruhi akun lain.</p></div>
          <BaseSearch v-model="userQuery" placeholder="Cari nama, email, atau lokasi..." width="min(360px, 100%)" />
        </div>
        <BaseTable
          :columns="userColumns"
          :data="filteredUsers"
          :loading="loadingUsers"
          :has-actions="isSuperAdmin"
          loading-text="Memuat akun perusahaan..."
          empty-text="Belum ada akun karyawan atau admin perusahaan."
        >
          <template #cell-account="{ item }">
            <strong class="company-name">{{ item.name }}</strong><small>{{ item.email || '-' }}</small>
          </template>
          <template #cell-role="{ item }">
            <span class="role-badge" :class="item.role === 'admin' ? 'admin' : 'employee'">
              {{ item.role === 'admin' ? 'Admin Perusahaan' : 'Karyawan' }}
            </span>
          </template>
          <template #cell-location="{ item }">
            {{ item.home_location?.name || locations.find((location) => Number(location.id) === Number(item.home_location_id))?.name || 'Belum ditempatkan' }}
          </template>
          <template #cell-status="{ item }">
            <span class="status-badge" :class="item.is_active ? 'active' : 'pending'">
              {{ item.is_active ? 'Aktif' : 'Belum aktivasi' }}
            </span>
          </template>
          <template #actions="{ item }">
            <button
              v-if="isSuperAdmin && item.role !== 'super_admin' && item.role !== 'superadmin'"
              type="button"
              class="role-action"
              :title="item.role === 'admin' ? 'Ubah menjadi karyawan' : 'Jadikan admin perusahaan'"
              @click="openRoleChange(item)"
            >
              <Icon :icon="item.role === 'admin' ? 'material-symbols:person-outline-rounded' : 'material-symbols:admin-panel-settings-outline-rounded'" width="18" />
              {{ item.role === 'admin' ? 'Turunkan role' : 'Jadikan admin' }}
            </button>
            <span v-else class="role-action-empty">{{ item.role === 'admin' ? 'Admin perusahaan' : 'Karyawan' }}</span>
          </template>
        </BaseTable>
      </section>
    </template>

    <Teleport to="body">
      <div v-if="roleChangeUser" class="modal-overlay" @click.self="closeRoleChange">
        <section class="role-modal">
          <header class="modal-heading">
            <div>
              <span class="eyebrow">{{ selectedCompany?.name }}</span>
              <h2>{{ roleChangeTarget === 'admin' ? 'Jadikan Admin Perusahaan' : 'Ubah menjadi Karyawan' }}</h2>
            </div>
            <button type="button" class="modal-close" aria-label="Tutup" @click="closeRoleChange">
              <Icon icon="material-symbols:close-rounded" width="21" />
            </button>
          </header>
          <div class="modal-copy">
            <strong>{{ roleChangeUser.name }}</strong>
            <p v-if="roleChangeTarget === 'admin'">Pilih akses untuk {{ roleChangeUser.name }} di {{ selectedCompany.name }}. Akun lain tidak berubah.</p>
            <p v-else>Akun ini tidak lagi memiliki akses Admin Perusahaan. Riwayatnya tetap tersimpan.</p>
          </div>
          <div v-if="roleChangeTarget === 'admin'" class="permission-checklist">
            <div v-if="loadingPermissionOptions" class="permission-loading">Memuat pilihan akses...</div>
            <label v-for="permission in permissionOptions" v-else :key="permission.id" class="permission-option">
              <input
                v-model="selectedPermissions"
                type="checkbox"
                :value="permission.id"
                :disabled="permission.id === 'dashboard.view'"
              />
              <span>
                <strong>{{ permission.label }}</strong>
                <small>{{ permission.description }}</small>
              </span>
            </label>
            <p class="permission-note">Dashboard wajib aktif agar admin dapat masuk ke panel perusahaan.</p>
          </div>
          <footer class="modal-actions">
            <BaseButton variant="ghost" :disabled="savingRole" @click="closeRoleChange">Batal</BaseButton>
            <BaseButton variant="primary" :disabled="savingRole || loadingPermissionOptions" @click="saveRoleChange">
              {{ savingRole ? 'Menyimpan...' : 'Konfirmasi perubahan' }}
            </BaseButton>
          </footer>
        </section>
      </div>
    </Teleport>
  </div>
</template>

<style scoped>
.role-access-page { --ink: #1c1c19; --muted: #667085; --line: #d9dde5; --navy: #2f3b69; --surface: #fff; color: var(--ink); font-family: 'Plus Jakarta Sans', sans-serif; }
.role-access-page * { box-sizing: border-box; font-family: inherit; }
.page-heading { margin-bottom: 18px; }
.eyebrow { color: #7b8499; font-size: 10px; font-weight: 800; }
.page-heading h1 { margin: 5px 0; font-size: 25px; }
.page-heading p { margin: 0; color: var(--muted); font-size: 13px; }
.role-levels { display: grid; grid-template-columns: repeat(3, minmax(0, 1fr)); gap: 12px; margin-bottom: 18px; }
@media (max-width: 760px) { .section-heading { align-items: stretch; flex-direction: column; } .company-heading { flex-wrap: wrap; } .scope-count { width: 100%; padding-left: 52px; } }
.content-section { margin-bottom: 18px; border: 1px solid var(--line); background: var(--surface); }
.section-heading, .company-heading { display: flex; align-items: center; justify-content: space-between; gap: 16px; padding: 16px 20px; border-bottom: 1px solid var(--line); }
.section-heading h2, .company-heading h2 { margin: 0 0 4px; font-size: 16px; }
.section-heading p { margin: 0; color: var(--muted); font-size: 12px; }
.company-heading { justify-content: flex-start; margin-bottom: 16px; border: 1px solid var(--line); background: #fff; }
.company-heading > div { flex: 1; }
.scope-count { color: var(--navy); font-size: 12px; font-weight: 700; }
.back-button, .modal-close { display: grid; place-items: center; width: 36px; height: 36px; border: 1px solid var(--line); background: #fff; color: var(--navy); cursor: pointer; }
.company-name { display: block; font-size: 13px; }
.company-name + small { display: block; margin-top: 4px; color: var(--muted); font-size: 11px; }
.role-badge, .status-badge { display: inline-flex; padding: 5px 8px; font-size: 11px; font-weight: 700; white-space: nowrap; }
.role-badge.admin { color: var(--navy); background: #e8ebf5; }
.role-badge.employee { color: #176b4b; background: #e1f3e9; }
.status-badge.active { color: #176b4b; background: #e1f3e9; }
.status-badge.pending { color: #8a5a00; background: #fff2cc; }
.open-company { display: inline-flex; align-items: center; gap: 5px; border: 0; background: transparent; color: var(--navy); font-size: 12px; font-weight: 700; cursor: pointer; }
.role-action { display: inline-flex; align-items: center; gap: 6px; padding: 7px 9px; border: 1px solid #d7ddea; border-radius: 6px; background: #f7f8fc; color: var(--navy); font-size: 11px; font-weight: 700; cursor: pointer; white-space: nowrap; }
.role-action:hover { background: #edf0f8; }
.role-action-empty { color: var(--muted); font-size: 11px; }
.modal-overlay { position: fixed; inset: 0; z-index: 1000; display: grid; place-items: center; padding: 20px; background: rgba(20, 25, 45, .48); }
.role-modal { width: min(480px, 100%); border: 1px solid var(--line); background: #fff; box-shadow: 0 20px 50px rgba(0, 0, 0, .2); }
.modal-heading, .modal-actions { display: flex; align-items: center; justify-content: space-between; gap: 12px; padding: 18px 20px; }
.modal-heading { border-bottom: 1px solid var(--line); }
.modal-heading h2 { margin: 4px 0 0; font-size: 18px; }
.modal-close { border: 0; color: var(--muted); }
.modal-copy { display: grid; gap: 8px; padding: 20px; }
.modal-copy p { margin: 0; color: var(--muted); font-size: 13px; line-height: 1.6; }
.permission-checklist { display: grid; gap: 8px; max-height: min(45vh, 360px); overflow-y: auto; padding: 0 20px 16px; }
.permission-option { display: flex; align-items: flex-start; gap: 10px; padding: 8px 0; cursor: pointer; }
.permission-option input { width: 16px; height: 16px; margin: 2px 0 0; accent-color: var(--navy); }
.permission-option span { display: grid; gap: 3px; }
.permission-option strong { font-size: 12px; }
.permission-option small,
.permission-note { color: var(--muted); font-size: 11px; }
.permission-note { margin: 4px 0 0; }
.permission-loading { padding: 20px 0; color: var(--muted); font-size: 12px; text-align: center; }
.modal-actions { justify-content: flex-end; border-top: 1px solid var(--line); }
@media (max-width: 760px) { .role-levels { grid-template-columns: 1fr; } .section-heading { align-items: stretch; flex-direction: column; } .company-heading { flex-wrap: wrap; } .scope-count { width: 100%; padding-left: 52px; } }
</style>