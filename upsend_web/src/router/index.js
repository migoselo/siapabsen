import { createRouter, createWebHistory } from 'vue-router'

const routes = [
  {
    path: '/',
    component: () => import('../layouts/MainLayout.vue'),
    children: [
      {
        path: '',
        name: 'Dashboard',
        component: () => import('../views/DashboardView.vue'),
      },
      // Tambahkan halaman lain di sini nanti, contoh:
      // { path: 'lokasi-kerja', name: 'LokasiKerja', component: () => import('../views/LokasiKerjaView.vue') },
      // { path: 'karyawan', name: 'DataKaryawan', component: () => import('../views/DataKaryawanView.vue') },
      // { path: 'absensi', name: 'DataAbsensiView', component: () => import('../views/DataAbsensiView.vue') },
    ],
  },
]

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes,
})

export default router