<script setup>
import { ref, computed, onMounted, onBeforeUnmount, nextTick, watch } from 'vue'
import { Icon } from '@iconify/vue'
import L from 'leaflet'
import 'leaflet/dist/leaflet.css'
import api from '../api'

/*
  Free map picker using Leaflet + OpenStreetMap tiles + Nominatim search.
  No API key required.
*/

const locations = ref([])
const loading = ref(false)
const searchQuery = ref('')
const currentPage = ref(1)
const perPage = ref(10)
const totalCount = ref(0)

const filteredLocations = computed(() => {
  const q = searchQuery.value.trim().toLowerCase()
  if (!q) return locations.value
  return locations.value.filter((l) => {
    const addressText = String(l.address || '').toLowerCase()
    return (
      l.name.toLowerCase().includes(q)
      || addressText.includes(q)
      || String(l.latitude).toLowerCase().includes(q)
      || String(l.longitude).toLowerCase().includes(q)
      || String(l.radius_meter || '').toLowerCase().includes(q)
    )
  })
})

const totalPages = computed(() => {
  const total = Math.max(1, Math.ceil(filteredLocations.value.length / perPage.value))
  if (currentPage.value > total) currentPage.value = total
  return total
})

const paginatedLocations = computed(() => {
  const start = (currentPage.value - 1) * perPage.value
  return filteredLocations.value.slice(start, start + perPage.value)
})

const displayTotal = computed(() => {
  return searchQuery.value.trim() ? filteredLocations.value.length : (totalCount.value || locations.value.length)
})

function prevPage() {
  if (currentPage.value > 1) currentPage.value -= 1
}

function nextPage() {
  if (currentPage.value < totalPages.value) currentPage.value += 1
}

watch([() => searchQuery.value, () => filteredLocations.value.length], () => {
  currentPage.value = 1
})

async function fetchLocations() {
  loading.value = true
  try {
    const res = await api.get('/locations')
    locations.value = res.data
    totalCount.value = Array.isArray(res.data) ? res.data.length : 0
  } catch (err) {
    console.error('Gagal mengambil data lokasi:', err)
  } finally {
    loading.value = false
  }
}

function onSearchInput() {
  // TODO: server-side search
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
  radius: 100,
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
  form.value = { name: '', latitude: '', longitude: '', radius: 100 }
  showModal.value = true
  nextTick(() => initMap())
}

function closeModal() {
  if (saving.value) return
  showModal.value = false
  destroyMap()
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
      if (mapInstance) mapInstance.setView([position.coords.latitude, position.coords.longitude], 15)
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

async function submitLocation() {
  saving.value = true
  try {
    await api.post('/locations', {
      name: form.value.name,
      latitude: form.value.latitude,
      longitude: form.value.longitude,
      radius_meter: form.value.radius,
    })
    showModal.value = false
    fetchLocations()
  } catch (err) {
    console.error('Gagal menyimpan lokasi:', err)
  } finally {
    saving.value = false
  }
}

onMounted(() => fetchLocations())
onBeforeUnmount(() => destroyMap())
</script>

<template>
  <div class="lokasi">
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
          </tr>
        </thead>
        <tbody>
          <tr v-if="loading">
            <td colspan="5" class="empty-cell">Memuat data...</td>
          </tr>
          <tr v-else-if="filteredLocations.length === 0">
            <td colspan="5" class="empty-cell">Tidak ada lokasi ditemukan.</td>
          </tr>
          <tr v-for="loc in paginatedLocations" :key="loc.id">
            <td>
              <div class="loc-name">{{ loc.name }}</div>
              <div class="loc-id">ID: {{ loc.id }}</div>
            </td>
            <td>{{ loc.latitude }}</td>
            <td>{{ loc.longitude }}</td>
            <td>{{ loc.radius_meter ?? '-' }}</td>
            <td>{{ loc.created_at ? new Date(loc.created_at).toLocaleDateString('id-ID') : '-' }}</td>
          </tr>
        </tbody>
      </table>

      <div class="table-footer">
        <span>Menampilkan {{ paginatedLocations.length }} dari {{ displayTotal }} lokasi</span>
        <div class="pager">
          <button :disabled="currentPage === 1" @click="prevPage">
            <Icon icon="material-symbols:chevron-left-rounded" width="18" height="18" />
          </button>
          <div style="display:flex;align-items:center;padding:0 8px;font-weight:600;color:var(--ink-soft);">Halaman {{ currentPage }} / {{ totalPages }}</div>
          <button :disabled="currentPage === totalPages" @click="nextPage">
            <Icon icon="material-symbols:chevron-right-rounded" width="18" height="18" />
          </button>
        </div>
      </div>
    </section>

    

    <!-- ================= MODAL TAMBAH LOKASI ================= -->
    <Teleport to="body">
      <div v-if="showModal" class="modal-overlay" @click.self="closeModal">
        <div class="modal" ref="modalRef">
          <div class="modal-head">
            <div class="modal-title">
              <Icon icon="material-symbols:add-location-alt-outline" width="22" height="22" />
              <h3>Tambah Lokasi Baru</h3>
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
                <input type="number" v-model="form.radius" placeholder="100" />
                <span>m</span>
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
                  <button class="map-search-btn" type="button" @click="searchLocation" :disabled="searchingLocation">
                    <Icon icon="material-symbols:search-rounded" width="16" height="16" />
                  </button>
                </div>
                <button class="map-action-btn" type="button" @click="useCurrentLocation" :disabled="geolocating">
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
              <Icon icon="material-symbols:save-outline" width="18" height="18" />
              {{ saving ? 'Menyimpan...' : 'Simpan Lokasi' }}
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
.lokasi * {
  box-sizing: border-box;
}

.panel {
  background: var(--card);
  border: 1px solid var(--line);
  border-radius: 16px;
}
.table-panel {
  padding: 22px 0 0;
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
  justify-content: space-between;
  align-items: center;
  padding: 16px 24px;
  font-size: 13px;
  color: var(--ink-soft);
  border-top: 1px solid var(--line);
}
.pager {
  display: flex;
  gap: 8px;
}
.pager button {
  width: 34px;
  height: 34px;
  border-radius: 8px;
  border: 1px solid var(--line);
  background: #fff;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
}
.pager button svg,
.pager button .iconify {
  color: var(--ink-soft);
}
.pager button:disabled {
  opacity: 0.4;
  cursor: not-allowed;
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
  position: fixed;
  inset: 0;
  background: rgba(28, 32, 55, 0.55);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
  padding: 24px;
}
.modal {
  width: 100%;
  max-width: 620px;
  max-height: 90vh;
  overflow-y: auto;
  background: #fff;
  border: 1px solid var(--line);
  border-radius: 18px;
  box-shadow: 0 20px 50px rgba(0, 0, 0, 0.25);
  font-family: 'Inter', system-ui, -apple-system, sans-serif;
}

/* Thinner, subtle scrollbar for modal while preserving scroll behavior */
.modal {
  scrollbar-width: thin;
  scrollbar-color: rgba(0,0,0,0.16) transparent;
}
.modal::-webkit-scrollbar {
  width: 8px;
}
.modal::-webkit-scrollbar-track {
  background: transparent;
}
.modal::-webkit-scrollbar-thumb {
  background: rgba(0,0,0,0.12);
  border-radius: 8px;
}
.modal::-webkit-scrollbar-thumb:hover {
  background: rgba(0,0,0,0.18);
}
.modal-head {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 22px 24px;
  background: var(--bg);
  border-bottom: 1px solid var(--line);
  border-radius: 18px 18px 0 0;
  position: sticky;
  top: 0;
  z-index: 1;
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
  padding: 24px;
  display: flex;
  flex-direction: column;
  gap: 20px;
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
}
.input-suffix span {
  font-size: 14px;
  color: var(--ink-soft);
  font-weight: 600;
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
  border: 1px solid var(--line);
  border-radius: 999px;
  background: #fff;
  padding: 0 8px 0 12px;
  flex: 1;
  min-width: 220px;
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
  border-radius: 999px;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
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
  border-radius: 999px;
  background: var(--bg);
  color: var(--blue-900);
  padding: 8px 12px;
  font-size: 13px;
  font-weight: 600;
  cursor: pointer;
}
.map-action-btn:disabled {
  opacity: 0.6;
  cursor: not-allowed;
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
  height: 240px;
  border-radius: 12px;
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
  padding: 18px 24px;
  border-top: 1px solid var(--line);
  background: var(--bg);
  border-radius: 0 0 18px 18px;
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
</style>