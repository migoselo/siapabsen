<script setup>
import { ref } from 'vue'
import logoUrl from '../../assets/Logo-web.svg'

const activeLegalModal = ref(null)
const legalContent = {
  privacy: {
    title: 'Kebijakan Privasi',
    sections: [
      ['Pengumpulan Informasi', 'SiapHadir dapat mengumpulkan data akun, perusahaan, karyawan, serta informasi lokasi yang diperlukan untuk mencatat kehadiran.'],
      ['Penggunaan Data', 'Data digunakan untuk menyediakan layanan absensi, memverifikasi lokasi kerja, membuat laporan, dan meningkatkan keamanan layanan.'],
      ['Keamanan Data', 'Kami berupaya menjaga data dengan langkah keamanan yang wajar dan membatasi akses hanya kepada pihak yang membutuhkannya.'],
      ['Keterbukaan Pihak Ketiga', 'Kami tidak menjual data pribadi. Data hanya dapat dibagikan kepada penyedia layanan pendukung atau apabila diwajibkan oleh hukum.'],
    ],
  },
  terms: {
    title: 'Syarat & Ketentuan',
    sections: [
      ['Penerimaan Syarat', 'Dengan menggunakan SiapHadir, Anda menyetujui syarat dan ketentuan yang berlaku pada layanan ini.'],
      ['Tanggung Jawab Pengguna', 'Pengguna bertanggung jawab menjaga kerahasiaan akun dan memastikan seluruh data yang diberikan benar serta lengkap.'],
      ['Penggunaan yang Dilarang', 'Pengguna dilarang menyalahgunakan layanan, mengakses akun pihak lain, atau mengganggu sistem SiapHadir.'],
      ['Ketersediaan Layanan', 'Pemeliharaan, pembaruan, atau keadaan di luar kendali kami dapat menyebabkan gangguan layanan sementara.'],
    ],
  },
}

function openLegalModal(type) {
  activeLegalModal.value = type
}

function closeLegalModal() {
  activeLegalModal.value = null
}
</script>

<template>
   <footer class="footer">
  <div class="footer-inner">
      <div class="footer-container">
        <div class="footer-col brand-col">
          <div class="footer-brand">
            <img :src="logoUrl" alt="SiapHadir" class="footer-logo" />
            <strong>SiapHadir</strong>
          </div>
          <p>Solusi kami memberikan efisiensi.<br />Hubungi kami untuk informasi lebih lanjut</p>
          <div class="footer-address">
            <strong>Head Office:</strong>
            <p>Jl. Simo Pomahan Baru 15/15 Simomulyo baru,<br />Sukomanunggal, Surabaya - Indonesia.</p>
          </div>
        </div>

        <div class="footer-col">
          <h4>Navigasi</h4>
          <ul>
            <li><a href="#beranda">Beranda</a></li>
            <li><a href="#tentang">Tentang Kami</a></li>
            <li><a href="#fitur">Fitur</a></li>
            <li><a href="#harga">Harga</a></li>
          </ul>
        </div>

        <div class="footer-col">
          <h4>Legal</h4>
          <ul>
            <li><a href="#kebijakan-privasi" @click.prevent="openLegalModal('privacy')">Kebijakan Privasi</a></li>
            <li><a href="#syarat-ketentuan" @click.prevent="openLegalModal('terms')">Syarat & Ketentuan</a></li>
          </ul>
        </div>

        <div class="footer-col">
          <h4>Kontak</h4>
          <p>
            CP:
            <a
              href="https://wa.me/6281331777345"
              target="_blank"
              rel="noopener noreferrer"
            >
              0813 3177 7345 (Mustafid Heryanto)
            </a>
          </p>
          <p>
            Email:
            <a href="mailto:pakhafied@yahoo.com">pakhafied@yahoo.com</a>
          </p>
        </div>
      </div>
      <div class="footer-bottom">
        <p>&copy; 2026 Siap Integrasi Absensi. Hak Cipta Dilindungi</p>
        <a href="#beranda" class="back-to-top">Kembali ke Atas</a>
      </div>
      </div>

      <div
        v-if="activeLegalModal"
        class="legal-modal-overlay"
        role="presentation"
        @click.self="closeLegalModal"
      >
        <section
          class="legal-modal"
          role="dialog"
          aria-modal="true"
          :aria-labelledby="`${activeLegalModal}-modal-title`"
        >
          <header class="legal-modal-header">
            <div class="legal-modal-title">
              <h2 :id="`${activeLegalModal}-modal-title`">{{ legalContent[activeLegalModal].title }}</h2>
            </div>
            <button class="modal-close" type="button" aria-label="Tutup" @click="closeLegalModal">&times;</button>
          </header>
          <div class="legal-modal-body">
            <p class="legal-modal-date">{{ legalContent[activeLegalModal].date }}</p>
            <article v-for="(section, index) in legalContent[activeLegalModal].sections" :key="section[0]" class="legal-modal-section">
              <h3><span>{{ index + 1 }}.</span> {{ section[0] }}</h3>
              <p>{{ section[1] }}</p>
            </article>
          </div>
          <footer class="legal-modal-footer">
            <button class="modal-confirm" type="button" @click="closeLegalModal">Saya Mengerti</button>
          </footer>
        </section>
      </div>
    </footer>
</template>

<style scoped>
@import url('https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap');

.footer {
  background: #2F3B69;
  color: #DCE1FF;
  padding: clamp(40px, 5vw, 60px) 8% 24px;
  font-size: 12px;
  letter-spacing: 0.4px;
}
.footer-inner {
  width: fit-content;
  max-width: 100%;
  margin: 0 auto;
}
.footer-container {
  display: grid;
  grid-template-columns: max-content max-content max-content max-content;
  column-gap: 70px;
  row-gap: 28px;
  justify-content: center;
  margin-bottom: 46px;
}
.footer-brand {
  display: flex;
  align-items: center;
  gap: 14px;
  margin-bottom: 18px;
}
.footer-brand strong {
  font-size: 18px;
  letter-spacing: 0;
  color: #FFFFFF;
}
.footer-logo {
  width: 32px;
  filter: brightness(0) invert(1);
}
.footer-col p {
  font-size: 12px;
  line-height: 1.75;
  margin: 0;
  text-align: justify;
}
.footer-address {
  margin-top: 26px;
}
.footer-address strong {
  color: #FFFFFF;
  display: block;
  margin-bottom: 8px;
}
.footer-col h4 {
  color: #FFFFFF;
  font-size: 12px;
  letter-spacing: 1px;
  margin: 4px 0 14px;
}
.footer-col ul {
  list-style: none;
  padding: 0;
  margin: 0;
  display: flex;
  flex-direction: column;
  gap: 12px;
}
.footer-col a {
  color: #DCE1FF;
  font-size: 12px;
  text-decoration: none;
  transition: color 0.2s ease, opacity 0.2s ease;
}
.footer-col a:hover {
  color: #FBEE00;
  opacity: 0.95;
}
.footer-col a:active {
  color: #FFFFFF;
  opacity: 0.7;
}
.footer-bottom {
  width: 100%;
  border-top: 1px solid rgba(255, 255, 255, 0.45);
  padding-top: 13px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  color: #aeb7d0;
  font-size: 12px;
}
.footer-bottom p {
  margin: 0;
}
.back-to-top {
  background: #edf0fa;
  color: #344273;
  border-radius: 18px;
  padding: 6px 13px;
  font-size: 12px;
  letter-spacing: 0.3px;
  text-decoration: none;
  transition: background-color 0.2s ease, color 0.2s ease, transform 0.1s ease;
}
.back-to-top:hover {
  background: #FBEE00;
  color: #2F3B69;
}
.back-to-top:active {
  transform: translateY(1px);
}

.legal-modal-overlay {
  position: fixed;
  inset: 0;
  z-index: 200;
  display: grid;
  place-items: center;
  padding: 20px;
  background: rgba(47, 59, 105, 0.72);
  backdrop-filter: blur(5px);
}
.legal-modal {
  width: min(620px, 100%);
  max-height: min(720px, calc(100vh - 40px));
  overflow: hidden;
  background: #ffffff;
  color: #2f3b69;
  border: 0;
  border-radius: 10px;
  box-shadow: 0 24px 60px rgba(0, 0, 0, 0.32);
}
.legal-modal-footer {
  background: #ffffff;
  padding: 16px 18px;
}
.legal-modal-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  background: #2F3B69;
  padding: 16px 18px;
  border-bottom: 1px solid #dce1ff;
}
.legal-modal-title {
  display: flex;
  align-items: center;
  gap: 10px;
}
.legal-modal-title h2 {
  margin: 0;
  font-size: 16px;
  color: #ffffff;
}
.modal-close {
  width: 28px;
  height: 28px;
  border: 0;
  border-radius: 6px;
  display: grid;
  place-items: center;
  padding: 0;
  background: transparent;
  color: #ffffff;
  cursor: pointer;
  font-size: 23px;
  line-height: 1;
  transition: background-color 0.2s ease, color 0.2s ease;
}
.modal-close:hover {
  background: transparent;
  color: #ffffff;
}
.legal-modal-body {
  max-height: 500px;
  overflow-y: auto;
  padding: 20px 18px 24px;
}
.legal-modal-date {
  margin: 0 0 6px;
  color: #858685;
  font-size: 11px;
  font-style: italic;
}
.legal-modal-section + .legal-modal-section {
  margin-top: 14px;
}
.legal-modal-section h3 {
  margin: 0 0 7px;
  font-size: 13px;
  color: #2f3b69;
}
.legal-modal-section h3 span {
  color: #2f3b69;
  margin-right: 4px;
}
.legal-modal-section p {
  margin: 0;
  color: #585f72;
  font-size: 11px;
  line-height: 1.65;
  text-align: justify;
}
.legal-modal-footer {
  display: flex;
  justify-content: flex-end;
  border-top: 1px solid #dce1ff;
}
.modal-confirm {
  border: 0;
  border-radius: 8px;
  padding: 8px 16px;
  background: #2f3b69;
  color: #ffffff;
  cursor: pointer;
  font-family: inherit;
  font-size: 11px;
  font-weight: 700;
  transition: background-color 0.2s ease, transform 0.1s ease;
}
.modal-confirm:hover { background: #4e62af; }
.modal-confirm:active { transform: translateY(1px); }

@media (max-width: 900px) {
  .footer-inner {
    width: 100%;
  }

  .footer-container {
    grid-template-columns: repeat(2, minmax(0, 1fr));
    column-gap: 28px;
  }

  .footer {
    padding-right: 8%;
    padding-left: 8%;
  }

  .footer-bottom {
    flex-wrap: wrap;
  }
}

@media (max-width: 560px) {
  .footer-container {
    grid-template-columns: 1fr;
    gap: 28px;
    margin-bottom: 32px;
  }

  .footer-bottom {
    align-items: flex-start;
    flex-direction: column;
    gap: 14px;
  }

  .footer-bottom p {
    text-align: left;
  }

  .back-to-top {
    align-self: flex-start;
  }
}

@media (max-width: 640px) {
  .legal-modal-overlay {
    padding: 12px;
  }

  .legal-modal {
    width: 100%;
    max-height: calc(100vh - 24px);
  }

  .legal-modal-header,
  .legal-modal-footer {
    padding: 14px 16px;
  }

  .legal-modal-title h2 {
    font-size: 15px;
  }

  .legal-modal-body {
    max-height: calc(100vh - 142px);
    padding: 16px 16px 20px;
  }

  .legal-modal-section + .legal-modal-section {
    margin-top: 14px;
  }

  .legal-modal-section h3 {
    font-size: 12px;
  }

  .legal-modal-section p {
    font-size: 11px;
    overflow-wrap: anywhere;
  }
}
</style>
