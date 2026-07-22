import { ref } from 'vue'
import { defineStore } from 'pinia'
import api from '../api'

/*
  Store ini yang nanti diisi oleh tim yang mengurus database/API.
  Frontend (Dashboard.vue) cuma konsumsi state di sini lewat props —
  tidak ada data karyawan/statistik yang ditulis manual di komponen.
*/
export const useDashboardStore = defineStore('dashboard', () => {
  const profile = ref({ name: '', role: '', avatarUrl: '' })
  const currentDate = ref('')
  const locationLabel = ref('Semua Lokasi')

  const stats = ref({
    totalEmployees: 0,
    totalGrowthLabel: '',
    checkedIn: 0,
    checkedInPercent: 0,
    notCheckedIn: 0,
    notCheckedInNote: '',
    checkedOut: 0,
    checkedOutExtraCount: 0,
  })

  const weeklyAverageLabel = ref('')
  const chartData = ref([])
  const insight = ref({ summary: '', topPerformerLabel: '', needAttentionLabel: '' })
  const employees = ref([])

  const loading = ref(false)
  const error = ref(null)

  async function fetchDashboard(period = 'hari') {
    loading.value = true
    error.value = null
    try {
      // TODO: sesuaikan endpoint dengan API yang disediakan tim backend
      const res = await api.get('/dashboard', { params: { period } })
      profile.value = res.data.profile
      currentDate.value = res.data.currentDate
      locationLabel.value = res.data.locationLabel
      stats.value = res.data.stats
      weeklyAverageLabel.value = res.data.weeklyAverageLabel
      chartData.value = res.data.chartData
      insight.value = res.data.insight
      employees.value = res.data.employees
    } catch (err) {
      error.value = err
    } finally {
      loading.value = false
    }
  }

  async function searchEmployees(query) {
    // TODO: kalau pencarian dilakukan di server, panggil endpoint terpisah di sini
    const res = await api.get('/dashboard/employees', { params: { q: query } })
    employees.value = res.data.employees
  }

  return {
    profile,
    currentDate,
    locationLabel,
    stats,
    weeklyAverageLabel,
    chartData,
    insight,
    employees,
    loading,
    error,
    fetchDashboard,
    searchEmployees,
  }
})