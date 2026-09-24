<script setup>
import { Icon } from '@iconify/vue'

defineProps({
  show: { type: Boolean, default: false },
  type: { type: String, default: 'success' }, // 'success' | 'error'
  message: { type: String, default: '' },
})
</script>

<template>
  <Teleport to="body">
    <div v-if="show" class="toast" :class="type">
      <Icon
        :icon="type === 'success' ? 'material-symbols:check-circle-rounded' : 'material-symbols:error-rounded'"
        width="18"
        height="18"
      />
      <span>{{ message }}</span>
    </div>
  </Teleport>
</template>

<style scoped>
.toast {
  position: fixed;
  top: 24px;
  left: 50%;
  transform: translateX(-50%);
  z-index: 2000;
  display: inline-flex;
  align-items: center;
  gap: 8px;
  padding: 12px 20px;
  border-radius: 12px;
  font-size: 14px;
  font-weight: 600;
  color: white;
  box-shadow: 0 10px 30px rgba(17, 24, 39, 0.2);
  font-family: 'Plus Jakarta Sans', sans-serif;
}
.toast.success { background: #1f9d67; }
.toast.error { background: #d92d20; }
</style>