<script setup lang="ts">
import { ref, computed } from "vue";

const ping = ref(50);
const loss = ref(0);
const jitter = ref(5);

const drift = computed(() => ping.value * 0.05 + loss.value * 1.2 + jitter.value * 0.3);
const desynced = computed(() => ping.value > 120 || loss.value > 2.0 || jitter.value > 15);
const logs = computed(() =>
  desynced.value
    ? [
        "[SYSTEM] Profiling diagnostics...",
        `[WARNING] Net ping: ${ping.value}ms exceeds substepping threshold.`,
        `[ERROR] Desync delta: ${drift.value.toFixed(1)} units. Snap client prediction position.`,
      ]
    : [
        "[SYSTEM] Profiling diagnostics...",
        "[FFI] JNI/Swift-C++-interop byte transfer checks completed.",
        `[SYSTEM] Delta packets: OK. Jitter: ${jitter.value}ms.`,
      ]
);
</script>

<template>
  <div class="tab-pane active" id="tab-qa">
    <div class="grid-2-col">
      <div class="panel glass">
        <h2>Automated Headless Audits &amp; Diagnostics</h2>
        <p>
          Headless C++ simulation passes run stress tests checking for Behavior Tree coordinate drifts, FFI
          boundary leakages, and network sync bounds.
        </p>
        <div class="panel-dark profile-panel" style="margin-top: 1.5rem">
          <h4>Network Latency Profiler</h4>
          <div class="slider-group">
            <label>Simulated Latency (Ping): <span>{{ ping }}ms</span></label>
            <input type="range" min="10" max="300" v-model.number="ping" class="slider" />
          </div>
          <div class="slider-group">
            <label>Packet Loss Ratio: <span>{{ loss.toFixed(1) }}%</span></label>
            <input type="range" min="0" max="100" v-model.number="loss" class="slider" />
          </div>
          <div class="slider-group">
            <label>Jitter (ms): <span>{{ jitter }}ms</span></label>
            <input type="range" min="0" max="50" v-model.number="jitter" class="slider" />
          </div>
        </div>
      </div>

      <div class="panel glass flex-center">
        <h3>Replication Parity Dashboard</h3>
        <div class="qa-status-box">
          <div class="alert-banner" :class="{ warning: desynced }">
            <span>{{ desynced ? "⚠️ REPLICATION DESYNC DETECTED" : "🟢 REPLICATION SYNCHRONIZED" }}</span>
          </div>
          <div class="stat-row" style="margin-top: 1rem">
            <span>Sync State:</span> <strong>{{ desynced ? "Replication Drift" : "Perfect Parity" }}</strong>
          </div>
          <div class="stat-row">
            <span>State Coordinates Drift:</span>
            <strong class="highlight" :style="{ color: desynced ? 'var(--accent)' : 'var(--accent-2)' }">
              {{ drift.toFixed(1) }} units
            </strong>
          </div>
          <div class="panel-dark" style="margin-top: 1rem; font-family: monospace; font-size: 0.75rem; height: 100px; overflow-y: auto">
            <div v-for="(l, i) in logs" :key="i">{{ l }}</div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
