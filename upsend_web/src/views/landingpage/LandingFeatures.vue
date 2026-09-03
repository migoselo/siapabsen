<template>
  <section id="fitur" class="features-section">
    <div class="section-title"><h2><span>Solusi Terbaik</span> untuk Mengelola Kehadiran</h2></div>
    <div class="mockup-stage">
      <div class="phone-card phone-presensi"><img src="../../assets/phone-presensi.svg" alt="Fitur Presensi" /></div>
      <div class="phone-card phone-cuti"><img src="../../assets/phone-cuti.svg" alt="Fitur Cuti" /></div>
    </div>
  </section>
</template>

<style scoped>
.features-section { padding: 80px 8%; background: #fff; text-align: center; }
.section-title h2 { margin: 0 0 40px; font-size: 28px; font-weight: 800; color: #2c3345; }
.section-title span { padding: 4px 12px; border-radius: 8px; background: #f2bd48; }
.mockup-stage { position: relative; width: 100%; max-width: 700px; height: 600px; margin: 0 auto; }
.phone-card { position: absolute; will-change: transform; }
.phone-card img { display: block; width: 100%; filter: drop-shadow(-10px 20px 30px rgba(15, 23, 42, .18)); }
.phone-presensi { top: -20px; right: 330px; z-index: 2; width: 240px; animation: float-presensi 5s ease-in-out infinite; }
.phone-cuti { top: 40px; right: 120px; z-index: 1; width: 220px; animation: float-cuti 5s ease-in-out -2.5s infinite; }
@keyframes float-presensi { 50% { transform: translateY(-16px) rotate(-1deg); } }
@keyframes float-cuti { 50% { transform: translateY(-14px) rotate(1deg); } }
@media (max-width: 640px) { .mockup-stage { height: 400px; } .phone-presensi { left: 10px; width: 190px; } .phone-cuti { top: 70px; right: 10px; width: 170px; } }
</style>
