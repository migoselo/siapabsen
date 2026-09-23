<script>
const defaultRequest = {
  id: 'req-1',
  employee: {
    name: 'Michael Chen',
    position: 'Senior Frontend Engineer',
    department: 'Engineering',
    employeeId: 'EMP-4092',
    email: 'm.chen@company.com',
    avatarUrl: '',
  },
  leaveTypeName: 'Cuti Tahunan',
  workDaysLabel: '5 Hari Kerja',
  startDate: '2023-10-10',
  endDate: '2023-10-16',
  reason:
    'Acara keluarga di kampung halaman dan istirahat tahunan. Pekerjaan mendesak telah diserahterimakan kepada rekan satu tim (Andi).',
  attachments: [
    { name: 'Undangan_Acara_Keluarga.pdf', sizeLabel: '2.4 MB', type: 'PDF', url: '#' },
    { name: 'Surat_Keterangan_Dokter.pdf', sizeLabel: '1.1 MB', type: 'PDF', url: '#' }
  ],
  leaveBalance: { used: 5, total: 12 },
  status: 'pending',
}
</script>

<script setup>
import { ref, computed } from 'vue'
import { Icon } from '@iconify/vue'

// Import Base Component
import BaseButton from '../components/BaseButton.vue'

const props = defineProps({
  request: { type: Object, default: () => defaultRequest },
})
const emit = defineEmits(['back', 'approve', 'reject'])

const req = computed(() => props.request || defaultRequest)

const dateFmt = new Intl.DateTimeFormat('id-ID', { day: '2-digit', month: 'short', year: 'numeric' })
function fmt(d) {
  return dateFmt.format(new Date(d))
}

const balancePct = computed(() => {
  const { used, total } = req.value.leaveBalance || { used: 0, total: 1 }
  return Math.min(100, Math.round((used / total) * 100))
})

function initials(name) {
  return name.split(' ').map((w) => w[0]).slice(0, 2).join('').toUpperCase()
}

const comment = ref('')

function handleApprove() {
  emit('approve', { id: req.value.id, comment: comment.value })
}
function handleReject() {
  emit('reject', { id: req.value.id, comment: comment.value })
}

function handleViewAttachment(file) {
  if (file.url && file.url !== '#') {
    window.open(file.url, '_blank')
  } else {
    window.alert(`Membuka pratinjau dokumen: ${file.name}`)
  }
}

function handleDownloadAttachment(file) {
  window.alert(`Mengunduh dokumen: ${file.name}`)
}
</script>

<template>
  <div class="detail-izin-cuti">
    <div class="page-head">
      <BaseButton variant="ghost" icon="material-symbols:arrow-back" @click="emit('back')" style="padding: 10px;" />
      <h1>Detail Izin dan Cuti</h1>
    </div>

    <div class="detail-layout">
      <!-- Kolom kiri -->
      <div class="col-main">
        <div class="card">
          <p class="card-eyebrow">Informasi Karyawan</p>
          <div class="employee-row">
            <img v-if="req.employee.avatarUrl" :src="req.employee.avatarUrl" class="avatar" />
            <div v-else class="avatar avatar-fallback">{{ initials(req.employee.name) }}</div>
            <div class="employee-meta">
              <p class="employee-name">{{ req.employee.name }}</p>
              <p class="employee-position">{{ req.employee.position }}</p>
              <div class="employee-facts">
                <span class="fact"><Icon icon="material-symbols:apartment-outline" width="16" />{{ req.employee.department }}</span>
                <span class="fact"><Icon icon="material-symbols:badge-outline" width="16" />{{ req.employee.employeeId }}</span>
                <span class="fact"><Icon icon="material-symbols:mail-outline" width="16" />{{ req.employee.email }}</span>
              </div>
            </div>
          </div>
        </div>

        <div class="card">
          <p class="card-title">Detail Cuti</p>
          <div class="info-grid">
            <div class="info-box">
              <p class="info-label"><Icon icon="material-symbols:eco-outline" width="16" /> Jenis Cuti</p>
              <p class="info-value">{{ req.leaveTypeName }}</p>
            </div>
            <div class="info-box">
              <p class="info-label"><Icon icon="material-symbols:schedule-outline" width="16" /> Durasi</p>
              <p class="info-value">{{ req.workDaysLabel }}</p>
            </div>
          </div>
          <div class="info-box info-box-wide">
            <p class="info-label"><Icon icon="material-symbols:calendar-month-outline" width="16" /> Tanggal Pelaksanaan</p>
            <p class="info-value date-range">
              {{ fmt(req.startDate) }}
              <Icon icon="material-symbols:arrow-forward" width="16" class="date-arrow" />
              {{ fmt(req.endDate) }}
            </p>
          </div>
          <div class="reason-block">
            <p class="reason-label">Alasan Cuti</p>
            <p class="reason-text">{{ req.reason }}</p>
          </div>
        </div>

        <!-- Field Lampiran Dokumen Pengajuan -->
        <div class="card">
          <p class="card-title"><Icon icon="material-symbols:attach-file" width="18" /> Lampiran Dokumen Pengajuan</p>
          
          <div v-if="!req.attachments || req.attachments.length === 0" class="empty-attachment">
            <Icon icon="material-symbols:folder-off-outline" width="32" />
            <p>Tidak ada dokumen lampiran yang diunggah oleh karyawan untuk pengajuan ini.</p>
          </div>

          <div v-else class="attachments-list">
            <div v-for="(file, i) in req.attachments" :key="i" class="attachment-row">
              <div class="attachment-icon">
                <Icon icon="material-symbols:description-outline" width="22" />
              </div>
              <div class="attachment-meta">
                <p class="attachment-name">{{ file.name }}</p>
                <p class="attachment-sub">{{ file.sizeLabel }} • {{ file.type || 'Dokumen' }}</p>
              </div>
              <div class="attachment-actions">
                <BaseButton variant="ghost" icon="material-symbols:visibility-outline" @click="handleViewAttachment(file)">
                  Lihat
                </BaseButton>
                <BaseButton variant="primary" icon="material-symbols:download" @click="handleDownloadAttachment(file)">
                  Unduh
                </BaseButton>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Kolom kanan -->
      <div class="col-side">
        <div class="card">
          <p class="card-title">Tinjau Permohonan</p>
          <p class="card-desc">Silakan tinjau rincian yang diberikan dan setujui atau tolak pengajuan ini.</p>

          <label class="comment-label" for="hr-comment">Catatan</label>
          <textarea id="hr-comment" v-model="comment" class="comment-box" placeholder="Tambahkan komentar untuk karyawan.."></textarea>

          <div class="action-buttons-wrap">
            <BaseButton 
              variant="primary" 
              icon="material-symbols:check-circle-outline" 
              :disabled="req.status !== 'pending'" 
              @click="handleApprove" 
              class="full-btn"
            >
              Terima
            </BaseButton>
            <BaseButton 
              variant="danger" 
              icon="material-symbols:cancel-outline" 
              :disabled="req.status !== 'pending'" 
              @click="handleReject" 
              class="full-btn"
            >
              Tolak
            </BaseButton>
          </div>
        </div>

        <div class="card card-dark">
          <p class="card-eyebrow eyebrow-light">Sisa Cuti Tahunan</p>
          <div class="balance-row">
            <span>Total cuti diajukan</span>
            <strong>{{ req.leaveBalance.used }} hari</strong>
          </div>
          <div class="balance-row">
            <span>Batas tahunan</span>
            <strong>{{ req.leaveBalance.total }} hari</strong>
          </div>
          <div class="balance-track">
            <div class="balance-fill" :style="{ width: balancePct + '%' }"></div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
@import url('https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap');

.detail-izin-cuti {
  --accent: var(--sidebar-accent, #252f58);
  --ink-dark: var(--ink-dark, #2c3345);
  --ink-soft: var(--ink-soft, #667085);
  --line: var(--line, #e4e7ec);
  --surface-soft: #f6f7fa;
  font-family: 'Plus Jakarta Sans', sans-serif;
  font-size: 14px;
  color: var(--ink-dark);
}

.detail-izin-cuti textarea { font-family: inherit; }

/* Header */
.page-head { display: flex; align-items: center; gap: 14px; margin-bottom: 24px; }
.page-head h1 { font-size: 24px; font-weight: 800; margin: 0; }

/* Layout */
.detail-layout { display: grid; grid-template-columns: minmax(0, 1fr) 340px; gap: 20px; align-items: start; }
.col-main, .col-side { display: flex; flex-direction: column; gap: 20px; }

.card { background: #fff; border: 1px solid var(--line); border-radius: 16px; padding: 22px 24px; }
.card-eyebrow { font-size: 12px; font-weight: 700; letter-spacing: 0.6px; text-transform: uppercase; color: var(--ink-soft); margin: 0 0 18px; }
.card-title { font-size: 17px; font-weight: 700; margin: 0 0 18px; display: flex; align-items: center; gap: 8px; padding-bottom: 14px; border-bottom: 1px solid var(--line); }
.card-desc { font-size: 13px; color: var(--ink-soft); margin: -10px 0 18px; line-height: 1.5; }

/* Informasi Karyawan */
.employee-row { display: flex; align-items: center; gap: 18px; }
.avatar { width: 68px; height: 68px; border-radius: 50%; object-fit: cover; flex-shrink: 0; border: 3px solid var(--surface-soft); }
.avatar-fallback { background: #e2e5f0; color: var(--accent); display: flex; align-items: center; justify-content: center; font-size: 20px; font-weight: 700; }
.employee-name { margin: 0; font-size: 19px; font-weight: 800; }
.employee-position { margin: 2px 0 10px; color: var(--ink-soft); font-size: 14px; }
.employee-facts { display: flex; flex-wrap: wrap; gap: 16px; }
.fact { display: inline-flex; align-items: center; gap: 6px; font-size: 13px; color: var(--ink-soft); }

/* Detail Cuti */
.info-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 14px; margin-bottom: 14px; }
.info-box { background: var(--surface-soft); border-radius: 12px; padding: 14px 16px; }
.info-box-wide { margin-bottom: 18px; }
.info-label { display: flex; align-items: center; gap: 6px; margin: 0 0 6px; font-size: 12px; font-weight: 600; color: var(--ink-soft); }
.info-value { margin: 0; font-size: 15px; font-weight: 700; color: var(--ink-dark); }
.date-range { display: flex; align-items: center; gap: 10px; }
.date-arrow { color: var(--ink-soft); }

.reason-block { background: var(--surface-soft); border-radius: 12px; padding: 16px; }
.reason-label { margin: 0 0 8px; font-size: 13px; font-weight: 600; color: var(--ink-soft); }
.reason-text { margin: 0; line-height: 1.6; color: var(--ink-dark); }

/* Lampiran Dokumen */
.attachments-list { display: flex; flex-direction: column; gap: 12px; }
.attachment-row { display: flex; align-items: center; gap: 14px; padding: 14px; border: 1px solid var(--line); border-radius: 12px; background: var(--surface-soft); }
.attachment-icon { width: 44px; height: 44px; border-radius: 10px; background: #eaf0ff; color: #2a4365; display: flex; align-items: center; justify-content: center; flex-shrink: 0; }
.attachment-meta { flex: 1; min-width: 0; }
.attachment-name { margin: 0; font-weight: 700; font-size: 14px; color: var(--ink-dark); overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.attachment-sub { margin: 2px 0 0; font-size: 12px; color: var(--ink-soft); }
.attachment-actions { display: flex; align-items: center; gap: 8px; }
.empty-attachment { display: flex; flex-direction: column; align-items: center; justify-content: center; padding: 24px; color: var(--ink-soft); text-align: center; gap: 8px; font-size: 13px; background: var(--surface-soft); border-radius: 12px; }

/* Tinjau Permohonan */
.comment-label { display: block; font-size: 13px; font-weight: 600; color: var(--ink-soft); margin-bottom: 8px; }
.comment-box { width: 100%; min-height: 96px; resize: vertical; border: 1px solid var(--line); border-radius: 12px; padding: 12px 14px; font-size: 14px; color: var(--ink-dark); margin-bottom: 16px; box-sizing: border-box; }
.comment-box::placeholder { color: #a4a9b6; }
.comment-box:focus { outline: 2px solid rgba(37, 47, 88, 0.15); border-color: var(--accent); }

.action-buttons-wrap { display: flex; flex-direction: column; gap: 10px; }
:deep(.full-btn) { width: 100%; justify-content: center; }

/* Sisa Cuti Tahunan */
.card-dark { background: var(--accent); border-color: var(--accent); color: #fff; }
.eyebrow-light { color: rgba(255, 255, 255, 0.65); }
.balance-row { display: flex; align-items: center; justify-content: space-between; font-size: 14px; padding: 10px 0; border-bottom: 1px solid rgba(255, 255, 255, 0.12); }
.balance-row:first-of-type { padding-top: 0; }
.balance-row span { color: rgba(255, 255, 255, 0.75); }
.balance-row strong { font-weight: 700; }
.balance-track { margin-top: 18px; height: 8px; border-radius: 999px; background: rgba(255, 255, 255, 0.18); overflow: hidden; }
.balance-fill { height: 100%; border-radius: 999px; background: #fff; }

@media (max-width: 900px) {
  .detail-layout { grid-template-columns: 1fr; }
  .info-grid { grid-template-columns: 1fr; }
  .attachment-row { flex-direction: column; align-items: flex-start; }
  .attachment-actions { width: 100%; justify-content: flex-end; margin-top: 8px; }
}
</style>