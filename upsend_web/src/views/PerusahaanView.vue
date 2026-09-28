<script setup>
import { computed, onMounted, ref } from 'vue'
import { Icon } from '@iconify/vue'
import api from '../api'
import BaseButton from '../components/BaseButton.vue'
import BaseActionBtn from '../components/BaseActionBtn.vue'
import BaseSearch from '../components/BaseSearch.vue'
import BaseTable from '../components/BaseTable.vue'
import BaseToast from '../components/BaseToast.vue'

const companies = ref([])
const loading = ref(false)
const saving = ref(false)
const showModal = ref(false)
const showBranchModal = ref(false)
const showBranchListModal = ref(false)
const editingId = ref(null)
const branchCompany = ref(null)
const branchLocations = ref([])
const loadingBranches = ref(false)
const employeeCompany = ref(null)
const employeeList = ref([])
const loadingEmployees = ref(false)
const showEmployeeListModal = ref(false)
const searchQuery = ref('')
const toast = ref({ show: false, type: 'success', message: '' })

const form = ref({
  name: '',
  slug: '',
  status: 'active',
  alpha_deduction_per_day: 0,
})

const branchForm = ref({
  name: '',
  address: '',
  latitude: '',
  longitude: '',
  radius_meter: 25,
})

const filteredCompanies = computed(() => {
  const query = searchQuery.value.trim().toLowerCase()
  if (!query) return companies.value
  return companies.value.filter((company) =>
    [company.name, company.slug, company.status].some((value) =>
      String(value || '').toLowerCase().includes(query),
    ),
  )
})

const companyColumns = [
  { key: 'company', label: 'Perusahaan' },
  { key: 'status', label: 'Status' },
  { key: 'locations', label: 'Cabang / Lokasi' },
  { key: 'employees', label: 'Karyawan' },
]

function showToast(message, type = 'success') {
  toast.value = { show: true, type, message }
  window.setTimeout(() => {
    toast.value.show = false
  }, 2800)
}

async function fetchCompanies() {
  loading.value = true
  try {
    const response = await api.get('/tenants')
    companies.value = Array.isArray(response.data) ? response.data : []
  } catch (error) {
    showToast(error.response?.data?.message || 'Data perusahaan gagal dimuat.', 'error')
  } finally {
    loading.value = false
  }
}

function openCreateModal() {
  editingId.value = null
  form.value = {
    name: '',
    slug: '',
    status: 'active',
    alpha_deduction_per_day: 0,
  }
  showModal.value = true
}

function openEditModal(company) {
  editingId.value = company.id
  form.value = {
    name: company.name || '',
    slug: company.slug || '',
    status: company.status || 'active',
    alpha_deduction_per_day: Number(company.alpha_deduction_per_day || 0),
  }
  showModal.value = true
}

function closeModal() {
  if (!saving.value) showModal.value = false
}

function openBranchModal(company) {
  branchCompany.value = company
  branchForm.value = {
    name: '',
    address: '',
    latitude: '',
    longitude: '',
    radius_meter: 25,
  }
  showBranchModal.value = true
}

async function openBranchList(company) {
  branchCompany.value = company
  branchLocations.value = []
  showBranchListModal.value = true
  loadingBranches.value = true

  try {
    const response = await api.get('/locations', {
      params: { tenant_id: company.id },
    })
    branchLocations.value = Array.isArray(response.data) ? response.data : []
  } catch (error) {
    showBranchListModal.value = false
    showToast(error.response?.data?.message || 'Daftar cabang gagal dimuat.', 'error')
  } finally {
    loadingBranches.value = false
  }
}

async function openEmployeeList(company) {
  employeeCompany.value = company
  employeeList.value = []
  showEmployeeListModal.value = true
  loadingEmployees.value = true

  try {
    const response = await api.get('/users', {
      params: { per_page: 1000 },
    })

    const list = Array.isArray(response.data?.data) ? response.data.data : Array.isArray(response.data) ? response.data : []

    employeeList.value = list.filter((user) => {
      const tenantId = user.tenant_id ?? user.tenantId ?? user.home_location?.tenant_id ?? user.home_location?.tenantId
      return Number(tenantId) === Number(company.id)
    })
  } catch (error) {
    showEmployeeListModal.value = false
    showToast(error.response?.data?.message || 'Daftar karyawan gagal dimuat.', 'error')
  } finally {
    loadingEmployees.value = false
  }
}

function closeBranchModal() {
  if (!saving.value) showBranchModal.value = false
}

async function submitBranch() {
  const branchName = branchForm.value.name.trim()
  const latitude = Number(branchForm.value.latitude)
  const longitude = Number(branchForm.value.longitude)

  if (!branchName || !Number.isFinite(latitude) || !Number.isFinite(longitude)) {
    showToast('Nama dan koordinat cabang wajib diisi.', 'error')
    return
  }

  saving.value = true
  try {
    await api.post('/locations', {
      ...branchForm.value,
      name: branchName,
      latitude,
      longitude,
      tenant_id: branchCompany.value.id,
    })
    showBranchModal.value = false
    await fetchCompanies()
    showToast('Cabang berhasil ditambahkan.')
  } catch (error) {
    const validation = Object.values(error.response?.data?.errors || {}).flat().join(' ')
    showToast(validation || error.response?.data?.message || 'Cabang gagal ditambahkan.', 'error')
  } finally {
    saving.value = false
  }
}

async function submitForm() {
  const name = form.value.name.trim()
  if (!name) {
    showToast('Nama perusahaan wajib diisi.', 'error')
    return
  }

  saving.value = true
  try {
    const payload = {
      name,
      slug: form.value.slug.trim() || undefined,
      status: form.value.status,
      alpha_deduction_per_day: Number(form.value.alpha_deduction_per_day || 0),
    }

    if (editingId.value) {
      await api.put(`/tenants/${editingId.value}`, payload)
      showToast('Data perusahaan berhasil diperbarui.')
    } else {
      await api.post('/tenants', payload)
      showToast('Perusahaan berhasil ditambahkan.')
    }

    showModal.value = false
    await fetchCompanies()
  } catch (error) {
    const validation = Object.values(error.response?.data?.errors || {}).flat().join(' ')
    showToast(validation || error.response?.data?.message || 'Perusahaan gagal disimpan.', 'error')
  } finally {
    saving.value = false
  }
}

async function toggleStatus(company) {
  const nextStatus = company.status === 'active' ? 'inactive' : 'active'
  try {
    await api.put(`/tenants/${company.id}`, { status: nextStatus })
    company.status = nextStatus
    showToast(nextStatus === 'active' ? 'Perusahaan diaktifkan.' : 'Perusahaan dinonaktifkan.')
  } catch (error) {
    showToast(error.response?.data?.message || 'Status perusahaan gagal diubah.', 'error')
  }
}

onMounted(fetchCompanies)
</script>

<template>
  <div class="companies-page">
    <BaseToast :show="toast.show" :type="toast.type" :message="toast.message" />

    <section class="page-intro">
      <div>
        <span class="eyebrow">SUPER ADMIN</span>
        <h2>Perusahaan</h2>
        <p>Kelola perusahaan yang menggunakan SiapHadir dan pantau cabang mereka.</p>
      </div>
      <BaseButton variant="primary" icon="material-symbols:add-rounded" @click="openCreateModal">
        Tambah Perusahaan
      </BaseButton>
    </section>

    <section class="table-panel">
      <div class="toolbar">
        <BaseSearch v-model="searchQuery" placeholder="Cari perusahaan..." width="min(360px, 100%)" />
        <span class="total-label">{{ filteredCompanies.length }} perusahaan</span>
      </div>

      <BaseTable
        :columns="companyColumns"
        :data="filteredCompanies"
        :loading="loading"
        has-actions
        empty-text="Belum ada perusahaan."
        loading-text="Memuat data perusahaan..."
      >
        <template #cell-company="{ item }">
          <strong>{{ item.name }}</strong>
          <small>{{ item.slug }}</small>
        </template>
        <template #cell-status="{ item }">
          <span class="status" :class="item.status">
            {{ item.status === 'active' ? 'Aktif' : 'Nonaktif' }}
          </span>
        </template>
        <template #cell-locations="{ item }">
          <button class="count-link" @click="openBranchList(item)">
            {{ item.locations_count ?? 0 }} cabang
          </button>
        </template>
        <template #cell-employees="{ item }">
          <button class="count-link" @click="openEmployeeList(item)">
            {{ item.users_count ?? 0 }} karyawan
          </button>
        </template>
        <template #actions="{ item }">
          <div class="actions">
            <BaseButton
              variant="ghost"
              icon="material-symbols:add-location-alt-outline-rounded"
              title="Tambah cabang"
              @click="openBranchModal(item)"
            >Cabang</BaseButton>
            <BaseActionBtn variant="edit" tooltip="Edit perusahaan" @click="openEditModal(item)" />
            <button
              class="toggle-action"
              :title="item.status === 'active' ? 'Nonaktifkan perusahaan' : 'Aktifkan perusahaan'"
              @click="toggleStatus(item)"
            >
              <Icon
                :icon="item.status === 'active' ? 'material-symbols:pause-circle-outline' : 'material-symbols:play-circle-outline'"
                width="19"
              />
            </button>
          </div>
        </template>
      </BaseTable>
    </section>

    <Teleport to="body">
      <div v-if="showModal" class="modal-overlay" @click.self="closeModal">
        <form class="modal" @submit.prevent="submitForm">
          <div class="modal-head">
            <div>
              <span class="eyebrow">{{ editingId ? 'EDIT DATA' : 'DATA BARU' }}</span>
              <h3>{{ editingId ? 'Edit Perusahaan' : 'Tambah Perusahaan' }}</h3>
            </div>
            <button type="button" class="close-btn" @click="closeModal" aria-label="Tutup">
              <Icon icon="material-symbols:close-rounded" width="22" />
            </button>
          </div>
          <div class="modal-body">
            <label>Nama perusahaan<input v-model="form.name" required maxlength="255" placeholder="Contoh: PT Maju Bersama" /></label>
            <label>Slug<input v-model="form.slug" maxlength="255" placeholder="pt-maju-bersama" /></label>
            <div class="field-row">
              <label>Status<select v-model="form.status"><option value="active">Aktif</option><option value="inactive">Nonaktif</option></select></label>
              <label>Potongan alpha / hari<input v-model.number="form.alpha_deduction_per_day" type="number" min="0" step="0.01" /></label>
            </div>
          </div>
          <div class="modal-footer">
            <button type="button" class="cancel-btn" :disabled="saving" @click="closeModal">Batal</button>
            <BaseButton type="submit" variant="primary" :disabled="saving">
              {{ saving ? 'Menyimpan...' : 'Simpan Perusahaan' }}
            </BaseButton>
          </div>
        </form>
      </div>
    </Teleport>

    <Teleport to="body">
      <div v-if="showBranchModal" class="modal-overlay" @click.self="closeBranchModal">
        <form class="modal" @submit.prevent="submitBranch">
          <div class="modal-head">
            <div>
              <span class="eyebrow">{{ branchCompany?.name }}</span>
              <h3>Tambah Cabang</h3>
            </div>
            <button type="button" class="close-btn" @click="closeBranchModal" aria-label="Tutup">
              <Icon icon="material-symbols:close-rounded" width="22" />
            </button>
          </div>
          <div class="modal-body">
            <label>Nama cabang<input v-model="branchForm.name" required maxlength="255" placeholder="Contoh: Cabang Bandung" /></label>
            <label>Alamat<input v-model="branchForm.address" maxlength="1000" placeholder="Alamat cabang" /></label>
            <div class="field-row">
              <label>Latitude<input v-model="branchForm.latitude" required type="number" step="0.000001" min="-90" max="90" placeholder="-6.2088" /></label>
              <label>Longitude<input v-model="branchForm.longitude" required type="number" step="0.000001" min="-180" max="180" placeholder="106.8456" /></label>
            </div>
            <label>Radius absensi (meter)<input v-model.number="branchForm.radius_meter" required type="number" min="1" /></label>
          </div>
          <div class="modal-footer">
            <button type="button" class="cancel-btn" :disabled="saving" @click="closeBranchModal">Batal</button>
            <BaseButton type="submit" variant="primary" :disabled="saving">
              {{ saving ? 'Menyimpan...' : 'Simpan Cabang' }}
            </BaseButton>
          </div>
        </form>
      </div>
    </Teleport>

    <Teleport to="body">
      <div v-if="showBranchListModal" class="modal-overlay" @click.self="showBranchListModal = false">
        <section class="modal branch-list-modal">
          <div class="modal-head">
            <div>
              <span class="eyebrow">{{ branchCompany?.name }}</span>
              <h3>Daftar Cabang</h3>
            </div>
            <button type="button" class="close-btn" @click="showBranchListModal = false" aria-label="Tutup">
              <Icon icon="material-symbols:close-rounded" width="22" />
            </button>
          </div>
          <div class="branch-list-body">
            <div v-if="loadingBranches" class="empty-cell">Memuat daftar cabang...</div>
            <div v-else-if="branchLocations.length === 0" class="empty-cell">Belum ada cabang.</div>
            <article v-for="location in branchLocations" v-else :key="location.id" class="branch-card">
              <div>
                <strong>{{ location.name }}</strong>
                <p>{{ location.address || 'Alamat belum diisi' }}</p>
              </div>
              <div class="branch-meta">
                <span>Radius {{ location.radius_meter ?? '-' }} m</span>
                <span>{{ location.latitude }}, {{ location.longitude }}</span>
              </div>
            </article>
          </div>
          <div class="modal-footer">
            <button type="button" class="cancel-btn" @click="showBranchListModal = false">Tutup</button>
            <BaseButton variant="primary" icon="material-symbols:add-location-alt-outline-rounded" @click="showBranchListModal = false; openBranchModal(branchCompany)">
              Tambah Cabang
            </BaseButton>
          </div>
        </section>
      </div>
    </Teleport>

    <Teleport to="body">
      <div v-if="showEmployeeListModal" class="modal-overlay" @click.self="showEmployeeListModal = false">
        <section class="modal branch-list-modal">
          <div class="modal-head">
            <div>
              <span class="eyebrow">{{ employeeCompany?.name }}</span>
              <h3>Daftar Karyawan</h3>
            </div>
            <button type="button" class="close-btn" @click="showEmployeeListModal = false" aria-label="Tutup">
              <Icon icon="material-symbols:close-rounded" width="22" />
            </button>
          </div>
          <div class="branch-list-body">
            <div v-if="loadingEmployees" class="empty-cell">Memuat daftar karyawan...</div>
            <div v-else-if="employeeList.length === 0" class="empty-cell">Belum ada karyawan di perusahaan ini.</div>
            <article v-for="employee in employeeList" v-else :key="employee.id" class="branch-card">
              <div>
                <strong>{{ employee.name }}</strong>
                <p>{{ employee.email || '-' }}</p>
              </div>
              <div class="branch-meta">
                <span>{{ employee.role || 'Karyawan' }}</span>
                <span>{{ employee.home_location?.name || employee.home_location_name || 'Belum ada lokasi' }}</span>
              </div>
            </article>
          </div>
          <div class="modal-footer">
            <button type="button" class="cancel-btn" @click="showEmployeeListModal = false">Tutup</button>
          </div>
        </section>
      </div>
    </Teleport>
  </div>
</template>

<style scoped>
.companies-page { --ink: #1c1c19; --muted: #667085; --line: #d9dde5; --navy: #2f3b69; font-family: 'Plus Jakarta Sans', sans-serif; }
.page-intro { display: flex; justify-content: space-between; gap: 24px; align-items: flex-end; margin-bottom: 24px; }
.eyebrow { color: #7b8499; font-size: 11px; font-weight: 800; letter-spacing: .12em; }
h2 { color: var(--ink); font-size: 28px; margin: 6px 0; } p { color: var(--muted); margin: 0; }
.table-panel { background: #fff; border: 1px solid var(--line); border-radius: 16px; overflow: hidden; }
.toolbar { display: flex; align-items: center; justify-content: space-between; gap: 16px; padding: 18px 20px; border-bottom: 1px solid var(--line); }
.total-label, small { color: var(--muted); font-size: 12px; } small { display: block; margin-top: 4px; }
.status { display: inline-flex; padding: 5px 9px; border-radius: 999px; font-size: 12px; font-weight: 700; } .status.active { background: #e6f7ef; color: #177a5b; } .status.inactive { background: #f1f2f4; color: #667085; }
.actions { display: flex; align-items: center; justify-content: flex-end; gap: 6px; } .close-btn { border: 0; background: transparent; color: var(--muted); cursor: pointer; padding: 7px; border-radius: 7px; } .close-btn:hover { background: #f1f3f7; color: var(--navy); }
.toggle-action { display: grid; place-items: center; width: 30px; height: 30px; padding: 0; border: 0; border-radius: 6px; background: transparent; color: var(--muted); cursor: pointer; }
.toggle-action:hover { background: #f1f3f7; color: var(--navy); }
.count-link { border: 0; background: transparent; color: var(--navy); cursor: pointer; font: inherit; font-weight: 700; padding: 0; }
.count-link:hover { text-decoration: underline; }
.branch-list-modal { max-width: 680px; }
.branch-list-body { display: grid; gap: 10px; max-height: 55vh; overflow-y: auto; padding: 20px 24px; }
.branch-card { display: flex; justify-content: space-between; gap: 16px; padding: 14px; border: 1px solid #e2e6ed; border-radius: 10px; }
.branch-card strong { color: var(--ink); }
.branch-card p { margin: 5px 0 0; font-size: 12px; }
.branch-meta { display: grid; gap: 4px; color: var(--muted); font-size: 11px; text-align: right; white-space: nowrap; }
.empty-cell { text-align: center; color: var(--muted); padding: 48px 20px; }
.modal-overlay { position: fixed; inset: 0; z-index: 1000; display: grid; place-items: center; padding: 20px; background: rgba(15, 23, 42, .42); }
.modal { width: min(560px, 100%); background: #fff; border-radius: 16px; box-shadow: 0 24px 70px rgba(15, 23, 42, .2); } .modal-head, .modal-footer { display: flex; align-items: center; justify-content: space-between; gap: 16px; padding: 20px 24px; } .modal-head { border-bottom: 1px solid var(--line); } h3 { margin: 5px 0 0; font-size: 20px; } .modal-body { display: grid; gap: 16px; padding: 24px; } label { display: grid; gap: 7px; color: var(--ink); font-size: 13px; font-weight: 700; } input, select { width: 100%; border: 1px solid var(--line); border-radius: 8px; padding: 11px 12px; font: inherit; font-weight: 400; outline: 0; } input:focus, select:focus { border-color: var(--navy); } .field-row { display: grid; grid-template-columns: 1fr 1fr; gap: 14px; } .modal-footer { justify-content: flex-end; border-top: 1px solid var(--line); } .cancel-btn { border: 0; background: transparent; color: var(--muted); padding: 10px 14px; cursor: pointer; }
@media (max-width: 640px) { .page-intro { align-items: stretch; flex-direction: column; } .field-row { grid-template-columns: 1fr; } .toolbar { align-items: stretch; flex-direction: column; } }
</style>
