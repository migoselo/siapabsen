<script setup>
import { onBeforeUnmount, onMounted, ref } from 'vue'
import { Icon } from '@iconify/vue'

// Ganti sesuai lokasi file gambar kamu di folder assets
import logoUrl from '../assets/Logo-web.svg'
import heroWomanImg from '../assets/hero-woman.svg' // Gambar wanita memegang HP
import mockupAppImg from '../assets/mockup-app.svg' // Gambar HP 3D SiapAbsen
//import mockupFeaturesImg from '../assets/mockup-features.png' // Gambar HP & ilustrasi fitur

const isNavbarVisible = ref(true)
let previousScrollY = window.scrollY

const handleScroll = () => {
  const currentScrollY = document.scrollingElement?.scrollTop ?? window.scrollY

  if (currentScrollY === 0 || currentScrollY < previousScrollY) {
    isNavbarVisible.value = true
  } else if (currentScrollY > previousScrollY) {
    isNavbarVisible.value = false
  }

  previousScrollY = currentScrollY
}

onMounted(() => {
  previousScrollY = document.scrollingElement?.scrollTop ?? window.scrollY
  document.addEventListener('scroll', handleScroll, { passive: true, capture: true })
})

onBeforeUnmount(() => {
  document.removeEventListener('scroll', handleScroll, { capture: true })
})
const activeLegalModal = ref(null)

const legalContent = {
  privacy: {
    title: 'Kebijakan Privasi',
    icon: 'material-symbols:shield-outline',
    date: 'Tanggal Efektif: September 2026',
    sections: [
      ['Pengumpulan Informasi', 'SiapHadir dapat mengumpulkan data akun, perusahaan, karyawan, serta informasi lokasi yang diperlukan untuk mencatat kehadiran.'],
      ['Penggunaan Data', 'Data digunakan untuk menyediakan layanan absensi, memverifikasi lokasi kerja, membuat laporan, dan meningkatkan keamanan layanan.'],
      ['Keamanan Data', 'Kami berupaya menjaga data dengan langkah keamanan yang wajar dan membatasi akses hanya kepada pihak yang membutuhkannya.'],
      ['Keterbukaan Pihak Ketiga', 'Kami tidak menjual data pribadi. Data hanya dapat dibagikan kepada penyedia layanan pendukung atau apabila diwajibkan oleh hukum.'],
    ],
  },
  terms: {
    title: 'Syarat & Ketentuan',
    icon: 'material-symbols:description-outline',
    date: 'Terakhir Diperbarui: September 2026',
    sections: [
      ['Penerimaan Syarat', 'Dengan menggunakan SiapHadir, Anda menyetujui syarat dan ketentuan yang berlaku pada layanan ini.'],
      ['Tanggung Jawab Pengguna', 'Pengguna bertanggung jawab menjaga kerahasiaan akun dan memastikan seluruh data yang diberikan benar serta lengkap.'],
      ['Penggunaan yang Dilarang', 'Pengguna dilarang menyalahgunakan layanan, mengakses akun pihak lain, atau mengganggu sistem SiapHadir.'],
      ['Ketersediaan Layanan', 'Pemeliharaan, pembaruan, atau keadaan di luar kendali kami dapat menyebabkan gangguan layanan sementara.'],
    ],
  },
}

function openLegalModal(type) {
  activeLegalModal.value = type
}

function closeLegalModal() {
  activeLegalModal.value = null
}
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
        <h2><span class="badge-yellow">Solusi Terbaik</span> untuk Mengelola Kehadiran</h2>
      </div>
      <!-- Wrapper untuk dua aset mockup HP floating -->
      <div class="features-mockup-container">
        <div class="mockup-stage">
          <!-- HP Kiri (Presensi): Lebih besar dan berada di depan -->
          <div class="phone-card phone-presensi">
            <img src="../assets/phone-presensi.svg" alt="Fitur Presensi" />
          </div>

          <!-- HP Kanan (Cuti): Lebih kecil dan bertengger sedikit di belakang -->
          <div class="phone-card phone-cuti">
            <img src="../assets/phone-cuti.svg" alt="Fitur Cuti" />
          </div>
        </div>
      </div>
    </section>

    <!-- 5. PRICING SECTION -->
    <section id="harga" class="pricing-section">
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
          <div class="feature-heading"><span>Fitur</span></div>
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
          <div class="feature-heading"><span>Fitur</span></div>
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
            <strong>SiapHadir</strong>
          </div>
          <p>Solusi kami memberikan efisiensi.<br />Hubungi kami untuk informasi<br />lebih lanjut</p>
          <div class="footer-address">
            <strong>Head Office:</strong>
            <p>Jl. Simo Pomahan Baru 15/15 Simomulyo baru,<br />Sukomanunggal, Surabaya - Indonesia.</p>
          </div>
        </div>

        <div class="footer-col">
          <h4>Navigasi</h4>
          <ul>
            <li><a href="#beranda">Beranda</a></li>
            <li><a href="#tentang">Tentang Kami</a></li>
            <li><a href="#fitur">Fitur</a></li>
            <li><a href="#harga">Harga</a></li>
          </ul>
        </div>

        <div class="footer-col">
          <h4>Legal</h4>
          <ul>
            <li><a href="#kebijakan-privasi" @click.prevent="openLegalModal('privacy')">Kebijakan Privasi</a></li>
            <li><a href="#syarat-ketentuan" @click.prevent="openLegalModal('terms')">Syarat & Ketentuan</a></li>
          </ul>
        </div>

        <div class="footer-col">
          <h4>Kontak</h4>
          <p>
            CP:
            <a
              href="https://wa.me/6281331777345"
              target="_blank"
              rel="noopener noreferrer"
            >
              0813 3177 7345 (Mustafid Heryanto)
            </a>
          </p>
          <p>
            Email:
            <a href="mailto:pakhafied@yahoo.com">pakhafied@yahoo.com</a>
          </p>
        </div>
      </div>
      <div class="footer-bottom">
        <p>&copy; 2026 Siap Integrasi Absensi. Hak Cipta Dilindungi</p>
        <a href="#beranda" class="back-to-top">Kembali ke Atas</a>
      </div>

      <div
        v-if="activeLegalModal"
        class="legal-modal-overlay"
        role="presentation"
        @click.self="closeLegalModal"
      >
        <section
          class="legal-modal"
          role="dialog"
          aria-modal="true"
          :aria-labelledby="`${activeLegalModal}-modal-title`"
        >
          <header class="legal-modal-header">
            <div class="legal-modal-title">
              <Icon :icon="legalContent[activeLegalModal].icon" />
              <h2 :id="`${activeLegalModal}-modal-title`">{{ legalContent[activeLegalModal].title }}</h2>
            </div>
            <button class="modal-close" type="button" aria-label="Tutup" @click="closeLegalModal">&times;</button>
          </header>
          <div class="legal-modal-body">
            <p class="legal-modal-date">{{ legalContent[activeLegalModal].date }}</p>
            <article v-for="(section, index) in legalContent[activeLegalModal].sections" :key="section[0]" class="legal-modal-section">
              <h3><span>{{ index + 1 }}.</span> {{ section[0] }}</h3>
              <p>{{ section[1] }}</p>
            </article>
          </div>
          <footer class="legal-modal-footer">
            <button class="modal-confirm" type="button" @click="closeLegalModal">Saya Mengerti</button>
          </footer>
        </section>
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
  background: #4e62af;
  color: #ffffff;
  padding: 88px 8% 80px;
  text-align: center;
}
.pricing-header h2 {
  font-size: 30px;
  font-weight: 800;
  margin-bottom: 8px;
}
.pricing-header .text-highlight-yellow {
  color: #fbee00;
}
.pricing-header p {
  color: #ffffff;
  margin-bottom: 74px;
}
.features-mockup-container {
  display: flex;
  justify-content: center;
  align-items: center;
  padding: 40px 0;
  overflow: visible;
}

/* Arena tempat kedua HP disusun secara overlap */
.mockup-stage {
  position: relative;
  width: 100%;
  max-width: 700px;
  height: 600px;
  display: flex;
  justify-content: center;
}

.phone-card {
  position: absolute;
  will-change: transform; /* Optimalisasi performa animasi GPU browser */
}

.phone-card img {
  width: 100%;
  height: auto;
  display: block;
  /* Shadow halus sesuai arah cahaya */
  filter: drop-shadow(-10px 20px 30px rgba(15, 23, 42, 0.18));
}

/* --- HP KIRI (PRESENSI) --- */
.phone-presensi {
  width: 240px;
  right : 330px;
  top: -20px;
  z-index: 2; /* Menjamin HP Presensi selalu berada di depan HP Cuti */
  animation: floatPresensi 5s cubic-bezier(0.45, 0.05, 0.55, 0.95) infinite;
}

/* --- HP KANAN (CUTI) --- */
.phone-cuti {
  width: 220px; /* Ukuran dibuat sedikit lebih kecil sesuai referensi */
  right: 120px;
  top: 40px; /* Digeser agak ke bawah */
  z-index: 1;
  animation: floatCuti 5s cubic-bezier(0.45, 0.05, 0.55, 0.95) infinite;
  animation-delay: -2.5s; /* Jeda animasi agar pergerakannya berlawanan arah secara halus */
}

/* --- KEYFRAMES ANIMASI SMOOTH FLOATING --- */
@keyframes floatPresensi {
  0%, 100% {
    transform: translateY(0px) rotate(0deg);
  }
  50% {
    transform: translateY(-16px) rotate(-1deg); /* Efek miring sangat halus saat terangkat */
  }
}

@keyframes floatCuti {
  0%, 100% {
    transform: translateY(0px) rotate(0deg);
  }
  50% {
    transform: translateY(-14px) rotate(1deg);
  }
}

/* --- RESPONSIONAL UNTUK LAYAR HP --- */
@media (max-width: 640px) {
  .mockup-stage {
    max-width: 340px;
    height: 400px;
  }
  .phone-presensi {
    width: 190px;
    left: 10px;
  }
  .phone-cuti {
    width: 170px;
    right: 10px;
    top: 70px;
  }
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
  gap: 40px;
  flex-wrap: wrap;
}
.price-card {
  background: #e5ebff;
  color: #000000;
  border-radius: 10px;
  padding: 26px 28px 28px;
  width: 100%;
  max-width: 384px;
  min-height: 412px;
  text-align: left;
}
.price-card h3 {
  font-size: 16px;
  gap: 30px;
  flex-wrap: wrap;
}
.price-sub {
  font-size: 13px;
  color: #000000;
  line-height: 2.2;
  min-height: 58px;
  margin-bottom: 16px;
}
.price-value {
  margin-bottom: 10px;
}
.price-value strong {
  font-size: 26px;
  font-weight: 800;
  color: #000000;
}
.price-value span {
  font-size: 13px;
  color: #000000;
}
.btn-price {
  display: block;
  text-align: center;
  background: #2f3b69;
  color: #ffffff;
  padding: 10px;
  border-radius: 9px;
  text-decoration: none;
  font-weight: 500;
  font-size: 16px;
  margin-bottom: 26px;
}
.feature-heading {
  display: flex;
  align-items: center;
  gap: 8px;
  color: #000000;
  font-size: 13px;
  margin: 0 7px 14px;
}
.feature-heading::before,
.feature-heading::after {
  content: '';
  height: 1px;
  flex: 1;
  background: #9a9a9a;
}
.price-features {
  list-style: none;
  padding: 0;
  margin: 0;
  display: flex;
  flex-direction: column;
  gap: 11px;
  font-size: 13.5px;
  color: #000000;
}
.price-features li {
  display: flex;
  align-items: center;
  gap: 10px;
}
.price-features svg {
  color: #000000;
  flex-shrink: 0;
}

/* --- FOOTER --- */
.footer {
  background: #2F3B69;
  color: #DCE1FF;
  padding: 60px 70px 24px;
  font-size: 13px;
  letter-spacing: 0.4px;
}
.footer-container {
  display: grid;
  grid-template-columns: 2fr 1.25fr 1.25fr 1.8fr;
  gap: 52px;
  margin-bottom: 46px;
}
.footer-brand {
  display: flex;
  align-items: center;
  gap: 14px;
  margin-bottom: 18px;
}
.footer-brand strong {
  font-size: 24px;
  letter-spacing: 0;
  color: #FFFFFF;
}
.footer-logo {
  width: 32px;
  filter: brightness(0) invert(1);
}
.footer-col p {
  line-height: 1.75;
  margin: 0;
}
.footer-address {
  margin-top: 26px;
}
.footer-address strong {
  color: #FFFFFF;
  display: block;
  margin-bottom: 8px;
}
.footer-col h4 {
  color: #FFFFFF;
  font-size: 16px;
  letter-spacing: 1px;
  margin: 4px 0 14px;
}
.footer-col ul {
  list-style: none;
  padding: 0;
  margin: 0;
  display: flex;
  flex-direction: column;
  gap: 12px;
}
.footer-col a {
  color: #DCE1FF;
  text-decoration: none;
  transition: color 0.2s ease, opacity 0.2s ease;
}
.footer-col a:hover {
  color: #FBEE00;
  opacity: 0.95;
}
.footer-col a:active {
  color: #FFFFFF;
  opacity: 0.7;
}
.footer-bottom {
  border-top: 1px solid rgba(255, 255, 255, 0.45);
  padding-top: 13px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  color: #aeb7d0;
  font-size: 13px;
}
.footer-bottom p {
  margin: 0;
}
.back-to-top {
  background: #edf0fa;
  color: #344273;
  border-radius: 18px;
  padding: 6px 13px;
  font-size: 12px;
  letter-spacing: 0.3px;
  text-decoration: none;
  transition: background-color 0.2s ease, color 0.2s ease, transform 0.1s ease;
}
.back-to-top:hover {
  background: #FBEE00;
  color: #2F3B69;
}
.back-to-top:active {
  transform: translateY(1px);
}

.legal-modal-overlay {
  position: fixed;
  inset: 0;
  z-index: 200;
  display: grid;
  place-items: center;
  padding: 20px;
  background: rgba(47, 59, 105, 0.72);
  backdrop-filter: blur(5px);
}
.legal-modal {
  width: min(620px, 100%);
  max-height: min(720px, calc(100vh - 40px));
  overflow: hidden;
  background: #2f3b69;
  color: #ffffff;
  border: 1px solid rgba(220, 225, 255, 0.12);
  border-radius: 10px;
  box-shadow: 0 24px 60px rgba(0, 0, 0, 0.32);
}
.legal-modal-header,
.legal-modal-footer {
  background: #4e62af;
  padding: 16px 18px;
}
.legal-modal-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  border-bottom: 1px solid rgba(220, 225, 255, 0.12);
}
.legal-modal-title {
  display: flex;
  align-items: center;
  gap: 10px;
}
.legal-modal-title svg {
  width: 20px;
  height: 20px;
  color: #fbee00;
}
.legal-modal-title h2 {
  margin: 0;
  font-size: 16px;
  color: #ffffff;
}
.modal-close {
  width: 28px;
  height: 28px;
  border: 0;
  border-radius: 6px;
  background: rgba(220, 225, 255, 0.08);
  color: #dce1ff;
  cursor: pointer;
  font-size: 23px;
  line-height: 1;
  transition: background-color 0.2s ease, color 0.2s ease;
}
.modal-close:hover {
  background: rgba(220, 225, 255, 0.18);
  color: #ffffff;
}
.legal-modal-body {
  max-height: 500px;
  overflow-y: auto;
  padding: 20px 18px 24px;
}
.legal-modal-date {
  margin: 0 0 22px;
  color: #858685;
  font-size: 11px;
  font-style: italic;
}
.legal-modal-section + .legal-modal-section {
  margin-top: 20px;
}
.legal-modal-section h3 {
  margin: 0 0 7px;
  font-size: 13px;
  color: #ffffff;
}
.legal-modal-section h3 span {
  color: #fbee00;
  margin-right: 4px;
}
.legal-modal-section p {
  margin: 0;
  color: #dce1ff;
  font-size: 11px;
  line-height: 1.65;
}
.legal-modal-footer {
  display: flex;
  justify-content: flex-end;
  border-top: 1px solid rgba(220, 225, 255, 0.12);
}
.modal-confirm {
  border: 0;
  border-radius: 8px;
  padding: 8px 16px;
  background: #fbee00;
  color: #2f3b69;
  cursor: pointer;
  font-family: inherit;
  font-size: 11px;
  font-weight: 700;
  transition: background-color 0.2s ease, transform 0.1s ease;
}
.modal-confirm:hover { background: #ffffff; }
.modal-confirm:active { transform: translateY(1px); }

/* --- RESPONSIVE MOBILE --- */
@media (max-width: 900px) {
  .nav-links { display: none; }
  .hero-card { grid-template-columns: 1fr; padding: 40px 24px 0; }
  .about-container { grid-template-columns: 1fr; }
  .footer { padding: 48px 24px 20px; }
  .footer-container { grid-template-columns: 1fr 1fr; gap: 32px 24px; }
  .footer-bottom { gap: 16px; font-size: 13px; }
}

@media (max-width: 560px) {
  .footer-container { grid-template-columns: 1fr; }
  .footer-bottom { align-items: flex-start; flex-direction: column; }
  .legal-modal-overlay { padding: 12px; }
  .legal-modal { max-height: calc(100vh - 24px); }
  .legal-modal-body { max-height: calc(100vh - 150px); }
}
</style>
