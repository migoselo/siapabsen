<script setup>
import logoUrl from '../../assets/Logo-web.svg'
import mockupAppImg from '../../assets/mockup-app.svg'
</script>

<template>
  <section id="tentang" class="about-section">
    <div class="about-container">
      <div class="about-copy">
        <div class="brand-badge">
          <img :src="logoUrl" alt="Logo" />
          <span>SiapHadir</span>
        </div>

        <p class="about-desc">
          Banyak perusahaan masih mengandalkan proses absensi manual yang memakan waktu, rentan kesalahan,
          dan sulit diaudit. Kami hadir dengan SiapAbsen sebagai jawaban atas tantangan tersebut. SiapAbsen
          merupakan sebuah sistem yang membantu perusahaan mencatat, memantau, dan mengelola kehadiran
          karyawan secara real-time.
        </p>

        <h4>"Memberikan <span>Kehadiran</span> Terpercaya"</h4>
      </div>

      <div class="about-mockup">
        <img :src="mockupAppImg" alt="SiapAbsen Mobile App" />
      </div>
    </div>
  </section>
</template>

<style scoped>
@import url('https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap');

.about-section {
  display: flex;
  align-items: center;
  justify-content: center;
  min-height: 100vh;
  padding: clamp(42px, 5vw, 84px) 8%;   
  background: #4E62AF;
  color: #ffffff;
  font-family: 'Plus Jakarta Sans', sans-serif;
}

.about-container {
  width: 100%;
  display: grid;
  grid-template-columns: minmax(0, 1fr) minmax(320px, 560px);
  gap: clamp(24px, 4vw, 90px);
  align-items: center;
  min-height: 0;
}

.about-copy {
  display: flex;
  flex-direction: column;
  align-items: flex-start;
  justify-content: center;
  align-self: center;
}

.brand-badge {
  display: inline-flex;
  align-items: center;
  gap: 16px;
  margin: 0 0 26px;
}

.brand-badge img {
  width: clamp(36px, 3vw, 48px);
  height: clamp(36px, 3vw, 48px);
  filter: brightness(0) invert(1);
}

.brand-badge span {
  font-size: clamp(24px, 2.1vw, 28px);
  font-weight: 800;
  letter-spacing: -0.05em;
  line-height: 1;
}

.about-desc {
  max-width: 700px;
  margin: 0 0 30px;
  color: rgba(255, 255, 255, 0.95);
  font-size: clamp(13px, 1.1vw, 15px);
  line-height: 1.75;
  letter-spacing: -0.01em;
}

.about-copy h4 {
  margin: 0;
  font-size: clamp(18px, 1.8vw, 22px);
  font-weight: 600;
  line-height: 1.3;
  letter-spacing: -0.02em;
  color: #ffffff;
  font-style: italic;
}

.about-copy h4 span {
  color: #FBEE00;
  font-weight: 700;
}

.about-mockup {
  display: flex;
  justify-content: center;
  align-items: center;
  padding-right: 0;
  margin-top: 0;
}

.about-mockup img {
  display: block;
  width: 100%;
  max-width: 560px;
  height: auto;
  object-fit: contain;
  filter: drop-shadow(-12px 24px 28px rgba(15, 21, 35, 0.35));  
  animation: float 3.5s ease-in-out infinite;
}

@keyframes float {
  0%, 100% {
    transform: translateY(0);
  }
  50% {
    transform: translateY(-18px);
  }
}

@media (max-width: 980px) {
  .about-section {
    min-height: auto;   /* <-- ini yang ditambahkan */
  }

  .about-container {
    grid-template-columns: 1fr;
    gap: 40px;
  }

  .about-copy {
    align-items: center;
    text-align: center;
    padding-left: 0;
  }

  .about-mockup {
    justify-content: center;
    padding-right: 0;
    transform: none;
  }

  .about-desc {
    max-width: 100%;
  }
}

@media (max-width: 560px) {
  .about-section {
    padding: 64px 20px 56px;
  }

  .brand-badge {
    gap: 10px;
    margin-bottom: 18px;
  }

  .brand-badge img {
    width: 38px;
    height: 38px;
  }

  .brand-badge span {
    font-size: 24px;
  }

  .about-desc {
    font-size: 14px;
    line-height: 1.7;
    margin-bottom: 20px;
  }

  .about-copy h4 {
    font-size: 16px;
  }
}
</style>
