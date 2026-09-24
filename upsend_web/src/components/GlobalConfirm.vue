<!-- src/components/GlobalConfirm.vue -->
<script setup>
import { Icon } from '@iconify/vue'
import { useConfirm } from '../composables/UseConfirm'

// Mengambil state dan fungsi dari composable
const { state, confirm, cancel } = useConfirm()
</script>

<template>
  <div v-if="state.isOpen" class="modal-overlay" @click.self="cancel">
    <div class="modal-content">
      <div class="modal-icon" :class="state.type">
        <Icon 
          :icon="state.type === 'danger' ? 'material-symbols:warning-outline-rounded' : 'material-symbols:info-outline-rounded'" 
          width="28" 
        />
      </div>
      
      <div class="modal-text">
        <h3>{{ state.title }}</h3>
        <p>{{ state.message }}</p>
      </div>

      <div class="modal-actions">
        <button class="btn-cancel" @click="cancel">{{ state.cancelText }}</button>
        <button class="btn-confirm" :class="state.type" @click="confirm">
          {{ state.confirmText }}
        </button>
      </div>
    </div>
  </div>
</template>

<style scoped>
.modal-overlay {
  position: fixed;
  inset: 0;
  background: rgba(20, 25, 45, 0.45);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 9999; /* Pastikan selalu paling atas */
  padding: 16px;
}

.modal-content {
  background: #ffffff;
  border-radius: 16px;
  width: 100%;
  max-width: 400px;
  padding: 24px;
  box-shadow: 0 12px 32px rgba(0, 0, 0, 0.12);
  text-align: center;
  font-family: 'Plus Jakarta Sans', sans-serif;
  animation: popIn 0.2s ease-out forwards;
}

@keyframes popIn {
  from { opacity: 0; transform: scale(0.95); }
  to { opacity: 1; transform: scale(1); }
}

.modal-icon {
  width: 56px;
  height: 56px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  margin: 0 auto 16px;
}

.modal-icon.danger { background: #fdeeee; color: #c53030; }
.modal-icon.primary { background: #eaf0ff; color: #2f3b69; }

.modal-text h3 {
  margin: 0 0 8px;
  font-size: 18px;
  color: #1c1c19;
}

.modal-text p {
  margin: 0 0 24px;
  font-size: 14px;
  color: #667085;
  line-height: 1.5;
}

.modal-actions {
  display: flex;
  gap: 12px;
}

button {
  flex: 1;
  padding: 10px 16px;
  font-size: 14px;
  font-weight: 700;
  border-radius: 10px;
  cursor: pointer;
  border: none;
  transition: background 0.15s;
  font-family: inherit;
}

.btn-cancel {
  background: #ffffff;
  border: 1px solid #d9dde5;
  color: #667085;
}
.btn-cancel:hover { background: #f4f5f8; }

.btn-confirm.danger { background: #c53030; color: white; }
.btn-confirm.danger:hover { background: #9b2c2c; }

.btn-confirm.primary { background: #2f3b69; color: white; }
.btn-confirm.primary:hover { background: #252f58; }
</style>