<script setup>
import logoUrl from '../../assets/Logo-web.svg'
import mockupAppImg from '../../assets/mockup-app.svg'
</script>

<template>
  <section id="tentang" class="about-section">
    <div class="about-container">
      <div>
        <div class="brand-badge"><img :src="logoUrl" alt="Logo" /><span>SiapAbsen</span></div>
        <p class="about-desc">
          Banyak perusahaan masih mengandalkan proses absensi manual yang memakan waktu, rentan kesalahan, dan tidak efisien. Kami hadir dengan SiapAbsen sebagai jawaban atas tantangan tersebut. SiapAbsen membantu perusahaan mencatat, memantau, dan mengelola kehadiran karyawan secara realtime.
        </p>
        <h4>"Memberikan <span>Kehadiran</span> Terpercaya"</h4>
      </div>
      <div class="about-mockup"><img :src="mockupAppImg" alt="SiapAbsen Mobile App" /></div>
    </div>
  </section>
</template>

<style scoped>
.about-section { padding: 80px 8%; background: #2f3b69; color: #fff; }
.about-container { display: grid; grid-template-columns: 1fr 1fr; gap: 60px; align-items: center; }
.brand-badge { display: inline-flex; align-items: center; gap: 8px; margin-bottom: 24px; font-size: 20px; font-weight: 800; }
.brand-badge img { width: 28px; filter: brightness(0) invert(1); }
.about-desc { margin: 0 0 32px; color: #e5e7f0; font-size: 15px; line-height: 1.7; }
h4 { margin: 0; font-size: 20px; } h4 span { color: #f2bd48; }
.about-mockup { text-align: center; } .about-mockup img { width: 100%; max-width: 380px; }
@media (max-width: 900px) { .about-container { grid-template-columns: 1fr; } }
</style>
