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
const photoError = ref('')
let currentPhotoObjectUrl = null

const checkInPhotoUrl = computed(() => photoUrl.value)

async function loadAttendancePhoto(attendanceId) {
  photoError.value = ''
  photoUrl.value = null

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

async function fetchAttendanceDetail() {
  loading.value = true
  error.value = ''
  photoError.value = ''
  try {
    const res = await api.get(`/attendances/${id}`)
    attendance.value = res.data
    if (attendance.value?.id) {
      await loadAttendancePhoto(attendance.value.id)
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
})

onMounted(() => {
  fetchAttendanceDetail()
})
</script>

<template>
  <div class="detail-absen-page">
    <section class="detail-layout">
      <div class="detail-header">
        <button class="icon-btn" @click="router.back()">
          <Icon icon="material-symbols:arrow-back-rounded" width="20" height="20" />
        </button>
        <div class="panel-head-title">
          <h2>Detail Absensi</h2>
          <p>ID: {{ id }}</p>
        </div>
      </div>

      <div v-if="loading" class="empty-cell">Memuat detail...</div>
      <div v-else-if="error" class="empty-cell">{{ error }}</div>
      <div v-else-if="attendance" class="detail-grid">
        <div class="detail-info">
          <div class="info-row"><span class="label">Nama</span><span class="value">{{ attendance.employee?.name || '-' }}</span></div>
          <div class="info-row"><span class="label">Lokasi</span><span class="value">{{ attendance.location?.name || '-' }}</span></div>
          <div class="info-row"><span class="label">Waktu Check In</span><span class="value">{{ attendance.check_in_time ? new Date(attendance.check_in_time).toLocaleString() : '-' }}</span></div>
          <div class="info-row"><span class="label">Waktu Check Out</span><span class="value">{{ attendance.check_out_time ? new Date(attendance.check_out_time).toLocaleString() : '-' }}</span></div>
          <div class="info-row"><span class="label">Status</span><span class="value">{{ attendance.status || '-' }}</span></div>
        </div>

        <div class="detail-photo" v-if="checkInPhotoUrl">
          <div class="photo-heading">Foto Check In</div>
          <div class="photo-preview">
            <img :src="checkInPhotoUrl" alt="Foto Check In" />
          </div>
        </div>
      </div>
    </section>
  </div>
</template>

<style scoped>
.detail-absen-page {
  --green-900: #173d31;
  --ink: #1c2521;
  --ink-soft: #5b6864;
  --line: #e7e7e2;
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
</style>
