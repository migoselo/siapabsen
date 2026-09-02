import axios from 'axios'
import { useAuthStore } from '../stores/auth'
import router from '../router'

const api = axios.create({
  baseURL:
    (import.meta.env.VITE_API_BASE_URL || 'http://localhost:8010/api').replace(/\/+$/, ''),
  headers: {
    Accept: 'application/json',
    'Content-Type': 'application/json',
    ...(import.meta.env.VITE_API_BASE_URL?.includes('ngrok') ? { 'ngrok-skip-browser-warning': 'true' } : {}),
  },
})

api.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('auth_token')
    if (token) {
      config.headers.Authorization = `Bearer ${token}`
    }
    return config
  },
  (error) => Promise.reject(error),
)

api.interceptors.response.use(
  (response) => response,
  (error) => {
    const status = error.response?.status
    const url = error.config?.url || ''
    const isAuthRequest = url.includes('/auth/login') || url.includes('/auth/logout')

    if (status === 401 && !isAuthRequest) {
      const authStore = useAuthStore()
      authStore.logout()

      if (router.currentRoute.value.path !== '/login') {
        router.push('/login')
      }
    }

    return Promise.reject(error)
  },
)

export default api