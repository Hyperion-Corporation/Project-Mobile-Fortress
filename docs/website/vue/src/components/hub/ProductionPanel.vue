<script setup lang="ts">
import { ref, computed } from "vue";

interface Sprint {
  title: string;
  timeline: string;
  goals: string[];
  deps: string;
}

const sprints: Record<number, Sprint> = {
  1: {
    title: "Sprint 1: Native Interface Parity",
    timeline: "Weeks 1-2 (Phase 1)",
    goals: [
      "Synchronize active GameLoop states across Swift and Kotlin codebases.",
      "Write JSON configuration loaders for static level layouts.",
      "Verify Canvas and SpriteKit resolution resizing operations.",
    ],
    deps: "Base platform templates integration.",
  },
  2: {
    title: "Sprint 2: C++ Simulation Core & ECS",
    timeline: "Weeks 5-6 (Phase 2)",
    goals: [
      "Build headless simulation engine using the C++ EnTT ECS library.",
      "Expose simulation controls through JNI (Android) and Swift C++ interop (iOS) bindings.",
      "Write zero-copy binary state serializers using FlatBuffers.",
    ],
    deps: "Completed FFI bindings mapping schemas.",
  },
  3: {
    title: "Sprint 3: Cooperative Netcode & Sockets",
    timeline: "Weeks 9-10 (Phase 3)",
    goals: [
      "Establish UDP packet delivery and delta replication buffers.",
      "Define latency-graduated matchmaking rules inside AWS GameLift FlexMatch.",
      "Build automatic fallback protocols for Spot Instance expirations.",
    ],
    deps: "Completed C++ core binary serialization schemas.",
  },
  4: {
    title: "Sprint 4: ML PCG Systems & Personalization",
    timeline: "Weeks 13-14 (Phase 4)",
    goals: [
      "Deploy offline PCGRL (PPO) map generators alongside WFC solvers.",
      "Integrate Imitation-Adversarial difficulty modulators.",
      "Wire Contextual Bandit (LinUCB) dynamic store pricing models.",
    ],
    deps: "Replicated game telemetry databases.",
  },
};

const selected = ref(1);
const current = computed(() => sprints[selected.value]);
</script>

<template>
  <div class="tab-pane active" id="tab-production">
    <div class="panel glass">
      <h2>Development Sprints &amp; Technical Pipelines</h2>
      <p class="panel-desc" style="margin-bottom: 2rem">
        Click on any sprint milestone below to view deliverables, active checklists, and technical dependencies.
      </p>

      <div class="sprints-interactive-grid">
        <div class="sprint-header-buttons">
          <button
            v-for="(s, id) in sprints"
            :key="id"
            class="sprint-nav-btn"
            :class="{ active: selected == Number(id) }"
            @click="selected = Number(id)"
          >
            {{ s.title }}
          </button>
        </div>

        <transition name="fade" mode="out-in">
          <div class="sprint-display-panel panel-dark" :key="selected">
            <h4 style="color: var(--accent-gold); margin-bottom: 0.3rem">{{ current.title }}</h4>
            <span style="font-size: 0.8rem; color: var(--accent-2); font-weight: bold; display: block; margin-bottom: 0.8rem">
              {{ current.timeline }}
            </span>
            <strong style="font-size: 0.85rem; color: var(--text)">Sprint Deliverables Checklist:</strong>
            <ul class="roadmap-list">
              <li v-for="(g, i) in current.goals" :key="i">{{ g }}</li>
            </ul>
            <div style="margin-top: 1rem; border-top: 1px solid var(--border-color); padding-top: 0.8rem; font-size: 0.8rem; color: var(--text-muted)">
              <strong>Technical Dependencies:</strong> {{ current.deps }}
            </div>
          </div>
        </transition>
      </div>
    </div>
  </div>
</template>
