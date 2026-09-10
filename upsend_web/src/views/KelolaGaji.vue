<script setup>
import { computed, ref } from 'vue'
import { Download, Pencil, Plus, Search, Wallet } from 'lucide-vue-next'

const employees = [
  ['Ahmad Rivaldi', 'EMP-2023089', 'Sr. Software Engineer', 'Engineering', 5, 11500000, 2000000, 1550000, 650000, 'Aktif'],
  ['Siti Rahmawati', 'EMP-2023012', 'Product Manager', 'Product', 6, 13000000, 2500000, 1800000, 1100000, 'Aktif'],
  ['Budi Santoso', 'EMP-2022045', 'UI/UX Designer', 'Design', 4, 9000000, 1500000, 1250000, 500000, 'Menunggu Review'],
  ['Dewi Lestari', 'EMP-2024003', 'HR Specialist', 'HR', 3, 8500000, 1200000, 1150000, 450000, 'Aktif'],
  ['Rian Prasetyo', 'EMP-2023118', 'Backend Developer', 'Engineering', 4, 10800000, 1800000, 1650000, 600000, 'Perlu Update'],
  ['Fitri Handayani', 'EMP-2022150', 'Finance Analyst', 'Finance', 3, 8000000, 1200000, 900000, 400000, 'Aktif'],
  ['Joko Setiawan', 'EMP-2023151', 'Operations Staff', 'Operations', 4, 8800000, 1400000, 1100000, 450000, 'Aktif'],
].map((item, index) => ({ id: index + 1, name: item[0], code: item[1], position: item[2], divisi: item[3], grade: item[4], pokok: item[5], tetap: item[6], variabel: item[7], potongan: item[8], status: item[9] }))

const search = ref('')
const divisi = ref('Semua Divisi')
const status = ref('Semua Status')
const grade = ref('Semua Level')
const page = ref(1)
const pageSize = 5
const rupiah = (value) => `Rp ${Math.round(value).toLocaleString('id-ID')}`
const initials = (name) => name.split(' ').map((part) => part[0]).slice(0, 2).join('')
const divisions = computed(() => ['Semua Divisi', ...new Set(employees.map((employee) => employee.divisi))])
const filtered = computed(() => employees.filter((employee) => {
  const query = search.value.trim().toLowerCase()
  return (!query || [employee.name, employee.code, employee.position].some((value) => value.toLowerCase().includes(query))) && (divisi.value === 'Semua Divisi' || employee.divisi === divisi.value) && (status.value === 'Semua Status' || employee.status === status.value) && (grade.value === 'Semua Level' || employee.grade === Number(grade.value.replace('Grade ', '')))
}))
const totalPages = computed(() => Math.max(1, Math.ceil(filtered.value.length / pageSize)))
const pageItems = computed(() => filtered.value.slice((page.value - 1) * pageSize, page.value * pageSize))
const totalBudget = computed(() => employees.reduce((sum, employee) => sum + employee.pokok + employee.tetap + employee.variabel - employee.potongan, 0))
function resetPage() { page.value = 1 }
function setFilter(target, value) { target.value = value; resetPage() }
function goToPage(value) { page.value = Math.min(Math.max(1, value), totalPages.value) }
</script>

<template>
  <main class="salary-page">
    <header class="page-header"><div><p class="eyebrow">HR ADMINISTRATION</p><h1>Kelola Gaji Karyawan</h1></div><button class="button dark"><Plus :size="16" /> Tetapkan Gaji Baru</button></header>
    <section class="stats"><article><Wallet :size="18" /><span>Total Anggaran Bulanan</span><strong>{{ rupiah(totalBudget) }}</strong><small>+3.2% vs bulan lalu</small></article><article><span>Karyawan Bergaji</span><strong>{{ employees.length }} Orang</strong><small>Seluruh data payroll aktif</small></article><article><span>Rata-rata THP Netto</span><strong>{{ rupiah(totalBudget / employees.length) }}</strong><small>Estimasi penghasilan bersih</small></article></section>
    <section class="toolbar"><label class="search"><Search :size="16" /><input v-model="search" @input="resetPage" placeholder="Cari nama, NIK, atau posisi..." /></label><select :value="divisi" @change="setFilter(divisi, $event.target.value)"><option v-for="item in divisions" :key="item">{{ item }}</option></select><select :value="status" @change="setFilter(status, $event.target.value)"><option>Semua Status</option><option>Aktif</option><option>Menunggu Review</option><option>Perlu Update</option></select><select :value="grade" @change="setFilter(grade, $event.target.value)"><option>Semua Level</option><option v-for="item in [3, 4, 5, 6]" :key="item">Grade {{ item }}</option></select><button class="button"><Download :size="16" /> Ekspor</button></section>
    <section class="table-wrap"><table><thead><tr><th>Karyawan</th><th>Gaji Pokok</th><th>Tunj. Tetap</th><th>Tunj. Variabel</th><th>Potongan</th><th>Take Home Pay</th><th>Status</th><th /></tr></thead><tbody><tr v-for="employee in pageItems" :key="employee.id"><td><div class="employee"><span class="avatar">{{ initials(employee.name) }}</span><div><strong>{{ employee.name }}</strong><small>{{ employee.code }} · {{ employee.position }}</small></div></div></td><td>{{ rupiah(employee.pokok) }}</td><td>{{ rupiah(employee.tetap) }}</td><td>{{ rupiah(employee.variabel) }}</td><td class="negative">- {{ rupiah(employee.potongan) }}</td><td><b class="pay">{{ rupiah(employee.pokok + employee.tetap + employee.variabel - employee.potongan) }}</b></td><td><span class="status" :class="employee.status.toLowerCase().replaceAll(' ', '-')">{{ employee.status }}</span></td><td><button class="icon-button" title="Edit gaji"><Pencil :size="15" /></button></td></tr><tr v-if="!pageItems.length"><td colspan="8" class="empty">Tidak ada karyawan yang cocok dengan filter ini.</td></tr></tbody></table><footer><span>Menampilkan {{ pageItems.length ? (page - 1) * pageSize + 1 : 0 }}-{{ Math.min(page * pageSize, filtered.length) }} dari {{ filtered.length }} karyawan</span><div><button class="icon-button" :disabled="page === 1" @click="goToPage(page - 1)">‹</button><button v-for="number in totalPages" :key="number" class="page-button" :class="{ selected: number === page }" @click="goToPage(number)">{{ number }}</button><button class="icon-button" :disabled="page === totalPages" @click="goToPage(page + 1)">›</button></div></footer></section>
  </main>
</template>

<style scoped>
.salary-page { min-height: 100%; padding: 32px; color: #172033; background: #f8fafc; font-family: 'Plus Jakarta Sans', sans-serif; } .page-header, .toolbar, footer { display: flex; align-items: center; justify-content: space-between; gap: 16px; } h1 { margin: 4px 0 0; font-size: 26px; } .eyebrow { margin: 0; color: #64748b; font-size: 11px; letter-spacing: .12em; } .button { display: inline-flex; align-items: center; gap: 8px; padding: 11px 15px; border: 1px solid #e2e8f0; border-radius: 10px; color: #475569; background: white; cursor: pointer; } .button.dark { color: white; background: #172554; border-color: #172554; } .stats { display: grid; grid-template-columns: repeat(3, 1fr); gap: 18px; margin: 28px 0 20px; } .stats article { display: grid; gap: 10px; padding: 20px; border: 1px solid #e2e8f0; border-radius: 14px; background: white; } .stats article > span { color: #64748b; font-size: 12px; text-transform: uppercase; letter-spacing: .05em; } .stats strong { font-size: 22px; } .stats small { color: #059669; } .toolbar { flex-wrap: wrap; margin-bottom: 16px; } .search { display: flex; align-items: center; gap: 8px; flex: 1; min-width: 230px; padding: 11px 13px; border: 1px solid #e2e8f0; border-radius: 10px; background: white; color: #94a3b8; } input, select { border: 0; outline: 0; background: transparent; color: #475569; } .search input { width: 100%; } select { padding: 11px 12px; border: 1px solid #e2e8f0; border-radius: 10px; background: white; } .table-wrap { overflow: auto; border: 1px solid #e2e8f0; border-radius: 14px; background: white; } table { width: 100%; min-width: 980px; border-collapse: collapse; text-align: left; font-size: 13px; } th { padding: 13px 16px; color: #94a3b8; background: #f8fafc; font-size: 11px; text-transform: uppercase; } td { padding: 16px; border-top: 1px solid #f1f5f9; white-space: nowrap; } .employee { display: flex; align-items: center; gap: 10px; } .employee small { display: block; margin-top: 4px; color: #94a3b8; } .avatar { display: grid; place-items: center; width: 38px; height: 38px; border-radius: 50%; color: #4338ca; background: #e0e7ff; font-weight: 700; } .negative { color: #e11d48; } .pay { padding: 7px 10px; border-radius: 7px; color: #312e81; background: #eef2ff; } .status { padding: 6px 10px; border-radius: 999px; font-size: 11px; } .aktif { color: #047857; background: #ecfdf5; } .menunggu-review { color: #b45309; background: #fffbeb; } .perlu-update { color: #be123c; background: #fff1f2; } footer { padding: 16px; color: #64748b; font-size: 12px; } footer div { display: flex; gap: 4px; } .icon-button, .page-button { display: inline-grid; place-items: center; min-width: 30px; height: 30px; border: 0; border-radius: 7px; background: transparent; color: #64748b; cursor: pointer; } .icon-button:hover, .page-button:hover, .selected { background: #eef2ff; color: #312e81; } button:disabled { opacity: .4; cursor: not-allowed; } .empty { padding: 40px; text-align: center; color: #94a3b8; } @media (max-width: 800px) { .salary-page { padding: 20px; } .stats { grid-template-columns: 1fr; } .page-header { align-items: flex-start; flex-direction: column; } }
</style>