<script setup>
/**
 * RoleAkses.vue
 * Alur: (super_admin) Pilih Perusahaan -> Pilih Cabang -> Akun & Role per cabang.
 * Role "admin" hanya punya satu perusahaan, jadi langsung dibuka di level Pilih Cabang
 * (tanpa layar pilih-perusahaan dan tanpa subjudul di bawah nama perusahaan).
 * Pilihan disimpan di URL (?company_id=&location_id=) supaya tombol back browser bekerja.
 */
import { computed, onMounted, ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { Icon } from '@iconify/vue'
import api from '../api'
import BaseButton from '../components/BaseButton.vue'
import BaseSearch from '../components/BaseSearch.vue'
import BaseTable from '../components/BaseTable.vue'
import BaseToast from '../components/BaseToast.vue'
import BaseBadge from '../components/BaseBadge.vue'
import BasePagination from '../components/BasePagination.vue'
import BasePanel from '../components/BasePanel.vue'

const route = useRoute()
const router = useRouter()

const authUser = JSON.parse(localStorage.getItem('auth_user') || 'null')
const isSuperAdmin = ['super_admin', 'superadmin'].includes(authUser?.role)

const companies = ref([])
const loadingCompanies = ref(false)
const companyQuery = ref('')

const branches = ref([])
const loadingBranches = ref(false)
const branchQuery = ref('')

const companyUsers = ref([])
const locationsById = ref({})
const userQuery = ref('')
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

// Pagination (client-side)
const companyPage = ref(1)
const companyPerPage = ref(20)
const branchPage = ref(1)
const branchPerPage = ref(20)
const userPage = ref(1)
const userPerPage = ref(20)

const companyColumns = [
  { key: 'company', label: 'Perusahaan' },
  { key: 'locations', label: 'Lokasi' },
  { key: 'accounts', label: 'Akun' },
]
const branchColumns = [
  { key: 'name', label: 'Nama Lokasi / Cabang' },
  { key: 'address', label: 'Alamat' },
]
const userColumns = [
  { key: 'account', label: 'Akun' },
  { key: 'role', label: 'Peran' },
  { key: 'status', label: 'Status' },
]

/* ------------------------------------------------------------------ */
/* Drill-down: Perusahaan -> Cabang -> Akun                            */
/* ------------------------------------------------------------------ */
const companyId = computed(() => String(route.query.company_id || '').trim())
const locationId = computed(() => String(route.query.location_id || '').trim())

// Admin biasa hanya punya satu perusahaan -> langsung dipakai tanpa layar pilih-perusahaan
const singleCompany = computed(() => (!isSuperAdmin ? companies.value[0] || null : null))

const selectedCompany = computed(() => {
  if (!isSuperAdmin) return singleCompany.value
  if (!companyId.value) return null
  return companies.value.find((c) => String(c.id) === companyId.value) || null
})

const selectedLocation = computed(() => {
  if (!locationId.value) return null
  return branches.value.find((b) => String(b.id) === locationId.value) || null
})

function openCompany(company) {
  router.push({ query: { company_id: String(company.id) } })
}

function openBranch(branch) {
  const query = { location_id: String(branch.id) }
  if (isSuperAdmin && selectedCompany.value) query.company_id = String(selectedCompany.value.id)
  router.push({ query })
}

// Tombol panah kembali: naik satu level
function goBack() {
  const previous = String(window.history.state?.back || '')
  if (previous.startsWith(route.path)) {
    router.back()
    return
  }
  const query = {}
  if (selectedLocation.value && isSuperAdmin && selectedCompany.value) {
    query.company_id = String(selectedCompany.value.id)
  }
  router.replace({ query })
}

function showToast(message, type = 'error') {
  toast.value = { show: true, type, message }
  if (toastTimer) clearTimeout(toastTimer)
  toastTimer = setTimeout(() => {
    toast.value.show = false
  }, 2800)
}

/* ------------------------------------------------------------------ */
/* Level 1: Daftar Perusahaan (super_admin)                            */
/* ------------------------------------------------------------------ */
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

const filteredCompanies = computed(() => {
  const query = companyQuery.value.trim().toLowerCase()
  if (!query) return companies.value
  return companies.value.filter((company) => String(company.name || '').toLowerCase().includes(query))
})
const companyLastPage = computed(() => Math.max(1, Math.ceil(filteredCompanies.value.length / companyPerPage.value)))
const paginatedCompanies = computed(() => {
  const start = (companyPage.value - 1) * companyPerPage.value
  return filteredCompanies.value.slice(start, start + companyPerPage.value)
})
function onCompanyPageChange(page) {
  companyPage.value = page
}
function onCompanyPerPageChange(value) {
  companyPerPage.value = value
  companyPage.value = 1
}
watch(companyQuery, () => {
  companyPage.value = 1
})

/* ------------------------------------------------------------------ */
/* Level 2: Daftar Cabang milik perusahaan terpilih                    */
/* ------------------------------------------------------------------ */
async function loadBranches(company) {
  branches.value = []
  branchQuery.value = ''
  branchPage.value = 1
  if (!company?.id) return
  loadingBranches.value = true
  try {
    const response = await api.get('/locations', { params: { tenant_id: company.id } })
    branches.value = Array.isArray(response.data) ? response.data : []
    locationsById.value = Object.fromEntries(branches.value.map((loc) => [String(loc.id), loc]))
  } catch (error) {
    showToast(error.response?.data?.message || 'Daftar cabang gagal dimuat.')
  } finally {
    loadingBranches.value = false
  }
}

const filteredBranches = computed(() => {
  const query = branchQuery.value.trim().toLowerCase()
  if (!query) return branches.value
  return branches.value.filter(
    (branch) =>
      String(branch.name || '').toLowerCase().includes(query) ||
      String(branch.address || '').toLowerCase().includes(query),
  )
})
const branchLastPage = computed(() => Math.max(1, Math.ceil(filteredBranches.value.length / branchPerPage.value)))
const paginatedBranches = computed(() => {
  const start = (branchPage.value - 1) * branchPerPage.value
  return filteredBranches.value.slice(start, start + branchPerPage.value)
})
function onBranchPageChange(page) {
  branchPage.value = page
}
function onBranchPerPageChange(value) {
  branchPerPage.value = value
  branchPage.value = 1
}
watch(branchQuery, () => {
  branchPage.value = 1
})

const branchEmptyText = computed(() => {
  if (loadingBranches.value) return 'Memuat data...'
  return branchQuery.value ? 'Cabang tidak ditemukan.' : 'Belum ada cabang di perusahaan ini.'
})

/* ------------------------------------------------------------------ */
/* Level 3: Akun & Role di cabang terpilih                             */
/* ------------------------------------------------------------------ */
async function loadCompanyUsers(company) {
  companyUsers.value = []
  if (!company?.id) return
  loadingUsers.value = true
  const currentRequest = ++requestSequence
  try {
    const response = await api.get('/users', { params: { tenant_id: company.id, per_page: 1000 } })
    if (currentRequest !== requestSequence) return
    companyUsers.value = Array.isArray(response.data?.data) ? response.data.data : []
  } catch (error) {
    if (currentRequest === requestSequence) {
      showToast(error.response?.data?.message || 'Daftar akun perusahaan gagal dimuat.')
    }
  } finally {
    if (currentRequest === requestSequence) loadingUsers.value = false
  }
}

// Akun di cabang yang sedang dipilih saja
const branchUsers = computed(() => {
  if (!selectedLocation.value) return []
  return companyUsers.value
    .filter((user) => ['admin', 'karyawan', 'employee'].includes(user.role))
    .filter((user) => {
      const userLocationId = user.home_location_id ?? user.home_location?.id
      return String(userLocationId) === String(selectedLocation.value.id)
    })
    .map((user) => ({
      ...user,
      roleLabel: user.role === 'admin' ? 'Admin Perusahaan' : 'Karyawan',
      statusLabel: user.is_active ? 'Aktif' : 'Belum aktivasi',
    }))
})

const filteredUsers = computed(() => {
  const query = userQuery.value.trim().toLowerCase()
  if (!query) return branchUsers.value
  return branchUsers.value.filter((user) =>
    `${user.name || ''} ${user.email || ''} ${user.roleLabel}`.toLowerCase().includes(query),
  )
})
const userLastPage = computed(() => Math.max(1, Math.ceil(filteredUsers.value.length / userPerPage.value)))
const paginatedUsers = computed(() => {
  const start = (userPage.value - 1) * userPerPage.value
  return filteredUsers.value.slice(start, start + userPerPage.value)
})
function onUserPageChange(page) {
  userPage.value = page
}
function onUserPerPageChange(value) {
  userPerPage.value = value
  userPage.value = 1
}
watch([userQuery, locationId], () => {
  userPage.value = 1
})

const adminCount = computed(() => branchUsers.value.filter((user) => user.role === 'admin').length)
const employeeCount = computed(() => branchUsers.value.filter((user) => user.role !== 'admin').length)

/* ------------------------------------------------------------------ */
/* Watchers: muat data setiap kali level berubah                       */
/* ------------------------------------------------------------------ */
watch(
  selectedCompany,
  (company) => {
    if (company) {
      loadBranches(company)
      loadCompanyUsers(company)
    } else {
      branches.value = []
      companyUsers.value = []
    }
  },
  { immediate: true },
)

watch(userQuery, () => {
  userPage.value = 1
})

/* ------------------------------------------------------------------ */
/* Ubah Role                                                            */
/* ------------------------------------------------------------------ */
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
    await loadCompanyUsers(selectedCompany.value)
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

    <!-- Level 1: Daftar Perusahaan (khusus super_admin) -->
    <BasePanel v-if="isSuperAdmin && !selectedCompany">
      <template #header>
        <div class="heading">
          <h2>Pilih Perusahaan</h2>
          <p>Pilih perusahaan untuk melihat cabang dan akun yang terdaftar.</p>
        </div>
        <BaseSearch v-model="companyQuery" placeholder="Cari perusahaan..." width="280px" />
      </template>

      <BaseTable
        :columns="companyColumns"
        :data="paginatedCompanies"
        :loading="loadingCompanies"
        has-actions
        loading-text="Memuat perusahaan..."
        empty-text="Belum ada perusahaan."
      >
        <template #cell-company="{ item }"><strong>{{ item.name }}</strong></template>
        <template #cell-locations="{ item }">{{ item.locations_count ?? 0 }} lokasi</template>
        <template #cell-accounts="{ item }">
          <span class="count-badge">{{ item.users_count ?? 0 }} Akun</span>
        </template>
        <template #actions="{ item }">
          <button type="button" class="link-btn" @click="openCompany(item)">Lihat Cabang</button>
        </template>
      </BaseTable>

      <BasePagination
        :current-page="companyPage"
        :last-page="companyLastPage"
        :per-page="companyPerPage"
        :total="filteredCompanies.length"
        :loading="loadingCompanies"
        @page-change="onCompanyPageChange"
        @per-page-change="onCompanyPerPageChange"
      />
    </BasePanel>

    <!-- Level 2: Daftar Cabang -->
    <BasePanel v-else-if="!selectedLocation">
      <template #header>
        <div class="header-left">
          <BaseButton
            v-if="isSuperAdmin"
            variant="ghost"
            icon="material-symbols:arrow-back-rounded"
            title="Kembali"
            style="padding: 10px"
            @click="goBack"
          />
          <div class="heading">
            <h2>{{ selectedCompany?.name }}</h2>
            <!-- Subjudul hanya untuk super_admin; untuk admin, ini layar awal jadi tidak perlu penjelasan tambahan -->
            <p v-if="isSuperAdmin">Pilih cabang untuk melihat akun dan role yang terdaftar.</p>
          </div>
        </div>
        <BaseSearch v-model="branchQuery" placeholder="Cari cabang..." width="280px" />
      </template>

      <BaseTable
        :columns="branchColumns"
        :data="paginatedBranches"
        :loading="loadingBranches"
        has-actions
        loading-text="Memuat cabang..."
        :empty-text="branchEmptyText"
      >
        <template #cell-name="{ item }"><strong>{{ item.name }}</strong></template>
        <template #cell-address="{ item }">{{ item.address || '-' }}</template>
        <template #actions="{ item }">
          <button type="button" class="link-btn" @click="openBranch(item)">Lihat Akun</button>
        </template>
      </BaseTable>

      <BasePagination
        :current-page="branchPage"
        :last-page="branchLastPage"
        :per-page="branchPerPage"
        :total="filteredBranches.length"
        :loading="loadingBranches"
        @page-change="onBranchPageChange"
        @per-page-change="onBranchPerPageChange"
      />
    </BasePanel>

    <!-- Level 3: Akun & Role di cabang terpilih -->
    <BasePanel v-else>
      <template #header>
        <div class="header-left">
          <BaseButton
            variant="ghost"
            icon="material-symbols:arrow-back-rounded"
            title="Kembali"
            style="padding: 10px"
            @click="goBack"
          />
          <div class="heading">
            <span class="heading-eyebrow">{{ selectedCompany?.name }} · {{ adminCount }} admin · {{ employeeCount }} karyawan</span>
            <h2>{{ selectedLocation.name }}</h2>
          </div>
        </div>
        <BaseSearch v-model="userQuery" placeholder="Cari nama atau email..." width="280px" />
      </template>

      <BaseTable
        :columns="userColumns"
        :data="paginatedUsers"
        :loading="loadingUsers"
        :has-actions="isSuperAdmin"
        loading-text="Memuat akun cabang..."
        empty-text="Belum ada akun karyawan atau admin di cabang ini."
      >
        <template #cell-account="{ item }">
          <div class="account-cell">
            <strong>{{ item.name }}</strong>
            <small>{{ item.email || '-' }}</small>
          </div>
        </template>
        <template #cell-role="{ item }">
          <BaseBadge :theme="item.role === 'admin' ? 'info' : 'success'">
            {{ item.role === 'admin' ? 'Admin Perusahaan' : 'Karyawan' }}
          </BaseBadge>
        </template>
        <template #cell-status="{ item }">
          <BaseBadge :theme="item.is_active ? 'success' : 'warning'">
            {{ item.is_active ? 'Aktif' : 'Belum aktivasi' }}
          </BaseBadge>
        </template>
        <template #actions="{ item }">
          <button
            v-if="isSuperAdmin && item.role !== 'super_admin' && item.role !== 'superadmin'"
            type="button"
            class="role-action"
            :title="item.role === 'admin' ? 'Ubah menjadi karyawan' : 'Jadikan admin perusahaan'"
            @click="openRoleChange(item)"
          >
            <Icon
              :icon="item.role === 'admin' ? 'material-symbols:person-outline-rounded' : 'material-symbols:admin-panel-settings-outline-rounded'"
              width="16"
            />
            {{ item.role === 'admin' ? 'Turunkan Role' : 'Jadikan Admin' }}
          </button>
          <span v-else class="role-action-empty">
            {{ item.role === 'admin' ? 'Admin Perusahaan' : 'Karyawan' }}
          </span>
        </template>
      </BaseTable>

      <BasePagination
        :current-page="userPage"
        :last-page="userLastPage"
        :per-page="userPerPage"
        :total="filteredUsers.length"
        :loading="loadingUsers"
        @page-change="onUserPageChange"
        @per-page-change="onUserPerPageChange"
      />
    </BasePanel>

    <!-- MODAL UBAH ROLE -->
    <Teleport to="body">
      <div v-if="roleChangeUser" class="modal-overlay" @click.self="closeRoleChange">
        <div class="modal">
          <div class="modal-head">
            <div class="modal-title">
              <Icon
                :icon="roleChangeTarget === 'admin' ? 'material-symbols:admin-panel-settings-outline-rounded' : 'material-symbols:person-outline-rounded'"
                width="22"
                height="22"
              />
              <div>
                <span class="modal-eyebrow">{{ selectedCompany?.name }}</span>
                <h3>{{ roleChangeTarget === 'admin' ? 'Jadikan Admin Perusahaan' : 'Ubah menjadi Karyawan' }}</h3>
              </div>
            </div>
          </div>

          <div class="modal-body">
            <div class="modal-copy">
              <strong>{{ roleChangeUser.name }}</strong>
              <p v-if="roleChangeTarget === 'admin'">
                Pilih akses untuk {{ roleChangeUser.name }} di {{ selectedCompany.name }}. Akun lain tidak berubah.
              </p>
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
          </div>

          <div class="modal-footer">
            <button type="button" class="btn-cancel" :disabled="savingRole" @click="closeRoleChange">Batal</button>
            <BaseButton
              variant="primary"
              icon="material-symbols:save-outline"
              :disabled="savingRole || loadingPermissionOptions"
              @click="saveRoleChange"
            >
              {{ savingRole ? 'Menyimpan...' : 'Konfirmasi Perubahan' }}
            </BaseButton>
          </div>
        </div>
      </div>
    </Teleport>
  </div>
</template>

<style scoped>
.role-access-page {
  --blue-900: #2f3b69;
  --ink: #1c1c19;
  --ink-soft: #667085;
  --line: #d9dde5;
  --bg: #f7f8fa;
  --card: #ffffff;
  font-family: 'Plus Jakarta Sans', sans-serif;
}
.role-access-page * {
  box-sizing: border-box;
  font-family: 'Plus Jakarta Sans', sans-serif;
}

/* Header di dalam kartu */
.header-left {
  display: flex;
  align-items: center;
  gap: 12px;
}
.heading h2 {
  margin: 0;
  color: var(--blue-900);
  font-size: 18px;
  font-weight: 700;
}
.heading p {
  margin: 4px 0 0;
  color: var(--ink-soft);
  font-size: 13px;
}
.heading-eyebrow {
  display: block;
  margin-bottom: 3px;
  color: var(--ink-soft);
  font-size: 12px;
}

/* Isi sel tabel */
.count-badge {
  display: inline-flex;
  font-size: 12px;
  color: var(--ink-soft);
  background: #e9edf7;
  border-radius: 999px;
  padding: 4px 10px;
  font-weight: 700;
}
.account-cell strong {
  display: block;
  font-size: 14px;
  color: var(--ink);
}
.account-cell small {
  display: block;
  margin-top: 4px;
  color: var(--ink-soft);
  font-size: 12px;
}
.link-btn {
  display: inline-flex;
  align-items: center;
  color: var(--blue-900);
  font-weight: 700;
  font-size: 14px;
  background: none;
  border: none;
  cursor: pointer;
  white-space: nowrap;
}
.link-btn:hover {
  text-decoration: underline;
}
.role-action {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  padding: 7px 10px;
  border: 1px solid #d7ddea;
  border-radius: 7px;
  background: #f7f8fc;
  color: var(--blue-900);
  font-size: 12px;
  font-weight: 700;
  cursor: pointer;
  white-space: nowrap;
}
.role-action:hover {
  background: #edf0f8;
}
.role-action-empty {
  color: var(--ink-soft);
  font-size: 12px;
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
  overflow-y: auto;
  overscroll-behavior: contain;
}
.modal {
  width: 100%;
  max-width: 520px;
  max-height: calc(100dvh - 32px);
  overflow-y: auto;
  overflow-x: hidden;
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
  border-bottom: 1px solid var(--line);
  border-radius: 20px 20px 0 0;
}
.modal-title {
  display: flex;
  align-items: flex-start;
  gap: 10px;
}
.modal-title .iconify {
  color: var(--blue-900);
  margin-top: 2px;
}
.modal-eyebrow {
  display: block;
  color: var(--ink-soft);
  font-size: 11px;
  font-weight: 700;
  letter-spacing: 0.04em;
  text-transform: uppercase;
}
.modal-title h3 {
  margin: 2px 0 0;
  font-size: 18px;
  font-weight: 700;
  color: var(--blue-900);
}
.modal-body {
  padding: 18px 24px 16px;
  display: flex;
  flex-direction: column;
  gap: 14px;
}
.modal-copy {
  display: grid;
  gap: 6px;
}
.modal-copy strong {
  font-size: 14px;
  color: var(--ink);
}
.modal-copy p {
  margin: 0;
  color: var(--ink-soft);
  font-size: 13px;
  line-height: 1.6;
}
.permission-checklist {
  display: grid;
  gap: 4px;
  max-height: min(40vh, 320px);
  overflow-y: auto;
  padding-top: 6px;
  border-top: 1px solid var(--line);
}
.permission-option {
  display: flex;
  align-items: flex-start;
  gap: 10px;
  padding: 10px 0;
  cursor: pointer;
  border-bottom: 1px solid #f0f1f4;
}
.permission-option:last-of-type {
  border-bottom: none;
}
.permission-option input {
  width: 16px;
  height: 16px;
  margin: 2px 0 0;
  accent-color: var(--blue-900);
}
.permission-option span {
  display: grid;
  gap: 3px;
}
.permission-option strong {
  font-size: 13px;
  color: var(--ink);
}
.permission-option small,
.permission-note {
  color: var(--ink-soft);
  font-size: 11.5px;
}
.permission-note {
  margin: 6px 0 0;
}
.permission-loading {
  padding: 20px 0;
  color: var(--ink-soft);
  font-size: 12px;
  text-align: center;
}
.modal-footer {
  display: flex;
  align-items: center;
  justify-content: flex-end;
  gap: 12px;
  padding: 16px 24px 18px;
  border-top: 1px solid var(--line);
  background: var(--bg);
  border-radius: 0 0 20px 20px;
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
.btn-cancel:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

@media (max-width: 700px) {
  .modal-overlay { align-items: flex-start; padding: 12px; }
  .modal { border-radius: 16px; }
  .modal-head, .modal-body, .modal-footer { padding-left: 16px; padding-right: 16px; }
}
</style>