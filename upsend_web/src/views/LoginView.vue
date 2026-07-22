<script setup>
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import api from '../api'

const router = useRouter()

const email = ref('')
const password = ref('')
const loading = ref(false)
const errorMessage = ref('')

async function handleLogin() {
  errorMessage.value = ''

  if (!email.value || !password.value) {
    errorMessage.value = 'Email dan password wajib diisi.'
    return
  }

  loading.value = true
  try {
    const res = await api.post('/login-web', {
      email: email.value,
      password: password.value,
    })

    const { user, token } = res.data
    localStorage.setItem('auth_token', token)
    localStorage.setItem('auth_user', JSON.stringify(user))

    router.push('/dashboard')
  } catch (err) {
    if (err.response?.status === 401) {
      errorMessage.value = err.response.data.message || 'Email atau password salah.'
    } else if (err.response?.status === 422) {
      const errors = err.response.data.errors
      errorMessage.value = errors ? Object.values(errors)[0][0] : 'Data tidak valid.'
    } else {
      errorMessage.value = 'Gagal terhubung ke server. Coba lagi nanti.'
    }
    console.error('Login gagal:', err)
  } finally {
    loading.value = false
  }
}
</script>

<template>
  <div class="login-page">
    <div class="login-card">
      <div class="brand">
        <div class="brand-icon">
          <svg width="28" height="28" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
            <path d="M3 21V10L9 6V21M9 21V13L15 9V21M15 21V4L21 8V21M3 21H21" stroke="white" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
          </svg>
        </div>
        <h1>SiapAbsen</h1>
      </div>

      <form @submit.prevent="handleLogin">
        <label for="email">Email</label>
        <div class="input-wrap">
          <svg class="input-icon" width="18" height="18" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
            <path d="M3 8L10.89 13.26C11.5 13.67 12.5 13.67 13.11 13.26L21 8M5 19H19C20.1 19 21 18.1 21 17V7C21 5.9 20.1 5 19 5H5C3.9 5 3 5.9 3 7V17C3 18.1 3.9 19 5 19Z" stroke="#9AA5A0" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"/>
          </svg>
          <input
            id="email"
            type="email"
            v-model="email"
            placeholder="email@gmail.com"
            autocomplete="username"
          />
        </div>

        <label for="password">Password</label>
        <div class="input-wrap">
          <svg class="input-icon" width="18" height="18" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
            <rect x="5" y="11" width="14" height="9" rx="2" stroke="#9AA5A0" stroke-width="1.6"/>
            <path d="M8 11V7C8 4.79 9.79 3 12 3C14.21 3 16 4.79 16 7V11" stroke="#9AA5A0" stroke-width="1.6" stroke-linecap="round"/>
          </svg>
          <input
            id="password"
            type="password"
            v-model="password"
            placeholder="Masukkan password"
            autocomplete="current-password"
          />
        </div>

        <p v-if="errorMessage" class="error-msg">{{ errorMessage }}</p>

        <button type="submit" class="submit-btn" :disabled="loading">
          {{ loading ? 'Memproses...' : 'Masuk' }}
        </button>
      </form>
    </div>
  </div>
</template>

<style scoped>
.login-page {
  min-height: 100vh;
  background: #0d5c42;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 24px;
}

.login-card {
  background: #fff;
  border-radius: 20px;
  padding: 40px 36px 36px;
  width: 100%;
  max-width: 380px;
  box-shadow: 0 20px 50px rgba(0, 0, 0, 0.15);
}

.brand {
  display: flex;
  flex-direction: column;
  align-items: center;
  margin-bottom: 32px;
}

.brand-icon {
  width: 52px;
  height: 52px;
  border-radius: 14px;
  background: #0d5c42;
  display: flex;
  align-items: center;
  justify-content: center;
  margin-bottom: 12px;
}

.brand h1 {
  font-size: 20px;
  font-weight: 700;
  color: #1c2521;
  margin: 0;
}

form label {
  display: block;
  font-size: 13.5px;
  font-weight: 600;
  color: #1c2521;
  margin-bottom: 8px;
}

.input-wrap {
  display: flex;
  align-items: center;
  gap: 10px;
  border: 1px solid #e0e0da;
  border-radius: 10px;
  padding: 12px 14px;
  margin-bottom: 20px;
}

.input-wrap input {
  border: none;
  outline: none;
  flex: 1;
  font-size: 14px;
  font-family: inherit;
  color: #1c2521;
}

.input-wrap input::placeholder {
  color: #a3aca7;
}

.input-icon {
  flex-shrink: 0;
}

.error-msg {
  color: #dc4646;
  font-size: 13px;
  margin: -8px 0 16px;
}

.submit-btn {
  width: 100%;
  background: #0d5c42;
  color: #fff;
  border: none;
  padding: 14px;
  border-radius: 10px;
  font-size: 15px;
  font-weight: 700;
  cursor: pointer;
  transition: background 0.15s ease;
}

.submit-btn:hover:not(:disabled) {
  background: #0a4a35;
}

.submit-btn:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}
</style>