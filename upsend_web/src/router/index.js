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
        component: () => import('../views/DashboardView.vue'),
      },
      {
        path: 'dashboard',
        component: () => import('../views/DashboardView.vue'),
      },
      {
        path: 'lokasi-kerja',
        component: () => import('../views/LokasiKerjaView.vue')
      },
      {
        path: 'karyawan',
        component: () => import('../views/DataKaryawanView.vue')
      },
      {
        path: 'absensi',
        component: () => import('../views/DataAbsensiView.vue')
      }
      // Tambahkan halaman lain di sini nanti, contoh:
      // { path: 'absensi', name: 'DataAbsensiView', component: () => import('../views/DataAbsensiView.vue') },
    ],
  },
]

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes,
})

router.beforeEach((to, from, next) => {
  const token = localStorage.getItem('auth_token')
  const requiresAuth = to.matched.some((record) => record.meta.requiresAuth)

  if (requiresAuth && !token) {
    next({ name: 'Login' })
  } else if (to.name === 'Login' && token) {
    // Udah login, gak perlu balik ke halaman login lagi
    next({ name: 'Dashboard' })
  } else {
    next()
  }
})

export default router