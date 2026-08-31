<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { Icon } from '@iconify/vue'
import { useAuthStore } from '../stores/auth'

const router = useRouter()
const route = useRoute()
const authStore = useAuthStore()

import logoUrl from '../assets/Logo-web.svg'

const profile = computed(() => ({
  name: authStore.user?.name ?? 'Pengguna',
  role: authStore.user?.role ?? 'Guest',
  avatarUrl: authStore.user?.avatarUrl ?? '',
}))

const navigation = [
  {
    id: 'dashboard',
    text: 'Dashboard',
    icon: 'material-symbols:dashboard-outline',
    activeIcon: 'material-symbols:dashboard',
    path: '/dashboard',
  },
  {
    id: 'lokasi',
    text: 'Lokasi Kerja',
    icon: 'material-symbols:location-on-outline',
    activeIcon: 'material-symbols:location-on',
    path: '/lokasi-kerja',
  },
  {
    id: 'karyawan',
    text: 'Data Karyawan',
    icon: 'material-symbols:group-outline',
    activeIcon: 'material-symbols:group',
    path: '/karyawan',
  },
  {
    id: 'absensi',
    text: 'Data Absensi',
    icon: 'material-symbols:history',
    activeIcon: 'material-symbols:history',
    path: '/absensi',
  },
  {
    id: 'izin-cuti',
    text: 'Data Izin dan Cuti',
    icon: 'material-symbols:calendar-month-outline',
    activeIcon: 'material-symbols:calendar-month',
    path: '/izin-cuti',
  },
  {
    id: 'lembur',
    text: 'Data Lembur',
    icon: 'material-symbols:more-time',
    activeIcon: 'material-symbols:more-time',
    path: '/lembur',
  },
]

function isActive(item) {
  return route.path === item.path || (route.path.startsWith(item.path) && item.path !== '/')
}

function iconFor(item) {
  return isActive(item) ? item.activeIcon : item.icon
}

const currentRouteName = computed(() => {
  const current = navigation.find((n) => isActive(n))
  return current ? current.text : 'Dashboard'
})

function handleLogout() {
  authStore.logout()
  router.push('/login')
}

function initials(name) {
  if (!name) return ''
  return name.split(' ').map((w) => w[0]).slice(0, 2).join('').toUpperCase()
}

// Responsif & Manajemen Status Sidebar
const isMobile = ref(false)
const isSidebarMinimized = ref(false)
const isSidebarOpen = ref(false)

function toggleSidebar() {
  if (isSidebarOpen.value) {
    isSidebarOpen.value = !isSidebarOpen.value
  } else {
    isSidebarMinimized.value = !isSidebarMinimized.value
  }
}



// Menutup sidebar otomatis saat rute berubah di mode mobile
router.afterEach(() => {
  if (isMobile.value) {
    isSidebarOpen.value = false
  }
})

function handleResize() {
  const wasMobile = isMobile.value
  isMobile.value = window.innerWidth <= 1100

  // Reset status sidebar jika kembali ke layar besar
  if (wasMobile && !isMobile.value) {
    isSidebarOpen.value = false
  }
}

onMounted(() => {
  handleResize()
  window.addEventListener('resize', handleResize)
})
onUnmounted(() => {
  window.removeEventListener('resize', handleResize)
})
</script>

<template>
  <div class="layout" :class="{ 'is-mobile': isMobile }">
    <!-- Overlay Latar Belakang (Hanya muncul di Mobile saat Sidebar Terbuka) -->
    <div
      v-if="isMobile && isSidebarOpen"
      class="sidebar-overlay"
      @click="isSidebarOpen = false"
    ></div>

    <!-- Sidebar: Di mode desktop posisinya statis, di mode mobile posisinya absolute/fixed off-canvas -->
    <aside 
    class="sidebar" 
    :class="{ 
      'sidebar-open': !isMobile && isSidebarOpen,
      'sidebar-collapsed': !isMobile && isSidebarMinimized

     }">
      <div class="brand">
        <img :src="logoUrl" alt="SiapHadir" class="brand-mark" />
        <div class="brand-text" v-if="!isSidebarMinimized">
          <strong>SiapHadir</strong>
          <span>HR ADMINISTRATION</span>
        </div>
        <!-- Tombol Tutup Sidebar di dalam menu (Opsional, untuk Mobile) -->
        <button v-if="isMobile" class="close-sidebar-btn" @click="isSidebarOpen = false">
          <Icon icon="material-symbols:close" width="24" />
        </button>
      </div>

      <nav class="nav">
        <router-link
          v-for="item in navigation"
          :key="item.id"
          :to="item.path"
          class="nav-item"
          :class="{ active: isActive(item) }"
          :title="isSidebarMinimized ? item.text : ''"
        >
          <Icon :icon="iconFor(item)" class="menu-icon" />
          <span class="nav-label" v-if="!isSidebarMinimized">{{ item.text }}</span>
        </router-link>
      </nav>

      <button class="logout" @click="handleLogout" :title="isSidebarMinimized ? 'Logout' : ''">
        <Icon icon="material-symbols:logout" class="menu-icon" />
        <span v-if="!isSidebarMinimized">Logout</span>
      </button>
    </aside>

    <main class="main-area">
      <!-- Header / Topbar Utama -->
      <header class="topbar">
        <div class="topbar-left">
          <!-- Tombol Hamburger (Hanya terlihat di layar mobile) -->
          <button v-if="isMobile" class="hamburger-btn" @click="toggleSidebar">
            <Icon icon="material-symbols:menu-rounded" width="28" />
          </button>
          <h1>{{ currentRouteName }}</h1>
        </div>

        <div class="profile" @click="router.push('/profile')">
          <div class="profile-text" v-if="!isMobile">
            <strong>{{ profile.name }}</strong>
            <span>{{ profile.role }}</span>
          </div>
          <div class="avatar">
            <img v-if="profile.avatarUrl" :src="profile.avatarUrl" :alt="profile.name" />
            <span v-else>{{ initials(profile.name) }}</span>
          </div>
        </div>
      </header>

      <div class="page-content">
        <router-view />
      </div>
    </main>
  </div>
</template>

<style scoped>
:global(html),
:global(body),
:global(#app) {
  width: 100%;
  min-height: 100%;
  margin: 0;
  padding: 0;
  /* Hindari scrolling body saat sidebar terbuka di mobile */
  overflow-x: hidden;
}

* {
  box-sizing: border-box;
}

.layout {
  --sidebar-bg: #2f3b69;
  --sidebar-active-bg: #eef0f5;
  --sidebar-accent: #2f3b69;
  --sidebar-text: #e5e7f0;
  --sidebar-line: rgba(255, 255, 255, 0.25);
  --ink-dark: #2c3345;
  --ink-soft: #667085;
  --line: #e4e7ec;
  --bg: #ffffff;
  font-family: 'Plus Jakarta Sans', sans-serif;
  background: var(--bg);
  color: var(--ink-dark);
  display: flex;
  height: 100vh;
  height: 100dvh;
  overflow: hidden;
  position: relative;
}

/* Sidebar Dasar */
.sidebar {
  width: 250px;
  flex-shrink: 0;
  background: var(--sidebar-bg);
  border-right: 1px solid var(--sidebar-line);
  display: flex;
  flex-direction: column;
  padding: 24px 16px 20px;
  position: sticky;
  top: 0;
  height: 100vh;
  overflow-y: auto;
  z-index: 40;
  
  /* Efek melipat seperti panel AI */
  transition: width 0.3s cubic-bezier(0.4, 0, 0.2, 1), 
              padding 0.3s cubic-bezier(0.4, 0, 0.2, 1), 
              border-color 0.3s ease;
  overflow-x: hidden;
}
/* --- KONDISI SAAT SIDEBAR DIMINIMIZE DI DESKTOP --- */
.sidebar.sidebar-minimized {
  width: 80px;
  padding: 24px 12px 20px;
}

.sidebar.sidebar-minimized .brand {
  justify-content: center;
  padding: 0 0 16px 0;
}

.sidebar.sidebar-minimized .brand-mark {
  width: 36px;
  height: 36px;
}

.sidebar.sidebar-minimized .nav-item {
  justify-content: center;
  padding: 0;
  gap: 0;
}

.sidebar.sidebar-minimized .logout {
  width: calc(100% + 24px);
  margin: 0 -12px;
  padding-left: 0;
  justify-content: center;
  gap: 0;
}

/* Sembunyikan garis indikator aktif samping jika diperkecil agar tidak berantakan */
.sidebar.sidebar-minimized .nav-item.active::after {
  display: none;
}

.sidebar::-webkit-scrollbar {
  width: 4px;
}
.sidebar::-webkit-scrollbar-thumb {
  background: rgba(255, 255, 255, 0.2);
  border-radius: 4px;
}

.sidebar * {
  font-family: inherit;
}

.brand {
  display: flex;
  align-items: center;
  justify-content: space-between; /* Menyesuaikan agar tombol X bisa di kanan */
  gap: 12px;
  padding: 0 8px 16px 8px;
  margin-bottom: 8px;
  border-bottom: 1px solid var(--sidebar-line);
}

/* Container untuk logo dan teks agar tetap bersebelahan jika ada tombol close */
.brand > img {
  flex-shrink: 0;
}
.brand-text {
  flex: 1;
}

.brand-mark {
  width: 44px;
  height: 44px;
  object-fit: contain;
  filter: brightness(0) invert(1);
}

.brand-text strong {
  display: block;
  font-size: 18px;
  font-weight: 800;
  line-height: 1.2;
  color: #ffffff;
}

.brand-text span {
  display: block;
  font-size: 10px;
  font-weight: 700;
  letter-spacing: 0.8px;
  text-transform: uppercase;
  color: var(--sidebar-text);
  margin-top: 2px;
}

.close-sidebar-btn {
  background: none;
  border: none;
  color: var(--sidebar-text);
  cursor: pointer;
  padding: 4px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.nav {
  display: flex;
  flex-direction: column;
  gap: 6px;
  flex: 1;
}

.nav-item {
  display: flex;
  align-items: center;
  gap: 14px;
  position: relative;
  width: 100%;
  height: 48px;
  padding: 0 16px;
  border-radius: 8px;
  background: transparent;
  color: var(--sidebar-text);
  text-decoration: none;
  font-size: 14px;
  font-weight: 500;
  transition: all 0.2s ease;
  overflow: hidden;
  outline: none;
  border: none;
}

.nav-item:hover {
  background: rgba(255, 255, 255, 0.08);
}

.nav-item.active {
  background: var(--sidebar-active-bg);
  color: var(--sidebar-accent);
  font-weight: 600;
}

.nav-item.active::after {
  content: '';
  position: absolute;
  top: 0;
  right: 0;
  width: 4px;
  height: 100%;
  background: #b7c0df;
  border-radius: 4px 0 0 4px;
}

.menu-icon {
  width: 22px;
  height: 22px;
  color: currentColor;
  flex-shrink: 0;
}

.logout {
  display: flex;
  align-items: center;
  gap: 14px;
  padding: 16px;
  font-size: 14px;
  font-weight: 500;
  color: var(--sidebar-text);
  cursor: pointer;
  border: none;
  background: none;
  width: calc(100% + 32px);
  margin: 0 -16px;
  padding-left: 32px;
  border-top: 1px solid var(--sidebar-line);
  transition: background 0.2s ease;
}

.logout:hover {
  background: rgba(255, 255, 255, 0.08);
}

.main-area {
  flex: 1;
  display: flex;
  flex-direction: column;
  min-width: 0;
  height: 100%;
}

.topbar {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 24px 36px 20px;
  border-bottom: 1px solid var(--line);
  background: #ffffff;
}

.topbar-left {
  display: flex;
  align-items: center;
  gap: 16px;
}

.hamburger-btn {
  background: none;
  border: none;
  color: var(--ink-dark);
  cursor: pointer;
  padding: 4px;
  display: flex;
  align-items: center;
  justify-content: center;
  margin-left: -8px; /* Mengkompensasi padding agar rata kiri */
}

.topbar h1 {
  font-size: 28px;
  font-weight: 700;
  color: #1a1f36;
  margin: 0;
}

.profile {
  display: flex;
  align-items: center;
  gap: 12px;
  cursor: pointer;
  border-left: 1px solid var(--line);
  padding-left: 24px;
}

.profile-text {
  text-align: right;
}

.profile-text strong {
  display: block;
  font-size: 14px;
  font-weight: 700;
}

.profile-text span {
  display: block;
  font-size: 12px;
  color: var(--ink-soft);
}

.avatar {
  width: 40px;
  height: 40px;
  border-radius: 50%;
  background: #e2e5f0;
  display: flex;
  align-items: center;
  justify-content: center;
  font-weight: 700;
  font-size: 14px;
  color: #2f3b69;
  overflow: hidden;
}

.avatar img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.page-content {
  flex: 1;
  padding: 24px 36px;
  overflow-y: auto;
  padding-bottom: 48px;
}

/* --- Tampilan Mobile --- */
@media (max-width: 1100px) {
  /* Menyiapkan sidebar sebagai elemen mengambang di luar layar */
  .sidebar {
    position: fixed;
    transform: translateX(-100%);
    box-shadow: 4px 0 24px rgba(20, 25, 45, 0.15);
  }

  /* Kelas untuk menggeser sidebar masuk ke dalam layar */
  .sidebar.sidebar-open {
    transform: translateX(0);
  }

  /* Overlay redup di belakang sidebar */
  .sidebar-overlay {
    position: fixed;
    inset: 0;
    background: rgba(20, 25, 45, 0.45);
    backdrop-filter: blur(2px);
    z-index: 30;
  }

  /* Penyesuaian padding topbar dan konten untuk layar kecil */
  .topbar {
    padding: 16px 20px;
  }

  .topbar h1 {
    font-size: 20px;
  }

  .profile {
    border-left: none;
    padding-left: 0;
  }

  .page-content {
    padding: 16px 20px;
  }
}
</style>
