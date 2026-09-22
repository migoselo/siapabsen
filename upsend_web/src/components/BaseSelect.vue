<!-- src/components/BaseSelect.vue -->
<script setup>
import { ref, computed, onMounted, onBeforeUnmount } from 'vue'
import { Icon } from '@iconify/vue'

const props = defineProps({
  modelValue: { type: [String, Number], required: true },
  options: { 
    type: Array, 
    required: true // Bisa format ['Option 1', 'Option 2'] atau [{label: 'Opt 1', value: 'opt1'}]
  },
  placeholder: { type: String, default: 'Pilih opsi' },
  icon: { type: String, default: '' } // Opsional: Ikon di sebelah kiri label
})

const emit = defineEmits(['update:modelValue', 'change'])

const isOpen = ref(false)
const selectContainer = ref(null)

// Normalisasi opsi agar bisa menerima array of string ATAU array of object
const normalizedOptions = computed(() => {
  return props.options.map(opt => {
    return typeof opt === 'object' ? opt : { label: opt, value: opt }
  })
})

const selectedLabel = computed(() => {
  const found = normalizedOptions.value.find(opt => opt.value === props.modelValue)
  return found ? found.label : props.placeholder
})

function toggle() {
  isOpen.value = !isOpen.value
}

function selectOption(value) {
  emit('update:modelValue', value)
  emit('change', value)
  isOpen.value = false
}

// Menutup menu jika klik di area luar
function handleClickOutside(e) {
  if (selectContainer.value && !selectContainer.value.contains(e.target)) {
    isOpen.value = false
  }
}

onMounted(() => document.addEventListener('click', handleClickOutside))
onBeforeUnmount(() => document.removeEventListener('click', handleClickOutside))
</script>

<template>
  <div class="custom-select" ref="selectContainer" @click="toggle">
    <Icon v-if="icon" :icon="icon" width="18" height="18" class="icon-left" />
    <span class="select-label">{{ selectedLabel }}</span>
    <Icon icon="material-symbols:keyboard-arrow-down-rounded" width="18" height="18" class="icon-right" />

    <div v-if="isOpen" class="select-menu" @click.stop>
      <button
        v-for="opt in normalizedOptions"
        :key="opt.value"
        type="button"
        class="select-item"
        :class="{ active: modelValue === opt.value }"
        @click="selectOption(opt.value)"
      >
        {{ opt.label }}
      </button>
    </div>
  </div>
</template>

<style scoped>
.custom-select {
  position: relative;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 8px;
  height: 40px;
  background: #ffffff;
  border: 1px solid #d9dde5;
  padding: 0 12px;
  border-radius: 10px;
  font-size: 14px;
  font-weight: 600;
  color: #1c1c19;
  cursor: pointer;
  min-width: 160px;
  user-select: none;
  font-family: 'Plus Jakarta Sans', sans-serif;
}

.icon-left, .icon-right { color: #667085; flex-shrink: 0; }
.select-label { flex: 1; text-align: left; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }

.select-menu {
  position: absolute;
  z-index: 50;
  top: calc(100% + 6px);
  left: 0;
  width: 100%;
  min-width: 200px;
  background: #ffffff;
  border: 1px solid #d9dde5;
  border-radius: 10px;
  box-shadow: 0 12px 28px rgba(0, 0, 0, 0.12);
  padding: 6px 0;
  max-height: 280px;
  overflow-y: auto;
}

.select-item {
  width: 100%; border: none; background: transparent; text-align: left;
  padding: 10px 16px; font-size: 14px; color: #1c1c19; cursor: pointer;
  transition: background 0.15s; font-family: inherit;
}
.select-item:hover { background: #f4f5f8; }
.select-item.active { background: #f4f5f8; color: #2f3b69; font-weight: 700; }
</style>