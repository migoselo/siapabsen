<script setup>
/**
 * DataAbsensiView.vue
 * Alur: Pilih Perusahaan -> Pilih Cabang -> Data Absensi.
 * Kalau akun tidak punya akses daftar perusahaan (/tenants), langsung pilih lokasi.
 * Pilihan disimpan di URL (?company_id=&location_id=) supaya tombol back browser bekerja.
 */
import { ref, computed, watch, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import api from '../api'
import { dateRangeForPeriod } from '../utils/date'

import BaseSummaryCard from '../components/BaseSummaryCard.vue'
import BaseButton from '../components/BaseButton.vue'
import BaseSearch from '../components/BaseSearch.vue'
import BaseTable from '../components/BaseTable.vue'
import BaseBadge from '../components/BaseBadge.vue'
import BasePagination from '../components/BasePagination.vue'
import BasePeriodFilter from '../components/BasePeriodFilter.vue'
import BasePanel from '../components/BasePanel.vue'

/* ------------------------------------------------------------------ */
/* State                                                               */
/* ------------------------------------------------------------------ */
const route = useRoute()
const router = useRouter()

const records = ref([])
const loading = ref(false)
const currentPage = ref(1)
const lastPage = ref(1)
const totalRecords = ref(0)
const perPage = ref(20)

const companies = ref([])
const locations = ref([])
const companyLocations = ref([])
const initialLoading = ref(true)
const loadingCompanyLocations = ref(false)

const filter = ref({ period: 'all', startDate: '', endDate: '', location_id: '' })
const searchQuery = ref('') // cari karyawan (level 3)
const listSearch = ref('') // cari perusahaan / cabang (level 1 & 2)

/* ------------------------------------------------------------------ */
/* Kolom tabel                                                         */
/* ------------------------------------------------------------------ */
const companyColumns = [
  { key: 'company', label: 'Nama Perusahaan' },
  { key: 'branches', label: 'Jumlah Cabang' },
  { key: 'employees', label: 'Jumlah Karyawan' },
]
const locationColumns = [
  { key: 'name', label: 'Nama Lokasi / Cabang' },
  { key: 'address', label: 'Alamat' },
]
const attendanceColumns = [
  { key: 'date', label: 'Tanggal' },
  { key: 'employee', label: 'Nama Karyawan' },
  { key: 'checkIn', label: 'Check In' },
  { key: 'checkOut', label: 'Check Out' },
  { key: 'status', label: 'Status' },
]

/* ------------------------------------------------------------------ */
/* Drill-down: Perusahaan -> Cabang -> Absensi                         */
/* ------------------------------------------------------------------ */
const isTenantMode = computed(() => companies.value.length > 0)
const companyId = computed(() => String(route.query.company_id || '').trim())
const locationId = computed(() => String(route.query.location_id || '').trim())

const selectedCompany = computed(() =>
  companyId.value ? companies.value.find((c) => String(c.id) === companyId.value) || null : null,
)
const selectedLocation = computed(() => {
  if (!locationId.value) return null
  const pool = [...companyLocations.value, ...locations.value]
  return pool.find((l) => String(l.id) === locationId.value) || null
})

const showCompanyList = computed(
  () => !selectedLocation.value && isTenantMode.value && !selectedCompany.value,
)
const showLocationList = computed(() => !selectedLocation.value && !showCompanyList.value)

// Pencarian di daftar perusahaan / cabang
const filteredCompanies = computed(() => {
  const q = listSearch.value.trim().toLowerCase()
  if (!q) return companies.value
  return companies.value.filter((c) => String(c.name || '').toLowerCase().includes(q))
})

const visibleLocations = computed(() => {
  const list = isTenantMode.value ? companyLocations.value : locations.value
  const q = listSearch.value.trim().toLowerCase()
  if (!q) return list
  return list.filter(
    (l) =>
      String(l.name || '').toLowerCase().includes(q) ||
      String(l.address || '').toLowerCase().includes(q),
  )
})

const listSearchPlaceholder = computed(() => {
  if (showCompanyList.value) return 'Cari perusahaan...'
  return isTenantMode.value ? 'Cari cabang...' : 'Cari lokasi...'
})

const companyEmptyText = computed(() =>
  initialLoading.value
    ? 'Memuat data...'
    : listSearch.value
      ? 'Perusahaan tidak ditemukan.'
      : 'Belum ada perusahaan.',
)

const locationEmptyText = computed(() => {
  if (initialLoading.value || loadingCompanyLocations.value) return 'Memuat data...'
  if (listSearch.value) return 'Cabang tidak ditemukan.'
  return isTenantMode.value ? 'Belum ada cabang di perusahaan ini.' : 'Data lokasi belum tersedia.'
})

function openCompany(company) {
  router.push({ query: { company_id: String(company.id) } })
}

function openLocation(loc) {
  const query = { location_id: String(loc.id) }
  if (selectedCompany.value) query.company_id = String(selectedCompany.value.id)
  router.push({ query })
}

// Tombol panah kembali: naik satu level
function goBack() {
  const previous = String(window.history.state?.back || '')
  if (previous.startsWith(route.path)) {
    router.back()
    return
  }
  const query = {}
  if (selectedLocation.value && selectedCompany.value) {
    query.company_id = String(selectedCompany.value.id)
  }
  router.replace({ query })
}

/* ------------------------------------------------------------------ */
/* Fetch data                                                          */
/* ------------------------------------------------------------------ */
// Daftar perusahaan (hanya bisa diakses super admin)
async function fetchCompanies() {
  try {
    const res = await api.get('/tenants')
    companies.value = Array.isArray(res.data) ? res.data : []
  } catch {
    // Akun tanpa akses /tenants -> pakai daftar lokasi langsung
    companies.value = []
  }
}

async function fetchLocations() {
  try {
    const res = await api.get('/locations')
    locations.value = Array.isArray(res.data) ? res.data : []
  } catch (err) {
    console.error('Gagal mengambil lokasi:', err)
  }
}

async function loadCompanyLocations(id) {
  companyLocations.value = []
  if (!id) return
  loadingCompanyLocations.value = true
  try {
    const res = await api.get('/locations', { params: { tenant_id: id } })
    companyLocations.value = Array.isArray(res.data) ? res.data : []
  } catch (err) {
    console.error('Gagal mengambil cabang perusahaan:', err)
  } finally {
    loadingCompanyLocations.value = false
  }
}

async function fetchAttendance(page = 1) {
  loading.value = true
  try {
    const params = { page, per_page: perPage.value }
    const { startDate, endDate } = dateRangeForPeriod(filter.value)

    if (startDate && endDate) {
      params.start_date = startDate
      params.end_date = endDate
      if (filter.value.period === 'today') params.date = startDate
    }
    if (filter.value.location_id) params.location_id = filter.value.location_id

    const res = await api.get('/attendances', { params })
    records.value = res.data.data || []
    totalRecords.value = res.data.total || 0
    currentPage.value = res.data.current_page || page
    lastPage.value = res.data.last_page || 1
  } catch (err) {
    console.error('Gagal mengambil data absensi:', err)
  } finally {
    loading.value = false
  }
}

function onPeriodChange(value) {
  filter.value = { ...filter.value, ...value }
  fetchAttendance(1)
}

function onPerPageChange(value) {
  perPage.value = value
  fetchAttendance(1)
}

watch(companyId, loadCompanyLocations, { immediate: true })

// Pindah level -> kosongkan kolom cari daftar
watch([companyId, locationId], () => {
  listSearch.value = ''
})

// Saat cabang dipilih -> muat absensi. Saat kembali -> kosongkan.
watch(
  () => selectedLocation.value?.id,
  (id) => {
    searchQuery.value = ''
    if (id) {
      filter.value.location_id = id
      fetchAttendance(1)
    } else {
      filter.value.location_id = ''
      records.value = []
      totalRecords.value = 0
    }
  },
  { immediate: true },
)

onMounted(async () => {
  await Promise.all([fetchCompanies(), fetchLocations()])
  initialLoading.value = false
})

/* ------------------------------------------------------------------ */
/* Data turunan & ringkasan                                            */
/* ------------------------------------------------------------------ */
function isLate(record) {
  return Boolean(record.check_in_time) && new Date(record.check_in_time).getHours() >= 9
}

function isOvertime(record) {
  const status = String(record.status || '').toLowerCase()
  return record.is_overtime === true || status === 'overtime' || status === 'lembur'
}

const periodFilteredRecords = computed(() => {
  const { startDate, endDate } = dateRangeForPeriod(filter.value)
  if (!startDate || !endDate) return records.value
  return records.value.filter((record) => {
    const recordDate = String(
      record.date || record.attendance_date || record.check_in_time || '',
    ).slice(0, 10)
    return recordDate >= startDate && recordDate <= endDate
  })
})

const filteredRecords = computed(() => {
  const query = searchQuery.value.trim().toLowerCase()
  if (!query) return periodFilteredRecords.value
  return periodFilteredRecords.value.filter((r) => r.employee?.name?.toLowerCase().includes(query))
})

const summary = computed(() => {
  const list = periodFilteredRecords.value
  return {
    onTime: list.filter((r) => r.check_in_time && !isLate(r)).length,
    late: list.filter(isLate).length,
    missed: list.filter((r) => !r.check_in_time).length,
    overtime: list.filter(isOvertime).length,
  }
})

/* ------------------------------------------------------------------ */
/* Helper tampilan                                                     */
/* ------------------------------------------------------------------ */
function formatTime(value) {
  return value
    ? new Date(value).toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit' })
    : '--:--'
}

function formatDate(value) {
  return value ? new Date(value).toLocaleDateString('id-ID') : '-'
}

function initials(name) {
  if (!name) return '-'
  return name
    .split(' ')
    .map((word) => word[0])
    .slice(0, 2)
    .join('')
    .toUpperCase()
}

function statusFor(record) {
  const status = String(record.status || '').toLowerCase()
  if (status === 'lupa_absen') return { label: 'Lupa Checkout', theme: 'danger' }
  if (status === 'alpha' || !record.check_in_time) return { label: 'Alpha', theme: 'danger' }
  if (status === 'lembur' || status === 'overtime') return { label: 'Lembur', theme: 'info' }
  if (status === 'telat' || status === 'terlambat') return { label: 'Terlambat', theme: 'warning' }
  return { label: 'Tepat Waktu', theme: 'success' }
}

function handleExport() {
  window.alert('Fitur ekspor belum tersedia di backend.')
}
</script>

<template>
  <div class="attendance-page">
    <!-- Ringkasan hanya muncul setelah cabang dipilih -->
    <section v-if="selectedLocation" class="summary-grid">
      <BaseSummaryCard
        tag="TOTAL"
        title="Tepat Waktu"
        :value="summary.onTime"
        subtitle="Check-in dan check-out tercatat"
        icon="material-symbols:groups-outline"
        theme="green"
      />
      <BaseSummaryCard
        tag="STATUS"
        title="Terlambat"
        :value="summary.late"
        subtitle="Check-in mulai pukul 09.00"
        icon="material-symbols:schedule-outline"
        theme="amber"
      />
      <BaseSummaryCard
        tag="ALERT"
        title="Lupa Absen"
        :value="summary.missed"
        subtitle="Belum melakukan check-in"
        icon="material-symbols:person-off-outline"
        theme="red"
      />
      <BaseSummaryCard
        tag="SHIFT"
        title="Lembur"
        :value="summary.overtime"
        subtitle="Sesuai penanda lembur"
        icon="material-symbols:logout-rounded"
        theme="blue"
      />
    </section>

    <!-- overflow-visible saat level 3: popup kalender periode harus bisa keluar dari kartu -->
    <BasePanel :overflow-visible="Boolean(selectedLocation)">
      <!-- Header kartu: judul + pencarian (sama seperti halaman Data Karyawan) -->
      <template #header>
        <div class="header-left">
          <BaseButton
            v-if="selectedCompany || selectedLocation"
            variant="ghost"
            icon="material-symbols:arrow-back-rounded"
            title="Kembali"
            style="padding: 10px"
            @click="goBack"
          />

          <!-- Level 3: cabang terpilih -->
          <div v-if="selectedLocation" class="heading">
            <span class="heading-eyebrow">{{ selectedCompany?.name || 'Data Absensi Lokasi' }}</span>
            <h2>{{ selectedLocation.name }}</h2>
          </div>

          <!-- Level 2: perusahaan terpilih, pilih cabang -->
          <div v-else-if="selectedCompany" class="heading">
            <h2>{{ selectedCompany.name }}</h2>
            <p>Pilih cabang untuk melihat data absensi harian.</p>
          </div>

          <!-- Level 1: pilih perusahaan / lokasi -->
          <div v-else class="heading">
            <h2>{{ isTenantMode ? 'Pilih Perusahaan' : 'Pilih Lokasi Kantor' }}</h2>
            <p v-if="isTenantMode">Pilih perusahaan untuk melihat cabang dan data absensinya.</p>
            <p v-else>Pilih lokasi kantor terlebih dahulu untuk melihat data absensi harian.</p>
          </div>
        </div>

        <BaseSearch
          v-if="!selectedLocation"
          v-model="listSearch"
          :placeholder="listSearchPlaceholder"
          width="280px"
        />
      </template>

      <!-- Level 1: Tabel Perusahaan -->
      <BaseTable
        v-if="showCompanyList"
        :columns="companyColumns"
        :data="filteredCompanies"
        has-actions
        :empty-text="companyEmptyText"
      >
        <template #cell-company="{ item }"><strong>{{ item.name }}</strong></template>
        <template #cell-branches="{ item }">{{ item.locations_count ?? 0 }} cabang</template>
        <template #cell-employees="{ item }">
          <span class="count-badge">{{ item.users_count ?? 0 }} Orang</span>
        </template>
        <template #actions="{ item }">
          <button type="button" class="link-btn" @click="openCompany(item)">Lihat Cabang</button>
        </template>
      </BaseTable>

      <!-- Level 2: Tabel Cabang / Lokasi -->
      <BaseTable
        v-else-if="showLocationList"
        :columns="locationColumns"
        :data="visibleLocations"
        has-actions
        :empty-text="locationEmptyText"
      >
        <template #cell-name="{ item }"><strong>{{ item.name }}</strong></template>
        <template #cell-address="{ item }">{{ item.address || '-' }}</template>
        <template #actions="{ item }">
          <button type="button" class="link-btn" @click="openLocation(item)">Lihat Absen</button>
        </template>
      </BaseTable>

      <!-- Level 3: Filter + Tabel Data Absensi -->
      <template v-else>
        <div class="filter-bar">
          <BasePeriodFilter :model-value="filter" @change="onPeriodChange" />

          <div class="search-wrap">
            <BaseSearch v-model="searchQuery" placeholder="Cari nama karyawan ..." width="240px" />
          </div>

          <div class="export-wrap">
            <BaseButton variant="primary" icon="material-symbols:download-rounded" @click="handleExport">
              Export ke Excel
            </BaseButton>
          </div>
        </div>

        <BaseTable
          :columns="attendanceColumns"
          :data="filteredRecords"
          has-actions
          empty-text="Belum ada data absensi untuk periode ini."
        >
          <template #cell-date="{ item }">{{ formatDate(item.check_in_time) }}</template>

          <template #cell-employee="{ item }">
            <div class="employee">
              <div class="employee-avatar">{{ initials(item.employee?.name) }}</div>
              <strong>{{ item.employee?.name || '—' }}</strong>
            </div>
          </template>

          <template #cell-checkIn="{ item }">{{ formatTime(item.check_in_time) }}</template>
          <template #cell-checkOut="{ item }">{{ formatTime(item.check_out_time) }}</template>

          <template #cell-status="{ item }">
            <BaseBadge :theme="statusFor(item).theme">{{ statusFor(item).label }}</BaseBadge>
          </template>

          <template #actions="{ item }">
            <router-link :to="{ name: 'DetailAbsen', params: { id: item.id } }" class="link-btn">
              Lihat Detail
            </router-link>
          </template>
        </BaseTable>

        <BasePagination
          :current-page="currentPage"
          :last-page="lastPage"
          :per-page="perPage"
          :total="totalRecords"
          :loading="loading"
          @page-change="fetchAttendance"
          @per-page-change="onPerPageChange"
        />
      </template>
    </BasePanel>
  </div>
</template>

<style scoped>
.attendance-page {
  --blue-900: #2f3b69;
  --ink-soft: #667085;
  --line: #d9dde5;
  font-family: 'Plus Jakarta Sans', sans-serif;
}

/* Header di dalam kartu */
.header-left {
  display: flex;
  align-items: center;
  gap: 12px;
}
.heading h2 {
  margin: 0;
  color: var(--blue-900);
  font-size: 18px;
  font-weight: 700;
}
.heading p {
  margin: 4px 0 0;
  color: var(--ink-soft);
  font-size: 13px;
}
.heading-eyebrow {
  display: block;
  margin-bottom: 3px;
  color: var(--ink-soft);
  font-size: 12px;
}

/* Layout */
.summary-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
  gap: 14px;
  margin-bottom: 20px;
}
.filter-bar {
  display: flex;
  align-items: flex-end;
  justify-content: space-between;
  flex-wrap: wrap;
  gap: 10px;
  padding: 18px 24px;
  background: #fff;
  border-bottom: 1px solid var(--line);
}
.search-wrap {
  flex: 1;
  display: flex;
  justify-content: flex-end;
}
.export-wrap { margin-left: 12px; }

/* Isi sel tabel */
.count-badge {
  display: inline-flex;
  font-size: 12px;
  color: var(--ink-soft);
  background: #e9edf7;
  border-radius: 999px;
  padding: 4px 10px;
  font-weight: 700;
}
.employee { display: flex; align-items: center; gap: 12px; }
.employee strong { font-size: 14px; color: #1c1c19; font-weight: 700; }
.employee-avatar {
  width: 36px;
  height: 36px;
  border-radius: 50%;
  background: #e2e5f0;
  color: var(--blue-900);
  font-size: 12px;
  font-weight: 700;
  display: grid;
  place-items: center;
  flex-shrink: 0;
}
.link-btn {
  display: inline-flex;
  align-items: center;
  color: var(--blue-900);
  font-weight: 700;
  font-size: 14px;
  background: none;
  border: none;
  cursor: pointer;
  text-decoration: none;
  white-space: nowrap;
}
.link-btn:hover { text-decoration: underline; }

@media (max-width: 760px) {
  .search-wrap { justify-content: flex-start; width: 100%; margin-top: 10px; }
  .export-wrap { width: 100%; margin-left: 0; margin-top: 10px; display: flex; justify-content: stretch; }
  .export-wrap :deep(.base-btn) { width: 100%; justify-content: center; }
}
</style>