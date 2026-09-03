<script setup>
import { onBeforeUnmount, onMounted, ref } from 'vue'
import { Icon } from '@iconify/vue'

// Ganti sesuai lokasi file gambar kamu di folder assets
import logoUrl from '../assets/Logo-web.svg'
import heroWomanImg from '../assets/hero-woman.svg' // Gambar wanita memegang HP
import mockupAppImg from '../assets/mockup-app.svg' // Gambar HP 3D SiapAbsen
//import mockupFeaturesImg from '../assets/mockup-features.png' // Gambar HP & ilustrasi fitur

const isNavbarVisible = ref(true)
let previousScrollY = 0

const handleScroll = () => {
  const currentScrollY = window.scrollY

  if (currentScrollY <= 0 || currentScrollY < previousScrollY) {
    isNavbarVisible.value = true
  } else if (currentScrollY > previousScrollY && currentScrollY > 80) {
    isNavbarVisible.value = false
  }

  previousScrollY = currentScrollY
}

onMounted(() => {
  window.addEventListener('scroll', handleScroll, { passive: true })
})

onBeforeUnmount(() => {
  window.removeEventListener('scroll', handleScroll)
})
</script>

<template>
  <div class="landing-page">
    <!-- 1. NAVBAR -->
    <nav class="navbar" :class="{ 'navbar-hidden': !isNavbarVisible }">
      <div class="nav-brand">
        <img :src="logoUrl" alt="SiapHadir" class="brand-logo" />
        <strong class="brand-title">SiapHadir</strong>
      </div>
      <div class="nav-links">
        <a href="#beranda">Beranda</a>
        <a href="#tentang">Tentang Kami</a>
        <a href="#fitur">Fitur</a>
      </div>
      <router-link to="/login" class="btn-nav">Coba Sekarang</router-link>
    </nav>

    <!-- 2. HERO SECTION -->
    <section id="beranda" class="hero-section">
      <div class="hero-card">
        <div class="hero-text">
          <h1>
            <span class="text-highlight-yellow">Siap</span> Kelola Kehadiran Lebih Mudah dan Akurat
          </h1>
          <p>
            Kelola kehadiran karyawan lebih efisien dan terstruktur. Dengan verifikasi lokasi presisi dan pencatatan absensi yang terintegrasi, menjadikan pencatatan kehadiran jauh lebih praktis dan akurat.
          </p>
          <div class="hero-actions">
            <router-link to="/login" class="btn-yellow">Coba Sekarang</router-link>
            <a href="#fitur" class="btn-outline-white">Pelajari Lebih</a>
          </div>
        </div>
        <div class="hero-image-wrap">
          <img :src="heroWomanImg" alt="SiapHadir User" class="hero-woman-img" />
        </div>
      </div>
    </section>

    <!-- 3. ABOUT SECTION (SiapAbsen / SiapHadir Intro) -->
    <section id="tentang" class="about-section">
      <div class="about-container">
        <div class="about-text">
          <div class="brand-badge">
            <img :src="logoUrl" alt="Logo" class="badge-logo" />
            <span>SiapAbsen</span>
          </div>
          <p class="about-desc">
            Banyak perusahaan masih mengandalkan proses absensi manual yang memakan waktu, rentan kesalahan, dan tidak efisien. Kami hadir dengan SiapAbsen sebagai jawaban atas tantangan tersebut. SiapAbsen merupakan sebuah sistem yang membantu perusahaan mencatat, memantau, dan mengelola kehadiran karyawan secara realtime.
          </p>
          <h4 class="quote-text">"Memberikan <span class="text-highlight-yellow">Kehadiran</span> Terpercaya"</h4>
        </div>
        <div class="about-mockup">
          <img :src="mockupAppImg" alt="SiapAbsen Mobile App" class="phone-3d-img" />
        </div>
      </div>
    </section>

    <!-- 4. FEATURES SECTION -->
    <section id="fitur" class="features-section">
      <div class="section-title">
        <h2>
          <span class="badge-yellow">Solusi Terbaik</span> untuk Mengelola Kehadiran
        </h2>
      </div>

      <div class="features-container">
        <!-- Jika kamu punya 1 gambar utuh fitur (mockupFeaturesImg) -->
        <img :src="mockupFeaturesImg" alt="Fitur SiapHadir" class="features-full-img" />
      </div>
    </section>

    <!-- 5. PRICING SECTION -->
    <section class="pricing-section">
      <div class="pricing-header">
        <h2>
          Solusi Terbaik dengan <span class="text-highlight-yellow">Harga Tepat</span>
        </h2>
        <p>Paket fleksibel untuk berbagai lini bisnis.</p>
      </div>

      <div class="pricing-cards">
        <!-- Starter Plan -->
        <div class="price-card">
          <h3>Starter</h3>
          <p class="price-sub">Cocok untuk usaha kecil dan berkembang yang baru memulai otomatisasi.</p>
          <div class="price-value">
            <strong>Rp 0</strong> <span>/ bulan</span>
          </div>
          <router-link to="/login" class="btn-price">Mulai</router-link>
          <ul class="price-features">
            <li><Icon icon="material-symbols:check-circle" /> Fitur Absensi Utama</li>
            <li><Icon icon="material-symbols:check-circle" /> Geofencing Lokasi</li>
            <li><Icon icon="material-symbols:check-circle" /> Pengajuan Cuti</li>
            <li><Icon icon="material-symbols:check-circle" /> Laporan Dasar</li>
          </ul>
        </div>

        <!-- Enterprise Plan -->
        <div class="price-card">
          <h3>Enterprise</h3>
          <p class="price-sub">Solusi lengkap untuk skala bisnis menengah hingga perusahaan besar.</p>
          <div class="price-value">
            <strong>Rp 50.000</strong> <span>/ bulan</span>
          </div>
          <router-link to="/login" class="btn-price">Mulai</router-link>
          <ul class="price-features">
            <li><Icon icon="material-symbols:check-circle" /> Seluruh Fitur Starter</li>
            <li><Icon icon="material-symbols:check-circle" /> Rekap Lembur Otomatis</li>
            <li><Icon icon="material-symbols:check-circle" /> Ekspor PDF & CSV</li>
            <li><Icon icon="material-symbols:check-circle" /> Dukungan Prioritas 24/7</li>
          </ul>
        </div>
      </div>
    </section>

    <!-- 6. FOOTER -->
    <footer class="footer">
      <div class="footer-container">
        <div class="footer-col brand-col">
          <div class="footer-brand">
            <img :src="logoUrl" alt="SiapHadir" class="footer-logo" />
            <strong>SiapAbsen</strong>
          </div>
          <p>Sistem pencatatan kehadiran modern berbasis cloud untuk efisiensi perusahaan Anda.</p>
          <div class="footer-address">
            <strong>Head Office:</strong>
            <p>Jl. Pembangunan No. 123, Surabaya, Jawa Timur, Indonesia</p>
          </div>
        </div>

        <div class="footer-col">
          <h4>Navigasi</h4>
          <ul>
            <li><a href="#beranda">Beranda</a></li>
            <li><a href="#tentang">Tentang Kami</a></li>
            <li><a href="#fitur">Fitur</a></li>
          </ul>
        </div>

        <div class="footer-col">
          <h4>Legal</h4>
          <ul>
            <li><a href="#">Kebijakan Privasi</a></li>
            <li><a href="#">Syarat & Ketentuan</a></li>
          </ul>
        </div>

        <div class="footer-col">
          <h4>Kontak</h4>
          <p>+62 812-3456-7890</p>
          <p>support@siapabsen.com</p>
        </div>
      </div>
      <div class="footer-bottom">
        <p>&copy; 2026 SiapAbsen / SiapHadir. All rights reserved.</p>
      </div>
    </footer>
  </div>
</template>

<style scoped>
@import url('https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap');

.landing-page {
  font-family: 'Plus Jakarta Sans', sans-serif;
  color: #2c3345;
  background-color: #ffffff;
  overflow-x: hidden;
  padding-top: 64px;
}

/* --- NAVBAR --- */
.navbar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 16px 8%;
  background: #ffffff;
  position: fixed;
  top: 0;
  left: 0;
  width: 100%;
  box-sizing: border-box;
  z-index: 100;
  transition: transform 0.25s ease;
  will-change: transform;
}
.navbar-hidden {
  transform: translateY(-100%);
}
.nav-brand {
  display: flex;
  align-items: center;
  gap: 10px;
}
.brand-logo {
  width: 32px;
  height: 32px;
}
.brand-title {
  font-size: 18px;
  font-weight: 800;
  color: #2f3b69;
}
.nav-links {
  display: flex;
  gap: 32px;
}
.nav-links a {
  text-decoration: none;
  color: #667085;
  font-size: 14px;
  font-weight: 600;
  transition: color 0.2s;
}
.nav-links a:hover {
  color: #2f3b69;
}
.btn-nav {
  background: #2f3b69;
  color: #ffffff;
  padding: 10px 20px;
  border-radius: 999px;
  font-size: 14px;
  font-weight: 700;
  text-decoration: none;
}

/* --- HERO SECTION --- */
.hero-section {
  padding: 20px 8% 60px;
}
.hero-card {
  background: #2f3b69;
  border-radius: 28px;
  padding: 60px 60px 0;
  color: #ffffff;
  display: grid;
  grid-template-columns: 1.2fr 0.8fr;
  align-items: center;
  gap: 40px;
  overflow: hidden;
}
.hero-text h1 {
  font-size: 40px;
  font-weight: 800;
  line-height: 1.25;
  margin-bottom: 20px;
}
.text-highlight-yellow {
  color: #f2bd48;
}
.hero-text p {
  font-size: 15px;
  line-height: 1.6;
  color: #e5e7f0;
  margin-bottom: 32px;
  max-width: 520px;
}
.hero-actions {
  display: flex;
  gap: 16px;
  margin-bottom: 40px;
}
.btn-yellow {
  background: #f2bd48;
  color: #2c3345;
  font-weight: 700;
  padding: 12px 24px;
  border-radius: 10px;
  text-decoration: none;
  font-size: 14px;
}
.btn-outline-white {
  border: 1px solid rgba(255, 255, 255, 0.4);
  color: #ffffff;
  font-weight: 600;
  padding: 12px 24px;
  border-radius: 10px;
  text-decoration: none;
  font-size: 14px;
}
.hero-image-wrap {
  display: flex;
  justify-content: flex-end;
  align-items: flex-end;
}
.hero-woman-img {
  width: 100%;
  max-width: 360px;
  object-fit: contain;
  display: block;
}

/* --- ABOUT SECTION --- */
.about-section {
  background: #2f3b69;
  color: #ffffff;
  padding: 80px 8%;
}
.about-container {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 60px;
  align-items: center;
}
.brand-badge {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  font-size: 20px;
  font-weight: 800;
  margin-bottom: 24px;
}
.badge-logo {
  width: 28px;
  filter: brightness(0) invert(1);
}
.about-desc {
  font-size: 15px;
  line-height: 1.7;
  color: #e5e7f0;
  margin-bottom: 32px;
}
.quote-text {
  font-size: 20px;
  font-weight: 700;
}
.about-mockup {
  text-align: center;
}
.phone-3d-img {
  width: 100%;
  max-width: 380px;
}

/* --- FEATURES SECTION --- */
.features-section {
  padding: 80px 8%;
  background: #ffffff;
  text-align: center;
}
.section-title h2 {
  font-size: 28px;
  font-weight: 800;
  margin-bottom: 40px;
}
.badge-yellow {
  background: #f2bd48;
  color: #2c3345;
  padding: 4px 12px;
  border-radius: 8px;
}
.features-full-img {
  width: 100%;
  max-width: 900px;
  margin: 0 auto;
}

/* --- PRICING SECTION --- */
.pricing-section {
  background: #2f3b69;
  color: #ffffff;
  padding: 80px 8%;
  text-align: center;
}
.pricing-header h2 {
  font-size: 32px;
  font-weight: 800;
  margin-bottom: 8px;
}
.pricing-header p {
  color: #b7c0df;
  margin-bottom: 48px;
}
.pricing-cards {
  display: flex;
  justify-content: center;
  gap: 30px;
  flex-wrap: wrap;
}
.price-card {
  background: #ffffff;
  color: #2c3345;
  border-radius: 20px;
  padding: 36px 30px;
  width: 100%;
  max-width: 360px;
  text-align: left;
}
.price-card h3 {
  font-size: 20px;
  font-weight: 800;
  margin-bottom: 8px;
}
.price-sub {
  font-size: 13px;
  color: #667085;
  min-height: 40px;
  margin-bottom: 20px;
}
.price-value {
  margin-bottom: 24px;
}
.price-value strong {
  font-size: 32px;
  font-weight: 800;
  color: #2f3b69;
}
.price-value span {
  font-size: 13px;
  color: #667085;
}
.btn-price {
  display: block;
  text-align: center;
  background: #2f3b69;
  color: #ffffff;
  padding: 12px;
  border-radius: 10px;
  text-decoration: none;
  font-weight: 700;
  font-size: 14px;
  margin-bottom: 28px;
}
.price-features {
  list-style: none;
  padding: 0;
  margin: 0;
  display: flex;
  flex-direction: column;
  gap: 12px;
  font-size: 13.5px;
  color: #4a5568;
}
.price-features li {
  display: flex;
  align-items: center;
  gap: 10px;
}
.price-features svg {
  color: #2f3b69;
  flex-shrink: 0;
}

/* --- FOOTER --- */
.footer {
  background: #1e2645;
  color: #b7c0df;
  padding: 60px 8% 24px;
  font-size: 13.5px;
}
.footer-container {
  display: grid;
  grid-template-columns: 2fr 1fr 1fr 1.5fr;
  gap: 40px;
  margin-bottom: 40px;
}
.footer-brand {
  display: flex;
  align-items: center;
  gap: 10px;
  margin-bottom: 12px;
}
.footer-brand strong {
  font-size: 18px;
  color: #ffffff;
}
.footer-logo {
  width: 28px;
  filter: brightness(0) invert(1);
}
.footer-address {
  margin-top: 20px;
}
.footer-address strong {
  color: #ffffff;
}
.footer-col h4 {
  color: #ffffff;
  font-size: 15px;
  margin-bottom: 16px;
}
.footer-col ul {
  list-style: none;
  padding: 0;
  margin: 0;
  display: flex;
  flex-direction: column;
  gap: 10px;
}
.footer-col a {
  color: #b7c0df;
  text-decoration: none;
}
.footer-col a:hover {
  color: #ffffff;
}
.footer-bottom {
  border-top: 1px solid rgba(255, 255, 255, 0.1);
  padding-top: 24px;
  text-align: center;
  font-size: 12px;
}

/* --- RESPONSIVE MOBILE --- */
@media (max-width: 900px) {
  .nav-links { display: none; }
  .hero-card { grid-template-columns: 1fr; padding: 40px 24px 0; }
  .about-container { grid-template-columns: 1fr; }
  .footer-container { grid-template-columns: 1fr 1fr; }
}
</style>