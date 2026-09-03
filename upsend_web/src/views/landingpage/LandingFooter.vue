<script setup>
import { ref } from 'vue'
import { Icon } from '@iconify/vue'
import logoUrl from '../../assets/Logo-web.svg'

const activeLegalModal = ref(null)
const legalContent = {
  privacy: { title: 'Kebijakan Privasi', icon: 'material-symbols:shield-outline', date: 'Tanggal Efektif: September 2026', text: 'SiapHadir dapat mengumpulkan data akun, perusahaan, karyawan, serta informasi lokasi yang diperlukan untuk mencatat kehadiran.' },
  terms: { title: 'Syarat & Ketentuan', icon: 'material-symbols:description-outline', date: 'Terakhir Diperbarui: September 2026', text: 'Dengan menggunakan SiapHadir, Anda menyetujui syarat dan ketentuan yang berlaku pada layanan ini.' },
}
</script>

<template>
  <footer class="landing-footer">
    <div class="footer-grid">
      <div><div class="footer-brand"><img :src="logoUrl" alt="SiapHadir" /><strong>SiapHadir</strong></div><p>Solusi kami memberikan efisiensi. Hubungi kami untuk informasi lebih lanjut.</p><p class="address"><strong>Head Office:</strong> Jl. Simo Pomahan Baru 15/15 Simomulyo baru, Sukomanunggal, Surabaya - Indonesia.</p></div>
      <div><h4>Navigasi</h4><a href="#beranda">Beranda</a><a href="#tentang">Tentang Kami</a><a href="#fitur">Fitur</a><a href="#harga">Harga</a></div>
      <div><h4>Legal</h4><a href="#" @click.prevent="activeLegalModal = 'privacy'">Kebijakan Privasi</a><a href="#" @click.prevent="activeLegalModal = 'terms'">Syarat & Ketentuan</a></div>
      <div><h4>Kontak</h4><a href="https://wa.me/6281331777345">0813 3177 7345</a><a href="mailto:pakhafied@yahoo.com">pakhafied@yahoo.com</a></div>
    </div>
    <div class="footer-bottom"><span>&copy; 2026 Siap Integrasi Absensi. Hak Cipta Dilindungi</span><a href="#beranda">Kembali ke Atas</a></div>
    <div v-if="activeLegalModal" class="modal-overlay" @click.self="activeLegalModal = null"><section class="modal"><header><div><Icon :icon="legalContent[activeLegalModal].icon" /><h2>{{ legalContent[activeLegalModal].title }}</h2></div><button type="button" @click="activeLegalModal = null">&times;</button></header><div class="modal-body"><small>{{ legalContent[activeLegalModal].date }}</small><p>{{ legalContent[activeLegalModal].text }}</p></div><footer><button type="button" @click="activeLegalModal = null">Saya Mengerti</button></footer></section></div>
  </footer>
</template>

<style scoped>
.landing-footer { padding: 60px 8% 24px; background: #2f3b69; color: #dce1ff; font-size: 13px; }
.footer-grid { display: grid; grid-template-columns: 2fr 1fr 1fr 1.4fr; gap: 52px; margin-bottom: 46px; } .footer-brand { display: flex; align-items: center; gap: 14px; margin-bottom: 18px; } .footer-brand img { width: 32px; filter: brightness(0) invert(1); } .footer-brand strong { color: #fff; font-size: 24px; } .landing-footer p { line-height: 1.75; } .address { margin-top: 26px; }
.landing-footer h4 { margin: 4px 0 14px; color: #fff; } .landing-footer a { display: block; margin-bottom: 12px; color: #dce1ff; text-decoration: none; } .footer-bottom { display: flex; justify-content: space-between; gap: 16px; padding-top: 13px; border-top: 1px solid rgba(220,225,255,.45); } .footer-bottom a { margin: 0; }
.modal-overlay { position: fixed; inset: 0; z-index: 200; display: grid; place-items: center; padding: 20px; background: rgba(47,59,105,.72); } .modal { width: min(620px, 100%); background: #2f3b69; border-radius: 10px; } .modal header, .modal footer { display: flex; justify-content: space-between; padding: 16px 18px; background: #4e62af; } .modal header div { display: flex; align-items: center; gap: 10px; } .modal h2 { font-size: 16px; } .modal header button, .modal footer button { border: 0; padding: 8px 16px; cursor: pointer; } .modal-body { padding: 20px 18px; }
@media (max-width: 900px) { .footer-grid { grid-template-columns: 1fr 1fr; gap: 32px 24px; } } @media (max-width: 560px) { .footer-grid { grid-template-columns: 1fr; } .footer-bottom { flex-direction: column; } }
</style>
