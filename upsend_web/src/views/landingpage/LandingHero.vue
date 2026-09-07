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
.hero-section {
  box-sizing: border-box;
  display: flex;
  align-items: center;
  justify-content: center;
  min-height: calc(100svh - clamp(72px, 8vw, 88px));
  padding: 12px 8% 60px;
}
.hero-card {
  box-sizing: border-box;
  width: min(100%, 1200px);
  background: #2f3b69;
  border-radius: 28px;
  padding: clamp(40px, 5vw, 60px) clamp(24px, 5vw, 60px) 0;
  color: #fff;
  display: grid;
  grid-template-columns: 1.2fr .8fr;
  align-items: center;
  gap: clamp(28px, 4vw, 40px);
  overflow: hidden;
}
.hero-text h1 { font-size: clamp(30px, 3.2vw, 40px); font-weight: 800; line-height: 1.25; margin: 0 0 20px; }
.hero-text h1 span { color: #FBEF00; }
.hero-text p { max-width: 520px; margin: 0 0 32px; color: #e5e7f0; font-size: clamp(14px, 1.2vw, 15px); line-height: 1.6; }
.hero-actions { display: flex; gap: 16px; margin-bottom: 40px; }
.btn-yellow, .btn-outline-white { padding: 12px 24px; border-radius: 10px; font-size: 14px; text-decoration: none; }
.btn-yellow { background: #FBEF00; color: #2c3345; font-weight: 700; }
.btn-outline-white { border: 1px solid rgba(255, 255, 255, .4); color: #fff; font-weight: 600; }
.hero-image-wrap { display: flex; justify-content: flex-end; align-items: flex-end; }
.hero-image-wrap img { display: block; width: min(100%, 360px); max-height: 70svh; object-fit: contain; }

@media (min-width: 2000px) {
  .hero-section {
    align-items: center;
    min-height: calc(100svh - 72px);
  }

  .hero-card {
    margin-inline: auto;
  }
}

@media (max-width: 900px) {
  .hero-section {
    align-items: center;
    min-height: calc(100svh - 72px);
    padding: 12px 6% 48px;
  }

  .hero-card {
    grid-template-columns: 1fr;
    padding: 40px 24px 0;
  }

  .hero-text {
    text-align: left;
  }

  .hero-image-wrap {
    justify-content: center;
  }

  .hero-image-wrap img {
    width: min(72vw, 320px);
    max-height: 46svh;
  }
}

@media (min-width: 561px) and (max-width: 1200px) {
  .hero-section {
    align-items: flex-start;
    min-height: auto;
    padding: 12px clamp(24px, 6vw, 72px) 48px;
  }

  .hero-card {
    width: 100%;
    margin-inline: auto;
  }
}

@media (max-width: 560px) {
  .hero-section {
    padding: 16px 20px 36px;
  }

  .hero-card {
    border-radius: 20px;
    padding: 32px 20px 0;
    gap: 24px;
  }

  .hero-text h1 {
    margin-bottom: 16px;
  }

  .hero-text p {
    margin-bottom: 24px;
  }

  .hero-actions {
    flex-wrap: wrap;
    margin-bottom: 28px;
  }
}
</style>
