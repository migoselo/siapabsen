<script setup>
import { onBeforeUnmount, onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import { Icon } from '@iconify/vue'
import api from '../api'
import logo from '../assets/Logo-web.svg'

const router = useRouter()

const email = ref('')
const password = ref('')
const showPassword = ref(false)
const loading = ref(false)
const errorMessage = ref('')

const restorePageScroll = () => {
  document.documentElement.style.overflow = ''
  document.body.style.overflow = ''
  document.getElementById('app')?.style.removeProperty('overflow')
}

onMounted(() => {
  document.documentElement.style.overflow = 'hidden'
  document.body.style.overflow = 'hidden'
  document.getElementById('app')?.style.setProperty('overflow', 'hidden')
})

onBeforeUnmount(restorePageScroll)

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
          <img :src="logo" alt="SiapHadir logo" />
        </div>
        <h1>SiapHadir</h1>
      </div>

      <form @submit.prevent="handleLogin">
        <label for="email">Email</label>
        <div class="input-wrap">
          <Icon class="input-icon" icon="material-symbols:mail-rounded" width="18" height="18" />
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
          <Icon class="input-icon" icon="material-symbols:lock-rounded" width="18" height="18" />
          <input
            id="password"
            :type="showPassword ? 'text' : 'password'"
            v-model="password"
            placeholder="Masukkan password"
            autocomplete="current-password"
          />
          <button
            type="button"
            class="password-toggle"
            :aria-label="showPassword ? 'Sembunyikan password' : 'Tampilkan password'"
            @click="showPassword = !showPassword"
          >
            <Icon
              :icon="showPassword ? 'material-symbols:visibility-off-rounded' : 'material-symbols:visibility-rounded'"
              width="20"
              height="20"
            />
          </button>
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
:global(html),
:global(body),
:global(#app) {
  width: 100%;
  height: 100%;
  margin: 0;
}

.login-page {
  position: relative;
  overflow: hidden;
  box-sizing: border-box;
  height: 100vh;
  min-height: 100dvh;
  background: #2F3B69;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 32px 24px;
  font-family: 'Plus Jakarta Sans', sans-serif;
}

.login-card {
  position: relative;
  z-index: 1;
  background: #fff;
  border-radius: 9px;
  padding: 50px 34px 49px;
  width: 100%;
  max-width: 330px;
  box-shadow: 0 12px 30px rgba(22, 31, 67, 0.12);
}

.brand {
  display: flex;
  flex-direction: column;
  align-items: center;
  margin-bottom: 39px;
}

.brand-icon {
  width: 38px;
  height: 38px;
  margin-bottom: 10px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.brand-icon img {
  display: block;
  width: 90px;
  height: 90px;
  object-fit: contain;
}

.brand h1 {
  font-size: 24px;
  font-weight: 600;
  color: #1C1C19;
  margin: 0;
  letter-spacing: -0.4px;
}

form label {
  display: block;
  font-size: 16px;
  font-weight: 500;
  color: #1C1C19;
  margin-bottom: 7px;
}

.input-wrap {
  box-sizing: border-box;
  display: flex;
  align-items: center;
  gap: 9px;
  height: 52px;
  border: 1px solid #cbd2ce;
  border-radius: 12px;
  padding: 12px 10px;
  margin-bottom: 19px;
}

.input-wrap:last-of-type {
  margin-bottom: 32px;
}

.input-wrap input {
  border: none;
  outline: none;
  flex: 1;
  font-size: 14px;
  font-family: inherit;
  color: #1C1C19;
}

.password-toggle {
  display: flex;
  align-items: center;
  justify-content: center;
  flex: 0 0 28px;
  width: 28px;
  height: 28px;
  padding: 0;
  border: 0;
  background: transparent;
  color: #9a9a9a;
  cursor: pointer;
}

.input-wrap input::placeholder {
  color: #9a9a9a;
}

.input-icon {
  flex-shrink: 0;
  color: #9aa5a0;
  opacity: 0.9;
}

.error-msg {
  color: #dc4646;
  font-size: 13px;
  margin: -8px 0 16px;
}

.submit-btn {
  box-sizing: border-box;
  width: 100%;
  height: 52px;
  font-family: 'Plus Jakarta Sans', sans-serif;
  background: #2F3B69;
  color: #fff;
  border: none;
  padding: 0 14px;
  border-radius: 11px;
  font-size: 16px;
  font-weight: 600;
  cursor: pointer;
  transition: background 0.15s ease;
}

.submit-btn:hover:not(:disabled) {
  background: #2F3B69;
}

.submit-btn:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

@media (max-width: 600px) {
  .login-card {
    padding: 42px 28px 40px;
  }
}
</style>