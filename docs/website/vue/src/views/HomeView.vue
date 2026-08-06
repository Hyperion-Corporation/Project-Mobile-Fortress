<script setup lang="ts">
import { ref, shallowRef, onMounted, onUnmounted } from "vue";
import DesignPanel from "../components/hub/DesignPanel.vue";
import TechPanel from "../components/hub/TechPanel.vue";
import AudioPanel from "../components/hub/AudioPanel.vue";
import ProductionPanel from "../components/hub/ProductionPanel.vue";
import QaPanel from "../components/hub/QaPanel.vue";

interface Tab {
  id: string;
  nav: string;
  icon: string;
  label: string;
  component: unknown;
}

const tabs: Tab[] = [
  { id: "design", nav: "Design", icon: "🏮", label: "Design Hub", component: DesignPanel },
  { id: "tech", nav: "Tech", icon: "⚙️", label: "Technical Blueprint", component: TechPanel },
  { id: "audio", nav: "Audio", icon: "🔊", label: "Acoustic Design", component: AudioPanel },
  { id: "production", nav: "Production", icon: "📅", label: "Production Roadmap", component: ProductionPanel },
  { id: "qa", nav: "QA", icon: "🔬", label: "QA Test Suite", component: QaPanel },
];

const activeTab = ref(tabs[0].id);
const activeComponent = shallowRef(tabs[0].component);

// public/ assets must be prefixed with BASE_URL by hand when referenced from
// a template string (unlike index.html's own src="...", Vite doesn't rewrite
// plain string literals inside .vue templates) — otherwise this 404s once
// deployed under the GitHub Pages project-site subpath (SITE_BASE).
const bannerSrc = import.meta.env.BASE_URL + "assets/mobile_fortress_banner.jpg";

function selectTab(id: string) {
  activeTab.value = id;
  activeComponent.value = tabs.find((t) => t.id === id)!.component;
}

function scrollToHub() {
  document.getElementById("design-hub")?.scrollIntoView({ behavior: "smooth" });
}

const phases = [
  {
    title: "Phase 1: Native Parity & Setup",
    date: "Weeks 1-4",
    desc: "Synchronize game state kinds across Kotlin Android client and Swift iOS client. Integrate shared levels asset JSON reading schemas.",
  },
  {
    title: "Phase 2: C++ Core Simulation Engine",
    date: "Weeks 5-8",
    desc: "Scaffold headless core simulation using EnTT ECS. Establish JNI/Swift-C++-interop bindings and FlatBuffers zero-copy serialization buffers.",
  },
  {
    title: "Phase 3: Cooperative Netcode & AWS",
    date: "Weeks 9-12",
    desc: "Write UDP sockets replication channels. Establish latency-graduated matchmaking queues on AWS GameLift FlexMatch.",
  },
  {
    title: "Phase 4: ML & Mathematical Optimizations",
    date: "Weeks 13-16",
    desc: "Deploy Genetic Algorithms for dynamic HQ layout generation, WFC PCG, and Contextual Bandits for storefront optimization.",
  },
];

// --- Falling petal canvas background (Ukiyo-e-influenced hero flourish) ---
const canvas = ref<HTMLCanvasElement | null>(null);
let ctx: CanvasRenderingContext2D | null = null;
let width = 0;
let height = 0;
let raf = 0;
const petals: Petal[] = [];
const NUM_PETALS = 40;

class Petal {
  x = 0;
  y = 0;
  size = 0;
  speedX = 0;
  speedY = 0;
  rotation = 0;
  rotationSpeed = 0;
  opacity = 0;
  constructor() {
    this.reset();
    this.y = Math.random() * height;
  }
  reset() {
    this.x = Math.random() * width;
    this.y = -20;
    this.size = Math.random() * 8 + 6;
    this.speedY = Math.random() * 1.5 + 0.8;
    this.speedX = Math.random() * 1.5 - 0.5;
    this.rotation = Math.random() * 360;
    this.rotationSpeed = Math.random() * 1.5 - 0.75;
    this.opacity = Math.random() * 0.4 + 0.3;
  }
  update() {
    this.y += this.speedY;
    this.x += this.speedX + Math.sin(this.y / 30) * 0.5;
    this.rotation += this.rotationSpeed;
    if (this.y > height + 20 || this.x > width + 20 || this.x < -20) this.reset();
  }
  draw() {
    if (!ctx) return;
    ctx.save();
    ctx.translate(this.x, this.y);
    ctx.rotate((this.rotation * Math.PI) / 180);
    ctx.beginPath();
    ctx.moveTo(0, 0);
    ctx.bezierCurveTo(-this.size, -this.size / 2, -this.size / 2, -this.size * 1.5, 0, -this.size);
    ctx.bezierCurveTo(this.size / 2, -this.size * 1.5, this.size, -this.size / 2, 0, 0);
    ctx.fillStyle = `rgba(255, 183, 197, ${this.opacity})`;
    ctx.fill();
    ctx.restore();
  }
}

function resize() {
  if (!canvas.value) return;
  width = canvas.value.width = window.innerWidth;
  height = canvas.value.height = window.innerHeight;
}

function animate() {
  if (ctx) {
    ctx.clearRect(0, 0, width, height);
    petals.forEach((p) => {
      p.update();
      p.draw();
    });
  }
  raf = requestAnimationFrame(animate);
}

onMounted(() => {
  if (!canvas.value) return;
  ctx = canvas.value.getContext("2d");
  resize();
  for (let i = 0; i < NUM_PETALS; i++) petals.push(new Petal());
  window.addEventListener("resize", resize);
  animate();
});
onUnmounted(() => {
  window.removeEventListener("resize", resize);
  if (raf) cancelAnimationFrame(raf);
});
</script>

<template>
  <div class="home">
    <canvas ref="canvas" class="blossoms-canvas"></canvas>

    <section class="hero-section">
      <div class="hero-overlay"></div>
      <div class="hero-content">
        <div class="badge">DEVELOPMENT CONSOLE V3.0</div>
        <h1>Defend the Coastal Fortress</h1>
        <p class="hero-desc">
          A 1540s–1560s Wōkòu-era Cooperative Tower Defense &amp; 4X Strategy Game — an East Asian coastal power and
          its Western trading-partner allies combine traditional Ukiyo-e-influenced aesthetics with headless C++
          core simulation, Dijkstra vector pathfinding, and machine learning difficulty adjustment to repel pirate
          raiders by land and sea.
        </p>
        <div class="hero-actions">
          <button class="btn btn-primary" @click="scrollToHub">Try Design Simulators</button>
          <router-link to="/design/game_design_document" class="btn btn-secondary">Read GDD Spec</router-link>
          <router-link to="/docs" class="btn btn-secondary">Browse Documentation</router-link>
        </div>
      </div>
      <div class="hero-image-container">
        <img :src="bannerSrc" alt="Wōkòu Raid: Night on the China Coast" class="hero-banner-img" />
      </div>
    </section>

    <div class="container">
      <section class="hub-tabs-section" id="design-hub">
        <div class="tabs-header">
          <button
            v-for="t in tabs"
            :key="t.id"
            class="tab-btn"
            :class="{ active: activeTab === t.id }"
            @click="selectTab(t.id)"
          >
            <span class="icon">{{ t.icon }}</span> {{ t.label }}
          </button>
        </div>
        <div class="tabs-content">
          <keep-alive>
            <component :is="activeComponent" />
          </keep-alive>
        </div>
      </section>

      <section class="roadmap-section">
        <h2 class="section-title">Mobile Fortress Roadmap</h2>
        <div class="timeline">
          <div class="timeline-item" v-for="(phase, idx) in phases" :key="idx">
            <div class="timeline-badge">{{ idx + 1 }}</div>
            <div class="timeline-panel panel">
              <h3>{{ phase.title }}</h3>
              <span class="timeline-date">{{ phase.date }}</span>
              <p>{{ phase.desc }}</p>
            </div>
          </div>
        </div>
      </section>
    </div>
  </div>
</template>
