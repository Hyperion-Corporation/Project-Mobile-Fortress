import { useEffect, useRef, useState } from "react";

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

function isSpawn(r: number, c: number) {
  return spawnPoints.some((p) => p.row === r && p.col === c);
}
function isKeepCell(r: number, c: number) {
  return keepPoint.row === r && keepPoint.col === c;
}

function buildGrid(): Cell[] {
  const grid: Cell[] = [];
  for (let r = 0; r < GRID_SIZE; r++) {
    for (let c = 0; c < GRID_SIZE; c++) {
      let type: Cell["type"] = "clear";
      if (isKeepCell(r, c)) type = "keep";
      else if (isSpawn(r, c)) type = "spawn";
      grid.push({
        row: r,
        col: c,
        type,
        cost: 1,
        distance: Infinity,
        vector: { x: 0, y: 0 },
        arrow: "",
      });
    }
  }
  return grid;
}

function cellAt(grid: Cell[], r: number, c: number) {
  return grid[r * GRID_SIZE + c];
}

function neighbors(grid: Cell[], r: number, c: number) {
  const dirs = [
    [-1, 0],
    [1, 0],
    [0, -1],
    [0, 1],
    [-1, -1],
    [-1, 1],
    [1, -1],
    [1, 1],
  ];
  const res: Cell[] = [];
  dirs.forEach(([dr, dc]) => {
    const nr = r + dr;
    const nc = c + dc;
    if (nr >= 0 && nr < GRID_SIZE && nc >= 0 && nc < GRID_SIZE) res.push(cellAt(grid, nr, nc));
  });
  return res;
}

const ARROWS: Record<string, string> = {
  "1,0": "→",
  "0,-1": "↑",
  "0,1": "↓",
  "-1,0": "←",
  "-1,-1": "↖",
  "1,-1": "↗",
  "-1,1": "↙",
  "1,1": "↘",
};

function recalc(grid: Cell[]): Cell[] {
  const next = grid.map((cell) => ({ ...cell, distance: Infinity, vector: { x: 0, y: 0 }, arrow: "" }));
  const start = cellAt(next, keepPoint.row, keepPoint.col);
  start.distance = 0;
  const queue: Cell[] = [start];
  while (queue.length) {
    const current = queue.shift()!;
    neighbors(next, current.row, current.col).forEach((n) => {
      if (n.type === "wall") return;
      const tentative = current.distance + n.cost;
      if (tentative < n.distance) {
        n.distance = tentative;
        queue.push(n);
      }
    });
  }
  next.forEach((cell) => {
    if (cell.type === "wall" || cell.type === "keep") return;
    let minDist = cell.distance;
    let target: Cell | null = null;
    neighbors(next, cell.row, cell.col).forEach((n) => {
      if (n.type !== "wall" && n.distance < minDist) {
        minDist = n.distance;
        target = n;
      }
    });
    if (target) {
      const t = target as Cell;
      const dx = t.col - cell.col;
      const dy = t.row - cell.row;
      cell.vector = { x: dx, y: dy };
      cell.arrow = ARROWS[dx + "," + dy] || "→";
    }
  });
  return next;
}

function cellClass(cell: Cell) {
  return [
    "grid-cell",
    cell.type === "spawn" && "cell-spawn",
    cell.type === "keep" && "cell-keep",
    cell.type === "wall" && "cell-wall",
    cell.type === "swamp" && "cell-swamp",
  ]
    .filter(Boolean)
    .join(" ");
}

export default function DesignPanel() {
  const [grid, setGrid] = useState<Cell[]>(() => recalc(buildGrid()));
  const [enemies, setEnemies] = useState<Enemy[]>([]);
  const [tool, setTool] = useState<"wall" | "swamp" | "clear">("wall");
  const [cellWidth, setCellWidth] = useState(36);
  const gridRef = useRef<HTMLDivElement | null>(null);
  const enemyIdRef = useRef(0);
  const simIntervalRef = useRef<ReturnType<typeof setInterval> | null>(null);
  const gridStateRef = useRef(grid);
  gridStateRef.current = grid;

  useEffect(() => {
    function updateCellWidth() {
      if (gridRef.current) setCellWidth(gridRef.current.clientWidth / GRID_SIZE);
    }
    updateCellWidth();
    window.addEventListener("resize", updateCellWidth);
    return () => {
      window.removeEventListener("resize", updateCellWidth);
      if (simIntervalRef.current) clearInterval(simIntervalRef.current);
    };
  }, []);

  function handleCellClick(cell: Cell) {
    if (cell.type === "keep" || cell.type === "spawn") return;
    setGrid((prev) => {
      const next = prev.map((c) => ({ ...c }));
      const target = cellAt(next, cell.row, cell.col);
      if (tool === "wall") {
        target.type = target.type === "wall" ? "clear" : "wall";
        target.cost = target.type === "wall" ? 99 : 1;
      } else if (tool === "swamp") {
        target.type = target.type === "swamp" ? "clear" : "swamp";
        target.cost = target.type === "swamp" ? 3 : 1;
      } else {
        target.type = "clear";
        target.cost = 1;
      }
      return recalc(next);
    });
  }

  function resetGrid() {
    setEnemies([]);
    if (simIntervalRef.current) clearInterval(simIntervalRef.current);
    setGrid(recalc(buildGrid()));
  }

  function tick() {
    setEnemies((prev) => {
      if (!prev.length) {
        if (simIntervalRef.current) clearInterval(simIntervalRef.current);
        return prev;
      }
      const next: Enemy[] = [];
      for (const e of prev) {
        if (e.r === keepPoint.row && e.c === keepPoint.col) continue;
        const cell = cellAt(gridStateRef.current, e.r, e.c);
        if (!cell || cell.type === "wall") continue;
        const nr = e.r + cell.vector.y;
        const nc = e.c + cell.vector.x;
        if (nr >= 0 && nr < GRID_SIZE && nc >= 0 && nc < GRID_SIZE) next.push({ ...e, r: nr, c: nc });
      }
      return next;
    });
  }

  function spawnEnemies() {
    if (simIntervalRef.current) clearInterval(simIntervalRef.current);
    spawnPoints.forEach((sp, idx) => {
      setTimeout(
        () => setEnemies((prev) => [...prev, { id: enemyIdRef.current++, r: sp.row, c: sp.col }]),
        idx * 400
      );
      setTimeout(
        () => setEnemies((prev) => [...prev, { id: enemyIdRef.current++, r: sp.row, c: sp.col }]),
        idx * 400 + 800
      );
    });
    simIntervalRef.current = setInterval(tick, 150);
  }

  return (
    <div className="tab-pane active" id="tab-design">
      <div className="grid-3-col">
        <div className="panel glass col-span-1">
          <h2>Wōkòu-Era Coastal Defense &amp; Unit Class Design</h2>
          <p>
            <strong>Mobile Fortress</strong> merges cooperative 2D tower defense combat with a persistent 4X coastal
            territory map. Players deploy garrison spearmen, Fo-lang-ji cannon crews, Portuguese arquebusiers, war
            junks, and veteran commanders to repel Wōkòu pirate raiders by land and sea.
          </p>
          <p>
            <strong>Flow Field Pathfinding</strong>: Recalculates cost vectors for all units simultaneously,
            bypassing standard pathfinding bottlenecks.
          </p>
          <div className="control-group">
            <label>Brush Tool:</label>
            <div className="btn-group">
              <button
                className={`btn btn-sm btn-tool${tool === "wall" ? " active" : ""}`}
                onClick={() => setTool("wall")}
              >
                🧱 Place Barricade
              </button>
              <button
                className={`btn btn-sm btn-tool${tool === "swamp" ? " active" : ""}`}
                onClick={() => setTool("swamp")}
              >
                🌾 Slow Swamp (Cost: 3)
              </button>
              <button
                className={`btn btn-sm btn-tool${tool === "clear" ? " active" : ""}`}
                onClick={() => setTool("clear")}
              >
                🧹 Clear Tile
              </button>
            </div>
          </div>
          <div className="control-group">
            <button className="btn btn-primary btn-block" onClick={spawnEnemies}>
              ⚔️ Spawn Wōkòu Raid Wave
            </button>
            <button className="btn btn-secondary btn-block" onClick={resetGrid}>
              🔄 Reset Grid
            </button>
          </div>
        </div>

        <div className="panel glass col-span-2 flex-center">
          <div className="grid-simulator-container">
            <div className="legend-bar">
              <span>⛩️ Spawn</span>
              <span>🏰 HQ (Goal)</span>
              <span>🧱 Barricade</span>
              <span>🌾 Swamp</span>
            </div>
            <div className="simulator-grid" ref={gridRef}>
              {grid.map((cell) => (
                <div
                  key={cell.row + "-" + cell.col}
                  className={cellClass(cell)}
                  onMouseDown={() => handleCellClick(cell)}
                >
                  {cell.arrow && <span className="cell-arrow">{cell.arrow}</span>}
                </div>
              ))}
              {enemies.map((e) => (
                <div
                  key={e.id}
                  className="enemy-dot"
                  style={{ left: e.c * cellWidth + cellWidth / 2 + "px", top: e.r * cellWidth + cellWidth / 2 + "px" }}
                />
              ))}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
