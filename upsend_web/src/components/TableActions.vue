<script setup>
import { Icon } from '@iconify/vue'

defineProps({
  showEdit: { type: Boolean, default: false },
  showDelete: { type: Boolean, default: false },
  showView: { type: Boolean, default: false },
  showApprove: { type: Boolean, default: false },
  showReject: { type: Boolean, default: false },
  // Tambahan prop untuk toggle status
  showToggleStatus: { type: Boolean, default: false },
  isActive: { type: Boolean, default: true }
})

defineEmits(['edit', 'delete', 'view', 'approve', 'reject', 'toggleStatus'])
</script>

<template>
  <div class="actions">
    <button v-if="showReject" class="icon-btn icon-btn-reject" title="Tolak" @click="$emit('reject')">
      <Icon icon="material-symbols:close" width="16" />
    </button>
    <button v-if="showApprove" class="icon-btn icon-btn-approve" title="Terima" @click="$emit('approve')">
      <Icon icon="material-symbols:check" width="16" />
    </button>
    <button v-if="showView" class="icon-btn icon-btn-view" title="Lihat Detail" @click="$emit('view')">
      <Icon icon="material-symbols:visibility-outline" width="16" />
    </button>
    <button v-if="showEdit" class="icon-btn icon-btn-edit" title="Edit" @click="$emit('edit')">
      <Icon icon="material-symbols:edit-outline" width="16" />
    </button>
    
    <!-- Tambahan tombol Aktif / Nonaktif -->
    <button 
      v-if="showToggleStatus" 
      class="icon-btn" 
      :class="isActive ? 'icon-btn-warning' : 'icon-btn-success'" 
      :title="isActive ? 'Nonaktifkan' : 'Aktifkan'" 
      @click="$emit('toggleStatus')"
    >
      <Icon :icon="isActive ? 'material-symbols:pause-circle-outline' : 'material-symbols:play-circle-outline'" width="19" />
    </button>

    <button v-if="showDelete" class="icon-btn-danger" title="Hapus" @click="$emit('delete')">
      <Icon icon="material-symbols:delete-outline" width="16" />
    </button>
  </div>
</template>

<style scoped>
.actions {
  display: flex;
  align-items: center;
  justify-content: flex-end;
  gap: 8px;
}
.icon-btn {
  width: 30px; height: 30px; border-radius: 6px; border: none;
  background: transparent; color: #667085; display: grid; place-items: center;
  cursor: pointer; transition: all 0.2s;
}
.icon-btn-danger {
  width: 30px; height: 30px; border-radius: 6px; border: none;
  background: transparent; color: #f80000; display: grid; place-items: center;
  cursor: pointer; transition: all 0.2s;
}
.icon-btn:hover { background: #f4f5f8; color: #1c1c19; }

/* Warna Spesifik */
.icon-btn-view { background: #eaf0ff; color: #2a4365; }
.icon-btn-view:hover { background: #dbe6ff; }
.icon-btn-edit:hover { background: #e8ebf5; color: #2f3b69; }
.icon-btn-danger:hover { background: #fdeeee; color: #c53030; }
.icon-btn-approve { background: #38a169; color: #fff; }
.icon-btn-reject { background: #fdeeee; color: #e53e3e; }

/* Tambahan Hover Warna untuk Toggle Status */
.icon-btn-warning:hover { background: #fff3cd; color: #856404; }
.icon-btn-success:hover { background: #d4edda; color: #155724; }
</style>