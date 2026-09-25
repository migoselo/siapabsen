<script setup>
import { computed, onMounted, ref } from 'vue'
import { Icon } from '@iconify/vue'
import api from '../api'
import BaseButton from '../components/BaseButton.vue'
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
        <div class="search-box">
          <Icon icon="material-symbols:search-rounded" width="18" height="18" />
          <input v-model="searchQuery" type="search" placeholder="Cari perusahaan..." />
        </div>
        <span class="total-label">{{ filteredCompanies.length }} perusahaan</span>
      </div>

      <div class="table-wrap">
        <table>
          <thead>
            <tr>
              <th>Perusahaan</th>
              <th>Status</th>
              <th>Cabang / Lokasi</th>
              <th>Karyawan</th>
              <th class="action-column">Aksi</th>
            </tr>
          </thead>
          <tbody>
            <tr v-if="loading">
              <td colspan="5" class="empty-cell">Memuat data perusahaan...</td>
            </tr>
            <tr v-else-if="filteredCompanies.length === 0">
              <td colspan="5" class="empty-cell">Belum ada perusahaan.</td>
            </tr>
            <tr v-for="company in filteredCompanies" :key="company.id">
              <td>
                <strong>{{ company.name }}</strong>
                <small>{{ company.slug }}</small>
              </td>
              <td>
                <span class="status" :class="company.status">
                  {{ company.status === 'active' ? 'Aktif' : 'Nonaktif' }}
                </span>
              </td>
              <td>
                <button class="count-link" @click="openBranchList(company)">
                  {{ company.locations_count ?? 0 }} cabang
                </button>
              </td>
              <td>{{ company.users_count ?? 0 }}</td>
              <td class="actions">
                <button class="branch-action" title="Tambah cabang" @click="openBranchModal(company)">
                  <Icon icon="material-symbols:add-location-alt-outline-rounded" width="18" />
                  Cabang
                </button>
                <button class="icon-action" title="Edit perusahaan" @click="openEditModal(company)">
                  <Icon icon="material-symbols:edit-outline-rounded" width="18" />
                </button>
                <button
                  class="icon-action"
                  :title="company.status === 'active' ? 'Nonaktifkan perusahaan' : 'Aktifkan perusahaan'"
                  @click="toggleStatus(company)"
                >
                  <Icon
                    :icon="company.status === 'active' ? 'material-symbols:pause-circle-outline' : 'material-symbols:play-circle-outline'"
                    width="19"
                  />
                </button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
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
  </div>
</template>

<style scoped>
.companies-page { --ink: #1c1c19; --muted: #667085; --line: #d9dde5; --navy: #2f3b69; font-family: 'Plus Jakarta Sans', sans-serif; }
.page-intro { display: flex; justify-content: space-between; gap: 24px; align-items: flex-end; margin-bottom: 24px; }
.eyebrow { color: #7b8499; font-size: 11px; font-weight: 800; letter-spacing: .12em; }
h2 { color: var(--ink); font-size: 28px; margin: 6px 0; } p { color: var(--muted); margin: 0; }
.table-panel { background: #fff; border: 1px solid var(--line); border-radius: 16px; overflow: hidden; }
.toolbar { display: flex; align-items: center; justify-content: space-between; gap: 16px; padding: 18px 20px; border-bottom: 1px solid var(--line); }
.search-box { display: flex; align-items: center; gap: 8px; width: min(360px, 100%); padding: 10px 12px; border: 1px solid var(--line); border-radius: 9px; color: var(--muted); }
.search-box input { width: 100%; border: 0; outline: 0; font: inherit; }
.total-label, small { color: var(--muted); font-size: 12px; } small { display: block; margin-top: 4px; }
.table-wrap { overflow-x: auto; } table { width: 100%; min-width: 680px; border-collapse: collapse; } th, td { text-align: left; padding: 16px 20px; border-bottom: 1px solid #edf0f4; } th { color: var(--muted); font-size: 11px; text-transform: uppercase; letter-spacing: .06em; } td { color: var(--ink); font-size: 14px; }
.status { display: inline-flex; padding: 5px 9px; border-radius: 999px; font-size: 12px; font-weight: 700; } .status.active { background: #e6f7ef; color: #177a5b; } .status.inactive { background: #f1f2f4; color: #667085; }
.actions { display: flex; gap: 6px; } .icon-action, .close-btn { border: 0; background: transparent; color: var(--muted); cursor: pointer; padding: 7px; border-radius: 7px; } .icon-action:hover, .close-btn:hover { background: #f1f3f7; color: var(--navy); }
.branch-action { display: inline-flex; align-items: center; gap: 4px; border: 1px solid #d7ddea; border-radius: 7px; background: #f7f8fc; color: var(--navy); cursor: pointer; padding: 7px 9px; font: inherit; font-size: 12px; font-weight: 700; }
.branch-action:hover { background: #edf0f8; }
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
