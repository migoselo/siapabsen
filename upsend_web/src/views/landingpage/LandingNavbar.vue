<script setup>
import { onBeforeUnmount, onMounted, ref } from 'vue'

import logoUrl from '../../assets/Logo-web.svg'

const isVisible = ref(true)
const isMenuOpen = ref(false)
const activeMenu = ref('')
let previousScrollY = 0

function selectMenu(menu) {
  activeMenu.value = menu
  isMenuOpen.value = false
}

function toggleMenu() {
  isMenuOpen.value = !isMenuOpen.value
}

function handleScroll() {
  const currentScrollY = window.scrollY

  if (currentScrollY === 0 || currentScrollY < previousScrollY) {
    isVisible.value = true
  } else if (currentScrollY > previousScrollY) {
    isVisible.value = false
  }

  previousScrollY = currentScrollY
}

onMounted(() => {
  previousScrollY = window.scrollY
  window.addEventListener('scroll', handleScroll, { passive: true })
})

onBeforeUnmount(() => {
  window.removeEventListener('scroll', handleScroll)
})
</script>

<template>
  <nav class="landing-navbar" :class="{ 'landing-navbar--hidden': !isVisible }">
    <div class="landing-navbar__brand">
      <img :src="logoUrl" alt="SiapHadir" />
      <strong>SiapHadir</strong>
    </div>

    <div class="landing-navbar__links">
      <a href="#beranda" :class="{ 'is-active': activeMenu === 'beranda' }" @click="selectMenu('beranda')">Beranda</a>
      <a href="#tentang" :class="{ 'is-active': activeMenu === 'tentang' }" @click="selectMenu('tentang')">Tentang Kami</a>
      <a href="#fitur" :class="{ 'is-active': activeMenu === 'fitur' }" @click="selectMenu('fitur')">Fitur</a>
      <a href="#harga" :class="{ 'is-active': activeMenu === 'harga' }" @click="selectMenu('harga')">Harga</a>
    </div>

    <router-link to="/login" class="landing-navbar__button">Coba Sekarang</router-link>

    <button
      class="landing-navbar__menu-toggle"
      type="button"
      :aria-expanded="isMenuOpen"
      aria-controls="landing-mobile-menu"
      :aria-label="isMenuOpen ? 'Tutup menu navigasi' : 'Buka menu navigasi'"
      @click.stop.prevent="toggleMenu"
    >
      <span></span>
      <span></span>
      <span></span>
    </button>

    <div v-if="isMenuOpen" id="landing-mobile-menu" class="landing-navbar__mobile-menu">
      <a href="#beranda" :class="{ 'is-active': activeMenu === 'beranda' }" @click="selectMenu('beranda')">Beranda</a>
      <a href="#tentang" :class="{ 'is-active': activeMenu === 'tentang' }" @click="selectMenu('tentang')">Tentang Kami</a>
      <a href="#fitur" :class="{ 'is-active': activeMenu === 'fitur' }" @click="selectMenu('fitur')">Fitur</a>
      <a href="#harga" :class="{ 'is-active': activeMenu === 'harga' }" @click="selectMenu('harga')">Harga</a>
    </div>
  </nav>
</template>

<style scoped>
.landing-navbar {
  position: fixed;
  top: 20px;
  left: 50%;
  z-index: 100;
  display: flex;
  align-items: center;
  justify-content: space-between;
  width: min(90%, 1080px);
  padding: 12px 20px;
  box-sizing: border-box;
  border: 1px solid rgba(47, 59, 105, 0.08);
  border-radius: 18px;
  background: #ffffff;
  box-shadow: 0 10px 28px rgba(30, 41, 75, 0.12);
  transform: translateX(-50%);
  transition: transform 0.25s ease;
  will-change: transform;
}

.landing-navbar--hidden {
  transform: translate(-50%, calc(-100% - 24px));
}

.landing-navbar__brand {
  display: flex;
  align-items: center;
  gap: 10px;
  color: #2f3b69;
}

.landing-navbar__brand img {
  width: 32px;
  height: 32px;
}

.landing-navbar__brand strong {
  font-size: 18px;
  font-weight: 800;
}

.landing-navbar__links {
  display: flex;
  gap: 32px;
}

.landing-navbar__links a {
  color: #667085;
  font-size: 14px;
  font-weight: 600;
  text-decoration: none;
  transition: color 0.2s ease;
}

.landing-navbar__links a:hover,
.landing-navbar__links a:focus-visible,
.landing-navbar__links a:active,
.landing-navbar__links a.is-active {
  color: #2F3B69;
}

.landing-navbar__button {
  padding: 10px 20px;
  border-radius: 999px;
  background: #2f3b69;
  color: #ffffff;
  font-size: 14px;
  font-weight: 700;
  text-decoration: none;
}

.landing-navbar__menu-toggle {
  position: relative;
  z-index: 2;
  display: none;
  width: 40px;
  height: 40px;
  padding: 9px;
  border: 0;
  border-radius: 8px;
  background: transparent;
  cursor: pointer;
  pointer-events: auto;
}

.landing-navbar__menu-toggle span {
  display: block;
  height: 2px;
  margin: 4px 0;
  border-radius: 2px;
  background: #2f3b69;
}

@media (min-width: 2000px), (max-width: 900px) {
  .landing-navbar__links {
    display: none;
  }

  .landing-navbar__mobile-menu {
    position: absolute;
    z-index: 1;
    top: calc(100% + 8px);
    right: 0;
    left: 0;
    display: flex;
    flex-direction: column;
    gap: 0;
    padding: 8px;
    border: 1px solid rgba(47, 59, 105, 0.08);
    border-radius: 14px;
    background: #ffffff;
    box-shadow: 0 10px 28px rgba(30, 41, 75, 0.12);
  }

  .landing-navbar__mobile-menu a {
    padding: 10px 12px;
    color: #667085;
    cursor: pointer;
    font-size: 14px;
    font-weight: 600;
    text-decoration: none;
    border-radius: 8px;
    transition: color 0.2s ease;
  }

  .landing-navbar__mobile-menu a:hover,
  .landing-navbar__mobile-menu a:focus-visible,
  .landing-navbar__mobile-menu a:active,
  .landing-navbar__mobile-menu a.is-active {
    color: #2F3B69;
  }

  .landing-navbar__button {
    display: none;
  }

  .landing-navbar__menu-toggle {
    display: block;
  }
}

@media (min-width: 901px) and (max-width: 1999px) {
  .landing-navbar__mobile-menu {
    display: none;
  }
}

@media (max-width: 900px) {
  .landing-navbar {
    top: 12px;
    width: calc(100% - 24px);
    padding: 10px 14px;
    border-radius: 15px;
  }

  .landing-navbar__links {
    display: none;
  }
}
</style>
