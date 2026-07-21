<script setup>
import { ref, computed, onMounted } from 'vue'
import { Icon } from '@iconify/vue'
import api from '../api'

/*
  View ini cuma berisi KONTEN halaman (sidebar & topbar sudah ditangani
  MainLayout.vue lewat router-view) — ikut pola yang sama dengan
  DashboardView.vue.
*/

const locations = ref([])
const loading = ref(false)
const searchQuery = ref('')

const filteredLocations = computed(() => {
  const q = searchQuery.value.trim().toLowerCase()
  if (!q) return locations.value
  return locations.value.filter(
    (l) => l.name.toLowerCase().includes(q) || l.address.toLowerCase().includes(q),
  )
})

async function fetchLocations() {
  loading.value = true
  try {
    // TODO: sesuaikan endpoint dengan API yang disediakan tim backend
    const res = await api.get('/locations')
    locations.value = res.data.locations
  } catch (err) {
    console.error('Gagal mengambil data lokasi:', err)
  } finally {
    loading.value = false
  }
}

function onSearchInput() {
  // TODO: kalau pencarian dilakukan di server, panggil endpoint terpisah di sini
}

/* ---------------- Modal Tambah Lokasi Baru ---------------- */
const showModal = ref(false)
const saving = ref(false)

const form = ref({
  name: '',
  latitude: '',
  longitude: '',
  radius: 100,
})

function openAddModal() {
  form.value = { name: '', latitude: '', longitude: '', radius: 100 }
  showModal.value = true
}

function closeModal() {
  if (saving.value) return
  showModal.value = false
}

async function submitLocation() {
  saving.value = true
  try {
    // TODO: sesuaikan endpoint dengan API yang disediakan tim backend
    await api.post('/locations', {
      name: form.value.name,
      latitude: form.value.latitude,
      longitude: form.value.longitude,
      radius: form.value.radius,
    })
    showModal.value = false
    fetchLocations()
  } catch (err) {
    console.error('Gagal menyimpan lokasi:', err)
  } finally {
    saving.value = false
  }
}

onMounted(() => {
  fetchLocations()
})
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
            <th>Alamat Cabang</th>
            <th>Latitude</th>
            <th>Longitude</th>
            <th>Status</th>
          </tr>
        </thead>
        <tbody>
          <tr v-if="loading">
            <td colspan="5" class="empty-cell">Memuat data...</td>
          </tr>
          <tr v-else-if="filteredLocations.length === 0">
            <td colspan="5" class="empty-cell">Tidak ada lokasi ditemukan.</td>
          </tr>
          <tr v-for="loc in filteredLocations" :key="loc.id">
            <td>
              <div class="loc-name">{{ loc.name }}</div>
              <div class="loc-id">ID: {{ loc.id }}</div>
            </td>
            <td>{{ loc.address }}</td>
            <td>{{ loc.latitude }}</td>
            <td>{{ loc.longitude }}</td>
            <td>
              <span class="badge" :class="loc.status === 'aktif' ? 'aktif' : 'nonaktif'">
                {{ loc.status === 'aktif' ? 'Aktif' : 'Nonaktif' }}
              </span>
            </td>
          </tr>
        </tbody>
      </table>

      <div class="table-footer">
        <span>Menampilkan {{ filteredLocations.length }} dari 150 lokasi</span>
        <div class="pager">
          <button disabled>
            <Icon icon="material-symbols:chevron-left-rounded" width="18" height="18" />
          </button>
          <button>
            <Icon icon="material-symbols:chevron-right-rounded" width="18" height="18" />
          </button>
        </div>
      </div>
    </section>

    <div class="add-btn-row">
      <button class="add-btn" @click="openAddModal">
        Tambah Lokasi Baru
        <Icon icon="material-symbols:add-rounded" width="18" height="18" />
      </button>
    </div>

    <!-- ================= MODAL TAMBAH LOKASI ================= -->
    <Teleport to="body">
      <div v-if="showModal" class="modal-overlay" @click.self="closeModal">
        <div class="modal">
          <div class="modal-head">
            <div class="modal-title">
              <Icon icon="material-symbols:add-location-alt-outline" width="22" height="22" />
              <h3>Tambah Lokasi Baru</h3>
            </div>
            <button class="modal-close" @click="closeModal">
              <Icon icon="material-symbols:close-rounded" width="20" height="20" />
            </button>
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
              <label>Preview Lokasi</label>
              <div class="map-preview">
                <div class="map-radius">
                  <div class="map-pin">
                    <Icon icon="material-symbols:location-on" width="18" height="18" />
                  </div>
                </div>
                <div class="map-coords">
                  Lat: {{ form.latitude || '-' }} | Long: {{ form.longitude || '-' }}
                </div>
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
  --green-900: #173d31;
  --red: #dc4646;
  --red-bg: #fdeaea;
  --mint-bg: #e1f3ea;
  --mint-text: #1c7a52;
  --ink: #1c2521;
  --ink-soft: #5b6864;
  --line: #e7e7e2;
  --bg: #ffffff;
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
  background: var(--green-900);
  border: none;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  flex-shrink: 0;
  transition: background 0.15s ease;
}
.icon-btn-solid:hover {
  background: #0f2b22;
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
  background: var(--green-900);
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
  background: #0f2b22;
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
  background: rgba(28, 37, 33, 0.55);
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
  border: 1px solid #e7e7e2;
  border-radius: 18px;
  box-shadow: 0 20px 50px rgba(0, 0, 0, 0.25);
  font-family: 'Inter', system-ui, -apple-system, sans-serif;
}
.modal-head {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 22px 24px;
  background: #f6f5f1;
  border-bottom: 1px solid #e7e7e2;
  border-radius: 18px 18px 0 0;
}
.modal-title {
  display: flex;
  align-items: center;
  gap: 10px;
}
.modal-title .iconify {
  color: #173d31;
}
.modal-title h3 {
  margin: 0;
  font-size: 18px;
  font-weight: 700;
  color: #154538;
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
  color: #5b6864;
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
  color: #404945;
}
.field input {
  border: 1px solid #e7e7e2;
  border-radius: 10px;
  padding: 12px 14px;
  font-size: 14px;
  font-family: inherit;
  color: #1c2521;
  outline: none;
}
.field input:focus {
  border-color: #173d31;
}
.field-row {
  display: flex;
  gap: 16px;
}
.input-suffix {
  display: flex;
  align-items: center;
  border: 1px solid #e7e7e2;
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
  color: #1c2521;
}
.input-suffix span {
  font-size: 14px;
  color: #5b6864;
  font-weight: 600;
}

.map-preview {
  position: relative;
  height: 220px;
  border-radius: 12px;
  overflow: hidden;
  border: 1px solid #e7e7e2;
  background:
    repeating-linear-gradient(45deg, #7fae5f 0 24px, #6fa04f 24px 48px),
    repeating-linear-gradient(-45deg, rgba(255, 255, 255, 0.05) 0 10px, transparent 10px 20px);
}
.map-radius {
  position: absolute;
  top: 50%;
  left: 50%;
  width: 130px;
  height: 130px;
  transform: translate(-50%, -50%);
  border-radius: 50%;
  background: rgba(255, 255, 255, 0.18);
  border: 2px solid rgba(255, 255, 255, 0.85);
  display: flex;
  align-items: center;
  justify-content: center;
}
.map-pin {
  width: 34px;
  height: 34px;
  border-radius: 50%;
  background: #fff;
  border: 3px solid #154538;
  display: flex;
  align-items: center;
  justify-content: center;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.3);
}
.map-pin .iconify {
  color: #154538;
}
.map-coords {
  position: absolute;
  left: 12px;
  bottom: 12px;
  background: rgba(255, 255, 255, 0.92);
  color: #1c2521;
  font-size: 12px;
  font-weight: 600;
  padding: 6px 10px;
  border-radius: 6px;
}

.modal-footer {
  display: flex;
  justify-content: flex-end;
  gap: 12px;
  padding: 18px 24px;
  border-top: 1px solid #e7e7e2;
  background: #f6f5f1;
  border-radius: 0 0 18px 18px;
}
.btn-cancel {
  padding: 12px 20px;
  border-radius: 10px;
  border: 1px solid #e7e7e2;
  background: #fff;
  color: #1c2521;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
}
.btn-cancel:hover {
  background: #f0f0eb;
}
.btn-save {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 12px 22px;
  border-radius: 10px;
  border: none;
  background: #2F5D4F;
  color: #fff;
  font-size: 14px;
  font-weight: 700;
  cursor: pointer;
  transition: background 0.15s ease;
}
.btn-save:hover {
  background: #0f2b22;
}
.btn-save:disabled,
.btn-cancel:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}
</style>