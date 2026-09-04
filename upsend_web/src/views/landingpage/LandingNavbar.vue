<script setup>
import { onBeforeUnmount, onMounted, ref } from 'vue'

import logoUrl from '../../assets/Logo-web.svg'

const isVisible = ref(true)
let previousScrollY = 0

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
      <a href="#beranda">Beranda</a>
      <a href="#tentang">Tentang Kami</a>
      <a href="#fitur">Fitur</a>
      <a href="#harga">Harga</a>
    </div>

    <router-link to="/login" class="landing-navbar__button">Coba Sekarang</router-link>
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
