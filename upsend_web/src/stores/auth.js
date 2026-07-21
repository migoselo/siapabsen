import { defineStore } from 'pinia'
import api from '../api'

export const useAuthStore = defineStore('auth', {
  state: () => ({
    user: JSON.parse(localStorage.getItem('auth_user') || 'null'),
    token: localStorage.getItem('auth_token') || null,
  }),
  getters: {
    isAuthenticated: (state) => !!state.token,
    userRole: (state) => state.user?.roles?.[0]?.slug || 'guest',
    hasPermission: (state) => (permission) => {
      if (!state.user || !state.user.permissions) return false
      return state.user.permissions.includes(permission)
    },
  },
  actions: {
    async login(email, password) {
      try {
        const response = await api.post('/auth/login', { email, password })

        if (response.data?.status) {
          const { token, user } = response.data.data

          this.token = token
          this.user = user

          localStorage.setItem('auth_token', token)
          localStorage.setItem('auth_user', JSON.stringify(user))

          return true
        }

        return false
      } catch (error) {
        this.token = null
        this.user = null
        localStorage.removeItem('auth_token')
        localStorage.removeItem('auth_user')
        throw error
      }
    },

    async logout() {
      this.token = null
      this.user = null
      localStorage.removeItem('auth_token')
      localStorage.removeItem('auth_user')
      return true
    },
  },
})