<script setup>
import { ref, computed, onMounted, onBeforeUnmount, nextTick, watch } from 'vue'
import { Icon } from '@iconify/vue'
import L from 'leaflet'
import 'leaflet/dist/leaflet.css'
import api from '../api'

// Data & State Utama
const locations = ref([])
const loading = ref(false)
const deletingId = ref(null)
const searchQuery = ref('')
const editingLocationId = ref(null)
const toast = ref({ show: false, type: 'success', message: '' })
let toastTimer = null

// Pagination State (Sama persis dengan dataabsensi)
const currentPage = ref(1)
const lastPage = ref(1)
const totalRecords = ref(0)
const perPage = ref(20)
const pageInput = ref(1)

// Filter & Pagination Logic
const filteredLocations = computed(() => {
  const q = searchQuery.value.trim().toLowerCase()
  let result = locations.value

  if (q) {
    result = result.filter((l) => {
      const addressText = String(l.address || '').toLowerCase()
      return (
        l.name.toLowerCase().includes(q) ||
        addressText.includes(q) ||
        String(l.latitude).toLowerCase().includes(q) ||
        String(l.longitude).toLowerCase().includes(q) ||
        String(l.radius_meter || '')
          .toLowerCase()
          .includes(q)
      )
    })
  }

  // Hitung total halaman berdasarkan data yang tersaring
  lastPage.value = Math.ceil(result.length / perPage.value) || 1

  // Potong array sesuai halaman saat ini (Client-side pagination)
  const start = (currentPage.value - 1) * perPage.value
  return result.slice(start, start + perPage.value)
})

// Watcher untuk menyinkronkan input halaman
watch(currentPage, (newPage) => {
  pageInput.value = newPage
})

watch([searchQuery], () => {
  currentPage.value = 1
  pageInput.value = 1
})

// Fungsi Aksi Pagination
function prevPage() {
  if (currentPage.value > 1) {
    currentPage.value--
    pageInput.value = currentPage.value
  }
}

function nextPage() {
  if (currentPage.value < lastPage.value) {
    currentPage.value++
    pageInput.value = currentPage.value
  }
}

function goToInputPage() {
  let page = Number(pageInput.value)
  if (isNaN(page) || page < 1) page = 1
  if (page > lastPage.value) page = lastPage.value
  currentPage.value = page
  pageInput.value = page
}

function changePerPage() {
  currentPage.value = 1
  pageInput.value = 1
}

// Fetch API
async function fetchLocations() {
  loading.value = true
  try {
    const res = await api.get('/locations')
    locations.value = Array.isArray(res.data) ? res.data : []
    totalRecords.value = locations.value.length
  } catch (err) {
    console.error('Gagal mengambil data lokasi:', err)
  } finally {
    loading.value = false
  }
}

function onSearchInput() {
  // Tempat pencarian server-side jika diperlukan di masa depan
}

/* ---------------- Modal Tambah Lokasi Baru ---------------- */
const showModal = ref(false)
const saving = ref(false)
const geolocating = ref(false)
const searchingLocation = ref(false)
const searchLocationQuery = ref('')
const mapContainer = ref(null)
let mapInstance = null
let markerInstance = null

const form = ref({
  name: '',
  latitude: '',
  longitude: '',
  radius: 25,
})

function createMarkerIcon() {
  return L.divIcon({
    html: '<div class="map-picker-pin"></div>',
    className: 'map-picker-icon-wrapper',
    iconSize: [28, 28],
    iconAnchor: [14, 28],
  })
}

function setCoordinates(lat, lng) {
  const parsedLat = Number(lat)
  const parsedLng = Number(lng)
  if (!Number.isFinite(parsedLat) || !Number.isFinite(parsedLng)) return

  form.value.latitude = parsedLat.toFixed(6)
  form.value.longitude = parsedLng.toFixed(6)

  if (markerInstance) markerInstance.setLatLng([parsedLat, parsedLng])
  if (mapInstance) mapInstance.panTo([parsedLat, parsedLng])
}

function initMap() {
  if (!mapContainer.value || mapInstance) return

  const defaultLat = Number.parseFloat(form.value.latitude) || -6.2088
  const defaultLng = Number.parseFloat(form.value.longitude) || 106.8456

  mapInstance = L.map(mapContainer.value).setView([defaultLat, defaultLng], 13)
  L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
    attribution: '&copy; OpenStreetMap contributors',
  }).addTo(mapInstance)

  markerInstance = L.marker([defaultLat, defaultLng], {
    draggable: true,
    icon: createMarkerIcon(),
  }).addTo(mapInstance)

  markerInstance.on('dragend', (e) => {
    const p = e.target.getLatLng()
    setCoordinates(p.lat, p.lng)
  })

  mapInstance.on('click', (e) => {
    setCoordinates(e.latlng.lat, e.latlng.lng)
  })
}

function destroyMap() {
  if (mapInstance) {
    mapInstance.off()
    mapInstance.remove()
    mapInstance = null
  }
  markerInstance = null
}

function openAddModal() {
  editingLocationId.value = null
  form.value = { name: '', latitude: '', longitude: '', radius: 25 }
  showModal.value = true
  nextTick(() => initMap())
}

function openEditModal(location) {
  editingLocationId.value = location?.id ?? null
  form.value = {
    name: location?.name || '',
    latitude: location?.latitude ?? '',
    longitude: location?.longitude ?? '',
    radius: Number(location?.radius_meter ?? location?.radius ?? 100),
  }
  showModal.value = true
  nextTick(() => {
    initMap()
    if (form.value.latitude && form.value.longitude) {
      setCoordinates(form.value.latitude, form.value.longitude)
    }
  })
}

function closeModal(force = false) {
  if (saving.value && !force) return
  showModal.value = false
  editingLocationId.value = null
  destroyMap()
}

function handleMissingBackendFeature(action) {
  const message =
    `Fitur ${action} sudah dibuat di frontend, tetapi endpoint backend belum tersedia atau belum dihubungkan. ` +
    'Silakan sambungkan API dari backend teman Anda.'
  window.alert(message)
}

function showToast(message, type = 'success') {
  toast.value = { show: true, type, message }

  if (toastTimer) {
    clearTimeout(toastTimer)
  }

  toastTimer = setTimeout(() => {
    toast.value.show = false
  }, 2600)
}

function useCurrentLocation() {
  if (!navigator.geolocation) {
    window.alert('Browser ini tidak mendukung geolocation.')
    return
  }

  geolocating.value = true
  navigator.geolocation.getCurrentPosition(
    (position) => {
      setCoordinates(position.coords.latitude, position.coords.longitude)
      if (mapInstance)
        mapInstance.setView([position.coords.latitude, position.coords.longitude], 15)
      geolocating.value = false
    },
    () => {
      geolocating.value = false
      window.alert('Tidak bisa mengambil lokasi saat ini. Silakan pilih titik di peta.')
    },
  )
}

async function searchLocation() {
  const query = searchLocationQuery.value.trim()
  if (!query) return
  searchingLocation.value = true
  try {
    const resp = await fetch(
      `https://nominatim.openstreetmap.org/search?format=jsonv2&limit=5&q=${encodeURIComponent(query)}`,
      { headers: { 'Accept-Language': 'id' } },
    )
    const results = await resp.json()
    if (results?.[0]) {
      const p = results[0]
      setCoordinates(p.lat, p.lon)
      if (mapInstance) mapInstance.setView([Number(p.lat), Number(p.lon)], 15)
    } else {
      window.alert('Lokasi tidak ditemukan. Coba kata kunci lain.')
    }
  } catch (err) {
    console.error('Gagal mencari lokasi:', err)
    window.alert('Gagal mencari lokasi. Silakan coba lagi.')
  } finally {
    searchingLocation.value = false
  }
}

watch(
  () => [form.value.latitude, form.value.longitude],
  ([latitude, longitude]) => {
    const lat = Number.parseFloat(latitude)
    const lng = Number.parseFloat(longitude)
    if (!Number.isFinite(lat) || !Number.isFinite(lng)) return
    if (markerInstance) markerInstance.setLatLng([lat, lng])
    if (mapInstance) mapInstance.panTo([lat, lng])
  },
  { flush: 'post' },
)

watch(showModal, (isOpen) => {
  document.body.classList.toggle('modal-open', isOpen)
})

async function submitLocation() {
  const trimmedName = String(form.value.name || '').trim()
  const latitude = Number(form.value.latitude)
  const longitude = Number(form.value.longitude)
  const radius = Number(form.value.radius)

  if (!trimmedName) {
    window.alert('Nama lokasi wajib diisi.')
    return
  }

  if (!Number.isFinite(latitude) || !Number.isFinite(longitude)) {
    window.alert('Pilih titik lokasi di peta atau gunakan GPS terlebih dahulu.')
    return
  }

  if (latitude < -90 || latitude > 90 || longitude < -180 || longitude > 180) {
    window.alert('Koordinat lokasi tidak valid.')
    return
  }

  if (!Number.isFinite(radius) || radius <= 0) {
    window.alert('Radius lokasi harus lebih dari 0 meter.')
    return
  }

  saving.value = true
  try {
    const payload = {
      name: trimmedName,
      latitude,
      longitude,
      radius_meter: Math.round(radius),
    }

    const isEditing = !!editingLocationId.value
    if (isEditing) {
      try {
        await api.put(`/locations/${editingLocationId.value}`, payload)
      } catch (err) {
        const status = err.response?.status
        if (status === 404 || status === 405) {
          await api.patch(`/locations/${editingLocationId.value}`, payload)
        } else {
          throw err
        }
      }
    } else {
      await api.post('/locations', payload)
    }

    saving.value = false
    closeModal(true)
    await fetchLocations()
    showToast(isEditing ? 'Lokasi berhasil diperbarui.' : 'Lokasi berhasil ditambahkan.')
  } catch (err) {
    console.error('Gagal menyimpan lokasi:', err)
    const status = err.response?.status
    const actionText = editingLocationId.value ? 'mengubah' : 'menyimpan'

    if (status === 404 || status === 405 || String(err.message).includes('Network Error')) {
      handleMissingBackendFeature(actionText)
    } else {
      const backendMessage = err.response?.data?.message || err.response?.data?.error || ''
      const details = backendMessage ? `\nDetail: ${backendMessage}` : ''
      window.alert(`Gagal ${actionText} lokasi. Silakan cek data yang dimasukkan.${details}`)
    }
  } finally {
    saving.value = false
  }
}

async function deleteLocation(location) {
  if (!location?.id) return

  const confirmed = window.confirm(`Hapus lokasi "${location.name}"?`)
  if (!confirmed) return

  deletingId.value = location.id
  try {
    await api.delete(`/locations/${location.id}`)
    await fetchLocations()
    showToast('Lokasi berhasil dihapus.')
  } catch (err) {
    console.error('Gagal menghapus lokasi:', err)
    const status = err.response?.status
    if (status === 404 || status === 405 || String(err.message).includes('Network Error')) {
      handleMissingBackendFeature('menghapus')
    } else {
      window.alert('Gagal menghapus lokasi. Silakan coba lagi.')
    }
  } finally {
    deletingId.value = null
  }
}

onMounted(() => fetchLocations())
onBeforeUnmount(() => {
  if (toastTimer) clearTimeout(toastTimer)
  document.body.classList.remove('modal-open')
  destroyMap()
})
</script>

<template>
  <div class="lokasi">
    <div v-if="toast.show" class="toast" :class="toast.type">
      <Icon
        :icon="toast.type === 'success' ? 'material-symbols:check-circle-rounded' : 'material-symbols:error-rounded'"
        width="18"
        height="18"
      />
      <span>{{ toast.message }}</span>
    </div>
    <section class="panel table-panel">
      <div class="table-head">
        <div class="search">
          <Icon icon="material-symbols:search-rounded" width="18" height="18" />
          <input
            type="text"
            v-model="searchQuery"
            @input="onSearchInput"
            placeholder="Cari lokasi cabang ..."
          />
        </div>
        <button class="icon-btn-solid" @click="openAddModal">
          <Icon icon="material-symbols:add-rounded" width="20" height="20" />
        </button>
      </div>

      <table>
        <thead>
          <tr>
            <th>Nama Cabang</th>
            <th>Latitude</th>
            <th>Longitude</th>
            <th>Radius (m)</th>
            <th>Dibuat</th>
            <th class="action-column">Aksi</th>
          </tr>
        </thead>
        <tbody>
          <tr v-if="loading && locations.length === 0">
            <td colspan="6" class="empty-cell">Memuat data...</td>
          </tr>
          <tr v-else-if="filteredLocations.length === 0">
            <td colspan="6" class="empty-cell">Tidak ada lokasi ditemukan.</td>
          </tr>
          <tr v-for="loc in filteredLocations" :key="loc.id">
            <td>
              <div class="loc-name">{{ loc.name }}</div>
              <div class="loc-id">ID: {{ loc.id }}</div>
            </td>
            <td>{{ loc.latitude }}</td>
            <td>{{ loc.longitude }}</td>
            <td>{{ loc.radius_meter ?? '-' }}</td>
            <td>
              {{ loc.created_at ? new Date(loc.created_at).toLocaleDateString('id-ID') : '-' }}
            </td>
            <td class="action-cell">
              <div class="action-actions">
                <button type="button" class="action-btn edit-btn" @click="openEditModal(loc)">
                  <Icon icon="material-symbols:edit-outline-rounded" width="16" height="16" />
                  Edit
                </button>
                <button
                  type="button"
                  class="action-btn delete-btn"
                  @click="deleteLocation(loc)"
                  :disabled="deletingId === loc.id"
                >
                  <Icon icon="material-symbols:delete-outline-rounded" width="16" height="16" />
                  {{ deletingId === loc.id ? 'Menghapus...' : 'Delete' }}
                </button>
              </div>
            </td>
          </tr>
        </tbody>
      </table>

      <div class="table-footer">
        <div class="table-footer-content">
          <!-- Kontrol Pagination -->
          <div class="pager">
            <button
              type="button"
              class="pager-btn"
              :disabled="currentPage === 1 || loading"
              @click="prevPage"
              title="Halaman Sebelumnya"
            >
              <Icon icon="material-symbols:chevron-left-rounded" width="18" height="18" />
            </button>

            <div class="page-input-wrapper">
              <span>Halaman</span>
              <input
                type="number"
                v-model.number="pageInput"
                @keydown.enter="goToInputPage"
                @blur="goToInputPage"
                min="1"
                :max="lastPage"
                class="page-input"
              />
              <span>dari {{ lastPage }}</span>
            </div>

            <button
              type="button"
              class="pager-btn"
              :disabled="currentPage === lastPage || loading"
              @click="nextPage"
              title="Halaman Berikutnya"
            >
              <Icon icon="material-symbols:chevron-right-rounded" width="18" height="18" />
            </button>
          </div>

          <!-- Dropdown Per Page / Rows -->
          <div class="per-page-select">
            <select v-model="perPage" @change="changePerPage" :disabled="loading">
              <option :value="10">10 baris</option>
              <option :value="20">20 baris</option>
              <option :value="50">50 baris</option>
              <option :value="100">100 baris</option>
            </select>
          </div>

          <!-- Informasi Total Records -->
          <span class="total-records-info">{{ locations.length }} catatan</span>
        </div>
      </div>
    </section>

    <!-- ================= MODAL TAMBAH LOKASI ================= -->
    <Teleport to="body">
      <div v-if="showModal" class="modal-overlay" @click.self="closeModal">
        <div class="modal" ref="modalRef">
          <div class="modal-head">
            <div class="modal-title">
              <Icon
                :icon="editingLocationId ? 'material-symbols:edit-location-alt-rounded' : 'material-symbols:add-location-alt-outline'"
                width="22"
                height="22"
              />
              <h3>{{ editingLocationId ? 'Edit Lokasi' : 'Tambah Lokasi Baru' }}</h3>
            </div>
          </div>

          <div class="modal-body">
            <div class="field">
              <label>Nama Outlet / Lokasi</label>
              <input type="text" v-model="form.name" placeholder="Contoh: Peternakan Blok C" />
            </div>

            <div class="field-row">
              <div class="field">
                <label>Latitude</label>
                <input type="text" v-model="form.latitude" placeholder="-6.2088" />
              </div>
              <div class="field">
                <label>Longitude</label>
                <input type="text" v-model="form.longitude" placeholder="106.8456" />
              </div>
            </div>

            <div class="field">
              <label>Radius Absensi (Meter)</label>
              <div class="input-suffix">
                <input type="number" v-model="form.radius" min="0" placeholder="25" />
              </div>
            </div>

            <div class="field">
              <label>Pilih Lokasi di Peta</label>
              <div class="map-actions">
                <div class="map-search">
                  <input
                    ref="searchInput"
                    v-model="searchLocationQuery"
                    type="text"
                    placeholder="Cari nama tempat / alamat"
                    @keydown.enter.prevent="searchLocation"
                  />
                  <button
                    class="map-search-btn"
                    type="button"
                    @click="searchLocation"
                    :disabled="searchingLocation"
                  >
                    <Icon icon="material-symbols:search-rounded" width="16" height="16" />
                  </button>
                </div>
                <button
                  class="map-action-btn"
                  type="button"
                  @click="useCurrentLocation"
                  :disabled="geolocating"
                >
                  <Icon icon="material-symbols:my-location-rounded" width="16" height="16" />
                  {{ geolocating ? 'Mengambil lokasi...' : 'Gunakan lokasi saya' }}
                </button>
              </div>
              <div class="map-help-box">
                <span>• Klik peta untuk menandai titik</span>
                <span>• Seret pin untuk mengatur posisi</span>
              </div>
              <div ref="mapContainer" class="map-preview"></div>
              <div class="map-coords">
                Lat: {{ form.latitude || '-' }} | Long: {{ form.longitude || '-' }}
              </div>
            </div>
          </div>

          <div class="modal-footer">
            <button class="btn-cancel" @click="closeModal" :disabled="saving">Batal</button>
            <button class="btn-save" @click="submitLocation" :disabled="saving">
              <Icon :icon="editingLocationId ? 'material-symbols:save-outline' : 'material-symbols:save-outline'" width="18" height="18" />
              {{ saving ? (editingLocationId ? 'Menyimpan perubahan...' : 'Menyimpan...') : (editingLocationId ? 'Simpan Perubahan' : 'Simpan Lokasi') }}
            </button>
          </div>
        </div>
      </div>
    </Teleport>
  </div>
</template>

<style scoped>
.lokasi {
  --blue-900: #2f3b69;
  --red: #d91e2e;
  --red-bg: #fdebed;
  --mint-bg: #ddf5ec;
  --mint-text: #177a5b;
  --ink: #1c1c19;
  --ink-soft: #667085;
  --line: #d9dde5;
  --bg: #f7f8fa;
  --card: #ffffff;
}
.lokasi {
  font-family: 'Plus Jakarta Sans', sans-serif;
}
.lokasi * {
  box-sizing: border-box;
  font-family: 'Plus Jakarta Sans', sans-serif;
}
.lokasi button,
.lokasi input,
.lokasi select,
.lokasi textarea {
  font-family: 'Plus Jakarta Sans', sans-serif;
}

.panel {
  background: var(--card);
  border: 1px solid var(--line);
  border-radius: 16px;
}
.table-panel {
  padding: 22px 0 0;
}
.action-column {
  width: 170px;
  text-align: center;
}
.action-cell {
  text-align: center;
}
.action-actions {
  display: flex;
  justify-content: center;
  align-items: center;
  gap: 8px;
  flex-wrap: nowrap;
  white-space: nowrap;
}
.action-btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 6px;
  border: none;
  border-radius: 8px;
  padding: 8px 10px;
  font-size: 0.8rem;
  font-weight: 600;
  cursor: pointer;
  transition: 0.2s ease;
  white-space: nowrap;
}
.edit-btn {
  background: #edf4ff;
  color: #1d4ed8;
}
.edit-btn:hover {
  background: #dfeeff;
}
.delete-btn {
  background: #ffe9eb;
  color: #c92d40;
}
.delete-btn:hover:not(:disabled) {
  background: #ffd9de;
}
.delete-btn:disabled {
  cursor: wait;
  opacity: 0.7;
}
.table-head {
  display: flex;
  justify-content: flex-end;
  align-items: center;
  gap: 10px;
  padding: 0 24px 22px;
  flex-wrap: wrap;
}
.search {
  display: flex;
  align-items: center;
  gap: 8px;
  background: var(--bg);
  border: 1px solid var(--line);
  padding: 10px 16px;
  border-radius: 10px;
  min-width: 280px;
}
.search svg,
.search .iconify {
  width: 18px;
  height: 18px;
  color: var(--ink-soft);
  flex-shrink: 0;
}
.search input {
  border: none;
  background: none;
  outline: none;
  font-size: 14px;
  width: 100%;
  font-family: inherit;
  color: var(--ink);
}
.icon-btn-solid {
  width: 44px;
  height: 44px;
  border-radius: 10px;
  background: var(--blue-900);
  border: none;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  flex-shrink: 0;
  transition: background 0.15s ease;
}
.icon-btn-solid:hover {
  background: #273258;
}
.icon-btn-solid svg,
.icon-btn-solid .iconify {
  color: #fff;
}

table {
  width: 100%;
  border-collapse: collapse;
}
thead tr {
  background: var(--blue-900);
}
thead th {
  color: #eef0f7;
  font-size: 11.5px;
  font-weight: 700;
  letter-spacing: 0.06em;
  text-align: left;
  padding: 14px 24px;
  text-transform: uppercase;
}
tbody td {
  padding: 18px 24px;
  font-size: 15px;
  border-bottom: 1px solid var(--line);
  vertical-align: middle;
  color: var(--ink);
}
tbody tr:last-child td {
  border-bottom: none;
}
.empty-cell {
  text-align: center;
  color: var(--ink-soft);
  padding: 32px;
}
.loc-name {
  font-weight: 700;
  font-size: 15px;
}
.loc-id {
  font-size: 12px;
  color: var(--ink-soft);
  margin-top: 2px;
}
.badge {
  display: inline-flex;
  align-items: center;
  font-size: 12.5px;
  font-weight: 700;
  padding: 5px 14px;
  border-radius: 20px;
}
.badge.aktif {
  background: var(--mint-bg);
  color: var(--mint-text);
}
.badge.nonaktif {
  background: var(--red-bg);
  color: var(--red);
}

.table-footer {
  display: flex;
  justify-content: flex-end;
  align-items: center;
  padding: 12px 20px;
  font-size: 13px;
  color: var(--ink-soft);
  border-top: 1px solid var(--line);
  background: var(--bg);
  border-radius: 0 0 15px 15px;
}

.table-footer-content {
  display: flex;
  align-items: center;
  gap: 16px;
}

.pager {
  display: flex;
  align-items: center;
  gap: 6px;
}

.pager-btn {
  width: 32px;
  height: 32px;
  border-radius: 6px;
  border: 1px solid var(--line);
  background: var(--card);
  display: inline-flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  transition: all 0.15s ease;
  color: var(--ink-soft);
}

.pager-btn:hover:not(:disabled) {
  background: #fff;
  border-color: var(--blue-900);
  color: var(--blue-900);
}

.pager-btn:disabled {
  opacity: 0.4;
  cursor: not-allowed;
}

.page-input-wrapper {
  display: flex;
  align-items: center;
  gap: 6px;
  font-weight: 600;
  color: var(--ink-soft);
  font-size: 13px;
}

.page-input {
  font-family: 'Plus Jakarta Sans', sans-serif;
  width: 44px;
  height: 32px;
  text-align: center;
  border: 1px solid var(--line);
  border-radius: 6px;
  background: var(--card);
  color: var(--ink);
  font-weight: 700;
  font-size: 13px;
  outline: none;
  -moz-appearance: textfield;
}

.page-input::-webkit-outer-spin-button,
.page-input::-webkit-inner-spin-button {
  -webkit-appearance: none;
  margin: 0;
}

.page-input:focus {
  border-color: var(--blue-900);
  box-shadow: 0 0 0 2px rgba(47, 59, 105, 0.12);
}

.per-page-select select {
  height: 32px;
  padding: 0 10px;
  border: 1px solid var(--line);
  border-radius: 6px;
  background: var(--card);
  color: var(--ink);
  font-size: 13px;
  font-weight: 600;
  cursor: pointer;
  outline: none;
  font-family: 'Plus Jakarta Sans', sans-serif !important;
}

.per-page-select select:focus {
  border-color: var(--blue-900);
}

.per-page-select select option {
  font-family: 'Plus Jakarta Sans', sans-serif !important;
  font-size: 13px;
  font-weight: 600;
  color: var(--ink);
  background: var(--card);
}

.total-records-info {
  font-size: 13px;
  font-weight: 600;
  color: var(--ink-soft);
  white-space: nowrap;
}

.add-btn-row {
  display: flex;
  justify-content: flex-end;
  margin-top: 20px;
}
.add-btn {
  display: flex;
  align-items: center;
  gap: 8px;
  background: var(--blue-900);
  color: #fff;
  border: none;
  padding: 14px 22px;
  border-radius: 12px;
  font-size: 14.5px;
  font-weight: 700;
  cursor: pointer;
  transition: background 0.15s ease;
}
.add-btn:hover {
  background: #273258;
}
.add-btn svg,
.add-btn .iconify {
  color: #fff;
}

@media (max-width: 700px) {
  .table-head {
    justify-content: stretch;
  }
  .search {
    min-width: 0;
    flex: 1;
  }
}

/* ================= MODAL ================= */
.modal-overlay {
  --blue-900: #2f3b69;
  --red: #d91e2e;
  --red-bg: #fdebed;
  --mint-bg: #ddf5ec;
  --mint-text: #177a5b;
  --ink: #1c1c19;
  --ink-soft: #667085;
  --line: #d9dde5;
  --bg: #f7f8fa;
  --card: #ffffff;
  position: fixed;
  inset: 0;
  background: rgba(28, 32, 55, 0.55);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
  padding: 24px;
  overflow-y: auto;
  overscroll-behavior: contain;
  font-family: 'Plus Jakarta Sans', sans-serif;
}
.modal-overlay button,
.modal-overlay input,
.modal-overlay select,
.modal-overlay textarea {
  font-family: 'Plus Jakarta Sans', sans-serif;
}

.modal {
  width: 100%;
  max-width: 620px;
  max-height: calc(100dvh - 32px);
  overflow-y: auto;
  overflow-x: hidden;
  overscroll-behavior: contain;
  scrollbar-gutter: stable;
  background: #fff;
  border: 1px solid var(--line);
  border-radius: 20px;
  clip-path: inset(0 round 20px);
  box-shadow: 0 20px 50px rgba(0, 0, 0, 0.25);
  font-family: 'Plus Jakarta Sans', sans-serif;
}

/* Thinner, subtle scrollbar for modal while preserving scroll behavior */
.modal {
  scrollbar-width: thin;
  scrollbar-color: rgba(0, 0, 0, 0.16) transparent;
}
.modal::-webkit-scrollbar {
  width: 8px;
}
.modal::-webkit-scrollbar-track {
  background: transparent;
  border-radius: 20px;
}
.modal::-webkit-scrollbar-thumb {
  background: rgba(0, 0, 0, 0.12);
  border: 2px solid transparent;
  background-clip: padding-box;
  border-radius: 20px;
}
.modal::-webkit-scrollbar-thumb:hover {
  background: rgba(0, 0, 0, 0.18);
}
.modal-head {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 18px 24px;
  background: var(--bg);
  border-bottom: 1px solid var(--line);
  border-radius: 20px 20px 0 0;
}
.modal-title {
  display: flex;
  align-items: center;
  gap: 10px;
}
.modal-title .iconify {
  color: var(--blue-900);
}
.modal-title h3 {
  margin: 0;
  font-size: 18px;
  font-weight: 700;
  color: var(--blue-900);
}
.modal-close {
  width: 32px;
  height: 32px;
  border-radius: 8px;
  border: none;
  background: transparent;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  color: var(--ink-soft);
}
.modal-close:hover {
  background: rgba(0, 0, 0, 0.06);
}

.modal-body {
  padding: 18px 24px 16px;
  display: flex;
  flex-direction: column;
  gap: 14px;
}
.field {
  display: flex;
  flex-direction: column;
  gap: 8px;
  flex: 1;
}
.field label {
  font-size: 13.5px;
  font-weight: 600;
  color: var(--ink-soft);
}
.field input {
  border: 1px solid var(--line);
  border-radius: 10px;
  padding: 12px 14px;
  font-size: 14px;
  font-family: inherit;
  color: var(--ink);
  outline: none;
}
.field input:focus {
  border-color: var(--blue-900);
}
.field-row {
  display: flex;
  gap: 16px;
}
.input-suffix {
  display: flex;
  align-items: center;
  border: 1px solid var(--line);
  border-radius: 10px;
  padding: 0 14px;
}
.input-suffix input {
  border: none;
  padding: 12px 0;
  flex: 1;
  outline: none;
  font-size: 14px;
  font-family: inherit;
  color: var(--ink);
  width: 100%;
}
.field-counter {
  font-size: 12px;
  color: var(--ink-soft);
  margin-top: -4px;
}

.map-actions {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  margin-bottom: 8px;
  flex-wrap: wrap;
}
.map-search {
  display: flex;
  align-items: center;
  border: 1px solid #d9dde5;
  border-radius: 12px;
  background: #fff;
  padding: 0 8px 0 12px;
  flex: 1;
  min-width: 220px;
  height: 46px;
}
.map-search input {
  border: none;
  background: transparent;
  outline: none;
  padding: 10px 0;
  font-size: 13px;
  width: 100%;
  color: var(--ink);
}
.map-search-btn {
  border: none;
  background: var(--blue-900);
  color: #fff;
  width: 34px;
  height: 34px;
  border-radius: 50%;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}
.map-search-btn:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}
.map-action-btn {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  border: 1px solid var(--line);
  border-radius: 12px;
  background: var(--bg);
  color: var(--ink);
  padding: 8px 12px;
  font-size: 13px;
  font-weight: 600;
  cursor: pointer;
  height: 46px;
}
.map-action-btn:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}
.toast {
  position: fixed;
  right: 24px;
  bottom: 24px;
  z-index: 1000;
  display: inline-flex;
  align-items: center;
  gap: 8px;
  padding: 12px 16px;
  border-radius: 12px;
  font-size: 14px;
  font-weight: 600;
  color: white;
  box-shadow: 0 10px 30px rgba(17, 24, 39, 0.15);
  animation: toastIn 0.2s ease;
}
.toast.success {
  background: #1f9d67;
}
.toast.error {
  background: #d92d20;
}
@keyframes toastIn {
  from {
    opacity: 0;
    transform: translateY(10px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}
.map-help-box {
  display: flex;
  flex-wrap: wrap;
  gap: 10px;
  font-size: 12px;
  color: var(--ink-soft);
  margin-bottom: 8px;
}
.map-preview {
  position: relative;
  height: 190px;
  border-radius: 14px;
  overflow: hidden;
  border: 1px solid var(--line);
  background: #eef0f7;
}
.map-preview > div,
.map-preview .gm-style,
.map-preview .leaflet-container {
  width: 100%;
  height: 100%;
  font-family: inherit;
}
.map-picker-pin {
  width: 20px;
  height: 20px;
  border-radius: 999px;
  background: var(--blue-900);
  border: 3px solid #fff;
  box-shadow: 0 0 0 4px rgba(47, 59, 105, 0.18);
}
.map-picker-icon-wrapper {
  background: transparent;
  border: none;
}
.map-coords {
  margin-top: 10px;
  background: var(--bg);
  color: var(--ink);
  font-size: 12px;
  font-weight: 600;
  padding: 8px 10px;
  border-radius: 6px;
  display: inline-block;
}

.modal-footer {
  display: flex;
  justify-content: flex-end;
  gap: 12px;
  padding: 16px 24px 18px;
  border-top: 1px solid var(--line);
  background: var(--bg);
  border-radius: 0 0 20px 20px;
}
.btn-cancel {
  padding: 12px 20px;
  border-radius: 10px;
  border: 1px solid var(--line);
  background: #fff;
  color: var(--ink);
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
}
.btn-cancel:hover {
  background: #eef0f7;
}
.btn-save {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 12px 22px;
  border-radius: 10px;
  border: none;
  background: var(--blue-900);
  color: #fff;
  font-size: 14px;
  font-weight: 700;
  cursor: pointer;
  transition: background 0.15s ease;
}
.btn-save:hover {
  background: #273258;
}
.btn-save:disabled,
.btn-cancel:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

:global(body.modal-open .page-content) {
  overflow: hidden;
}

@media (max-width: 700px) {
  .modal-overlay {
    align-items: flex-start;
    padding: 12px;
  }

  .modal {
    max-height: calc(100dvh - 24px);
    border-radius: 16px;
  }

  .modal-head,
  .modal-body,
  .modal-footer {
    padding-left: 16px;
    padding-right: 16px;
  }

  .field-row {
    flex-direction: column;
    gap: 14px;
  }

  .map-search {
    min-width: 0;
    width: 100%;
  }

  .map-action-btn {
    width: 100%;
    justify-content: center;
  }

  .modal-footer {
    flex-wrap: wrap;
  }

  .btn-cancel,
  .btn-save {
    flex: 1 1 140px;
    justify-content: center;
  }
}
</style>
