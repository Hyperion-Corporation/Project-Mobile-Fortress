import { useEffect, useRef, useState } from "react";
import { UNIT_ROSTER } from "../../../../constants/fortress";

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

interface DesignSection {
  id: string;
  label: string;
}

const DESIGN_SECTIONS: DesignSection[] = [
  { id: "flow-field", label: "Flow Field Pathfinding" },
  { id: "unit-classes", label: "Unit Class Design" },
  { id: "coastal-defense", label: "Coastal Fortress Network" },
  { id: "wokou-crisis", label: "Wōkōu Crisis" },
];

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

function FlowFieldSimulator() {
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
    <div className="flow-field-simulator">
      <div className="sim-controls-bar">
        <div className="control-group-inline">
          <label>Brush Tool:</label>
          <div className="btn-group-inline">
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
        <div className="control-group-inline">
          <button className="btn btn-primary btn-sm" onClick={spawnEnemies}>
            ⚔️ Spawn Wōkōu Raid Wave
          </button>
          <button className="btn btn-secondary btn-sm" onClick={resetGrid}>
            🔄 Reset Grid
          </button>
        </div>
      </div>

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
  );
}

function UnitClassSection() {
  const landUnits = UNIT_ROSTER.filter((u) => u.domain === "land");
  const seaUnits = UNIT_ROSTER.filter((u) => u.domain === "sea");
  const coastUnits = UNIT_ROSTER.filter((u) => u.domain === "coast");

  return (
    <div className="unit-class-section">
      <p className="section-intro">
        <strong>Mobile Fortress</strong> merges cooperative 2D tower defense combat with a persistent 4X coastal
        territory map. Players deploy garrison spearmen, Fo-lang-ji cannon crews, Portuguese arquebusiers, war
        junks, and veteran commanders to repel Wōkōu pirate raiders by land and sea.
      </p>

      <div className="unit-domain-group">
        <h4 className="domain-label">🗡️ Land Units</h4>
        <div className="unit-cards-row">
          {landUnits.map((u) => (
            <div key={u.id} className="unit-card">
              <span className="unit-name">{u.name}</span>
              <span className="unit-civ">{u.civ}</span>
            </div>
          ))}
        </div>
      </div>

      <div className="unit-domain-group">
        <h4 className="domain-label">⚓ Sea Units</h4>
        <div className="unit-cards-row">
          {seaUnits.map((u) => (
            <div key={u.id} className="unit-card">
              <span className="unit-name">{u.name}</span>
              <span className="unit-civ">{u.civ}</span>
            </div>
          ))}
        </div>
      </div>

      <div className="unit-domain-group">
        <h4 className="domain-label">🏰 Coastal Defense</h4>
        <div className="unit-cards-row">
          {coastUnits.map((u) => (
            <div key={u.id} className="unit-card">
              <span className="unit-name">{u.name}</span>
              <span className="unit-civ">{u.civ}</span>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}

function CoastalDefenseSection() {
  return (
    <div className="coastal-defense-section">
      <p className="section-intro">
        A Main HQ / Citadel is the loss condition. Resource Outposts fund land units; Trading Outposts fund naval
        power. Flow-field pathing routes raiders along land corridors and coastal arcs toward the citadel ring.
      </p>

      <div className="defense-cards-grid">
        <div className="defense-card">
          <h4>🏰 Main HQ / Citadel</h4>
          <p>The central fortress. If raiders breach this point, the defense fails. All flow-field vectors route toward this location.</p>
        </div>
        <div className="defense-card">
          <h4>⛏️ Resource Outposts</h4>
          <p>Generate economy for land-based garrison units. Protect these to maintain your spearmen, archers, and cannon crews.</p>
        </div>
        <div className="defense-card">
          <h4>🏪 Trading Outposts</h4>
          <p>Fund naval power projection. War junks and galleons are financed through coastal trade revenue.</p>
        </div>
        <div className="defense-card">
          <h4>🧱 Barricades & Terrain</h4>
          <p>Modify flow-field vectors with barricades (impassable) and swamps (slow zone, cost: 3). Shape raider paths to maximize kill zones.</p>
        </div>
      </div>
    </div>
  );
}

function WokouCrisisSection() {
  return (
    <div className="wokou-crisis-section">
      <p className="section-intro">
        Mixed Japanese rōnin and Chinese/Korean pirate-smugglers strike East Asian coasts by land and sea.
        Coastal fortresses must repel raids while protecting trade lanes and inland grain stores — the historical
        pressure that frames Mobile Fortress.
      </p>

      <div className="era-badge">1540s–1560s Jiajing-era Wōkōu crisis</div>

      <div className="crisis-details">
        <div className="crisis-card">
          <h4>⚔️ The Raider Threat</h4>
          <p>
            Wōkōu (倭寇) — literally "Japanese pirates" — were mixed bands of Japanese rōnin, Chinese smugglers,
            and Korean coastal raiders who terrorized the East Asian coastline during the mid-16th century.
          </p>
        </div>
        <div className="crisis-card">
          <h4>🏯 Coastal Defense Response</h4>
          <p>
            Ming China's coastal garrison, reinforced by Portuguese trading partners newly arrived at Macau,
            developed sophisticated fortress networks combining traditional East Asian fortification with
            Western artillery positions.
          </p>
        </div>
        <div className="crisis-card">
          <h4>🌏 Dual-Front Combat</h4>
          <p>
            Raiders strike simultaneously by land (through coastal corridors) and sea (via war junks and
            landing craft), forcing defenders to manage both fronts with coordinated garrison deployment.
          </p>
        </div>
      </div>
    </div>
  );
}

export default function DesignPanel() {
  const [activeSection, setActiveSection] = useState("flow-field");

  function renderContent() {
    switch (activeSection) {
      case "flow-field":
        return <FlowFieldSimulator />;
      case "unit-classes":
        return <UnitClassSection />;
      case "coastal-defense":
        return <CoastalDefenseSection />;
      case "wokou-crisis":
        return <WokouCrisisSection />;
      default:
        return <FlowFieldSimulator />;
    }
  }

  return (
    <div className="tab-pane active" id="tab-design">
      <div className="panel glass">
        <h2>Wōkōu-Era Coastal Defense &amp; Unit Class Design</h2>
        <p className="panel-desc" style={{ marginBottom: "2rem" }}>
          Explore the core design pillars of Mobile Fortress — from Dijkstra flow-field pathfinding to the unit
          roster and coastal fortress network that defines the dual-front tower defense experience.
        </p>

        <div className="sprints-interactive-grid">
          <div className="sprint-header-buttons">
            {DESIGN_SECTIONS.map((s) => (
              <button
                key={s.id}
                className={`sprint-nav-btn${activeSection === s.id ? " active" : ""}`}
                onClick={() => setActiveSection(s.id)}
              >
                {s.label}
              </button>
            ))}
          </div>

          <div className="sprint-display-panel panel-dark" key={activeSection}>
            {renderContent()}
          </div>
        </div>
      </div>
    </div>
  );
}
