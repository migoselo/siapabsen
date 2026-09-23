import { fileURLToPath, URL } from 'node:url'

import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import vueDevTools from 'vite-plugin-vue-devtools'

// https://vite.dev/config/
export default defineConfig({
  plugins: [
    vue(),
    vueDevTools(),
  ],
  resolve: {
    alias: {
      '@': fileURLToPath(new URL('./src', import.meta.url)),
    },
  },
 server: {
  allowedHosts: ['dipodic-burlily-roxie.ngrok-free.dev'],
    proxy: {
      '/api': {
        target: 'http://localhost:8010', // ganti sesuai port Laravel kamu
        changeOrigin: true,
      }
    }
  }
})