<script setup>
import { computed } from 'vue'
import { useAuthStore } from '../stores/auth'

const authStore = useAuthStore()
const user = computed(() => authStore.user || {})
</script>

<template>
  <div class="profile-page">
    <section class="panel info-panel">
      <div class="profile-header">
        <div>
          <h2>Profil Saya</h2>
          <p>Kelola informasi akun dan lihat detail profil Anda.</p>
        </div>
      </div>

      <div class="profile-grid">
        <div class="profile-card">
          <label>Nama Lengkap</label>
          <div>{{ user.name || '-' }}</div>
        </div>
        <div class="profile-card">
          <label>Email</label>
          <div>{{ user.email || '-' }}</div>
        </div>
        <div class="profile-card">
          <label>Peran</label>
          <div>{{ user.role || user.roles?.[0]?.name || '-' }}</div>
        </div>
        <div class="profile-card">
          <label>No. Telepon</label>
          <div>{{ user.phone || '-' }}</div>
        </div>
      </div>
    </section>
  </div>
</template>

<style scoped>
.profile-page {
  --ink: #1c2521;
  --ink-soft: #5b6864;
  --line: #e7e7e2;
  --card: #ffffff;
}
.profile-page * {
  box-sizing: border-box;
}
.panel {
  background: var(--card);
  border: 1px solid var(--line);
  border-radius: 16px;
  padding: 24px;
}
.profile-header {
  margin-bottom: 24px;
}
.profile-header h2 {
  margin: 0 0 8px;
  font-size: 22px;
  font-weight: 700;
}
.profile-header p {
  margin: 0;
  color: var(--ink-soft);
}
.profile-grid {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 16px;
}
.profile-card {
  background: #f8faf7;
  padding: 18px;
  border-radius: 14px;
  border: 1px solid var(--line);
}
.profile-card label {
  display: block;
  margin-bottom: 8px;
  font-size: 12px;
  color: var(--ink-soft);
  text-transform: uppercase;
  letter-spacing: 0.05em;
}
.profile-card div {
  font-size: 15px;
  color: var(--ink);
  font-weight: 600;
}
@media (max-width: 720px) {
  .profile-grid {
    grid-template-columns: 1fr;
  }
}
</style>
