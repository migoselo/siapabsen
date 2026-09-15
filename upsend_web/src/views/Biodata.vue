<script setup>
import { ref, reactive, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { Icon } from '@iconify/vue'
import api from '../api'

const route = useRoute()
const router = useRouter()

const toast = ref({ show: false, type: 'success', message: '' })
let toastTimer = null
const loading = ref(true)

function showToast(message, type = 'success') {
  toast.value = { show: true, type, message }
  if (toastTimer) clearTimeout(toastTimer)
  toastTimer = setTimeout(() => {
    toast.value.show = false
  }, 2600)
}

const employee = reactive({
  id: route.params.id || '-',
  name: '-',
  email: '-',
  jabatan_header: '-',
  lokasi_header: '-',
  avatar_url: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?fit=crop&w=300&h=300',
  pekerjaan: {
    id_karyawan: '-',
    nama_panggilan: '-',
    departemen: '-',
    jabatan: '-',
    golongan: '-',
    cabang: '-',
    tipe_karyawan: '-',
    tanggal_bergabung: '-',
  },
  pribadi: {
    nik: '-',
    tempat_tanggal_lahir: '-',
    jenis_kelamin: '-',
    agama: '-',
    golongan_darah: '-',
    status_pernikahan: '-',
  },
  kontak: {
    no_hp: '-',
    email: '-',
    alamat_lengkap: '-',
    kontak_darurat: '-',
  },
  rekening: {
      no_hp: '-',
      email: '-',
    atas_nama: '-',
    kode_ptkp: '-',
    bpjs_tk: '-',
    bpjs_kes: '-',
  },

  // Section 5: Pendidikan & Keluarga
  pendidikan: {
    pendidikan_terakhir: '-',
    institusi: '-',
    sertifikasi: '-',
    nama_pasangan: '-',
    nama_ayah: '-',
    nama_ibu: '-',
    jumlah_anak: '-',
  },
})

const isOpen = reactive({
  pekerjaan: true,
  pribadi: true,
  kontak: true,
  rekening: true,
  pendidikan: true,
})

// State Mode Edit per Section
const isEditing = reactive({
  pekerjaan: false,
  pribadi: false,
  kontak: false,
  rekening: false,
  pendidikan: false,
})

const tempForm = reactive({})

function toggleAccordion(section) {
  isOpen[section] = !isOpen[section]
}

function startEdit(section) {
  // Buka accordion jika dalam kondisi tertutup
  isOpen[section] = true
  isEditing[section] = true
  // Copy data asli ke buffer temporary form
  tempForm[section] = JSON.parse(JSON.stringify(employee[section]))
}

function cancelEdit(section) {
  isEditing[section] = false
  delete tempForm[section]
}

function saveEdit(section) {
  // Simpan data temporary ke state utama
  Object.assign(employee[section], tempForm[section])
  
  // Update header profil jika nama/email/jabatan ikut diubah
  if (section === 'pekerjaan') {
    employee.name = employee.pekerjaan.nama_panggilan || employee.name
    employee.jabatan_header = employee.pekerjaan.jabatan || employee.jabatan_header
  }

  isEditing[section] = false
  delete tempForm[section]
  showToast('Perubahan data berhasil disimpan.')
}

function goBack() {
  router.back()
}

function mapEmployee(data) {
  const locationName = data.homeLocation?.name || data.home_location?.name || '-'
  const name = data.name || '-'
  const role = data.role === 'admin' ? 'Admin' : data.role === 'karyawan' ? 'Karyawan' : '-'

  Object.assign(employee, {
    id: data.id ?? route.params.id ?? '-',
    name,
    email: data.email || '-',
    jabatan_header: role,
    lokasi_header: locationName,
    pekerjaan: {
      ...employee.pekerjaan,
      id_karyawan: data.employee_id || data.id || '-',
      nama_panggilan: name,
      jabatan: role,
      cabang: locationName,
    },
    kontak: {
      ...employee.kontak,
      no_hp: data.no_hp || '-',
      email: data.email || '-',
    },
  })
}

async function fetchEmployee() {
  loading.value = true
  try {
    const res = await api.get(`/users/${route.params.id}`)
    mapEmployee(res.data)
  } catch (err) {
    console.error('Gagal mengambil data karyawan:', err)
    showToast('Data karyawan tidak dapat dimuat.', 'error')
  } finally {
    loading.value = false
  }
}

onMounted(fetchEmployee)
</script>

<template>
  <div class="biodata-view">
    <!-- Toast Notification -->
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

    <!-- Header Navigation -->
    <div class="page-title-bar">
      <button class="btn-back" @click="goBack" title="Kembali">
        <Icon icon="material-symbols:arrow-back-rounded" width="22" height="22" />
      </button>
      <h2>Biodata Karyawan</h2>
    </div>

    <!-- Main Container Layout -->
    <div class="biodata-container">
      <!-- Card Banner Profile Atas -->
      <div class="profile-card">
        <img :src="employee.avatar_url" alt="Avatar" class="profile-avatar" />
        <div class="profile-info">
          <h3>{{ employee.name }}</h3>
          <p class="profile-email">{{ employee.email }}</p>
          <div class="profile-meta">
            <span>{{ employee.jabatan_header }}</span>
            <span class="meta-divider">•</span>
            <span class="meta-item">
              <Icon icon="material-symbols:location-on-outline-rounded" width="16" height="16" />
              {{ employee.lokasi_header }}
            </span>
          </div>
        </div>
      </div>

      <!-- SECTION 1: Informasi Pekerjaan -->
      <div class="biodata-section">
        <div class="section-header" @click="toggleAccordion('pekerjaan')">
          <div class="section-title">
            <h4>Informasi Pekerjaan</h4>
          </div>
          <div class="section-actions" @click.stop>
            <template v-if="isEditing.pekerjaan">
              <button class="btn-sec-cancel" @click="cancelEdit('pekerjaan')">Batal</button>
              <button class="btn-sec-save" @click="saveEdit('pekerjaan')">Simpan</button>
            </template>
            <template v-else>
              <button class="btn-sec-edit" @click="startEdit('pekerjaan')">
                <Icon icon="material-symbols:edit-outline-rounded" width="16" height="16" />
                Edit
              </button>
              <button class="btn-collapse" @click="toggleAccordion('pekerjaan')">
                <Icon :icon="isOpen.pekerjaan ? 'material-symbols:keyboard-arrow-up-rounded' : 'material-symbols:keyboard-arrow-down-rounded'" width="22" height="22" />
              </button>
            </template>
          </div>
        </div>

        <div v-show="isOpen.pekerjaan" class="section-body">
          <div class="details-grid">
            <div class="detail-row">
              <span class="label">ID Karyawan</span>
              <span class="separator">:</span>
              <input v-if="isEditing.pekerjaan" v-model="tempForm.pekerjaan.id_karyawan" class="edit-input" />
              <span v-else class="value">{{ employee.pekerjaan.id_karyawan }}</span>
            </div>

            <div class="detail-row">
              <span class="label">Nama Panggilan</span>
              <span class="separator">:</span>
              <input v-if="isEditing.pekerjaan" v-model="tempForm.pekerjaan.nama_panggilan" class="edit-input" />
              <span v-else class="value">{{ employee.pekerjaan.nama_panggilan }}</span>
            </div>

            <div class="detail-row">
              <span class="label">Departemen</span>
              <span class="separator">:</span>
              <input v-if="isEditing.pekerjaan" v-model="tempForm.pekerjaan.departemen" class="edit-input" />
              <span v-else class="value">{{ employee.pekerjaan.departemen }}</span>
            </div>

            <div class="detail-row">
              <span class="label">Jabatan</span>
              <span class="separator">:</span>
              <input v-if="isEditing.pekerjaan" v-model="tempForm.pekerjaan.jabatan" class="edit-input" />
              <span v-else class="value bold-text">{{ employee.pekerjaan.jabatan }}</span>
            </div>

            <div class="detail-row">
              <span class="label">Golongan</span>
              <span class="separator">:</span>
              <input v-if="isEditing.pekerjaan" v-model="tempForm.pekerjaan.golongan" class="edit-input" />
              <span v-else class="value">{{ employee.pekerjaan.golongan }}</span>
            </div>

            <div class="detail-row">
              <span class="label">Cabang (Branch)</span>
              <span class="separator">:</span>
              <input v-if="isEditing.pekerjaan" v-model="tempForm.pekerjaan.cabang" class="edit-input" />
              <span v-else class="value">{{ employee.pekerjaan.cabang }}</span>
            </div>

            <div class="detail-row">
              <span class="label">Tipe Karyawan</span>
              <span class="separator">:</span>
              <input v-if="isEditing.pekerjaan" v-model="tempForm.pekerjaan.tipe_karyawan" class="edit-input" />
              <span v-else class="value">{{ employee.pekerjaan.tipe_karyawan }}</span>
            </div>

            <div class="detail-row">
              <span class="label">Tanggal Bergabung</span>
              <span class="separator">:</span>
              <input v-if="isEditing.pekerjaan" type="date" v-model="tempForm.pekerjaan.tanggal_bergabung" class="edit-input" />
              <span v-else class="value">{{ employee.pekerjaan.tanggal_bergabung }}</span>
            </div>
          </div>
        </div>
      </div>

      <!-- SECTION 2: Data Pribadi -->
      <div class="biodata-section">
        <div class="section-header" @click="toggleAccordion('pribadi')">
          <div class="section-title">
            <h4>Data Pribadi</h4>
          </div>
          <div class="section-actions" @click.stop>
            <template v-if="isEditing.pribadi">
              <button class="btn-sec-cancel" @click="cancelEdit('pribadi')">Batal</button>
              <button class="btn-sec-save" @click="saveEdit('pribadi')">Simpan</button>
            </template>
            <template v-else>
              <button class="btn-sec-edit" @click="startEdit('pribadi')">
                <Icon icon="material-symbols:edit-outline-rounded" width="16" height="16" />
                Edit
              </button>
              <button class="btn-collapse" @click="toggleAccordion('pribadi')">
                <Icon :icon="isOpen.pribadi ? 'material-symbols:keyboard-arrow-up-rounded' : 'material-symbols:keyboard-arrow-down-rounded'" width="22" height="22" />
              </button>
            </template>
          </div>
        </div>

        <div v-show="isOpen.pribadi" class="section-body">
          <div class="details-grid">
            <div class="detail-row">
              <span class="label">NIK</span>
              <span class="separator">:</span>
              <input v-if="isEditing.pribadi" v-model="tempForm.pribadi.nik" class="edit-input" />
              <span v-else class="value">{{ employee.pribadi.nik }}</span>
            </div>

            <div class="detail-row">
              <span class="label">Tempat, Tanggal Lahir</span>
              <span class="separator">:</span>
              <input v-if="isEditing.pribadi" v-model="tempForm.pribadi.tempat_tanggal_lahir" class="edit-input" />
              <span v-else class="value">{{ employee.pribadi.tempat_tanggal_lahir }}</span>
            </div>

            <div class="detail-row">
              <span class="label">Jenis Kelamin</span>
              <span class="separator">:</span>
              <select v-if="isEditing.pribadi" v-model="tempForm.pribadi.jenis_kelamin" class="edit-input">
                <option value="Laki-laki">Laki-laki</option>
                <option value="Perempuan">Perempuan</option>
              </select>
              <span v-else class="value">{{ employee.pribadi.jenis_kelamin }}</span>
            </div>

            <div class="detail-row">
              <span class="label">Agama</span>
              <span class="separator">:</span>
              <input v-if="isEditing.pribadi" v-model="tempForm.pribadi.agama" class="edit-input" />
              <span v-else class="value">{{ employee.pribadi.agama }}</span>
            </div>

            <div class="detail-row">
              <span class="label">Golongan Darah</span>
              <span class="separator">:</span>
              <input v-if="isEditing.pribadi" v-model="tempForm.pribadi.golongan_darah" class="edit-input" />
              <span v-else class="value">{{ employee.pribadi.golongan_darah }}</span>
            </div>

            <div class="detail-row">
              <span class="label">Status Pernikahan</span>
              <span class="separator">:</span>
              <input v-if="isEditing.pribadi" v-model="tempForm.pribadi.status_pernikahan" class="edit-input" />
              <span v-else class="value">{{ employee.pribadi.status_pernikahan }}</span>
            </div>
          </div>
        </div>
      </div>

      <!-- SECTION 3: Kontak & Alamat -->
      <div class="biodata-section">
        <div class="section-header" @click="toggleAccordion('kontak')">
          <div class="section-title">
            <h4>Kontak & Alamat</h4>
          </div>
          <div class="section-actions" @click.stop>
            <template v-if="isEditing.kontak">
              <button class="btn-sec-cancel" @click="cancelEdit('kontak')">Batal</button>
              <button class="btn-sec-save" @click="saveEdit('kontak')">Simpan</button>
            </template>
            <template v-else>
              <button class="btn-sec-edit" @click="startEdit('kontak')">
                <Icon icon="material-symbols:edit-outline-rounded" width="16" height="16" />
                Edit
              </button>
              <button class="btn-collapse" @click="toggleAccordion('kontak')">
                <Icon :icon="isOpen.kontak ? 'material-symbols:keyboard-arrow-up-rounded' : 'material-symbols:keyboard-arrow-down-rounded'" width="22" height="22" />
              </button>
            </template>
          </div>
        </div>

        <div v-show="isOpen.kontak" class="section-body">
          <div class="details-grid">
            <div class="detail-row">
              <span class="label">No. Hp / Telepon</span>
              <span class="separator">:</span>
              <input v-if="isEditing.kontak" v-model="tempForm.kontak.no_hp" class="edit-input" />
              <span v-else class="value">{{ employee.kontak.no_hp }}</span>
            </div>

            <div class="detail-row">
              <span class="label">Email</span>
              <span class="separator">:</span>
              <input v-if="isEditing.kontak" v-model="tempForm.kontak.email" class="edit-input" />
              <span v-else class="value">{{ employee.kontak.email }}</span>
            </div>

            <div class="detail-row">
              <span class="label">Alamat Lengkap</span>
              <span class="separator">:</span>
              <input v-if="isEditing.kontak" v-model="tempForm.kontak.alamat_lengkap" class="edit-input" />
              <span v-else class="value">{{ employee.kontak.alamat_lengkap }}</span>
            </div>

            <div class="detail-row">
              <span class="label">Kontak Darurat</span>
              <span class="separator">:</span>
              <input v-if="isEditing.kontak" v-model="tempForm.kontak.kontak_darurat" class="edit-input" />
              <span v-else class="value">{{ employee.kontak.kontak_darurat }}</span>
            </div>
          </div>
        </div>
      </div>

      <!-- SECTION 4: Rekening & BPJS -->
      <div class="biodata-section">
        <div class="section-header" @click="toggleAccordion('rekening')">
          <div class="section-title">
            <h4>Rekening & BPJS</h4>
          </div>
          <div class="section-actions" @click.stop>
            <template v-if="isEditing.rekening">
              <button class="btn-sec-cancel" @click="cancelEdit('rekening')">Batal</button>
              <button class="btn-sec-save" @click="saveEdit('rekening')">Simpan</button>
            </template>
            <template v-else>
              <button class="btn-sec-edit" @click="startEdit('rekening')">
                <Icon icon="material-symbols:edit-outline-rounded" width="16" height="16" />
                Edit
              </button>
              <button class="btn-collapse" @click="toggleAccordion('rekening')">
                <Icon :icon="isOpen.rekening ? 'material-symbols:keyboard-arrow-up-rounded' : 'material-symbols:keyboard-arrow-down-rounded'" width="22" height="22" />
              </button>
            </template>
          </div>
        </div>

        <div v-show="isOpen.rekening" class="section-body">
          <div class="details-grid">
            <div class="detail-row">
              <span class="label">Nama Bank</span>
              <span class="separator">:</span>
              <input v-if="isEditing.rekening" v-model="tempForm.rekening.nama_bank" class="edit-input" />
              <span v-else class="value">{{ employee.rekening.nama_bank }}</span>
            </div>

            <div class="detail-row">
              <span class="label">No. Rekening</span>
              <span class="separator">:</span>
              <input v-if="isEditing.rekening" v-model="tempForm.rekening.no_rekening" class="edit-input" />
              <span v-else class="value">{{ employee.rekening.no_rekening }}</span>
            </div>

            <div class="detail-row">
              <span class="label">Atas Nama Rekening</span>
              <span class="separator">:</span>
              <input v-if="isEditing.rekening" v-model="tempForm.rekening.atas_nama" class="edit-input" />
              <span v-else class="value">{{ employee.rekening.atas_nama }}</span>
            </div>

            <div class="detail-row">
              <span class="label">Kode PTKP / NPWP</span>
              <span class="separator">:</span>
              <input v-if="isEditing.rekening" v-model="tempForm.rekening.kode_ptkp" class="edit-input" />
              <span v-else class="value">{{ employee.rekening.kode_ptkp }}</span>
            </div>

            <div class="detail-row">
              <span class="label">BPJS Ketenagakerjaan</span>
              <span class="separator">:</span>
              <input v-if="isEditing.rekening" v-model="tempForm.rekening.bpjs_tk" class="edit-input" />
              <span v-else class="value">{{ employee.rekening.bpjs_tk }}</span>
            </div>

            <div class="detail-row">
              <span class="label">BPJS Kesehatan</span>
              <span class="separator">:</span>
              <input v-if="isEditing.rekening" v-model="tempForm.rekening.bpjs_kes" class="edit-input" />
              <span v-else class="value">{{ employee.rekening.bpjs_kes }}</span>
            </div>
          </div>
        </div>
      </div>

      <!-- SECTION 5: Pendidikan & Keluarga -->
      <div class="biodata-section">
        <div class="section-header" @click="toggleAccordion('pendidikan')">
          <div class="section-title">
            <h4>Pendidikan & Keluarga</h4>
          </div>
          <div class="section-actions" @click.stop>
            <template v-if="isEditing.pendidikan">
              <button class="btn-sec-cancel" @click="cancelEdit('pendidikan')">Batal</button>
              <button class="btn-sec-save" @click="saveEdit('pendidikan')">Simpan</button>
            </template>
            <template v-else>
              <button class="btn-sec-edit" @click="startEdit('pendidikan')">
                <Icon icon="material-symbols:edit-outline-rounded" width="16" height="16" />
                Edit
              </button>
              <button class="btn-collapse" @click="toggleAccordion('pendidikan')">
                <Icon :icon="isOpen.pendidikan ? 'material-symbols:keyboard-arrow-up-rounded' : 'material-symbols:keyboard-arrow-down-rounded'" width="22" height="22" />
              </button>
            </template>
          </div>
        </div>

        <div v-show="isOpen.pendidikan" class="section-body">
          <div class="details-grid">
            <div class="detail-row">
              <span class="label">Pendidikan Terakhir</span>
              <span class="separator">:</span>
              <input v-if="isEditing.pendidikan" v-model="tempForm.pendidikan.pendidikan_terakhir" class="edit-input" />
              <span v-else class="value">{{ employee.pendidikan.pendidikan_terakhir }}</span>
            </div>

            <div class="detail-row">
              <span class="label">Institusi / Sekolah</span>
              <span class="separator">:</span>
              <input v-if="isEditing.pendidikan" v-model="tempForm.pendidikan.institusi" class="edit-input" />
              <span v-else class="value">{{ employee.pendidikan.institusi }}</span>
            </div>

            <div class="detail-row">
              <span class="label">Sertifikasi</span>
              <span class="separator">:</span>
              <input v-if="isEditing.pendidikan" v-model="tempForm.pendidikan.sertifikasi" class="edit-input" />
              <span v-else class="value">{{ employee.pendidikan.sertifikasi }}</span>
            </div>

            <div class="detail-row">
              <span class="label">Nama Pasangan</span>
              <span class="separator">:</span>
              <input v-if="isEditing.pendidikan" v-model="tempForm.pendidikan.nama_pasangan" class="edit-input" />
              <span v-else class="value">{{ employee.pendidikan.nama_pasangan }}</span>
            </div>

            <div class="detail-row">
              <span class="label">Nama Ayah</span>
              <span class="separator">:</span>
              <input v-if="isEditing.pendidikan" v-model="tempForm.pendidikan.nama_ayah" class="edit-input" />
              <span v-else class="value">{{ employee.pendidikan.nama_ayah }}</span>
            </div>

            <div class="detail-row">
              <span class="label">Nama Ibu</span>
              <span class="separator">:</span>
              <input v-if="isEditing.pendidikan" v-model="tempForm.pendidikan.nama_ibu" class="edit-input" />
              <span v-else class="value">{{ employee.pendidikan.nama_ibu }}</span>
            </div>

            <div class="detail-row">
              <span class="label">Jumlah Anak</span>
              <span class="separator">:</span>
              <input v-if="isEditing.pendidikan" v-model="tempForm.pendidikan.jumlah_anak" class="edit-input" />
              <span v-else class="value">{{ employee.pendidikan.jumlah_anak }}</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.biodata-view {
  --blue-900: #2f3b69;
  --ink: #1c1c19;
  --ink-soft: #667085;
  --line: #d9dde5;
  --bg: #f7f8fa;
  --card: #ffffff;
  font-family: 'Plus Jakarta Sans', sans-serif;
  max-width: 900px;
}

.biodata-view * {
  box-sizing: border-box;
  font-family: 'Plus Jakarta Sans', sans-serif;
}

/* Page Title Bar */
.page-title-bar {
  display: flex;
  align-items: center;
  gap: 12px;
  margin-bottom: 24px;
}

.btn-back {
  border: none;
  background: transparent;
  color: var(--ink);
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 4px;
  border-radius: 8px;
}

.btn-back:hover {
  background: var(--line);
}

.page-title-bar h2 {
  margin: 0;
  font-size: 20px;
  font-weight: 700;
  color: var(--ink);
}

.biodata-container {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

/* Card Profile Banner (Warna Biru Header Persis Gambar) */
.profile-card {
  background: var(--blue-900);
  border-radius: 16px;
  padding: 24px 32px;
  display: flex;
  align-items: center;
  gap: 24px;
  color: #ffffff;
}

.profile-avatar {
  width: 90px;
  height: 90px;
  border-radius: 50%;
  object-fit: cover;
  border: 3px solid rgba(255, 255, 255, 0.2);
}

.profile-info h3 {
  margin: 0 0 4px 0;
  font-size: 22px;
  font-weight: 700;
}

.profile-email {
  margin: 0 0 10px 0;
  font-size: 14px;
  opacity: 0.85;
}

.profile-meta {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 13px;
  opacity: 0.9;
}

.meta-divider {
  opacity: 0.5;
}

.meta-item {
  display: flex;
  align-items: center;
  gap: 4px;
}

/* Section Box */
.biodata-section {
  background: var(--card);
  border: 1px solid var(--line);
  border-radius: 16px;
  overflow: hidden;
}

.section-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 16px 24px;
  background: #ffffff;
  cursor: pointer;
  user-select: none;
}

.section-title h4 {
  margin: 0;
  font-size: 16px;
  font-weight: 700;
  color: var(--blue-900);
}

.section-actions {
  display: flex;
  align-items: center;
  gap: 8px;
}

.btn-sec-edit {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  border: none;
  background: #edf4ff;
  color: #1d4ed8;
  padding: 6px 12px;
  border-radius: 6px;
  font-size: 13px;
  font-weight: 600;
  cursor: pointer;
}

.btn-sec-edit:hover {
  background: #dfeeff;
}

.btn-sec-cancel {
  border: 1px solid var(--line);
  background: #fff;
  color: var(--ink);
  padding: 6px 12px;
  border-radius: 6px;
  font-size: 13px;
  font-weight: 600;
  cursor: pointer;
}

.btn-sec-save {
  border: none;
  background: var(--blue-900);
  color: #fff;
  padding: 6px 14px;
  border-radius: 6px;
  font-size: 13px;
  font-weight: 600;
  cursor: pointer;
}

.btn-collapse {
  border: none;
  background: transparent;
  color: var(--ink-soft);
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
}

/* Section Body & Detail List Grid */
.section-body {
  padding: 0 24px 20px;
  border-top: 1px solid #f1f5f9;
}

.details-grid {
  display: flex;
  flex-direction: column;
  gap: 12px;
  padding-top: 16px;
}

.detail-row {
  display: flex;
  align-items: center;
  font-size: 14px;
}

.label {
  width: 200px;
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
}

.edit-input {
  border: 1.5px solid #cbd5e1;
  border-radius: 6px;
  padding: 6px 10px;
  font-size: 13.5px;
  color: var(--ink);
  outline: none;
  max-width: 320px;
  width: 100%;
}

.edit-input:focus {
  border-color: var(--blue-900);
}

/* Toast Notifikasi Melayang */
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

.toast.success { background: #1f9d67; }
.toast.error { background: #d92d20; }

@keyframes toastIn {
  from { opacity: 0; transform: translate(-50%, -20px); }
  to { opacity: 1; transform: translate(-50%, 0); }
}

@media (max-width: 640px) {
  .detail-row {
    flex-direction: column;
    align-items: flex-start;
    gap: 4px;
  }
  .label {
    width: 100%;
  }
  .separator {
    display: none;
  }
  .profile-card {
    flex-direction: column;
    text-align: center;
  }
}
</style>