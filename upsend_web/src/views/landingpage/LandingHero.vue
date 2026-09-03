<script setup>
import heroWomanImg from '../../assets/hero-woman.svg'
</script>

<template>
  <section id="beranda" class="hero-section">
    <div class="hero-card">
      <div class="hero-text">
        <h1><span>Siap</span> Kelola Kehadiran Lebih Mudah dan Akurat</h1>
        <p>
          Kelola kehadiran karyawan lebih efisien dan terstruktur. Dengan verifikasi lokasi presisi dan pencatatan absensi yang terintegrasi, menjadikan pencatatan kehadiran jauh lebih praktis dan akurat.
        </p>
        <div class="hero-actions">
          <router-link to="/login" class="btn-yellow">Coba Sekarang</router-link>
          <a href="#fitur" class="btn-outline-white">Pelajari Lebih</a>
        </div>
      </div>
      <div class="hero-image-wrap">
        <img :src="heroWomanImg" alt="SiapHadir User" />
      </div>
    </div>
  </section>
</template>

<style scoped>
.hero-section { padding: 20px 8% 60px; }
.hero-card { background: #2f3b69; border-radius: 28px; padding: 60px 60px 0; color: #fff; display: grid; grid-template-columns: 1.2fr .8fr; align-items: center; gap: 40px; overflow: hidden; }
.hero-text h1 { font-size: 40px; font-weight: 800; line-height: 1.25; margin: 0 0 20px; }
.hero-text h1 span { color: #f2bd48; }
.hero-text p { max-width: 520px; margin: 0 0 32px; color: #e5e7f0; font-size: 15px; line-height: 1.6; }
.hero-actions { display: flex; gap: 16px; margin-bottom: 40px; }
.btn-yellow, .btn-outline-white { padding: 12px 24px; border-radius: 10px; font-size: 14px; text-decoration: none; }
.btn-yellow { background: #f2bd48; color: #2c3345; font-weight: 700; }
.btn-outline-white { border: 1px solid rgba(255, 255, 255, .4); color: #fff; font-weight: 600; }
.hero-image-wrap { display: flex; justify-content: flex-end; align-items: flex-end; }
.hero-image-wrap img { display: block; width: 100%; max-width: 360px; object-fit: contain; }
@media (max-width: 900px) { .hero-card { grid-template-columns: 1fr; padding: 40px 24px 0; } }
</style>
