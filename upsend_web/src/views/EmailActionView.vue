<script setup>
import { computed, ref } from 'vue'
import { useRoute } from 'vue-router'
import api from '../api'

const route = useRoute()
const isReset = computed(() => route.path === '/reset-password')
const token = String(route.query.token || '')
const password = ref('')
const passwordConfirmation = ref('')
const loading = ref(false)
const message = ref('')
const error = ref('')

async function submit() {
  error.value = ''
  message.value = ''
  if (!token) {
    error.value = 'Link tidak memiliki token yang valid.'
    return
  }
  if (password.value.length < 8 || password.value !== passwordConfirmation.value) {
    error.value = 'Password minimal 8 karakter dan harus sama dengan konfirmasi.'
    return
  }

  loading.value = true
  try {
    const endpoint = isReset.value ? '/password/reset' : '/activate-account'
    await api.post(endpoint, {
      token,
      password: password.value,
      password_confirmation: passwordConfirmation.value,
    })
    message.value = isReset.value
      ? 'Password berhasil diubah. Silakan login.'
      : 'Akun berhasil diaktifkan. Silakan login.'
  } catch (requestError) {
    error.value = requestError.response?.data?.message || 'Link tidak valid atau sudah kedaluwarsa.'
  } finally {
    loading.value = false
  }
}
</script>

<template>
  <main class="email-action-page">
    <section class="email-action-card">
      <h1>{{ isReset ? 'Buat Password Baru' : 'Aktivasi Akun' }}</h1>
      <p>{{ isReset ? 'Masukkan password baru untuk akun Anda.' : 'Buat password untuk mengaktifkan akun Anda.' }}</p>
      <form v-if="!message" @submit.prevent="submit">
        <label>Password baru</label>
        <input v-model="password" type="password" minlength="8" autocomplete="new-password" required />
        <label>Ulangi password</label>
        <input v-model="passwordConfirmation" type="password" minlength="8" autocomplete="new-password" required />
        <button type="submit" :disabled="loading">{{ loading ? 'Memproses...' : 'Simpan Password' }}</button>
      </form>
      <p v-if="message" class="success">{{ message }}</p>
      <p v-if="error" class="error">{{ error }}</p>
    </section>
  </main>
</template>

<style scoped>
.email-action-page { min-height: 100vh; display: grid; place-items: center; padding: 24px; background: #f7f8fa; font-family: 'Plus Jakarta Sans', sans-serif; }
.email-action-card { width: min(100%, 440px); padding: 32px; background: #fff; border: 1px solid #e4e7ec; border-radius: 16px; box-shadow: 0 12px 32px rgba(37, 47, 88, .08); }
h1 { margin: 0 0 8px; color: #252f58; font-size: 24px; }
p { color: #667085; line-height: 1.5; }
form { display: grid; gap: 10px; margin-top: 24px; }
label { color: #344054; font-size: 13px; font-weight: 700; }
input { padding: 12px; border: 1px solid #d0d5dd; border-radius: 8px; font: inherit; }
button { padding: 12px; border: 0; border-radius: 8px; background: #2f3b69; color: #fff; font: inherit; font-weight: 700; cursor: pointer; }
button:disabled { opacity: .6; cursor: wait; }
.success { color: #16804b; font-weight: 700; }
.error { color: #c53030; font-weight: 600; }
</style>
