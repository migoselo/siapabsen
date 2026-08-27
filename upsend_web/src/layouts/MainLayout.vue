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

// Responsif: sembunyikan sidebar di layar kecil
const isMobile = ref(false)
function handleResize() {
  isMobile.value = window.innerWidth <= 1100
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
    <aside v-if="!isMobile" class="sidebar">
      <div class="brand">
        <img :src="logoUrl" alt="SiapHadir" class="brand-mark" />
        <div class="brand-text">
          <strong>SiapHadir</strong>
          <span>HR ADMINISTRATION</span>
        </div>
      </div>

      <nav class="nav">
        <router-link
          v-for="item in navigation"
          :key="item.id"
          :to="item.path"
          class="nav-item"
          :class="{ active: isActive(item) }"
        >
          <Icon :icon="iconFor(item)" class="menu-icon" />
          <span class="nav-label">{{ item.text }}</span>
        </router-link>
      </nav>

      <button class="logout" @click="handleLogout">
        <Icon icon="material-symbols:logout" class="menu-icon" />
        <span>Logout</span>
      </button>
    </aside>

    <main class="main-area">
      <header class="topbar">
        <h1>{{ currentRouteName }}</h1>
        <div class="profile" @click="router.push('/profile')">
          <div class="profile-text">
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

    <nav v-if="isMobile" class="bottom-nav">
      <router-link
        v-for="item in navigation"
        :key="item.id"
        :to="item.path"
        class="bottom-nav-item"
        :class="{ active: isActive(item) }"
      >
        <Icon :icon="iconFor(item)" class="menu-icon" />
        <span>{{ item.text.split(' ')[0] }}</span>
      </router-link>
    </nav>
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
  min-height: 100vh;
}

.layout.is-mobile {
  flex-direction: column;
}

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
  font-family: 'Plus Jakarta Sans', sans-serif;
}

.sidebar * {
  font-family: inherit;
}

.brand {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 0 8px 16px 8px;
  margin-bottom: 8px;
  border-bottom: 1px solid var(--sidebar-line);
}

.brand-mark {
  width: 44px;
  height: 44px;
  object-fit: contain;
  flex-shrink: 0;
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

.nav-item:focus,
.nav-item:focus-visible {
  outline: none;
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
}

.topbar {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 24px 36px 20px;
  border-bottom: 1px solid var(--line);
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
}

.bottom-nav {
  display: flex;
  justify-content: space-around;
  background: #fff;
  border-top: 1px solid var(--line);
  padding: 8px 0;
  flex-shrink: 0;
}

.bottom-nav-item {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 4px;
  font-size: 11px;
  color: var(--ink-soft);
  text-decoration: none;
}

.bottom-nav-item.active {
  color: var(--sidebar-accent);
  font-weight: 600;
}

@media (max-width: 600px) {
  .topbar {
    padding: 16px;
  }
  .page-content {
    padding: 16px;
  }
}
</style>