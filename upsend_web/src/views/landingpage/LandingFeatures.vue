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
       <div class="notes-text durasi">
          <h3><span>Siap Pantau Durasi Kerja</span></h3>
          <p>Kelola jam kerja lebih efisien<br>dengan pemantauan durasi kerja<br> yang otomatis, akurat, dan mudah dipantau.</p>
        </div>
      <div>
        <img src="../../assets/ring.svg" alt="Location Icon" class="ring-wrapper" />
        <div class="notes-text verif"> 
          <p>Verifikasi lokasi akurat<br>dan real-time</p>
        </div>
      </div>
      <div class="phone-card phone-cuti">
        <img src="../../assets/phone-cuti.svg" alt="Fitur Cuti" />
        <img src="../../assets/history.svg" alt="History Icon" class="floating-icon icon-history" />
      </div>
      <div class="notes-text cuti"> 
          <h3><span>Pengajuan Cuti Mudah</span></h3>
          <p>Pengajuan cuti lebih cepat,<br> persetujuan lebih mudah,<br> dan riwayat cuti tersimpan dengan rapi.</p>
        </div>
      <div>
        <img src="../../assets/scan-woman.svg" alt="Face" class="floating-icon icon-scan" />
         <div class="notes-text face"> 
          <p>Face Recognition<br>untuk presensi akurat</p>
        </div>
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
.notes-text{
  font-size: 20px;
  font-weight: 400;
  color: #2c3345;
}
.notes-text h3{
  font-weight: 600;
  color: #ffffff;
}
.notes-text span {
  padding: 8px 14px;
  border-radius: 8px;
  background: #2c3345;
}
.verif{
  position: absolute;
  top: 80px;
  right: -200px;
  text-align: left;
}
.cuti{
  position: absolute;
  bottom: 170px;
  right: -320px;
  text-align: left;
}
.durasi{
  position: absolute;
  top: 60px;
  left: -300px;
  text-align: left;
}
.face{
  position: absolute;
  bottom: 100px;
  left: -300px;
  text-align: left;
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
  background: #FBEE00;
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
  width: 240px; 
  height: auto;
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

@keyframes pulseZoom {
  0%,
  100% {
    transform: scale(1); /* Ukuran normal */
  }
  50% {
    transform: scale(1.08); /* Zoom in sebesar 8% pada detik pertengahan */
  }
}
/* =========================================================
   RESPONSIVE DESIGN (UNTUK TABLET DAN HP / MOBILE)
   ========================================================= */
@media (max-width: 992px) {
  
  /* 1. Reset Wadah Utama */
  .mockup-stage {
    width: 100%;
    height: auto !important;
    min-height: 100px !important;
    margin: 10px auto !important;
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 20px; /* Memberi jarak antar elemen */
  }

  /* 2. Pastikan setiap kelompok (div) berderet ke bawah dan di tengah */
  .mockup-stage > div {
    display: flex;
    flex-direction: column;
    align-items: center;
    width: 100%;
  }

  /* 3. Reset Posisi Semua Teks agar Tidak Menumpuk */
  .notes-text, 
  .durasi, 
  .verif, 
  .cuti, 
  .face {
    position: relative !important;
    top: auto !important;
    bottom: auto !important;
    left: auto !important;
    right: auto !important;
    width: 100% !important;
    text-align: center !important;
    margin: 8px 0 !important;
  }

  /* 4. Reset Posisi HP (Tetap Relative agar pop-up melekat) */
  .phone-card {
    position: relative !important;
    top: auto !important;
    right: auto !important;
    left: auto !important;
    margin: 20px 0 !important;
  }

  .phone-presensi, .phone-cuti { width: 200px; margin: 10px 0 !important; }  
  /* 5. Ikon Pop-Up (Waktu & History) tetap melayang di atas HP */
  .icon-time {
    width: 110px !important;
    left: -10px !important;
    top: 150px !important;
  }
  
  .icon-history {
    width: 130px !important;
    right: -10px !important;
    bottom: 30px !important;
  }
  
  /* 6. PERBAIKAN UTAMA: Ring & Scan tidak boleh absolute lagi di HP */
  .ring-wrapper {
    position: relative !important; /* Kunci agar tidak nabrak teks */
    top: auto !important;
    right: auto !important;
    left: auto !important;
    transform: none !important;
    width: 200px !important;
    margin: 10px auto !important;
  }

  .icon-scan {
    position: relative !important; /* Kunci agar tidak nabrak teks */
    bottom: auto !important;
    left: auto !important;
    width: 100px !important;
    margin: 10px auto !important;
  }
}
</style>