<script setup lang="ts">
import { reactive, ref, onMounted, onUnmounted, nextTick } from "vue";

interface Point {
  row: number;
  col: number;
}
interface Cell {
  row: number;
  col: number;
  type: "clear" | "wall" | "swamp" | "spawn" | "keep";
  cost: number;
  distance: number;
  vector: { x: number; y: number };
  arrow: string;
}
interface Enemy {
  id: number;
  r: number;
  c: number;
}

const GRID_SIZE = 12;
const spawnPoints: Point[] = [
  { row: 0, col: 0 },
  { row: 0, col: 11 },
  { row: 11, col: 0 },
];
const keepPoint: Point = { row: 5, col: 5 };

const grid = reactive<Cell[]>([]);
const enemies = reactive<Enemy[]>([]);
const tool = ref<"wall" | "swamp" | "clear">("wall");
const gridEl = ref<HTMLElement | null>(null);
const cellWidth = ref(36);
let enemyId = 0;
let simInterval: ReturnType<typeof setInterval> | null = null;

function isSpawn(r: number, c: number) {
  return spawnPoints.some((p) => p.row === r && p.col === c);
}
function isKeepCell(r: number, c: number) {
  return keepPoint.row === r && keepPoint.col === c;
}
function cellAt(r: number, c: number) {
  return grid[r * GRID_SIZE + c];
}
function neighbors(r: number, c: number) {
  const dirs = [
    [-1, 0], [1, 0], [0, -1], [0, 1],
    [-1, -1], [-1, 1], [1, -1], [1, 1],
  ];
  const res: Cell[] = [];
  dirs.forEach(([dr, dc]) => {
    const nr = r + dr, nc = c + dc;
    if (nr >= 0 && nr < GRID_SIZE && nc >= 0 && nc < GRID_SIZE) res.push(cellAt(nr, nc));
  });
  return res;
}

function buildGrid() {
  grid.length = 0;
  for (let r = 0; r < GRID_SIZE; r++) {
    for (let c = 0; c < GRID_SIZE; c++) {
      let type: Cell["type"] = "clear";
      if (isKeepCell(r, c)) type = "keep";
      else if (isSpawn(r, c)) type = "spawn";
      grid.push({
        row: r, col: c, type,
        cost: type === "wall" ? 99 : type === "swamp" ? 3 : 1,
        distance: Infinity,
        vector: { x: 0, y: 0 },
        arrow: "",
      });
    }
  }
}

function recalc() {
  grid.forEach((cell) => {
    cell.distance = Infinity;
    cell.vector = { x: 0, y: 0 };
    cell.arrow = "";
  });
  const start = cellAt(keepPoint.row, keepPoint.col);
  start.distance = 0;
  const queue: Cell[] = [start];
  while (queue.length) {
    const current = queue.shift()!;
    neighbors(current.row, current.col).forEach((n) => {
      if (n.type === "wall") return;
      const tentative = current.distance + n.cost;
      if (tentative < n.distance) {
        n.distance = tentative;
        queue.push(n);
      }
    });
  }
  const arrows: Record<string, string> = {
    "1,0": "→", "0,-1": "↑", "0,1": "↓", "-1,0": "←",
    "-1,-1": "↖", "1,-1": "↗", "-1,1": "↙", "1,1": "↘",
  };
  grid.forEach((cell) => {
    if (cell.type === "wall" || cell.type === "keep") return;
    let minDist = cell.distance;
    let target: Cell | null = null;
    neighbors(cell.row, cell.col).forEach((n) => {
      if (n.type !== "wall" && n.distance < minDist) {
        minDist = n.distance;
        target = n;
      }
    });
    if (target) {
      const t = target as Cell;
      const dx = t.col - cell.col, dy = t.row - cell.row;
      cell.vector = { x: dx, y: dy };
      cell.arrow = arrows[dx + "," + dy] || "→";
    }
  });
}

function handleCellClick(cell: Cell) {
  if (cell.type === "keep" || cell.type === "spawn") return;
  if (tool.value === "wall") {
    cell.type = cell.type === "wall" ? "clear" : "wall";
    cell.cost = cell.type === "wall" ? 99 : 1;
  } else if (tool.value === "swamp") {
    cell.type = cell.type === "swamp" ? "clear" : "swamp";
    cell.cost = cell.type === "swamp" ? 3 : 1;
  } else {
    cell.type = "clear";
    cell.cost = 1;
  }
  recalc();
}

function cellClass(cell: Cell) {
  return {
    "cell-spawn": cell.type === "spawn",
    "cell-keep": cell.type === "keep",
    "cell-wall": cell.type === "wall",
    "cell-swamp": cell.type === "swamp",
  };
}

function resetGrid() {
  enemies.length = 0;
  if (simInterval) clearInterval(simInterval);
  buildGrid();
  recalc();
}

function tick() {
  if (!enemies.length) {
    if (simInterval) clearInterval(simInterval);
    return;
  }
  for (let i = enemies.length - 1; i >= 0; i--) {
    const e = enemies[i];
    if (e.r === keepPoint.row && e.c === keepPoint.col) {
      enemies.splice(i, 1);
      continue;
    }
    const cell = cellAt(e.r, e.c);
    if (!cell || cell.type === "wall") {
      enemies.splice(i, 1);
      continue;
    }
    const nr = e.r + cell.vector.y, nc = e.c + cell.vector.x;
    if (nr >= 0 && nr < GRID_SIZE && nc >= 0 && nc < GRID_SIZE) {
      e.r = nr;
      e.c = nc;
    } else {
      enemies.splice(i, 1);
    }
  }
}

function spawnEnemies() {
  if (simInterval) clearInterval(simInterval);
  spawnPoints.forEach((sp, idx) => {
    setTimeout(() => enemies.push({ id: enemyId++, r: sp.row, c: sp.col }), idx * 400);
    setTimeout(() => enemies.push({ id: enemyId++, r: sp.row, c: sp.col }), idx * 400 + 800);
  });
  simInterval = setInterval(tick, 150);
}

function updateCellWidth() {
  if (gridEl.value) cellWidth.value = gridEl.value.clientWidth / GRID_SIZE;
}

onMounted(() => {
  buildGrid();
  recalc();
  nextTick(updateCellWidth);
  window.addEventListener("resize", updateCellWidth);
});
onUnmounted(() => {
  if (simInterval) clearInterval(simInterval);
  window.removeEventListener("resize", updateCellWidth);
});
</script>

<template>
  <div class="tab-pane active" id="tab-design">
    <div class="grid-3-col">
      <div class="panel glass col-span-1">
        <h2>Wōkòu-Era Coastal Defense &amp; Unit Class Design</h2>
        <p>
          <strong>Mobile Fortress</strong> merges cooperative 2D tower defense combat with a persistent 4X coastal
          territory map. Players deploy garrison spearmen, Fo-lang-ji cannon crews, Portuguese arquebusiers, war
          junks, and veteran commanders to repel Wōkòu pirate raiders by land and sea.
        </p>
        <p>
          <strong>Flow Field Pathfinding</strong>: Recalculates cost vectors for all units simultaneously, bypassing
          standard pathfinding bottlenecks.
        </p>
        <div class="control-group">
          <label>Brush Tool:</label>
          <div class="btn-group">
            <button class="btn btn-sm btn-tool" :class="{ active: tool === 'wall' }" @click="tool = 'wall'">
              🧱 Place Barricade
            </button>
            <button class="btn btn-sm btn-tool" :class="{ active: tool === 'swamp' }" @click="tool = 'swamp'">
              🌾 Slow Swamp (Cost: 3)
            </button>
            <button class="btn btn-sm btn-tool" :class="{ active: tool === 'clear' }" @click="tool = 'clear'">
              🧹 Clear Tile
            </button>
          </div>
        </div>
        <div class="control-group">
          <button class="btn btn-primary btn-block" @click="spawnEnemies">⚔️ Spawn Wōkòu Raid Wave</button>
          <button class="btn btn-secondary btn-block" @click="resetGrid">🔄 Reset Grid</button>
        </div>
      </div>

      <div class="panel glass col-span-2 flex-center">
        <div class="grid-simulator-container">
          <div class="legend-bar">
            <span>⛩️ Spawn</span>
            <span>🏰 HQ (Goal)</span>
            <span>🧱 Barricade</span>
            <span>🌾 Swamp</span>
          </div>
          <div class="simulator-grid" ref="gridEl">
            <div
              v-for="cell in grid"
              :key="cell.row + '-' + cell.col"
              class="grid-cell"
              :class="cellClass(cell)"
              @mousedown="handleCellClick(cell)"
            >
              <span v-if="cell.arrow" class="cell-arrow">{{ cell.arrow }}</span>
            </div>
            <div
              v-for="e in enemies"
              :key="e.id"
              class="enemy-dot"
              :style="{ left: e.c * cellWidth + cellWidth / 2 + 'px', top: e.r * cellWidth + cellWidth / 2 + 'px' }"
            ></div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
