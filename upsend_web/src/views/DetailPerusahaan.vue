<script setup>
import { ref, onMounted, onBeforeUnmount } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { Icon } from '@iconify/vue'
import api from '../api'

// Import Base Components
import BasePageHeader from '../components/BasePageHeader.vue'
import BaseTable from '../components/BaseTable.vue'
import BaseButton from '../components/BaseButton.vue'
import BaseSelect from '../components/BaseSelect.vue'
import TableActions from '../components/TableActions.vue'
import GlobalConfirm from '../components/GlobalConfirm.vue'
import { useConfirm } from '../composables/UseConfirm'

const route = useRoute()
const router = useRouter()
const confirmDialog = useConfirm()

const company = ref(null)
const branches = ref([])
const loading = ref(true)
const saving = ref(false)

// State Modal & Form
const showEditCompanyModal = ref(false)
const showBranchModal = ref(false)
const editingBranchId = ref(null)

const toast = ref({ show: false, type: 'success', message: '' })
let toastTimer = null

const statusOptions = [
  { label: 'Aktif', value: 'active' },
  { label: 'Nonaktif', value: 'inactive' }
]

const branchColumns = [
  { key: 'name', label: 'Nama Cabang' },
  { key: 'address', label: 'Alamat Lengkap' },
  { key: 'coordinates', label: 'Latitude, Longitude' },
  { key: 'radius', label: 'Radius' }
]

// Form Edit Perusahaan
const companyForm = ref({
  name: '',
  slug: '',
  status: 'active',
  alpha_deduction_per_day: 0,
})

// Form Tambah / Edit Cabang
const branchForm = ref({
  name: '',
  address: '',
  latitude: '',
  longitude: '',
  radius_meter: 25,
})

function showToast(message, type = 'success') {
  toast.value = { show: true, type, message }
  if (toastTimer) clearTimeout(toastTimer)
  toastTimer = setTimeout(() => {
    toast.value.show = false
  }, 2800)
}

function goBack() {
  if (window.history.length > 1) {
    router.back()
  } else {
    router.push('/dashboard/perusahaan')
  }
}

function formatCurrency(value) {
  if (!value) return 'Rp 0'
  return new Intl.NumberFormat('id-ID', {
    style: 'currency',
    currency: 'IDR',
    minimumFractionDigits: 0
  }).format(value)
}

// ----------------------------------------------------
// FETCH DATA
// ----------------------------------------------------
async function fetchDetail() {
  loading.value = true
  try {
    const tenantId = route.params.id
    const [companyRes, branchRes] = await Promise.all([
      api.get(`/tenants/${tenantId}`),
      api.get('/locations', { params: { tenant_id: tenantId } })
    ])
    
    company.value = companyRes.data?.data || companyRes.data
    branches.value = Array.isArray(branchRes.data) ? branchRes.data : []
  } catch (error) {
    console.error('Gagal memuat detail perusahaan:', error)
    showToast('Gagal memuat data perusahaan.', 'error')
  } finally {
    loading.value = false
  }
}

// ----------------------------------------------------
// EDIT INFORMASI PERUSAHAAN
// ----------------------------------------------------
function openEditCompany() {
  companyForm.value = {
    name: company.value.name || '',
    slug: company.value.slug || '',
    status: company.value.status || 'active',
    alpha_deduction_per_day: Number(company.value.alpha_deduction_per_day || 0),
  }
  showEditCompanyModal.value = true
}

async function submitCompany() {
  const name = companyForm.value.name.trim()
  if (!name) {
    showToast('Nama perusahaan wajib diisi.', 'error')
    return
  }

  saving.value = true
  try {
    const payload = {
      name,
      slug: companyForm.value.slug.trim() || undefined,
      status: companyForm.value.status,
      alpha_deduction_per_day: Number(companyForm.value.alpha_deduction_per_day || 0),
    }

    await api.put(`/tenants/${company.value.id}`, payload)
    showToast('Informasi perusahaan berhasil diperbarui.')
    showEditCompanyModal.value = false
    await fetchDetail() // Refresh data
  } catch (error) {
    const validation = Object.values(error.response?.data?.errors || {}).flat().join(' ')
    showToast(validation || error.response?.data?.message || 'Gagal menyimpan pembaruan.', 'error')
  } finally {
    saving.value = false
  }
}

// ----------------------------------------------------
// CRUD CABANG / LOKASI KERJA
// ----------------------------------------------------
function openAddBranch() {
  editingBranchId.value = null
  branchForm.value = {
    name: '',
    address: '',
    latitude: '',
    longitude: '',
    radius_meter: 25,
  }
  showBranchModal.value = true
}

function openEditBranch(branch) {
  editingBranchId.value = branch.id
  branchForm.value = {
    name: branch.name || '',
    address: branch.address || '',
    latitude: branch.latitude || '',
    longitude: branch.longitude || '',
    radius_meter: Number(branch.radius_meter || 25),
  }
  showBranchModal.value = true
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
    const payload = {
      ...branchForm.value,
      name: branchName,
      latitude,
      longitude,
      tenant_id: company.value.id, // Kaitkan ke perusahaan ini
    }

    if (editingBranchId.value) {
      await api.put(`/locations/${editingBranchId.value}`, payload)
      showToast('Cabang berhasil diperbarui.')
    } else {
      await api.post('/locations', payload)
      showToast('Cabang baru berhasil ditambahkan.')
    }
    
    showBranchModal.value = false
    await fetchDetail() // Refresh daftar cabang
  } catch (error) {
    const validation = Object.values(error.response?.data?.errors || {}).flat().join(' ')
    showToast(validation || error.response?.data?.message || 'Gagal menyimpan cabang.', 'error')
  } finally {
    saving.value = false
  }
}

async function deleteBranch(branch) {
  const isConfirmed = await confirmDialog.showConfirm({
    title: 'Hapus Data Cabang',
    message: `Apakah Anda yakin ingin menghapus cabang "${branch.name}"? Data yang sudah dihapus tidak dapat dikembalikan.`,
    type: 'danger',
    confirmText: 'Hapus Cabang',
    cancelText: 'Batal',
  })

  if (!isConfirmed) return

  try {
    await api.delete(`/locations/${branch.id}`)
    showToast('Cabang berhasil dihapus.')
    await fetchDetail()
  } catch (error) {
    showToast(error.response?.data?.message || 'Gagal menghapus cabang.', 'error')
  }
}

onMounted(fetchDetail)
onBeforeUnmount(() => {
  if (toastTimer) clearTimeout(toastTimer)
})
</script>

<template>
  <div class="detail-perusahaan-view">
    <!-- Toast & Global Confirm -->
    <Teleport to="body">
      <div v-if="toast.show" class="toast" :class="toast.type">
        <Icon :icon="toast.type === 'success' ? 'material-symbols:check-circle-rounded' : 'material-symbols:error-rounded'" width="18" height="18" />
        <span>{{ toast.message }}</span>
      </div>
    </Teleport>
    <GlobalConfirm />

    <BasePageHeader :title="loading ? 'Memuat Detail...' : `Detail Perusahaan`" @back="goBack" />

    <div v-if="loading" class="loading-state">Memuat data perusahaan...</div>
    
    <div v-else-if="company" class="content-container">
      
      <!-- GRID ATAS: Info Umum di Kiri & Profil Perusahaan di Kanan -->
      <div class="top-row-grid">
        
        <!-- KIRI: Detail Informasi Perusahaan -->
        <section class="detail-section">
          <div class="section-header">
            <h4>Informasi Umum</h4>
            <button class="btn-sec-edit" @click="openEditCompany">
              <Icon icon="material-symbols:edit-outline-rounded" width="16" height="16" />
              Edit Info
            </button>
          </div>
          <div class="section-body details-grid">
            <div class="detail-row">
              <span class="label">Nama Perusahaan</span>
              <span class="separator">:</span>
              <span class="value">{{ company.name }}</span>
            </div>
            <div class="detail-row">
              <span class="label">Slug / ID Unik</span>
              <span class="separator">:</span>
              <span class="value">{{ company.slug || '-' }}</span>
            </div>
            <div class="detail-row">
              <span class="label">Status</span>
              <span class="separator">:</span>
              <span class="value">{{ company.status === 'active' ? 'Aktif' : 'Nonaktif' }}</span>
            </div>
            <div class="detail-row">
              <span class="label">Potongan Alpha / Hari</span>
              <span class="separator">:</span>
              <span class="value bold-text">{{ formatCurrency(company.alpha_deduction_per_day) }}</span>
            </div>
          </div>
        </section>

        <!-- KANAN: Info Card Perusahaan -->
        <section class="company-card">
          <div class="company-avatar">
            <Icon icon="material-symbols:domain-rounded" width="48" height="48" color="#2f3b69" />
          </div>
          <div class="company-info">
            <h3>{{ company.name }}</h3>
            <p class="company-slug">@{{ company.slug || 'tanpa-slug' }}</p>
            <div class="company-meta">
              <span class="status-badge" :class="company.status">
                {{ company.status === 'active' ? 'Aktif' : 'Nonaktif' }}
              </span>
            </div>
          </div>
        </section>

      </div>

      <!-- BAWAH: Daftar Cabang / Lokasi Kerja -->
      <section class="detail-section">
        <div class="section-header">
          <h4>Daftar Cabang ({{ branches.length }})</h4>
          <BaseButton variant="primary" icon="material-symbols:add-location-alt-outline-rounded" @click="openAddBranch">
            Tambah Cabang
          </BaseButton>
        </div>
        <div class="table-container">
          <BaseTable 
            :columns="branchColumns" 
            :data="branches" 
            emptyText="Perusahaan ini belum memiliki cabang."
            hasActions
          >
            <!-- Slot untuk alamat -->
            <template #cell-address="{ item }">
              {{ item.address || '-' }}
            </template>
            
            <!-- Slot untuk koordinat gabungan -->
            <template #cell-coordinates="{ item }">
              <span class="coords">{{ item.latitude }}, {{ item.longitude }}</span>
            </template>
            
            <!-- Slot untuk radius -->
            <template #cell-radius="{ item }">
              {{ item.radius_meter ?? '-' }} m
            </template>

            <!-- Slot untuk aksi (Edit & Hapus Cabang) -->
            <template #actions="{ item }">
              <TableActions
                showEdit
                showDelete
                @edit="openEditBranch(item)"
                @delete="deleteBranch(item)"
              />
            </template>
          </BaseTable>
        </div>
      </section>
    </div>
    
    <div v-else class="empty-state">
      Perusahaan tidak ditemukan.
    </div>

    <!-- MODAL EDIT INFORMASI PERUSAHAAN -->
    <Teleport to="body">
      <div v-if="showEditCompanyModal" class="modal-overlay" @click.self="showEditCompanyModal = false">
        <form class="modal" @submit.prevent="submitCompany">
          <div class="modal-head">
            <div class="modal-title">
              <Icon icon="material-symbols:edit-document-outline" width="22" height="22" />
              <h3>Edit Perusahaan</h3>
            </div>
          </div>
          <div class="modal-body">
            <div class="field">
              <label>Nama Perusahaan</label>
              <input v-model="companyForm.name" required maxlength="255" placeholder="Contoh: PT Maju Bersama" />
            </div>
            <div class="field">
              <label>Slug (Opsional)</label>
              <input v-model="companyForm.slug" maxlength="255" placeholder="Contoh: pt-maju-bersama" />
            </div>
            <div class="field-row">
              <div class="field">
                <label>Status</label>
                <div class="input-wrapper">
                  <BaseSelect v-model="companyForm.status" :options="statusOptions" placeholder="Pilih Status" />
                </div>
              </div>
              <div class="field">
                <label>Potongan Alpha / Hari</label>
                <input v-model.number="companyForm.alpha_deduction_per_day" type="number" min="0" step="0.01" />
              </div>
            </div>
          </div>
          <div class="modal-footer">
            <button type="button" class="btn-cancel" :disabled="saving" @click="showEditCompanyModal = false">Batal</button>
            <button type="submit" class="btn-save" :disabled="saving">
              <Icon icon="material-symbols:save-outline" width="18" height="18" />
              {{ saving ? 'Menyimpan...' : 'Simpan Perubahan' }}
            </button>
          </div>
        </form>
      </div>
    </Teleport>

    <!-- MODAL TAMBAH / EDIT CABANG -->
    <Teleport to="body">
      <div v-if="showBranchModal" class="modal-overlay" @click.self="showBranchModal = false">
        <form class="modal" @submit.prevent="submitBranch">
          <div class="modal-head">
            <div class="modal-title">
              <Icon :icon="editingBranchId ? 'material-symbols:edit-location-alt-outline-rounded' : 'material-symbols:add-location-alt-outline'" width="22" height="22" />
              <h3>{{ editingBranchId ? 'Edit Cabang' : 'Tambah Cabang Baru' }}</h3>
            </div>
          </div>
          <div class="modal-body">
            <div class="field">
              <label>Nama Cabang</label>
              <input v-model="branchForm.name" required maxlength="255" placeholder="Contoh: Cabang Bandung" />
            </div>
            <div class="field">
              <label>Alamat Lengkap</label>
              <input v-model="branchForm.address" maxlength="1000" placeholder="Contoh: Jl. Raya Kopo No. 12" />
            </div>
            <div class="field-row">
              <div class="field">
                <label>Latitude</label>
                <input v-model="branchForm.latitude" required type="number" step="0.000001" min="-90" max="90" placeholder="-6.2088" />
              </div>
              <div class="field">
                <label>Longitude</label>
                <input v-model="branchForm.longitude" required type="number" step="0.000001" min="-180" max="180" placeholder="106.8456" />
              </div>
            </div>
            <div class="field">
              <label>Radius Absensi (Meter)</label>
              <input v-model.number="branchForm.radius_meter" required type="number" min="1" placeholder="25" />
            </div>
          </div>
          <div class="modal-footer">
            <button type="button" class="btn-cancel" :disabled="saving" @click="showBranchModal = false">Batal</button>
            <button type="submit" class="btn-save" :disabled="saving">
              <Icon icon="material-symbols:save-outline" width="18" height="18" />
              {{ saving ? 'Menyimpan...' : (editingBranchId ? 'Simpan Perubahan' : 'Simpan Cabang') }}
            </button>
          </div>
        </form>
      </div>
    </Teleport>

  </div>
</template>

<style scoped>
.detail-perusahaan-view {
  --blue-900: #2f3b69;
  --ink: #1c1c19;
  --ink-soft: #667085;
  --line: #d9dde5;
  --bg: #f7f8fa;
  --card: #ffffff;
  font-family: 'Plus Jakarta Sans', sans-serif;
  width: 100%;
  min-height: calc(100vh - 120px);
  max-width: none;
}
.detail-perusahaan-view * {
  box-sizing: border-box;
  font-family: 'Plus Jakarta Sans', sans-serif;
}

.content-container {
  display: flex;
  flex-direction: column;
  gap: 24px;
  width: 100%;
  min-height: 100%;
}

/* ================= GRID ATAS ================= */
.top-row-grid {
  display: grid;
  grid-template-columns: 2fr 1fr;
  gap: 24px;
  align-items: stretch;
}

/* Card Profile Perusahaan (Kanan) */
.company-card {
  background: #ffffff;
  border: 1px solid var(--line);
  border-radius: 16px;
  padding: 32px 24px;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  text-align: center;
  gap: 16px;
}
.company-avatar {
  width: 88px;
  height: 88px;
  border-radius: 20px;
  background: #f0f3fa;
  display: flex;
  align-items: center;
  justify-content: center;
  border: 1px solid #d9dde5;
}
.company-info {
  display: flex;
  flex-direction: column;
  align-items: center;
}
.company-info h3 {
  margin: 0 0 6px 0;
  font-size: 22px;
  font-weight: 700;
  color: var(--ink);
}
.company-slug {
  margin: 0 0 12px 0;
  font-size: 14px;
  color: var(--ink-soft);
  font-weight: 500;
}
.status-badge {
  display: inline-flex;
  padding: 5px 12px;
  border-radius: 999px;
  font-size: 12px;
  font-weight: 700;
}
.status-badge.active { background: #e6f7ef; color: #177a5b; }
.status-badge.inactive { background: #f1f2f4; color: #667085; }

/* Section Data (Kiri & Bawah) */
.detail-section {
  background: var(--card);
  border: 1px solid var(--line);
  border-radius: 16px;
  overflow: hidden;
  display: flex;
  flex-direction: column;
}
.section-header {
  padding: 18px 24px;
  background: #ffffff;
  border-bottom: 1px solid #f1f5f9;
  display: flex;
  justify-content: space-between;
  align-items: center;
}
.section-header h4 {
  margin: 0;
  font-size: 16px;
  font-weight: 700;
  color: var(--blue-900);
}
.section-body {
  padding: 24px;
  flex: 1;
}

.btn-sec-edit {
  border: 1px solid #2f3b69;
  background: #eef6ff;
  color: var(--blue-900);
  padding: 6px 12px;
  border-radius: 6px;
  display: inline-flex;
  align-items: center;
  gap: 5px;
  font-size: 13px;
  font-weight: 600;
  cursor: pointer;
  transition: background 0.2s ease, border-color 0.2s ease;
}
.btn-sec-edit:hover {
  background: #dfeeff;
  border-color: #2f3b69;
}

/* Grid Info Umum */
.details-grid {
  display: flex;
  flex-direction: column;
  gap: 16px;
}
.detail-row {
  display: flex;
  align-items: center;
  font-size: 14px;
}
.label {
  width: 180px;
  color: var(--ink-soft);
  flex-shrink: 0;
}
.separator {
  width: 20px;
  color: var(--ink-soft);
  flex-shrink: 0;
}
.value {
  color: var(--ink);
  font-weight: 500;
}
.value.bold-text {
  font-weight: 700;
  color: var(--blue-900);
}

.table-container {
  border-top: 1px solid var(--line);
}
.coords {
  font-family: monospace;
  background: #f1f3f7;
  padding: 4px 8px;
  border-radius: 6px;
  font-size: 13px;
}

.loading-state, .empty-state {
  text-align: center;
  padding: 40px;
  color: var(--ink-soft);
  font-weight: 500;
}

/* ================= MODAL STYLES ================= */
.modal-overlay {
  position: fixed; inset: 0; z-index: 1000;
  background: rgba(28, 32, 55, 0.55);
  display: flex; align-items: center; justify-content: center;
  padding: 24px; overflow-y: auto; overscroll-behavior: contain;
}
.modal {
  width: 100%; max-width: 620px; max-height: calc(100dvh - 32px);
  overflow-y: auto; overflow-x: hidden; overscroll-behavior: contain; scrollbar-gutter: stable;
  background: #fff; border: 1px solid var(--line); border-radius: 20px;
  box-shadow: 0 20px 50px rgba(0, 0, 0, 0.25);
}
.modal-head {
  display: flex; align-items: center; justify-content: space-between;
  padding: 18px 24px; background: var(--bg); border-bottom: 1px solid var(--line);
  border-radius: 20px 20px 0 0;
}
.modal-title { display: flex; align-items: center; gap: 10px; }
.modal-title .iconify { color: var(--blue-900); }
.modal-title h3 { margin: 0; font-size: 18px; font-weight: 700; color: var(--blue-900); }

.modal-body {
  padding: 18px 24px 16px; display: flex; flex-direction: column; gap: 14px;
}
.field { display: flex; flex-direction: column; gap: 8px; flex: 1; }
.field label { font-size: 13.5px; font-weight: 600; color: var(--ink-soft); }
.field input {
  border: 1px solid var(--line); border-radius: 10px; padding: 12px 14px;
  font-size: 14px; font-family: inherit; color: var(--ink); outline: none;
}
.field input:focus, .field :deep(.custom-select):focus-within { border-color: var(--blue-900); }
.field-row { display: flex; gap: 16px; }
.input-wrapper :deep(.custom-select) { height: 44px; }

.modal-footer {
  display: flex; justify-content: flex-end; gap: 12px;
  padding: 16px 24px 18px; border-top: 1px solid var(--line);
  background: var(--bg); border-radius: 0 0 20px 20px;
}
.btn-cancel {
  padding: 10px 20px; border-radius: 10px; border: 1px solid var(--line);
  background: #fff; color: var(--ink); font-size: 14px; font-weight: 600; cursor: pointer;
}
.btn-cancel:hover { background: #eef0f7; }
.btn-save {
  display: flex; align-items: center; gap: 8px;
  padding: 10px 22px; border-radius: 10px; border: none;
  background: #2c3964; color: #fff; font-size: 14px; font-weight: 700;
  cursor: pointer; transition: background 0.15s ease;
}
.btn-save:hover { background: #273258; }
.btn-save:disabled, .btn-cancel:disabled { opacity: 0.6; cursor: not-allowed; }

/* Toast */
.toast {
  position: fixed; top: 24px; left: 50%; transform: translateX(-50%); z-index: 2000;
  display: inline-flex; align-items: center; gap: 8px;
  padding: 12px 20px; border-radius: 12px; font-size: 14px; font-weight: 600;
  color: white; box-shadow: 0 10px 30px rgba(17, 24, 39, 0.2);
}
.toast.success { background: #1f9d67; }
.toast.error { background: #d92d20; }

@media (max-width: 768px) {
  .detail-perusahaan-view {
    min-height: calc(100vh - 90px);
  }

  .top-row-grid {
    grid-template-columns: 1fr; /* Di layar kecil kembali menjadi 1 kolom atas-bawah */
  }
  .company-card {
    order: -1; /* Pindah Profil ke paling atas pada versi HP */
    flex-direction: row;
    text-align: left;
    justify-content: flex-start;
    padding: 20px;
  }
  .company-avatar {
    width: 64px;
    height: 64px;
  }
  .company-info {
    align-items: flex-start;
  }
  .detail-row { flex-direction: column; align-items: flex-start; gap: 4px; }
  .label { width: 100%; }
  .separator { display: none; }
  .field-row { flex-direction: column; }
}
</style>