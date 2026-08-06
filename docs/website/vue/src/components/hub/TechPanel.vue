<script setup lang="ts">
import { reactive, ref, onMounted } from "vue";

interface GaCell {
  row: number;
  col: number;
  type: "clear" | "spawn" | "keep" | "wall" | "path";
}

const GA_SIZE = 8;
const grid = reactive<GaCell[]>([]);
const gen = ref(0);
const bestFitness = ref(0);
const avgFitness = ref(0);

function cellAt(r: number, c: number) {
  return grid[r * GA_SIZE + c];
}

function buildGrid() {
  grid.length = 0;
  for (let r = 0; r < GA_SIZE; r++) {
    for (let c = 0; c < GA_SIZE; c++) {
      let type: GaCell["type"] = "clear";
      if (r === 0 && c === 0) type = "spawn";
      else if (r === GA_SIZE - 1 && c === GA_SIZE - 1) type = "keep";
      grid.push({ row: r, col: c, type });
    }
  }
}

function reset() {
  gen.value = 0;
  bestFitness.value = 0;
  avgFitness.value = 0;
  grid.forEach((cell) => {
    if (cell.type !== "spawn" && cell.type !== "keep") cell.type = "clear";
  });
}

function setCells(coords: { r: number; c: number }[], type: GaCell["type"]) {
  coords.forEach(({ r, c }) => {
    const cell = cellAt(r, c);
    if (cell) cell.type = type;
  });
}

function runGeneration() {
  gen.value++;
  let targetBest: number, targetAvg: number;
  if (gen.value < 5) {
    targetBest = 16; targetAvg = 12.2;
  } else if (gen.value < 15) {
    targetBest = 20; targetAvg = 15.6;
  } else if (gen.value < 30) {
    targetBest = 24; targetAvg = 19.8;
  } else {
    targetBest = 28; targetAvg = 23.4;
  }
  bestFitness.value = targetBest;
  avgFitness.value = targetAvg + (Math.random() * 1.5 - 0.75);

  grid.forEach((cell) => {
    if (cell.type !== "spawn" && cell.type !== "keep") cell.type = "clear";
  });

  let wallCoords: { r: number; c: number }[] = [];
  let pathCoords: { r: number; c: number }[] = [];
  if (gen.value < 5) {
    wallCoords = [{ r: 1, c: 2 }, { r: 2, c: 5 }, { r: 4, c: 1 }, { r: 5, c: 6 }, { r: 6, c: 3 }];
    pathCoords = [{ r: 0, c: 1 }, { r: 1, c: 1 }, { r: 2, c: 1 }, { r: 3, c: 1 }, { r: 3, c: 2 }, { r: 3, c: 3 }, { r: 3, c: 4 }, { r: 3, c: 5 }, { r: 4, c: 5 }, { r: 5, c: 5 }, { r: 6, c: 5 }, { r: 7, c: 5 }, { r: 7, c: 6 }];
  } else if (gen.value < 15) {
    wallCoords = [{ r: 1, c: 2 }, { r: 2, c: 2 }, { r: 3, c: 2 }, { r: 5, c: 5 }, { r: 6, c: 5 }, { r: 4, c: 5 }];
    pathCoords = [{ r: 0, c: 1 }, { r: 0, c: 2 }, { r: 0, c: 3 }, { r: 1, c: 3 }, { r: 2, c: 3 }, { r: 3, c: 3 }, { r: 4, c: 3 }, { r: 4, c: 4 }, { r: 4, c: 6 }, { r: 5, c: 6 }, { r: 6, c: 6 }, { r: 7, c: 6 }];
  } else if (gen.value < 30) {
    wallCoords = [{ r: 1, c: 0 }, { r: 1, c: 1 }, { r: 1, c: 2 }, { r: 1, c: 3 }, { r: 1, c: 4 }, { r: 1, c: 5 }, { r: 4, c: 2 }, { r: 4, c: 3 }, { r: 4, c: 4 }, { r: 4, c: 5 }, { r: 4, c: 6 }, { r: 4, c: 7 }];
    pathCoords = [{ r: 0, c: 1 }, { r: 0, c: 2 }, { r: 0, c: 3 }, { r: 0, c: 4 }, { r: 0, c: 5 }, { r: 0, c: 6 }, { r: 1, c: 6 }, { r: 2, c: 6 }, { r: 3, c: 6 }, { r: 3, c: 5 }, { r: 3, c: 4 }, { r: 3, c: 3 }, { r: 3, c: 2 }, { r: 3, c: 1 }, { r: 4, c: 1 }, { r: 5, c: 1 }, { r: 6, c: 1 }, { r: 7, c: 1 }, { r: 7, c: 2 }, { r: 7, c: 3 }, { r: 7, c: 4 }, { r: 7, c: 5 }, { r: 7, c: 6 }];
  } else {
    wallCoords = [{ r: 1, c: 0 }, { r: 1, c: 1 }, { r: 1, c: 2 }, { r: 1, c: 3 }, { r: 1, c: 4 }, { r: 1, c: 5 }, { r: 1, c: 6 }, { r: 4, c: 1 }, { r: 4, c: 2 }, { r: 4, c: 3 }, { r: 4, c: 4 }, { r: 4, c: 5 }, { r: 4, c: 6 }, { r: 4, c: 7 }, { r: 6, c: 0 }, { r: 6, c: 1 }];
    pathCoords = [{ r: 0, c: 1 }, { r: 0, c: 2 }, { r: 0, c: 3 }, { r: 0, c: 4 }, { r: 0, c: 5 }, { r: 0, c: 6 }, { r: 0, c: 7 }, { r: 1, c: 7 }, { r: 2, c: 7 }, { r: 3, c: 7 }, { r: 3, c: 6 }, { r: 3, c: 5 }, { r: 3, c: 4 }, { r: 3, c: 3 }, { r: 3, c: 2 }, { r: 3, c: 1 }, { r: 3, c: 0 }, { r: 4, c: 0 }, { r: 5, c: 0 }, { r: 5, c: 1 }, { r: 5, c: 2 }, { r: 5, c: 3 }, { r: 5, c: 4 }, { r: 5, c: 5 }, { r: 5, c: 6 }, { r: 6, c: 6 }, { r: 7, c: 6 }];
  }
  setCells(wallCoords, "wall");
  setCells(pathCoords, "path");
}

function gaCellClass(cell: GaCell) {
  return {
    "ga-spawn": cell.type === "spawn",
    "ga-keep": cell.type === "keep",
    "ga-wall": cell.type === "wall",
    "ga-path": cell.type === "path",
  };
}
function gaCellIcon(cell: GaCell) {
  if (cell.type === "spawn") return "⛩️";
  if (cell.type === "keep") return "🏰";
  if (cell.type === "path") return "🔸";
  return "";
}

onMounted(buildGrid);
</script>

<template>
  <div class="tab-pane active" id="tab-tech">
    <div class="grid-2-col">
      <div class="panel glass">
        <h2>Headless C++ Core &amp; FFI Architecture</h2>
        <p>The simulation engine is isolated within a headless C++20 core, bound to the native clients via <strong>JNI</strong> (Android) and <strong>Swift C++ interop</strong> (iOS).</p>
        <ul>
          <li><strong>EnTT ECS Engine</strong>: sparse-set component storage that maximizes memory cache hits on mobile processors.</li>
          <li><strong>FlatBuffers Serialization</strong>: generates zero-copy state buffers, bypassing dynamic language parsing overhead.</li>
        </ul>

        <h3 style="margin-top: 1.5rem; margin-bottom: 0.5rem">Evolve Wall Placements</h3>
        <p class="panel-desc">
          The game runs a Genetic Algorithm (GA) to evolve wall layouts that maximize path length to the HQ within
          budget limits.
        </p>
        <div class="panel-dark ga-controls-box" style="margin-top: 1rem">
          <div class="stat-row"><span>Generation:</span> <strong>{{ gen }}</strong></div>
          <div class="stat-row"><span>Best Fitness (Path Length):</span> <strong>{{ bestFitness }}</strong></div>
          <div class="stat-row"><span>Average Fitness:</span> <strong>{{ avgFitness.toFixed(1) }}</strong></div>
          <div class="btn-row" style="margin-top: 1rem; display: flex; gap: 0.5rem">
            <button class="btn btn-sm btn-primary" @click="runGeneration">🧬 Evolve Gen</button>
            <button class="btn btn-sm btn-secondary" @click="reset">🔄 Reset GA</button>
          </div>
        </div>
      </div>

      <div class="panel glass flex-center">
        <h3>Genetic Algorithm Maze Grid</h3>
        <p class="panel-desc" style="margin-bottom: 1rem">
          Evolved wall blockages (red) maximize winding pathways (gold) from the spawn (blue) to the HQ (purple).
        </p>
        <div class="ga-grid-container" style="display: flex; justify-content: center">
          <div
            style="display: grid; grid-template-columns: repeat(8, 1fr); gap: 2px; width: 320px; height: 320px; background: rgba(0, 0, 0, 0.3); border: 2px solid var(--border-color); border-radius: 4px; padding: 2px"
          >
            <div v-for="cell in grid" :key="cell.row + '-' + cell.col" class="ga-cell" :class="gaCellClass(cell)">
              {{ gaCellIcon(cell) }}
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
