<script setup>
import { ref, reactive, onMounted, computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { Icon } from '@iconify/vue'
import api from '../api'

// Import Base Components
import BasePageHeader from '../components/BasePageHeader.vue'
import BaseSelect from '../components/BaseSelect.vue'
import BaseButton from '../components/BaseButton.vue'
import { useConfirm } from '../composables/UseConfirm'
import GlobalConfirm from '../components/GlobalConfirm.vue'

const route = useRoute()
const router = useRouter()
const { showConfirm } = useConfirm()

const toast = ref({ show: false, type: 'success', message: '' })
let toastTimer = null
const loading = ref(true)
const deleting = ref(false)
const savingSection = ref(null)

// State untuk menyimpan data dari KelolaDivisiShift
const divisions = ref([]) 
const shifts = ref([])
const locations = ref([])

// Format opsi agar kompatibel dengan BaseSelect (array of objects {label, value})
const divisionOptions = computed(() => {
  return divisions.value.map((division) => ({
    label: division.name,
    value: Number(division.id),
  }))
})

const shiftOptions = computed(() => {
  return shifts.value.map(s => {
    const start = s.work_start_time ? String(s.work_start_time).slice(0, 5) : ''
    const end = s.work_end_time ? String(s.work_end_time).slice(0, 5) : ''
    const timeLabel = start && end ? ` (${start} - ${end})` : ''
    return { label: `${s.name}${timeLabel}`, value: s.id }
  })
})

const locationOptions = computed(() => locations.value.map((location) => ({
  label: location.name,
  value: Number(location.id),
})))

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
  avatar_url: null,
  home_location_id: null, 
  pekerjaan: {
    id_karyawan: '-',
    nama_panggilan: '-',
    departemen: '-',
    jabatan: '-',
    divisi: '-',
    divisi_id: '', 
    shift: '-',
    shift_id: '',
    golongan: '-',
    cabang: '-',
    cabang_id: '',
    tipe_karyawan: '-',
    tanggal_bergabung: '-',
  },
  pribadi: {
    nik: '-',
    tempat_tanggal_lahir: '-',
    tempat_lahir: '',
    tanggal_lahir: '',
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
    nama_bank: '-',
    no_rekening: '-',
    atas_nama: '-',
    kode_ptkp: '-',
    bpjs_tk: '-',
    bpjs_kes: '-',
  },
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
  isOpen[section] = true
  isEditing[section] = true
  tempForm[section] = JSON.parse(JSON.stringify(employee[section]))
}

function cancelEdit(section) {
  isEditing[section] = false
  delete tempForm[section]
}

async function saveEdit(section) {
  if (savingSection.value) return
  savingSection.value = section

  try {
    const valueOrNull = (value) => value === '-' || value === '' || value == null ? null : value
    let payload

    if (section === 'pekerjaan') {
      const form = tempForm.pekerjaan
      payload = {
        employee_id: valueOrNull(form.id_karyawan),
        name: valueOrNull(form.nama_panggilan),
        department: valueOrNull(form.departemen),
        division_id: form.divisi_id ? Number(form.divisi_id) : null,
        shift_id: form.shift_id ? Number(form.shift_id) : null,
        role: String(form.jabatan || '').trim().toLowerCase(),
        grade: valueOrNull(form.golongan),
        home_location_id: form.cabang_id ? Number(form.cabang_id) : null,
        employee_type: valueOrNull(form.tipe_karyawan),
        joined_at: valueOrNull(form.tanggal_bergabung),
      }
    } else if (section === 'pribadi') {
      const form = tempForm.pribadi
      payload = {
        nik: valueOrNull(form.nik),
        birth_place: valueOrNull(form.tempat_lahir),
        birth_date: valueOrNull(form.tanggal_lahir),
        gender: valueOrNull(form.jenis_kelamin),
        religion: valueOrNull(form.agama),
        blood_type: valueOrNull(form.golongan_darah),
        marital_status: valueOrNull(form.status_pernikahan),
      }
    } else if (section === 'kontak') {
      const form = tempForm.kontak
      payload = {
        no_hp: valueOrNull(form.no_hp),
        email: valueOrNull(form.email),
        address: valueOrNull(form.alamat_lengkap),
        emergency_contact: valueOrNull(form.kontak_darurat),
      }
    } else if (section === 'rekening') {
      const form = tempForm.rekening
      payload = {
        bank_name: valueOrNull(form.nama_bank),
        bank_account_number: valueOrNull(form.no_rekening),
        bank_account_name: valueOrNull(form.atas_nama),
        tax_number: valueOrNull(form.kode_ptkp),
        bpjs_employment: valueOrNull(form.bpjs_tk),
        bpjs_health: valueOrNull(form.bpjs_kes),
      }
    } else {
      const form = tempForm.pendidikan
      payload = {
        last_education: valueOrNull(form.pendidikan_terakhir),
        education_institution: valueOrNull(form.institusi),
        certification: valueOrNull(form.sertifikasi),
        spouse_name: valueOrNull(form.nama_pasangan),
        father_name: valueOrNull(form.nama_ayah),
        mother_name: valueOrNull(form.nama_ibu),
        children_count: form.jumlah_anak === '-' || form.jumlah_anak === ''
          ? null
          : Number(form.jumlah_anak),
      }
    }

    const config = route.query.tenant_id
      ? { params: { tenant_id: route.query.tenant_id } }
      : undefined
    const response = await api.put(`/users/${employee.id}`, payload, config)
    mapEmployee(response.data)
    isEditing[section] = false
    delete tempForm[section]
    showToast('Perubahan data berhasil disimpan.')
  } catch (err) {
    console.error('Gagal menyimpan biodata karyawan:', err)
    const validationErrors = Object.values(err.response?.data?.errors || {}).flat()
    showToast(
      validationErrors.join(' ') || err.response?.data?.message || 'Perubahan biodata gagal disimpan.',
      'error',
    )
  } finally {
    savingSection.value = null
  }
}

function goBack() {
  // Menggunakan history router bawaan agar kembali ke state/halaman sebelumnya secara presisi.
  // Jika tidak ada history (buka link langsung), fallback ke halaman daftar karyawan.
  if (window.history.length > 1) {
    router.back()
  } else {
    router.push({ 
      path: '/dashboard/karyawan', 
      query: { location_id: employee.home_location_id } 
    })
  }
}

async function deleteEmployee() {
  const ok = await showConfirm({
    title: 'Hapus Karyawan',
    message: 'Apakah Anda yakin ingin menghapus karyawan ini?',
    confirmText: 'Ya, Hapus',
    cancelText: 'Batal',
    type: 'danger',
  })
  if (!ok) return

  deleting.value = true
  try {
    await api.delete(`/users/${employee.id}`)
    showToast('Karyawan berhasil dihapus.')
    router.push({
      path: '/dashboard/karyawan',
      query: { location_id: employee.home_location_id },
    })
  } catch (err) {
    console.error('Gagal menghapus karyawan:', err)
    showToast(err.response?.data?.message || 'Gagal menghapus karyawan.', 'error')
  } finally {
    deleting.value = false
  }
}

function displayValue(value) {
  return value === null || value === undefined || value === '' ? '-' : String(value)
}

function roleLabel(role) {
  return role === 'admin' ? 'Admin' : role === 'karyawan' ? 'Karyawan' : displayValue(role)
}

function birthInfo(data) {
  const place = displayValue(data.birth_place)
  const date = displayValue(data.birth_date)
  if (place === '-' && date === '-') return '-'
  if (date === '-') return place
  if (place === '-') return date
  return `${place}, ${date}`
}

function initials(name) {
  return displayValue(name)
    .split(' ')
    .filter(Boolean)
    .map((part) => part[0])
    .slice(0, 2)
    .join('')
    .toUpperCase()
}

// Fetch Opsi Divisi & Shift secara paralel
async function fetchDivisionsAndShifts(tenantId = null) {
  try {
    const config = tenantId ? { params: { tenant_id: tenantId } } : {}
    const [divRes, shiftRes, locationRes] = await Promise.all([
      api.get('/divisions', config),
      api.get('/shifts', config),
      api.get('/locations', config),
    ])
    divisions.value = Array.isArray(divRes.data) ? divRes.data : []
    shifts.value = Array.isArray(shiftRes.data) ? shiftRes.data : []
    locations.value = Array.isArray(locationRes.data) ? locationRes.data : []
  } catch (err) {
    console.error('Gagal mengambil opsi divisi dan shift:', err)
  }
}

function mapEmployee(data) {
  const locationName = data.homeLocation?.name || data.home_location?.name || '-'
  const locationId = data.homeLocation?.id || data.home_location?.id || data.home_location_id || null
  const tenantId = data.homeLocation?.tenant_id || data.home_location?.tenant_id || data.tenant_id || null
  const name = displayValue(data.name)
  const role = roleLabel(data.role)
  
  // Mapping Divisi
  const divisionName = displayValue(data.division?.name ?? data.division_name ?? data.divisi)
  const divisionId = data.division?.id ?? data.division_id ?? ''

  // Mapping Shift
  const shiftName = displayValue(
    data.shift?.name 
      ? `${data.shift.name} (${String(data.shift.work_start_time).slice(0, 5)} - ${String(data.shift.work_end_time).slice(0, 5)})` 
      : data.shift_name ?? data.shift
  )
  const shiftId = data.shift?.id ?? data.shift_id ?? ''

  Object.assign(employee, {
    id: displayValue(data.id ?? route.params.id),
    name,
    email: displayValue(data.email),
    jabatan_header: role,
    lokasi_header: displayValue(locationName),
    avatar_url: data.avatar_url || data.avatar || null,
    home_location_id: locationId,
    pekerjaan: {
      id_karyawan: displayValue(data.employee_id || data.id),
      nama_panggilan: name,
      departemen: displayValue(data.department),
      divisi: divisionName,
      divisi_id: divisionId,
      shift: shiftName,
      shift_id: shiftId,
      jabatan: role,
      golongan: displayValue(data.grade),
      cabang: displayValue(locationName),
      cabang_id: locationId ?? '',
      tipe_karyawan: displayValue(data.employee_type),
      tanggal_bergabung: displayValue(data.joined_at),
    },
    pribadi: {
      nik: displayValue(data.nik),
      tempat_tanggal_lahir: birthInfo(data),
      tempat_lahir: data.birth_place || '',
      tanggal_lahir: data.birth_date || '',
      jenis_kelamin: displayValue(data.gender),
      agama: displayValue(data.religion),
      golongan_darah: displayValue(data.blood_type),
      status_pernikahan: displayValue(data.marital_status),
    },
    kontak: {
      no_hp: displayValue(data.no_hp),
      email: displayValue(data.email),
      alamat_lengkap: displayValue(data.address),
      kontak_darurat: displayValue(data.emergency_contact),
    },
    rekening: {
      nama_bank: displayValue(data.bank_name),
      no_rekening: displayValue(data.bank_account_number),
      atas_nama: displayValue(data.bank_account_name),
      kode_ptkp: displayValue(data.tax_number),
      bpjs_tk: displayValue(data.bpjs_employment),
      bpjs_kes: displayValue(data.bpjs_health),
    },
    pendidikan: {
      pendidikan_terakhir: displayValue(data.last_education),
      institusi: displayValue(data.education_institution),
      sertifikasi: displayValue(data.certification),
      nama_pasangan: displayValue(data.spouse_name),
      nama_ayah: displayValue(data.father_name),
      nama_ibu: displayValue(data.mother_name),
      jumlah_anak: displayValue(data.children_count),
    },
  })

  // Fetch daftar divisi & shift sesuai lokasi/tenant
  fetchDivisionsAndShifts(tenantId)
}

async function fetchEmployee() {
  loading.value = true
  try {
    try {
      const params = route.query.tenant_id
        ? { tenant_id: route.query.tenant_id }
        : undefined
      const res = await api.get(`/users/${route.params.id}`, { params })
      mapEmployee(res.data)
    } catch (err) {
      if (err.response?.status !== 404) throw err

      const listRes = await api.get('/users', {
        params: {
          per_page: 100,
          ...(route.query.tenant_id ? { tenant_id: route.query.tenant_id } : {}),
        },
      })
      const users = Array.isArray(listRes.data?.data) ? listRes.data.data : []
      const found = users.find(
        (item) =>
          String(item.id) === String(route.params.id) ||
          String(item.employee_id) === String(route.params.id),
      )

      if (!found) throw err
      mapEmployee(found)
    }
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

    <!-- Komponen GlobalConfirm untuk Modal Dialog -->
    <GlobalConfirm />

    <!-- Header Components -->
    <BasePageHeader title="Biodata Karyawan" @back="goBack">
      <BaseButton
        variant="danger"
        icon="material-symbols:delete-outline-rounded"
        :disabled="deleting"
        @click="deleteEmployee"
      >
        {{ deleting ? 'Menghapus...' : 'Hapus Karyawan' }}
      </BaseButton>
    </BasePageHeader>

    <div class="biodata-container">
      <!-- Profile Header -->
      <div class="profile-card">
        <img v-if="employee.avatar_url" :src="employee.avatar_url" alt="Avatar" class="profile-avatar" />
        <div v-else class="profile-avatar profile-initials">{{ initials(employee.name) }}</div>
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
              <button class="btn-sec-save" :disabled="Boolean(savingSection)" @click="saveEdit('pekerjaan')">
                {{ savingSection === 'pekerjaan' ? 'Menyimpan...' : 'Simpan' }}
              </button>
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
              <span class="label">Nama Lengkap</span>
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

            <!-- Divisi Dropdown (Terhubung ke KelolaDivisiShift) -->
            <div class="detail-row">
              <span class="label">Divisi</span>
              <span class="separator">:</span>
              <div v-if="isEditing.pekerjaan" class="edit-input-wrapper">
                <BaseSelect 
                  v-model="tempForm.pekerjaan.divisi_id" 
                  :options="divisionOptions" 
                  placeholder="Pilih Divisi" 
                />
              </div>
              <span v-else class="value">{{ employee.pekerjaan.divisi }}</span>
            </div>

            <!-- Jam Kerja / Shift Dropdown (Terhubung ke KelolaDivisiShift) -->
            <div class="detail-row">
              <span class="label">Jam Kerja / Shift</span>
              <span class="separator">:</span>
              <div v-if="isEditing.pekerjaan" class="edit-input-wrapper">
                <BaseSelect 
                  v-model="tempForm.pekerjaan.shift_id" 
                  :options="shiftOptions" 
                  placeholder="Gunakan Jam Lokasi" 
                />
              </div>
              <span v-else class="value">{{ employee.pekerjaan.shift }}</span>
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
              <div v-if="isEditing.pekerjaan" class="edit-input-wrapper">
                <BaseSelect
                  v-model="tempForm.pekerjaan.cabang_id"
                  :options="[
                    { label: 'Tanpa cabang', value: '' },
                    ...locationOptions,
                  ]"
                  placeholder="Pilih cabang"
                />
              </div>
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
              <button class="btn-sec-save" :disabled="Boolean(savingSection)" @click="saveEdit('pribadi')">
                {{ savingSection === 'pribadi' ? 'Menyimpan...' : 'Simpan' }}
              </button>
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

            <template v-if="isEditing.pribadi">
              <div class="detail-row">
                <span class="label">Tempat Lahir</span>
                <span class="separator">:</span>
                <input v-model="tempForm.pribadi.tempat_lahir" class="edit-input" />
              </div>
              <div class="detail-row">
                <span class="label">Tanggal Lahir</span>
                <span class="separator">:</span>
                <input type="date" v-model="tempForm.pribadi.tanggal_lahir" class="edit-input" />
              </div>
            </template>
            <div v-else class="detail-row">
              <span class="label">Tempat, Tanggal Lahir</span>
              <span class="separator">:</span>
              <span class="value">{{ employee.pribadi.tempat_tanggal_lahir }}</span>
            </div>

            <div class="detail-row">
              <span class="label">Jenis Kelamin</span>
              <span class="separator">:</span>
              <div v-if="isEditing.pribadi" class="edit-input-wrapper">
                <BaseSelect 
                  v-model="tempForm.pribadi.jenis_kelamin" 
                  :options="['Laki-laki', 'Perempuan']" 
                  placeholder="Pilih Gender" 
                />
              </div>
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
              <button class="btn-sec-save" :disabled="Boolean(savingSection)" @click="saveEdit('kontak')">
                {{ savingSection === 'kontak' ? 'Menyimpan...' : 'Simpan' }}
              </button>
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
              <button class="btn-sec-save" :disabled="Boolean(savingSection)" @click="saveEdit('rekening')">
                {{ savingSection === 'rekening' ? 'Menyimpan...' : 'Simpan' }}
              </button>
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
              <button class="btn-sec-save" :disabled="Boolean(savingSection)" @click="saveEdit('pendidikan')">
                {{ savingSection === 'pendidikan' ? 'Menyimpan...' : 'Simpan' }}
              </button>
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

.biodata-container {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

/* Card Profile Banner */
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

.profile-initials {
  display: flex;
  align-items: center;
  justify-content: center;
  background: rgba(255, 255, 255, 0.16);
  color: #ffffff;
  font-size: 28px;
  font-weight: 700;
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
.edit-input-wrapper {
  max-width: 320px;
  width: 100%;
}
.edit-input-wrapper :deep(.custom-select) {
  border: 1.5px solid #cbd5e1;
  border-radius: 6px;
  height: 34px; 
}
.edit-input:focus,
.edit-input-wrapper :deep(.custom-select):focus-within {
  border-color: var(--blue-900);
}

/* Toast Notifikasi */
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
  .label { width: 100%; }
  .separator { display: none; }
  .profile-card { flex-direction: column; text-align: center; }
  .edit-input-wrapper { max-width: 100%; }
}
</style>