<script setup>
/**
 * DetailLembur.vue
 * Halaman detail permohonan lembur karyawan.
 */
import { ref } from 'vue'
import { Icon } from '@iconify/vue'

const props = defineProps({
  request: {
    type: Object,
    required: true,
  },
})

const emit = defineEmits(['back', 'approve', 'reject'])

const comment = ref('')

function handleApprove() {
  emit('approve', { id: props.request.id, comment: comment.value })
}

function handleReject() {
  emit('reject', { id: props.request.id, comment: comment.value })
}
</script>

<template>
  <div class="detail-lembur">
    <!-- Tombol Kembali dan Judul sesuai referensi -->
    <div class="detail-header">
      <button class="back-btn" @click="$emit('back')" title="Kembali">
        <Icon icon="material-symbols:arrow-back" width="22" />
      </button>
      <h1 class="detail-title">Detail Lembur</h1>
    </div>

    <div class="detail-grid">
      <!-- Kolom Kiri -->
      <div class="detail-left">
        <!-- Informasi Karyawan -->
        <div class="card info-card">
          <p class="card-section-title">INFORMASI KARYAWAN</p>
          <div class="employee-info-row">
            <img
              v-if="request.employee.avatarUrl"
              :src="request.employee.avatarUrl"
              class="avatar-lg"
            />
            <div v-else class="avatar-lg avatar-fallback">
              {{ request.employee.name.split(' ').map(w => w[0]).slice(0, 2).join('').toUpperCase() }}
            </div>
            <div class="employee-details">
              <h2>{{ request.employee.name }}</h2>
              <p class="employee-position">{{ request.employee.position }}</p>
              
              <div class="employee-meta">
                <span><Icon icon="material-symbols:domain" width="16" /> {{ request.employee.department }}</span>
                <span><Icon icon="material-symbols:badge-outline" width="16" /> {{ request.employee.employeeId }}</span>
                <span><Icon icon="material-symbols:mail-outline" width="16" /> {{ request.employee.email }}</span>
              </div>
            </div>
          </div>
        </div>

        <!-- Detail Permohonan -->
        <div class="card">
          <p class="card-section-title">DETAIL PERMOHONAN</p>
          
          <div class="time-grid">
            <div class="time-box">
              <p class="time-label">Tanggal</p>
              <p class="time-val">{{ request.date }}</p>
            </div>
            <div class="time-box">
              <p class="time-label">Jam Mulai</p>
              <p class="time-val">{{ request.startTime }}</p>
            </div>
            <div class="time-box">
              <p class="time-label">Jam Selesai</p>
              <p class="time-val">{{ request.endTime }}</p>
            </div>
            <div class="time-box highlight-box">
              <p class="time-label highlight-label">Durasi</p>
              <p class="time-val highlight-val">{{ request.durationLabel }}</p>
            </div>
          </div>

          <p class="reason-title">Alasan Lembur</p>
          <div class="reason-box">
            {{ request.reason }}
          </div>
        </div>
      </div>

      <!-- Kolom Kanan -->
      <div class="detail-right">
        <!-- Tinjau Permohonan -->
        <div class="card review-card">
          <h3>Tinjau Permohonan</h3>
          <p class="review-desc">Silakan tinjau rincian yang diberikan dan setujui atau tolak pengajuan ini.</p>
          
          <label class="comment-label">Catatan</label>
          <textarea
            v-model="comment"
            class="comment-textarea"
            placeholder="Tambahkan komentar untuk karyawan.."
          ></textarea>

          <button class="btn-action btn-accept" @click="handleApprove">
            <Icon icon="material-symbols:check-circle-outline" width="18" /> Terima
          </button>
          <button class="btn-action btn-refuse" @click="handleReject">
            <Icon icon="material-symbols:cancel-outline" width="18" /> Tolak
          </button>
        </div>

        <!-- Konteks Bulanan -->
        <div class="monthly-context-card">
          <p class="monthly-title">KONTEKS BULANAN</p>
          
          <div class="monthly-row">
            <span>Total lembur bulanan</span>
            <span class="monthly-val">12.5 jam</span>
          </div>
          <div class="monthly-divider"></div>
          <div class="monthly-row">
            <span>Batas bulanan</span>
            <span class="monthly-val">40.0 jam</span>
          </div>

          <div class="progress-track">
            <div class="progress-fill" style="width: 31.25%;"></div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
@import url('https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap');

.detail-lembur {
  font-family: 'Plus Jakarta Sans', sans-serif;
  color: #2c3345;
  padding-bottom: 32px;
}

.detail-header {
  display: flex;
  align-items: center;
  gap: 16px;
  margin-bottom: 24px;
}

.back-btn {
  background: #ffffff;
  border: 1px solid #e4e7ec;
  border-radius: 10px;
  width: 40px;
  height: 40px;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  color: #2c3345;
  transition: background 0.2s;
}
.back-btn:hover {
  background: #f4f5f8;
}

.detail-title {
  font-size: 24px;
  font-weight: 700;
  margin: 0;
  color: #111827;
}

.detail-grid {
  display: grid;
  grid-template-columns: 2fr 1fr;
  gap: 24px;
  align-items: start;
}

.card {
  background: #ffffff;
  border: 1px solid #e4e7ec;
  border-radius: 16px;
  padding: 24px;
  margin-bottom: 24px;
}

.card-section-title {
  font-size: 12px;
  font-weight: 700;
  color: #667085;
  letter-spacing: 0.8px;
  margin: 0 0 20px 0;
}

/* Info Karyawan */
.info-card {
  position: relative;
  overflow: hidden;
}
.employee-info-row {
  display: flex;
  align-items: center;
  gap: 20px;
  position: relative;
  z-index: 1;
}
.avatar-lg {
  width: 64px;
  height: 64px;
  border-radius: 50%;
  object-fit: cover;
  flex-shrink: 0;
}
.avatar-fallback {
  background: #eaf0ff;
  color: #2a4365;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 18px;
  font-weight: 700;
}
.employee-details h2 {
  font-size: 18px;
  font-weight: 700;
  margin: 0 0 4px 0;
}
.employee-position {
  font-size: 14px;
  color: #667085;
  margin: 0 0 12px 0;
}
.employee-meta {
  display: flex;
  flex-wrap: wrap;
  gap: 16px;
  font-size: 13px;
  color: #667085;
}
.employee-meta span {
  display: flex;
  align-items: center;
  gap: 6px;
}

/* Time Grid */
.time-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 12px;
  margin-bottom: 24px;
}
.time-box {
  background: #f8fafc;
  border: 1px solid #f1f5f9;
  border-radius: 10px;
  padding: 14px;
}
.time-label {
  font-size: 12px;
  color: #667085;
  margin: 0 0 6px 0;
}
.time-val {
  font-size: 15px;
  font-weight: 700;
  color: #111827;
  margin: 0;
  white-space: pre-line;
}
.highlight-box {
  background: #eaf0ff;
  border-color: #c7d7fe;
}
.highlight-label {
  color: #2a4365;
  font-weight: 600;
}
.highlight-val {
  color: #1e3a8a;
}

.reason-title {
  font-size: 14px;
  font-weight: 600;
  color: #111827;
  margin: 0 0 8px 0;
}
.reason-box {
  background: #f8fafc;
  border: 1px solid #e4e7ec;
  border-radius: 10px;
  padding: 16px;
  font-size: 14px;
  line-height: 1.6;
  color: #334155;
}

/* Review Card (Right) */
.review-card h3 {
  font-size: 18px;
  font-weight: 700;
  margin: 0 0 6px 0;
}
.review-desc {
  font-size: 13px;
  color: #667085;
  margin: 0 0 16px 0;
  line-height: 1.5;
}
.comment-label {
  display: block;
  font-size: 12px;
  font-weight: 600;
  color: #334155;
  margin-bottom: 6px;
}
.comment-textarea {
  width: 100%;
  height: 110px;
  padding: 12px;
  border: 1px solid #e4e7ec;
  border-radius: 10px;
  font-size: 13px;
  font-family: inherit;
  resize: none;
  outline: none;
  margin-bottom: 16px;
}
.comment-textarea:focus {
  border-color: #252f58;
}

.btn-action {
  width: 100%;
  padding: 12px;
  border-radius: 10px;
  font-size: 14px;
  font-weight: 700;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  cursor: pointer;
  border: none;
  margin-bottom: 10px;
  font-family: inherit;
}
.btn-accept {
  background: #15245a;
  color: #ffffff;
}
.btn-accept:hover {
  background: #1c2e6d;
}
.btn-refuse {
  background: #f1f2f5;
  color: #334155;
}
.btn-refuse:hover {
  background: #e2e5f0;
}

/* Monthly Context Card */
.monthly-context-card {
  background: #252f58;
  border-radius: 16px;
  padding: 24px;
  color: #ffffff;
}
.monthly-title {
  font-size: 12px;
  font-weight: 700;
  letter-spacing: 0.8px;
  color: #9ba3c4;
  margin: 0 0 20px 0;
}
.monthly-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-size: 13px;
}
.monthly-val {
  font-weight: 700;
  font-size: 15px;
}
.monthly-divider {
  height: 1px;
  background: rgba(255, 255, 255, 0.1);
  margin: 14px 0;
}
.progress-track {
  height: 8px;
  background: rgba(255, 255, 255, 0.2);
  border-radius: 999px;
  margin-top: 16px;
  overflow: hidden;
}
.progress-fill {
  height: 100%;
  background: #3b82f6;
  border-radius: 999px;
}

@media (max-width: 1024px) {
  .detail-grid {
    grid-template-columns: 1fr;
  }
}
</style>