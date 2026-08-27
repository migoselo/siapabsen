<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { Icon } from '@iconify/vue'
import api from '../api'

const route = useRoute()
const router = useRouter()
const id = route.params.id

const attendance = ref(null)
const loading = ref(false)
const error = ref('')
const photoUrl = ref(null)
const checkoutPhotoUrl = ref(null)
const photoError = ref('')
let currentPhotoObjectUrl = null
let currentCheckoutPhotoObjectUrl = null

const checkInPhotoUrl = computed(() => photoUrl.value)
const checkOutPhotoSource = computed(() => attendance.value?.check_out_photo_url
  || attendance.value?.checkout_photo_url
  || attendance.value?.check_out_photo
  || attendance.value?.photo_checkout
  || attendance.value?.photo_checkout_url
  || attendance.value?.check_out_photo_path
  || attendance.value?.checkout_photo_path
  || attendance.value?.photo_out
  || attendance.value?.photo_out_url
  || attendance.value?.checkOutPhotoUrl)

function resolvePhotoUrl(value) {
  if (value && typeof value === 'object') value = value.url || value.path || value.src
  if (!value || typeof value !== 'string') return null
  if (/^https?:\/\//i.test(value) || value.startsWith('blob:') || value.startsWith('data:')) return value
  const baseUrl = api.defaults.baseURL?.replace(/\/api\/?$/, '') || ''
  return `${baseUrl}/${value.replace(/^\/+/, '')}`
}

const formattedDate = computed(() => {
  const value = attendance.value?.check_in_time || attendance.value?.check_out_time
  return value ? new Date(value).toLocaleDateString('id-ID', { weekday: 'long', day: 'numeric', month: 'long', year: 'numeric' }) : '-'
})

const statusLabel = computed(() => {
  const status = String(attendance.value?.status || '').toLowerCase()
  if (status === 'lembur' || status === 'overtime') return 'Lembur'
  if (!attendance.value?.check_in_time) return 'Lupa Absen'
  return new Date(attendance.value.check_in_time).getHours() >= 9 ? 'Terlambat' : 'Tepat Waktu'
})

const statusClass = computed(() => statusLabel.value.toLowerCase().replace(' ', '-'))

const checkInCoordinates = computed(() => attendance.value?.check_in_location || attendance.value?.checkin_location || {})
const checkOutCoordinates = computed(() => attendance.value?.check_out_location || attendance.value?.checkout_location || {})
const checkInLatitude = computed(() => attendance.value?.check_in_latitude || attendance.value?.checkin_latitude || attendance.value?.check_in_lat || checkInCoordinates.value.latitude || attendance.value?.latitude || attendance.value?.lat || '-')
const checkInLongitude = computed(() => attendance.value?.check_in_longitude || attendance.value?.checkin_longitude || attendance.value?.check_in_lng || checkInCoordinates.value.longitude || attendance.value?.longitude || attendance.value?.lng || '-')
const checkOutLatitude = computed(() => attendance.value?.check_out_latitude || attendance.value?.checkout_latitude || attendance.value?.check_out_lat || checkOutCoordinates.value.latitude || attendance.value?.latitude || attendance.value?.lat || '-')
const checkOutLongitude = computed(() => attendance.value?.check_out_longitude || attendance.value?.checkout_longitude || attendance.value?.check_out_lng || checkOutCoordinates.value.longitude || attendance.value?.longitude || attendance.value?.lng || '-')

const totalDuration = computed(() => {
  if (!attendance.value?.check_in_time || !attendance.value?.check_out_time) return '-'
  const minutes = Math.max(0, Math.round((new Date(attendance.value.check_out_time) - new Date(attendance.value.check_in_time)) / 60000))
  return `${Math.floor(minutes / 60)}j ${String(minutes % 60).padStart(2, '0')}m`
})

function formatDateTime(value) {
  return value ? new Date(value).toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit' }) : '--:--'
}

async function loadAttendancePhoto(attendanceId) {
  photoError.value = ''
  photoUrl.value = null

  if (!attendance.value?.photo_available) {
    return
  }

  try {
    const response = await api.get(`/attendances/${attendanceId}/photo`, {
      responseType: 'blob',
    })

    if (currentPhotoObjectUrl) {
      URL.revokeObjectURL(currentPhotoObjectUrl)
    }

    currentPhotoObjectUrl = URL.createObjectURL(response.data)
    photoUrl.value = currentPhotoObjectUrl
  } catch (err) {
    console.error('Gagal memuat foto check-in:', err)
    photoError.value = 'Foto check-in tidak dapat dimuat.'
  }
}

async function loadCheckoutPhoto(attendanceId) {
  checkoutPhotoUrl.value = resolvePhotoUrl(checkOutPhotoSource.value)
  if (checkoutPhotoUrl.value) return

  const endpoints = [
    `/attendances/${attendanceId}/checkout-photo`,
    `/attendances/${attendanceId}/photo-checkout`,
    `/attendances/${attendanceId}/check-out-photo`,
    `/attendances/${attendanceId}/photo?type=checkout`,
    `/attendances/${attendanceId}/photo?photo_type=checkout`,
  ]

  for (const endpoint of endpoints) {
    try {
      const response = await api.get(endpoint, { responseType: 'blob' })
      if (currentCheckoutPhotoObjectUrl) URL.revokeObjectURL(currentCheckoutPhotoObjectUrl)
      currentCheckoutPhotoObjectUrl = URL.createObjectURL(response.data)
      checkoutPhotoUrl.value = currentCheckoutPhotoObjectUrl
      return
    } catch (err) {
      // Coba nama endpoint berikutnya untuk kompatibilitas backend.
    }
  }
}

async function fetchAttendanceDetail() {
  loading.value = true
  error.value = ''
  photoError.value = ''
  try {
    const res = await api.get(`/attendances/${id}`)
    attendance.value = res.data
    if (attendance.value?.id) {
      await Promise.all([
        loadAttendancePhoto(attendance.value.id),
        loadCheckoutPhoto(attendance.value.id),
      ])
    }
  } catch (err) {
    console.error('Gagal mengambil detail absen:', err)
    error.value = 'Gagal memuat detail absensi.'
  } finally {
    loading.value = false
  }
}

onUnmounted(() => {
  if (currentPhotoObjectUrl) {
    URL.revokeObjectURL(currentPhotoObjectUrl)
  }
  if (currentCheckoutPhotoObjectUrl) {
    URL.revokeObjectURL(currentCheckoutPhotoObjectUrl)
  }
})

onMounted(() => {
  fetchAttendanceDetail()
})
</script>

<template>
  <div class="detail-absen-page">
    <div class="detail-heading">
      <button class="back-btn" @click="router.back()"><Icon icon="material-symbols:arrow-back-rounded" width="22" height="22" /></button>
      <h2>Detail Absensi</h2>
    </div>

    <div v-if="loading" class="empty-cell">Memuat detail...</div>
    <div v-else-if="error" class="empty-cell">{{ error }}</div>
    <section v-else-if="attendance" class="detail-layout">
      <div class="identity">
        <div><strong>{{ attendance.employee?.name || '-' }}</strong><span>{{ attendance.employee?.id || id }}</span><b>{{ formattedDate }}</b></div>
        <span class="status-pill" :class="statusClass">{{ statusLabel }}</span>
      </div>
      <div class="attendance-columns">
        <div class="attendance-event check-in">
          <h3><i></i>Check In - {{ formatDateTime(attendance.check_in_time) }}</h3>
          <div v-if="checkInPhotoUrl" class="photo-preview"><img :src="checkInPhotoUrl" alt="Foto Check In" /></div>
          <div v-else class="photo-empty">Foto check-in tidak tersedia</div>
          <div class="location-card"><strong>{{ attendance.location?.name || 'Lokasi tidak tersedia' }}</strong><span>{{ checkInLatitude }}, {{ checkInLongitude }}</span><b>Jarak lokasi</b><em>{{ attendance.check_in_distance || attendance.checkin_distance || attendance.check_in_distance_meter || attendance.distance_meter || '-' }}{{ (attendance.check_in_distance || attendance.checkin_distance || attendance.check_in_distance_meter || attendance.distance_meter) ? ' Meter' : '' }}</em></div>
        </div>
        <div class="attendance-event check-out">
          <h3><i></i>Check Out - {{ formatDateTime(attendance.check_out_time) }}</h3>
          <div v-if="checkoutPhotoUrl" class="photo-preview"><img :src="checkoutPhotoUrl" alt="Foto Check Out" /></div>
          <div v-else class="photo-empty">{{ attendance.check_out_time ? 'Foto check-out tidak tersedia' : 'Belum melakukan check-out' }}</div>
          <div class="location-card"><strong>{{ attendance.location?.name || 'Lokasi tidak tersedia' }}</strong><span>{{ checkOutLatitude }}, {{ checkOutLongitude }}</span><b>Jarak lokasi</b><em>{{ attendance.check_out_distance || attendance.checkout_distance || attendance.check_out_distance_meter || attendance.distance_meter || '-' }}{{ (attendance.check_out_distance || attendance.checkout_distance || attendance.check_out_distance_meter || attendance.distance_meter) ? ' Meter' : '' }}</em></div>
        </div>
      </div>
      <div class="summary-card"><small>RINGKASAN HARI INI</small><div><span>Total Jam Kerja<strong>{{ totalDuration }}</strong></span><span>Durasi<strong>{{ totalDuration }}</strong></span></div></div>
    </section>
  </div>
</template>

<style scoped>
.detail-absen-page {
  --blue-900: #2f3b69;
  --ink: #1c1c19;
  --ink-soft: #667085;
  --line: #d9dde5;
  --card: #ffffff;
  padding: 24px;
  min-height: calc(100vh - 80px);
}
.detail-absen-page * {
  box-sizing: border-box;
}
.detail-layout {
  background: var(--card);
  border: 1px solid var(--line);
  border-radius: 20px;
  padding: 24px;
  max-width: 1040px;
  margin: 0 auto;
}
.detail-header {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-bottom: 8px;
}
.panel-head-title {
  display: flex;
  flex-direction: column;
  gap: 2px;
}
.detail-header h2 {
  margin: 0;
  font-size: 18px;
  line-height: 1.15;
  font-weight: 700;
}
.detail-header p {
  margin: 0;
  color: var(--ink-soft);
  font-size: 13px;
  opacity: 0.9;
}
.icon-btn {
  width: 44px;
  height: 44px;
  border-radius: 12px;
  border: 1px solid var(--line);
  background: #fff;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
}
.detail-grid {
  display: grid;
  grid-template-columns: 1.2fr 1fr;
  gap: 24px;
  align-items: start;
}
.detail-info {
  display: grid;
  gap: 10px;
}
.info-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 10px 0;
  border-bottom: 1px solid var(--line);
}
.info-row:last-child {
  border-bottom: none;
}
.label {
  color: var(--ink-soft);
  font-weight: 700;
  min-width: 150px;
}
.value {
  color: var(--ink);
  text-align: right;
  max-width: 320px;
  word-wrap: break-word;
}
.detail-photo {
  display: flex;
  flex-direction: column;
  gap: 12px;
}
.photo-heading {
  font-weight: 600;
  color: var(--ink-soft);
}
.empty-cell {
  text-align: center;
  color: var(--ink-soft);
  padding: 32px;
}
.photo-preview {
  width: 100%;
  overflow: hidden;
  border-radius: 14px;
}
.photo-preview img {
  width: 100%;
  height: auto;
  display: block;
  border-radius: 14px;
  border: 1px solid var(--line);
  object-fit: contain;
  max-height: 320px;
}

.detail-absen-page {
  --success: #16b364;
  --warning: #a26c00;
  --warning-bg: #fff0c7;
  font-family: 'Plus Jakarta Sans', sans-serif;
  padding: 26px 32px 56px;
  background: #fff;
}
.detail-absen-page * { font-family: inherit; }
.detail-heading { max-width: 1100px; margin: 0 auto 24px; display: flex; align-items: center; gap: 10px; }
.back-btn { border: 0; background: transparent; padding: 0; display: grid; place-items: center; cursor: pointer; color: var(--ink); }
.detail-heading h2 { margin: 0; font-size: 26px; font-weight: 700; }
.detail-layout { padding: 0; overflow: hidden; border-radius: 14px; max-width: 1100px; }
.identity { display: flex; justify-content: space-between; align-items: flex-start; padding: 24px 28px; background: #f0f1f1; border-bottom: 1px solid var(--line); }
.identity div { display: grid; gap: 7px; }
.identity strong { font-size: 18px; }
.identity span { font-size: 16px; font-weight: 600; }
.identity b { font-size: 16px; }
.status-pill { padding: 9px 18px; border-radius: 999px; font-size: 13px !important; color: var(--success); background: #dcf8e5; }
.status-pill.terlambat { color: var(--warning); background: var(--warning-bg); }
.status-pill.lupa-absen { color: #c91f2d; background: #fde0e2; }
.status-pill.lembur { color: var(--blue-900); background: #dce6ff; }
.attendance-columns { display: grid; grid-template-columns: 1fr 1fr; }
.attendance-event { padding: 30px 72px; min-width: 0; }
.attendance-event + .attendance-event { border-left: 1px solid var(--line); }
.attendance-event h3 { display: flex; align-items: center; gap: 10px; margin: 0 0 18px; font-size: 16px; color: var(--blue-900); }
.attendance-event.check-in h3 { color: var(--success); }
.attendance-event h3 i { display: block; width: 7px; height: 22px; border-radius: 4px; background: currentColor; }
.photo-preview, .photo-empty { width: 100%; min-height: 150px; border-radius: 10px; overflow: hidden; }
.photo-preview { display: flex; align-items: center; justify-content: center; background: #f7f8fa; }
.photo-preview img { display: block; width: auto; height: auto; max-width: 100%; max-height: 280px; object-fit: contain; border: 0; border-radius: 0; }
.photo-empty { display: grid; place-items: center; padding: 16px; color: var(--ink-soft); background: #f7f8fa; border: 1px dashed var(--line); text-align: center; font-size: 14px; }
.location-card { margin-top: 14px; padding: 16px; min-height: 70px; display: grid; grid-template-columns: 1fr auto; gap: 6px 14px; border: 1px solid var(--line); border-radius: 10px; }
.location-card strong { grid-column: 1 / -1; font-size: 13px; text-transform: uppercase; }
.location-card span { font-size: 12px; color: var(--ink-soft); }
.location-card b { font-size: 10px; text-align: right; text-transform: uppercase; }
.location-card em { grid-column: 2; color: var(--blue-900); font-size: 14px; font-style: normal; font-weight: 700; text-align: right; }
.summary-card { padding: 18px 28px; color: #fff; background: var(--blue-900); }
.summary-card > small { color: #cbd2eb; font-size: 11px; font-weight: 700; letter-spacing: .08em; }
.summary-card > div { display: flex; gap: 24px; margin-top: 8px; }
.summary-card > div span { display: grid; gap: 3px; padding-right: 24px; border-right: 1px solid rgba(255,255,255,.35); color: #cbd2eb; font-size: 11px; }
.summary-card > div span:last-child { border-right: 0; }
.summary-card strong { color: #fff; font-size: 21px; }
@media (max-width: 760px) {
  .detail-absen-page { padding: 20px 16px 40px; }
  .attendance-columns { grid-template-columns: 1fr; }
  .attendance-event { padding: 20px; }
  .attendance-event + .attendance-event { border-left: 0; border-top: 1px solid var(--line); }
}
</style>
