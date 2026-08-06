<script setup lang="ts">
import { reactive, ref, computed, onMounted, onUnmounted } from "vue";

const enemyCount = ref(2);
const healthLoss = ref(0);
const boss = ref(0);
const waveHeights = reactive<number[]>(Array.from({ length: 20 }, () => 8));
let timeoutId: ReturnType<typeof setTimeout> | null = null;
let raf = 0;

const bossText = computed(() => (boss.value === 1 ? "Wōkòu Warlord" : boss.value === 2 ? "Pirate Fleet Admiral" : "None"));
const bossMod = computed(() => (boss.value === 1 ? 0.15 : boss.value === 2 ? 0.4 : 0));
const excitement = computed(() =>
  Math.min(1, Math.max(0, enemyCount.value * 0.008 + healthLoss.value * 0.003 + bossMod.value))
);
const state = computed(() =>
  excitement.value > 0.6 ? "Peak Siege Roar" : excitement.value > 0.25 ? "Night Defense" : "Day Preparation"
);
const desc = computed(() => {
  if (excitement.value > 0.6) return "Executing heavy, rapid Taiko drum rolls and sweeping battle vocal loops!";
  if (excitement.value > 0.25) return "Triggering light Taiko percussion tracks and dynamic Shamisen riffs.";
  return "Playing ambient forest wind, rustling bamboo, and soft Shakuhachi flute loops.";
});
const activeClass = computed(() => (excitement.value > 0.6 ? "active-warn" : excitement.value > 0.25 ? "active-gold" : ""));

function animate() {
  const E = excitement.value;
  for (let i = 0; i < 20; i++) {
    const base = 5 + E * 40;
    const variance = Math.random() * (10 + E * 30);
    waveHeights[i] = Math.min(75, base + variance);
  }
  timeoutId = setTimeout(() => {
    raf = requestAnimationFrame(animate);
  }, 120);
}

onMounted(animate);
onUnmounted(() => {
  if (raf) cancelAnimationFrame(raf);
  if (timeoutId) clearTimeout(timeoutId);
});
</script>

<template>
  <div class="tab-pane active" id="tab-audio">
    <div class="grid-2-col">
      <div class="panel glass">
        <h2>Dynamic Taiko Percussion &amp; Ambience</h2>
        <p>
          Ambient nature sounds and high-energy Taiko drums scale dynamically. The audio layers adjust using a
          centralized <strong>Excitement Scale</strong> ($E$) computed by the game loop:
        </p>
        <p class="math-formula">
          $$E = w_1 \cdot \text{EnemiesOnScreen} + w_2 \cdot \text{HQHealthLoss} + w_3 \cdot \text{BossPresence}$$
        </p>
        <div class="panel-dark profile-panel" style="margin-top: 1rem">
          <h4>Pitch Excitement Modulators</h4>
          <div class="slider-group">
            <label>Active Enemies on Screen: <span>{{ enemyCount }}</span></label>
            <input type="range" min="0" max="60" v-model.number="enemyCount" class="slider" />
          </div>
          <div class="slider-group">
            <label>Fortress HQ Health Loss: <span>{{ healthLoss }}%</span></label>
            <input type="range" min="0" max="100" v-model.number="healthLoss" class="slider" />
          </div>
          <div class="slider-group">
            <label>On-Pitch Boss Presence: <span>{{ bossText }}</span></label>
            <input type="range" min="0" max="2" v-model.number="boss" class="slider" />
          </div>
        </div>
      </div>

      <div class="panel glass flex-center">
        <h3>MetaSound Excitement Waveform</h3>
        <div class="audio-visualization-box panel-dark">
          <div class="wave-visualizer-container">
            <div class="audio-wave">
              <div
                v-for="(h, i) in waveHeights"
                :key="i"
                class="wave-bar"
                :class="activeClass"
                :style="{ height: h + 'px' }"
              ></div>
            </div>
          </div>
          <div class="stat-row" style="margin-top: 1rem">
            <span>Atmosphere State:</span> <strong class="highlight">{{ state }}</strong>
          </div>
          <div class="stat-row">
            <span>Calculated Excitement ($E$):</span> <strong>{{ excitement.toFixed(2) }}</strong>
          </div>
          <div class="ai-speech" style="margin-top: 1rem">
            <strong>Active Audio Track:</strong>
            <p>{{ desc }}</p>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
