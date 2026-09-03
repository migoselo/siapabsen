<template>
  <section id="fitur" class="features-section">
    <div class="section-title">
      <h2><span>Solusi Terbaik</span> untuk Mengelola Kehadiran</h2>
    </div>
    <div class="mockup-stage">
      <div class="phone-card phone-presensi">
        <img src="../../assets/phone-presensi.svg" alt="Fitur Presensi" />
        <img src="../../assets/time.svg" alt="Time Icon" class="floating-icon icon-time" />
      </div>
      <div>
        <img src="../../assets/ring.svg" alt="Location Icon" class="ring-wrapper" />
      </div>
      <div class="phone-card phone-cuti">
        <img src="../../assets/phone-cuti.svg" alt="Fitur Cuti" />
        <img src="../../assets/history.svg" alt="History Icon" class="floating-icon icon-history" />
      </div>
      <div class="scanner-container">
        <img src="../../assets/scan-woman.svg" alt="Face" class="floating-icon icon-scan" />
      </div>
    </div>
  </section>
</template>

<style scoped>
.features-section {
  padding: 80px 8%;
  background: #fff;
  text-align: center;
}
.section-title h2 {
  margin: 0 0 40px;
  font-size: 28px;
  font-weight: 800;
  color: #2c3345;
}
.section-title span {
  padding: 4px 12px;
  border-radius: 8px;
  background: #f2bd48;
}
.mockup-stage {
  position: relative;
  width: 100%;
  max-width: 700px;
  height: 600px;
  margin: 0 auto;
}
.phone-card {
  position: absolute;
  will-change: transform;
}
.phone-card img {
  display: block;
  width: 100%;
  filter: drop-shadow(-10px 20px 30px rgba(15, 23, 42, 0.18));
}
.phone-presensi {
  top: -20px;
  right: 330px;
  z-index: 2;
  width: 240px;
  animation: float-presensi 5s ease-in-out infinite;
}
.phone-cuti {
  top: 40px;
  right: 120px;
  z-index: 2;
  width: 220px;
  animation: float-cuti 5s ease-in-out -2.5s infinite;
}
.floating-icon {
  position: absolute;
  width: 50px;
  height: auto;
  z-index: 10;
  filter: drop-shadow(0 4px 8px rgba(0, 0, 0, 0.15));
}

/* 3. Atur posisi spesifik untuk time.svg */
.icon-time {
  top: 240px;
  left: -150px;
}
.icon-history {
  bottom: 60px;
  right: -120px;
}
.icon-scan{
  width: 120px;
  bottom: 50px;
  left:-80px;
  animation: pulseZoom 4s ease-in-out infinite;
}
.ring-wrapper {
  position: absolute;
  top: 30px;
  right: 40px;
  z-index: 0;
  pointer-events: none;
  animation: pulseZoom 4s ease-in-out infinite;
} 
@keyframes float-presensi {
  50% {
    transform: translateY(-16px) rotate(-1deg);
  }
}
@keyframes float-cuti {
  50% {
    transform: translateY(-14px) rotate(1deg);
  }
}
@media (max-width: 640px) {
  .mockup-stage {
    height: 400px;
  }
  .phone-presensi {
    left: 10px;
    width: 190px;
  }
  .phone-cuti {
    top: 70px;
    right: 10px;
    width: 170px;
  }
}
@keyframes pulseZoom {
  0%,
  100% {
    transform: scale(1); /* Ukuran normal */
  }
  50% {
    transform: scale(1.08); /* Zoom in sebesar 8% pada detik pertengahan */
  }
}
</style>
