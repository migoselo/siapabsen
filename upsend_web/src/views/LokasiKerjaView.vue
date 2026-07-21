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

function handleAddLocation() {
  // TODO: buka modal/route form tambah lokasi
  console.log('tambah lokasi baru')
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
        <button class="icon-btn-solid" @click="handleAddLocation">
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
      <button class="add-btn" @click="handleAddLocation">
        Tambah Lokasi Baru
        <Icon icon="material-symbols:add-rounded" width="18" height="18" />
      </button>
    </div>
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
  background: #F6F5F1;
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
</style>
