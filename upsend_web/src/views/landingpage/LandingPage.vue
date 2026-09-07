<script setup>
import LandingNavbar from './LandingNavbar.vue'
import LandingHero from './LandingHero.vue'
import LandingAbout from './LandingAbout.vue'
import LandingFeatures from './LandingFeatures.vue'
import LandingPricing from './LandingPricing.vue'
import LandingFooter from './LandingFooter.vue'
</script>

<template>
  <div class="landing-page">
    <LandingNavbar />
    <main>
      <LandingHero />
      <LandingAbout />
      <LandingFeatures />
      <LandingPricing />
    </main>
    <LandingFooter />
  </div>
</template>

<style>
.landing-page {
  min-height: 100vh;
  overflow-x: hidden;
  background: #ffffff;
  color: #2c3345;
  font-family: 'Plus Jakarta Sans', sans-serif;
}

.landing-page main {
  padding-top: 88px;
}

@media (max-width: 900px) {
  .landing-page main {
    padding-top: 72px;
  }
}
</style>
