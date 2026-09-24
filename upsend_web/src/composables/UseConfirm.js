// src/composables/useConfirm.js
import { reactive } from 'vue'

// State global, bisa diakses dari mana saja
const state = reactive({
  isOpen: false,
  title: 'Konfirmasi',
  message: 'Apakah Anda yakin?',
  confirmText: 'Ya',
  cancelText: 'Batal',
  type: 'danger', // 'danger' (Hapus) | 'primary' (Simpan)
  resolvePromise: null,
})

export function useConfirm() {
  // Fungsi untuk memanggil modal dari halaman manapun
  const showConfirm = (options = {}) => {
    state.title = options.title || 'Konfirmasi'
    state.message = options.message || 'Apakah Anda yakin?'
    state.confirmText = options.confirmText || 'Ya'
    state.cancelText = options.cancelText || 'Batal'
    state.type = options.type || 'danger'
    state.isOpen = true

    // Mengembalikan Promise agar bisa ditunggu (await) hasilnya
    return new Promise((resolve) => {
      state.resolvePromise = resolve
    })
  }

  // Fungsi saat tombol "Ya" diklik
  const confirm = () => {
    state.isOpen = false
    if (state.resolvePromise) state.resolvePromise(true)
  }

  // Fungsi saat tombol "Batal" atau area luar diklik
  const cancel = () => {
    state.isOpen = false
    if (state.resolvePromise) state.resolvePromise(false)
  }

  return {
    state,
    showConfirm,
    confirm,
    cancel,
  }
}