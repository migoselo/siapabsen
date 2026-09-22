import { createRouter, createWebHistory } from 'vue-router'

const routes = [
  {
    path: '/',
    name: 'LandingPage',
    component: () => import('../views/landingpage/LandingPage.vue'),
  },
  {
    path: '/login',
    name: 'Login',
    component: () => import('../views/LoginView.vue'),
  },
  {
    path: '/aktivasi-akun',
    name: 'AccountActivation',
    component: () => import('../views/EmailActionView.vue'),
  },
  {
    path: '/reset-password',
    name: 'PasswordReset',
    component: () => import('../views/EmailActionView.vue'),
  },
  {
    path: '/dashboard',
    component: () => import('../layouts/MainLayout.vue'),
    meta: { requiresAuth: true },
    children: [
      {
        path: '',
        name: 'Dashboard',
        alias: '/dashboard',
        component: () => import('../views/DashboardView.vue'),
      },
      {
        path: 'lokasi-kerja',
        name: 'LokasiKerja',
        component: () => import('../views/LokasiKerjaView.vue'),
      },
      {
        path: 'karyawan',
        name: 'DataKaryawan',
        component: () => import('../views/DataKaryawanView.vue'),
      },
      {
        path: 'karyawan/:id',
        name: 'BiodataKaryawan',
        component: () => import('../views/Biodata.vue'),
      },
      {
        path: 'role-akses',
        name: 'Role',
        component: () => import('../views/RoleAkses.vue'),
      },
      {
        path: 'absensi',
        name: 'DataAbsensi',
        component: () => import('../views/DataAbsensiView.vue'),
      },
      {
        path: 'absensi/:id',
        name: 'DetailAbsen',
        component: () => import('../views/DetailAbsenView.vue'),
      },
      {
        path: 'profile',
        name: 'Profile',
        component: () => import('../views/ProfileView.vue'),
      },
      {
        path: 'izin-cuti',
        name: 'izin-cuti',
        component: () => import('@/views/DataIzinCuti.vue'),
      },
      {
        path: 'lembur',
        name: 'lembur',
        component: () => import('@/views/DataLembur.vue'),
      },
      {
        path: 'gaji',
        name: 'gaji',
        component: () => import('@/views/KelolaGaji.vue'),
      },
      {
        path: 'gaji/form/:employeeId?',
        name: 'GajiForm',
        component: () => import('@/views/FormGaji.vue'),
      },
      {
        path: 'divisi-shift',
        name: 'DivisiShift',
        component: () => import('@/views/KelolaDivisiShift.vue'),
      },
    ],
  },
]

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes,
})

router.beforeEach((to, from) => {
  const token = localStorage.getItem('auth_token')
  const requiresAuth = to.matched.some((record) => record.meta.requiresAuth)

  if (requiresAuth && !token) {
    return { name: 'Login' }
  }
})

router.onError((error) => {
  const message = String(error?.message || '')
  if (message.includes('Failed to fetch dynamically imported module')) {
    console.warn('Modul halaman gagal dimuat. Silakan refresh halaman setelah Vite siap.')
  }
  console.error('Gagal berpindah halaman:', error)
})

export default router