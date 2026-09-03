<script setup>
// Tidak perlu import Dashboard di sini.
// <router-view /> yang otomatis nampilin komponen sesuai route aktif,
// jadi App.vue cukup jadi "cangkang" saja.
</script>

<template>
  <router-view />
</template>

<style>
html,
body,
#app,
:root {
  width: 100%;
  min-width: 0;
  min-height: 100%;
  margin: 0;
  padding: 0;
  overflow-x: hidden;
}

body {
  min-height: 100vh;
}

:root,
body,
#app,
button,
input,
select,
textarea {
  font-family: 'Plus Jakarta Sans', sans-serif;
}

*,
*::before,
*::after {
  box-sizing: border-box;
}
</style>