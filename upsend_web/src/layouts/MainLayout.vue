<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { Icon } from '@iconify/vue'
import { useAuthStore } from '../stores/auth'

const router = useRouter()
const route = useRoute()
const authStore = useAuthStore()

// sesuaikan path ini dengan lokasi asli "Logo Container.svg" di project kamu
import logoUrl from '../assets/Logo Container.svg'

const profile = computed(() => ({
  name: authStore.user?.name ?? 'Pengguna',
  role: authStore.user?.role ?? 'Guest',
  avatarUrl: authStore.user?.avatarUrl ?? '',
}))

const navigation = [
  { id: 'dashboard', text: 'Dashboard', icon: 'material-symbols:dashboard-outline', path: '/' },
  { id: 'lokasi', text: 'Lokasi Kerja', icon: 'material-symbols:location-on-outline', path: '/lokasi-kerja' },
  { id: 'karyawan', text: 'Data Karyawan', icon: 'material-symbols:group-outline', path: '/karyawan' },
  { id: 'absensi', text: 'Data Absensi', icon: 'material-symbols:history', path: '/absensi' },
]

const currentRouteName = computed(() => {
  const current = navigation.find(
    (n) => route.path === n.path || (route.path.startsWith(n.path) && n.path !== '/'),
  )
  return current ? current.text : 'Dashboard'
})

function handleItemClick(path) {
  router.push(path)
}

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
        <img :src="logoUrl" alt="SiapAbsen" class="brand-mark" />
        <div class="brand-text">
          <strong>SiapAbsen</strong>
          <span>HR ADMINISTRATION</span>
        </div>
      </div>

      <nav class="nav">
        <button
          v-for="item in navigation"
          :key="item.id"
          class="nav-item"
          :class="{
            active: route.path === item.path || (route.path.startsWith(item.path) && item.path !== '/'),
          }"
          @click="handleItemClick(item.path)"
        >
          <Icon :icon="item.icon" width="22" height="22" />
          {{ item.text }}
        </button>
      </nav>

      <button class="logout" @click="handleLogout">
        <Icon icon="material-symbols:logout" width="20" height="20" />
        Logout
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
      <div
        v-for="item in navigation"
        :key="item.id"
        class="bottom-nav-item"
        :class="{
          active: route.path === item.path || (route.path.startsWith(item.path) && item.path !== '/'),
        }"
        @click="handleItemClick(item.path)"
      >
        <Icon :icon="item.icon" width="22" height="22" />
        <span>{{ item.text.split(' ')[0] }}</span>
      </div>
    </nav>

  </div>
</template>

<style scoped>
* {
  box-sizing: border-box;
}
.layout {
  --green-900: #173d31;
  --green-800: #1e4a3c;
  --green-100: #e6f0ea;
  --green-50: #f2f7f4;
  --ink: #1c2521;
  --ink-soft: #5b6864;
  --line: #e7e7e2;
  --bg: #f6f5f1;
  font-family: 'Inter', system-ui, -apple-system, sans-serif;
  background: var(--bg);
  color: var(--ink);
  display: flex;
  min-height: 100vh;
}
.layout.is-mobile {
  flex-direction: column;
}

.sidebar {
  width: 230px;
  flex-shrink: 0;
  background: #fff;
  border-right: 1px solid var(--line);
  display: flex;
  flex-direction: column;
  padding: 20px 16px;
  position: sticky;
  top: 0;
  height: 100vh;
}
.brand {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 0 6px 26px 6px;
}
.brand-mark {
  width: 40px;
  height: 40px;
  object-fit: contain;
  flex-shrink: 0;
}
.brand-text strong {
  display: block;
  font-family: 'Inter', sans-serif;
  font-size: 18px;
  font-weight: 700;
  line-height: 22.5px;
  letter-spacing: 0;
  color: #154538;
}
.brand-text span {
  display: block;
  font-family: 'Inter', sans-serif;
  font-size: 10px;
  font-weight: 600;
  line-height: 15px;
  letter-spacing: 1px;
  text-transform: uppercase;
  color: #404945;
}

.nav {
  display: flex;
  flex-direction: column;
  gap: 2px;
  margin-top: 8px;
  flex: 1;
}
.nav-item {
  display: flex;
  align-items: center;
  gap: 12px;
  position: relative;
  width: 100%;
  height: 56px;
  padding: 0 18px;
  border: none;
  border-radius: 12px;
  background: transparent;
  cursor: pointer;
  text-align: left;
  font-family: 'Plus Jakarta Sans', sans-serif;
  font-size: 14px;
  font-weight: 600;
  color: #4f5b58;
  transition: all 0.2s ease;
}
.nav-item svg,
.nav-item .iconify {
  width: 22px;
  height: 22px;
  color: #66706c;
  flex-shrink: 0;
}
.nav-item:hover {
  background: var(--green-50);
}
.nav-item.active {
  background: #ecefe8;
  color: #173d31;
  font-weight: 700;
}
.nav-item.active svg,
.nav-item.active .iconify {
  color: var(--green-900);
}
.nav-item.active::after {
  content: '';
  position: absolute;
  top: 0;
  right: 0;
  width: 8px;
  height: 100%;
  background: #173d31;
  border-radius: 0 12px 12px 0;
}

.logout {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 11px 12px;
  font-size: 14.5px;
  font-weight: 500;
  color: #3b4541;
  cursor: pointer;
  border: none;
  background: none;
  width: 100%;
  text-align: left;
  border-top: 1px solid var(--line);
  margin-top: 8px;
  padding-top: 18px;
}
.logout svg,
.logout .iconify {
  width: 19px;
  height: 19px;
  color: #5b6864;
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
  padding: 28px 36px 0;
  margin-bottom: 26px;
}
.topbar h1 {
  font-family: 'Plus Jakarta Sans', sans-serif;
  font-size: 32px;
  font-weight: 600;
  line-height: 1.2;
  letter-spacing: 0;
  color: #000000;
  margin: 0;
}
.profile {
  display: flex;
  align-items: center;
  gap: 12px;
  cursor: pointer;
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
  width: 42px;
  height: 42px;
  border-radius: 50%;
  background: linear-gradient(135deg, #cfe3d8, #9cc4ac);
  display: flex;
  align-items: center;
  justify-content: center;
  font-weight: 700;
  font-size: 14px;
  color: var(--green-900);
  overflow: hidden;
}
.avatar img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.page-content {
  flex: 1;
  padding: 0 36px 60px;
  overflow-y: auto;
}

.bottom-nav {
  display: flex;
  justify-content: space-around;
  background: #fff;
  border-top: 1px solid var(--line);
  padding: 10px 0;
  flex-shrink: 0;
}
.bottom-nav-item {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 4px;
  font-size: 12px;
  color: var(--ink-soft);
  cursor: pointer;
}
.bottom-nav-item.active {
  color: var(--green-900);
  font-weight: 700;
}

@media (max-width: 600px) {
  .topbar {
    padding: 20px 16px 0;
  }
  .page-content {
    padding: 0 16px 40px;
  }
}
</style>