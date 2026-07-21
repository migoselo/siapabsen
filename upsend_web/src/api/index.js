import axios from 'axios'
import { useAuthStore } from '../stores/auth'
import router from '../router'

const api = axios.create({
      baseURL: 'https://26.214.138.24/api',
  headers: {
    Accept: 'application/json',
    'Content-Type': 'application/json',
  },
})

api.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('auth_token')
    if (token) {
      config.headers.Authorization = `Bearer ${token}`
    }

    const outletId = 1
    if (config.method === 'get') {
      config.params = { ...config.params, outlet_id: outletId }
    } else if (config.method === 'post' || config.method === 'put') {
      if (config.data && typeof config.data === 'object' && !(config.data instanceof FormData)) {
        config.data.outlet_id = outletId
      }
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