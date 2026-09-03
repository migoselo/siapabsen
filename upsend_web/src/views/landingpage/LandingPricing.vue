<script setup>
import { Icon } from '@iconify/vue'
</script>

<template>
  <section id="harga" class="pricing-section">
    <div class="pricing-header">
      <h2>Solusi Terbaik dengan <span>Harga Tepat</span></h2>
      <p>Paket fleksibel untuk berbagai lini bisnis.</p>
    </div>

    <div class="pricing-cards">
      <div class="price-card">
        <h3>Starter</h3>
        <p class="price-sub">Cocok untuk usaha kecil dan berkembang yang baru memulai otomatisasi.</p>
        <div class="price-value"><strong>Rp 0</strong> <span>/ bulan</span></div>
        <router-link to="/login" class="btn-price">Mulai</router-link>
        <div class="feature-heading"><span>Fitur</span></div>
        <ul class="price-features">
          <li><Icon icon="material-symbols:check-circle" /> Fitur Absensi Utama</li>
          <li><Icon icon="material-symbols:check-circle" /> Geofencing Lokasi</li>
          <li><Icon icon="material-symbols:check-circle" /> Pengajuan Cuti</li>
          <li><Icon icon="material-symbols:check-circle" /> Laporan Dasar</li>
        </ul>
      </div>

      <div class="price-card">
        <h3>Enterprise</h3>
        <p class="price-sub">Solusi lengkap untuk skala bisnis menengah hingga perusahaan besar.</p>
        <div class="price-value"><strong>Rp 50.000</strong> <span>/ bulan</span></div>
        <router-link to="/login" class="btn-price">Mulai</router-link>
        <div class="feature-heading"><span>Fitur</span></div>
        <ul class="price-features">
          <li><Icon icon="material-symbols:check-circle" /> Seluruh Fitur Starter</li>
          <li><Icon icon="material-symbols:check-circle" /> Rekap Lembur Otomatis</li>
          <li><Icon icon="material-symbols:check-circle" /> Ekspor PDF &amp; CSV</li>
          <li><Icon icon="material-symbols:check-circle" /> Dukungan Prioritas 24/7</li>
        </ul>
      </div>
    </div>
  </section>
</template>

<style scoped>
@import url('https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap');

.pricing-section {
  padding: 88px 8% 80px;
  background: #4e62af;
  color: #ffffff;
  text-align: center;
}
.pricing-header h2 {
  margin: 0 0 8px;
  font-size: 30px;
  font-weight: 800;
}
.pricing-header h2 span { color: #fbee00; }
.pricing-header p {
  margin: 0 0 74px;
  color: #ffffff;
}
.pricing-cards {
  display: flex;
  justify-content: center;
  gap: 40px;
  flex-wrap: wrap;
}
.price-card {
  width: 100%;
  max-width: 384px;
  min-height: 412px;
  padding: 26px 28px 28px;
  border-radius: 10px;
  background: #e5ebff;
  color: #000000;
  text-align: left;
}
.price-card h3 {
  margin: 0 0 8px;
  font-size: 16px;
  font-weight: 800;
}
.price-sub {
  min-height: 58px;
  margin: 0 0 16px;
  color: #000000;
  font-size: 13px;
  line-height: 2.2;
}
.price-value { margin-bottom: 10px; }
.price-value strong {
  color: #000000;
  font-size: 26px;
  font-weight: 800;
}
.price-value span { color: #000000; font-size: 13px; }
.btn-price {
  display: block;
  margin: 0 0 26px;
  padding: 10px;
  border-radius: 9px;
  background: #2f3b69;
  color: #ffffff;
  font-size: 16px;
  font-weight: 500;
  text-align: center;
  text-decoration: none;
  transition: background-color 0.2s ease, transform 0.1s ease;
}
.btn-price:hover { background: #4e62af; }
.btn-price:active { transform: translateY(1px); }
.feature-heading {
  display: flex;
  align-items: center;
  gap: 8px;
  margin: 0 7px 14px;
  color: #000000;
  font-size: 13px;
}
.feature-heading::before,
.feature-heading::after {
  content: '';
  height: 1px;
  flex: 1;
  background: #9a9a9a;
}
.price-features {
  display: flex;
  flex-direction: column;
  gap: 11px;
  padding: 0;
  margin: 0;
  color: #000000;
  font-size: 13.5px;
  list-style: none;
}
.price-features li { display: flex; align-items: center; gap: 10px; }
.price-features svg { flex-shrink: 0; color: #000000; }

@media (max-width: 900px) {
  .pricing-section { padding: 64px 24px; }
}

@media (max-width: 560px) {
  .pricing-section { padding: 56px 16px; }
  .pricing-header h2 { font-size: 25px; }
  .pricing-header p { margin-bottom: 40px; }
  .price-card { max-width: 384px; }
}
</style>
