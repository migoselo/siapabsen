<script setup>
defineProps({
  theme: { type: String, default: 'success' }, // success | warning | danger | info
})
</script>

<template>
  <span class="base-badge" :class="`is-${theme}`"><slot /></span>
</template>

<style scoped>
.base-badge {
  display: inline-flex;
  padding: 6px 12px;
  border-radius: 999px;
  font-size: 11px;
  font-weight: 700;
  white-space: nowrap;
}
.is-success { background: #dcf8e5; color: #15924f; }
.is-warning { background: #fff0c7; color: #9a6900; }
.is-danger { background: #fde0e2; color: #c91f2d; }
.is-info { background: #dce6ff; color: #2f3b69; }
</style>