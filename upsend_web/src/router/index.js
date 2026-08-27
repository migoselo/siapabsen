import { createRouter, createWebHistory } from 'vue-router'

const routes = [
  {
    path: '/login',
    name: 'Login',
    component: () => import('../views/LoginView.vue'),
  },
  {
    path: '/',
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
        component: () => import('@/views/DataIzinCuti.vue')
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
  } else if (to.name === 'Login' && token) {
    // Udah login, gak perlu balik ke halaman login lagi
    return { name: 'Dashboard' }
  }
})

export default router