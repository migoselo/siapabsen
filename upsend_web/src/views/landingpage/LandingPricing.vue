<template>
  <section id="harga" class="pricing-section">
    <header class="pricing-header"><h2>Solusi Terbaik dengan <span>Harga Tepat</span></h2><p>Paket fleksibel untuk berbagai lini bisnis.</p></header>
    <div class="pricing-cards">
      <article v-for="plan in plans" :key="plan.name" class="price-card">
        <h3>{{ plan.name }}</h3><p class="price-sub">{{ plan.description }}</p>
        <div class="price-value"><strong>{{ plan.price }}</strong> <span>/ bulan</span></div>
        <router-link to="/login" class="btn-price">Mulai</router-link>
        <div class="feature-heading"><span>Fitur</span></div>
        <ul class="price-features"><li v-for="feature in plan.features" :key="feature">&#10003; {{ feature }}</li></ul>
      </article>
    </div>
  </section>
</template>

<script setup>
const plans = [
  { name: 'Starter', price: 'Rp 0', description: 'Cocok untuk usaha kecil dan berkembang yang baru memulai otomatisasi.', features: ['Fitur Absensi Utama', 'Geofencing Lokasi', 'Pengajuan Cuti', 'Laporan Dasar'] },
  { name: 'Enterprise', price: 'Rp 50.000', description: 'Solusi lengkap untuk skala bisnis menengah hingga perusahaan besar.', features: ['Seluruh Fitur Starter', 'Rekap Lembur Otomatis', 'Ekspor PDF & CSV', 'Dukungan Prioritas 24/7'] },
]
</script>

<style scoped>
.pricing-section { padding: 80px 8%; background: #2f3b69; color: #fff; text-align: center; }
.pricing-header h2 { margin: 0 0 8px; font-size: 32px; } .pricing-header h2 span { color: #fbee00; } .pricing-header p { margin: 0 0 48px; color: #b7c0df; }
.pricing-cards { display: flex; justify-content: center; gap: 40px; flex-wrap: wrap; }
.price-card { width: 100%; max-width: 384px; min-height: 412px; padding: 26px 28px 28px; border-radius: 10px; background: #e5ebff; color: #000; text-align: left; }
.price-card h3 { font-size: 16px; } .price-sub { min-height: 58px; font-size: 13px; line-height: 2.2; } .price-value strong { font-size: 26px; } .price-value span { font-size: 13px; }
.btn-price { display: block; margin: 10px 0 26px; padding: 10px; border-radius: 9px; background: #2f3b69; color: #fff; text-align: center; text-decoration: none; }
.feature-heading { display: flex; align-items: center; gap: 8px; margin: 0 7px 14px; font-size: 13px; } .feature-heading::before, .feature-heading::after { content: ''; height: 1px; flex: 1; background: #9a9a9a; }
.price-features { display: flex; flex-direction: column; gap: 11px; padding: 0; margin: 0; list-style: none; font-size: 13.5px; }
</style>
