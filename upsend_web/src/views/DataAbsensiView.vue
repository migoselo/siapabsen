<script setup>
import { ref, computed, onMounted } from 'vue'
import { Icon } from '@iconify/vue'
import api from '../api'

/*
  View ini cuma berisi KONTEN halaman (sidebar & topbar sudah ditangani
  MainLayout.vue lewat router-view) — ikut pola yang sama dengan
  DashboardView.vue / LokasiKerjaView.vue / DataKaryawanView.vue.
*/

const dateRangeLabel = ref('01 Jan 2024 - 31 Jan 2024')
const outletLabel = ref('Semua Outlet')
const searchQuery = ref('')

const records = ref([])
const loading = ref(false)

const currentPage = ref(1)
const totalPages = ref(1)
const totalRecords = ref(0)

const avatarPalette = ['avatar-green', 'avatar-amber', 'avatar-pink', 'avatar-red']
function avatarClass(idx) {
  return avatarPalette[idx % avatarPalette.length]
}

function initials(name) {
  if (!name) return ''
  return name.split(' ').map((w) => w[0]).slice(0, 2).join('').toUpperCase()
}

const filteredRecords = computed(() => {
  const q = searchQuery.value.trim().toLowerCase()
  if (!q) return records.value
  return records.value.filter((r) => r.employeeName.toLowerCase().includes(q))
})

async function fetchRecords(page = 1) {
  loading.value = true
  try {
    // TODO: sesuaikan endpoint & params (date range, outlet, search) dengan API backend
    const res = await api.get('/attendance', {
      params: { page, outlet: outletLabel.value, q: searchQuery.value },
    })
    records.value = res.data.records
    currentPage.value = res.data.currentPage
    totalPages.value = res.data.totalPages
    totalRecords.value = res.data.total
  } catch (err) {
    console.error('Gagal mengambil data absensi:', err)
  } finally {
    loading.value = false
  }
}

function goToPage(page) {
  if (page < 1 || page > totalPages.value) return
  fetchRecords(page)
}

function handleExportExcel() {
  // TODO: panggil endpoint export (mis. GET /attendance/export) dan trigger download
  console.log('export ke excel')
}

/* ---------------- Panel Detail Absensi ---------------- */
const selectedRecord = ref(null)

function openDetail(record) {
  selectedRecord.value = record
}

function closeDetail() {
  selectedRecord.value = null
}

function handlePrintSlip() {
  // TODO: panggil endpoint / generate PDF slip absensi
  console.log('print slip')
}

function handleSaveReview() {
  // TODO: panggil endpoint simpan review/verifikasi absensi
  console.log('simpan review')
}

onMounted(() => {
  fetchRecords(1)
})
</script>

<template>
  <div class="absensi">
    <section class="panel filter-panel">
      <div class="filter-row">
        <div class="field">
          <label>Rentang Tanggal</label>
          <div class="date-input">
            <Icon icon="material-symbols:calendar-today-outline" width="18" height="18" />
            <span>{{ dateRangeLabel }}</span>
          </div>
        </div>

        <div class="field">
          <label>Outlet</label>
          <div class="select">
            <span>{{ outletLabel }}</span>
            <Icon icon="material-symbols:keyboard-arrow-down-rounded" width="18" height="18" />
          </div>
        </div>

        <div class="field grow">
          <label>Karyawan</label>
          <div class="search">
            <Icon icon="material-symbols:search-rounded" width="18" height="18" />
            <input type="text" v-model="searchQuery" @input="fetchRecords(1)" placeholder="Cari karyawan..." />
          </div>
        </div>

        <button class="export-btn" @click="handleExportExcel">
          <Icon icon="material-symbols:download-rounded" width="18" height="18" />
          Export ke Excel
        </button>
      </div>
    </section>

    <section class="panel table-panel">
      <table>
        <thead>
          <tr>
            <th>Tanggal</th>
            <th>Nama Karyawan</th>
            <th>Outlet</th>
            <th>Check In</th>
            <th>Check Out</th>
            <th>Durasi</th>
          </tr>
        </thead>
        <tbody>
          <tr v-if="loading">
            <td colspan="6" class="empty-cell">Memuat data...</td>
          </tr>
          <tr v-else-if="filteredRecords.length === 0">
            <td colspan="6" class="empty-cell">Tidak ada data absensi ditemukan.</td>
          </tr>
          <tr
            v-for="(rec, idx) in filteredRecords"
            :key="rec.id"
            class="clickable-row"
            @click="openDetail(rec)"
          >
            <td>{{ rec.date }}</td>
            <td>
              <div class="emp">
                <div class="emp-avatar" :class="avatarClass(idx)">{{ initials(rec.employeeName) }}</div>
                <div class="emp-name">{{ rec.employeeName }}</div>
              </div>
            </td>
            <td>{{ rec.outlet }}</td>
            <td>
              <span v-if="rec.checkInTime" :class="{ late: rec.late }">{{ rec.checkInTime }}</span>
              <span v-else class="dash">-</span>
            </td>
            <td>
              <span v-if="rec.checkOutTime">{{ rec.checkOutTime }}</span>
              <span v-else class="dash">-</span>
            </td>
            <td>
              <span v-if="rec.duration">{{ rec.duration }}</span>
              <span v-else class="dash">-</span>
            </td>
          </tr>
        </tbody>
      </table>

      <div class="table-footer">
        <span>Menampilkan {{ filteredRecords.length }} dari {{ totalRecords }} data</span>
        <div class="pager">
          <button :disabled="currentPage <= 1" @click="goToPage(currentPage - 1)">
            <Icon icon="material-symbols:chevron-left-rounded" width="18" height="18" />
          </button>
          <button
            v-for="p in totalPages"
            :key="p"
            class="page-btn"
            :class="{ active: p === currentPage }"
            @click="goToPage(p)"
          >
            {{ p }}
          </button>
          <button :disabled="currentPage >= totalPages" @click="goToPage(currentPage + 1)">
            <Icon icon="material-symbols:chevron-right-rounded" width="18" height="18" />
          </button>
        </div>
      </div>
    </section>

    <!-- ================= PANEL DETAIL ABSENSI ================= -->
    <Teleport to="body">
      <div v-if="selectedRecord" class="detail-overlay" @click.self="closeDetail">
        <div class="detail-panel">
          <div class="detail-head">
            <div>
              <h3>Detail Absensi</h3>
              <p>{{ selectedRecord.employeeName }}</p>
            </div>
            <button class="detail-close" @click="closeDetail">
              <Icon icon="material-symbols:close-rounded" width="20" height="20" />
            </button>
          </div>

          <div class="detail-body">
            <div class="event">
              <div class="event-title checkin-title">
                <span class="bar checkin-bar"></span>
                Check In - {{ selectedRecord.checkInTime || '-' }}
              </div>

              <div class="photo-wrap">
                <img
                  v-if="selectedRecord.checkInPhotoUrl"
                  :src="selectedRecord.checkInPhotoUrl"
                  alt="Foto verifikasi check-in"
                />
                <div v-else class="photo-placeholder">
                  <Icon icon="material-symbols:no-photography-outline" width="28" height="28" />
                  <span>Tidak ada foto verifikasi</span>
                </div>
              </div>

              <div class="coord-row">
                <div>
                  <div class="coord-label">Koordinat</div>
                  <div class="coord-value">{{ selectedRecord.checkInCoordinate || '-' }}</div>
                </div>
                <div class="coord-right">
                  <div class="coord-label">Jarak ke Lokasi</div>
                  <div class="coord-value">{{ selectedRecord.checkInDistance || '-' }}</div>
                </div>
              </div>

              <button class="map-btn checkin-map-btn">
                <Icon icon="material-symbols:map-outline" width="18" height="18" />
                Lihat di Peta
              </button>
            </div>

            <div class="event">
              <div class="event-title checkout-title">
                <span class="bar checkout-bar"></span>
                Check Out - {{ selectedRecord.checkOutTime || '-' }}
              </div>

              <p class="note">Sistem check-out tidak memerlukan verifikasi foto.</p>

              <div class="coord-row">
                <div>
                  <div class="coord-label">Koordinat</div>
                  <div class="coord-value">{{ selectedRecord.checkOutCoordinate || '-' }}</div>
                </div>
                <div class="coord-right">
                  <div class="coord-label">Jarak ke Lokasi</div>
                  <div class="coord-value">{{ selectedRecord.checkOutDistance || '-' }}</div>
                </div>
              </div>

              <button class="map-btn checkout-map-btn">
                <Icon icon="material-symbols:map-outline" width="18" height="18" />
                Lihat di Peta
              </button>
            </div>

            <div class="summary-box">
              <div class="summary-title">Ringkasan Hari Ini</div>
              <div class="summary-row">
                <div>
                  <div class="summary-label">Total Jam Kerja</div>
                  <div class="summary-value">{{ selectedRecord.totalWorkHours || '-' }}</div>
                </div>
                <div>
                  <div class="summary-label">Overtime</div>
                  <div class="summary-value">{{ selectedRecord.overtime || '-' }}</div>
                </div>
              </div>
            </div>
          </div>

          <div class="detail-footer">
            <button class="btn-print" @click="handlePrintSlip">Print Slip</button>
            <button class="btn-save-review" @click="handleSaveReview">Simpan Review</button>
          </div>
        </div>
      </div>
    </Teleport>
  </div>
</template>

<style scoped>
.absensi {
  --green-900: #173d31;
  --gold: #eaa93d;
  --gold-dark: #d99524;
  --red: #dc4646;
  --ink: #1c2521;
  --ink-soft: #5b6864;
  --line: #e7e7e2;
  --bg: #f6f5f1;
  --card: #ffffff;
}
.absensi * {
  box-sizing: border-box;
}

.panel {
  background: var(--card);
  border: 1px solid var(--line);
  border-radius: 16px;
}

/* ---------- Filter bar ---------- */
.filter-panel {
  padding: 20px 24px;
  margin-bottom: 18px;
}
.filter-row {
  display: flex;
  align-items: flex-end;
  gap: 18px;
  flex-wrap: wrap;
}
.field {
  display: flex;
  flex-direction: column;
  gap: 8px;
}
.field.grow {
  flex: 1;
  min-width: 200px;
}
.field label {
  font-size: 13px;
  font-weight: 600;
  color: var(--ink);
}
.date-input,
.select,
.search {
  display: flex;
  align-items: center;
  gap: 8px;
  border: 1px solid var(--line);
  border-radius: 10px;
  padding: 10px 14px;
  font-size: 14px;
  color: var(--ink);
  background: #fff;
  white-space: nowrap;
}
.date-input svg,
.date-input .iconify,
.select svg,
.select .iconify,
.search svg,
.search .iconify {
  color: var(--ink-soft);
  flex-shrink: 0;
}
.select {
  cursor: pointer;
  justify-content: space-between;
  min-width: 160px;
}
.search {
  width: 100%;
}
.search input {
  border: none;
  outline: none;
  background: none;
  font-size: 14px;
  width: 100%;
  font-family: inherit;
  color: var(--ink);
}
.export-btn {
  display: flex;
  align-items: center;
  gap: 8px;
  background: var(--gold);
  color: #3b2a05;
  border: none;
  padding: 11px 18px;
  border-radius: 10px;
  font-size: 14px;
  font-weight: 700;
  cursor: pointer;
  white-space: nowrap;
  transition: background 0.15s ease;
}
.export-btn:hover {
  background: var(--gold-dark);
}

/* ---------- Table ---------- */
.table-panel {
  padding: 0;
  overflow: hidden;
}
table {
  width: 100%;
  border-collapse: collapse;
}
thead tr {
  background: var(--green-900);
}
thead th {
  color: #dfe9e3;
  font-size: 11.5px;
  font-weight: 700;
  letter-spacing: 0.06em;
  text-align: left;
  padding: 14px 24px;
  text-transform: uppercase;
}
tbody td {
  padding: 16px 24px;
  font-size: 14.5px;
  border-bottom: 1px solid var(--line);
  vertical-align: middle;
  color: var(--ink);
}
tbody tr:last-child td {
  border-bottom: none;
}
.clickable-row {
  cursor: pointer;
  transition: background 0.12s ease;
}
.clickable-row:hover {
  background: var(--bg);
}
.empty-cell {
  text-align: center;
  color: var(--ink-soft);
  padding: 32px;
}
.emp {
  display: flex;
  align-items: center;
  gap: 12px;
}
.emp-avatar {
  width: 34px;
  height: 34px;
  border-radius: 50%;
  font-weight: 700;
  font-size: 12px;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}
.emp-avatar.avatar-green {
  background: #d6ecdf;
  color: #1c7a52;
}
.emp-avatar.avatar-amber {
  background: #fdf1d6;
  color: #a9721a;
}
.emp-avatar.avatar-pink {
  background: #fbe3ec;
  color: #a9316c;
}
.emp-avatar.avatar-red {
  background: #fdeaea;
  color: #dc4646;
}
.emp-name {
  font-weight: 700;
  font-size: 14.5px;
}
.late {
  color: var(--red);
  font-weight: 700;
}
.dash {
  color: var(--ink-soft);
}

.table-footer {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 16px 24px;
  font-size: 13px;
  color: var(--ink-soft);
  border-top: 1px solid var(--line);
  background: var(--bg);
  flex-wrap: wrap;
  gap: 10px;
}
.pager {
  display: flex;
  gap: 8px;
  align-items: center;
}
.pager button {
  width: 32px;
  height: 32px;
  border-radius: 8px;
  border: 1px solid var(--line);
  background: #fff;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  font-size: 13px;
  font-weight: 600;
  color: var(--ink);
}
.pager button svg,
.pager button .iconify {
  color: var(--ink-soft);
}
.pager button:disabled {
  opacity: 0.4;
  cursor: not-allowed;
}
.pager button.page-btn.active {
  background: var(--green-900);
  color: #fff;
  border-color: var(--green-900);
}

/* ================= PANEL DETAIL (Teleport) ================= */
.detail-overlay {
  position: fixed;
  inset: 0;
  background: rgba(28, 37, 33, 0.4);
  display: flex;
  justify-content: flex-end;
  z-index: 1000;
}
.detail-panel {
  width: 100%;
  max-width: 420px;
  height: 100%;
  background: #fff;
  box-shadow: -8px 0 30px rgba(0, 0, 0, 0.15);
  display: flex;
  flex-direction: column;
  font-family: 'Inter', system-ui, -apple-system, sans-serif;
  overflow-y: auto;
}
.detail-head {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  padding: 22px 24px;
  border-bottom: 1px solid #e7e7e2;
  background: #f6f5f1;
}
.detail-head h3 {
  margin: 0 0 2px;
  font-size: 18px;
  font-weight: 700;
  color: #173d31;
}
.detail-head p {
  margin: 0;
  font-size: 13px;
  color: #5b6864;
}
.detail-close {
  width: 32px;
  height: 32px;
  border-radius: 8px;
  border: none;
  background: transparent;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  color: #1c2521;
  flex-shrink: 0;
}
.detail-close:hover {
  background: rgba(0, 0, 0, 0.06);
}

.detail-body {
  padding: 22px 24px;
  display: flex;
  flex-direction: column;
  gap: 24px;
}
.event-title {
  display: flex;
  align-items: center;
  gap: 10px;
  font-size: 15px;
  font-weight: 700;
  color: #1c2521;
  margin-bottom: 14px;
}
.bar {
  width: 4px;
  height: 18px;
  border-radius: 2px;
  display: inline-block;
}
.checkin-bar {
  background: #173d31;
}
.checkout-bar {
  background: #eaa93d;
}

.photo-wrap {
  border-radius: 12px;
  overflow: hidden;
  margin-bottom: 14px;
  border: 1px solid #e7e7e2;
}
.photo-wrap img {
  width: 100%;
  height: 200px;
  object-fit: cover;
  display: block;
}
.photo-placeholder {
  width: 100%;
  height: 160px;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 8px;
  background: #f6f5f1;
  color: #5b6864;
  font-size: 12.5px;
}

.note {
  font-size: 12.5px;
  font-style: italic;
  color: #5b6864;
  margin: 0 0 14px;
}

.coord-row {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 14px;
}
.coord-right {
  text-align: right;
}
.coord-label {
  font-size: 10.5px;
  font-weight: 700;
  letter-spacing: 0.05em;
  color: #5b6864;
  text-transform: uppercase;
  margin-bottom: 4px;
}
.coord-value {
  font-size: 14px;
  font-weight: 700;
  color: #1c2521;
}

.map-btn {
  width: 100%;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  border: none;
  padding: 12px;
  border-radius: 10px;
  font-size: 14px;
  font-weight: 700;
  cursor: pointer;
  transition: background 0.15s ease;
}
.checkin-map-btn {
  background: #173d31;
  color: #fff;
}
.checkin-map-btn:hover {
  background: #0f2b22;
}
.checkout-map-btn {
  background: #eaa93d;
  color: #3b2a05;
}
.checkout-map-btn:hover {
  background: #d99524;
}

.summary-box {
  background: #173d31;
  border-radius: 14px;
  padding: 18px 20px;
  color: #fff;
}
.summary-title {
  font-size: 11px;
  font-weight: 700;
  letter-spacing: 0.06em;
  text-transform: uppercase;
  color: #a9c2b6;
  margin-bottom: 14px;
}
.summary-row {
  display: flex;
  justify-content: space-between;
}
.summary-label {
  font-size: 12px;
  color: #cfe0d7;
  margin-bottom: 4px;
}
.summary-value {
  font-size: 20px;
  font-weight: 800;
}

.detail-footer {
  display: flex;
  gap: 12px;
  padding: 18px 24px;
  border-top: 1px solid #e7e7e2;
  background: #f6f5f1;
}
.btn-print {
  flex: 1;
  padding: 12px;
  border-radius: 10px;
  border: 1px solid #e7e7e2;
  background: #fff;
  color: #1c2521;
  font-size: 14px;
  font-weight: 700;
  cursor: pointer;
}
.btn-print:hover {
  background: #f0f0eb;
}
.btn-save-review {
  flex: 1;
  padding: 12px;
  border-radius: 10px;
  border: none;
  background: #173d31;
  color: #fff;
  font-size: 14px;
  font-weight: 700;
  cursor: pointer;
  transition: background 0.15s ease;
}
.btn-save-review:hover {
  background: #0f2b22;
}

@media (max-width: 900px) {
  .filter-row {
    align-items: stretch;
  }
  .export-btn {
    justify-content: center;
  }
}
</style>