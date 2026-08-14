import { useState } from "react";

interface GaCell {
  row: number;
  col: number;
  type: "clear" | "spawn" | "keep" | "wall" | "path";
}

const GA_SIZE = 8;

function buildGrid(): GaCell[] {
  const grid: GaCell[] = [];
  for (let r = 0; r < GA_SIZE; r++) {
    for (let c = 0; c < GA_SIZE; c++) {
      let type: GaCell["type"] = "clear";
      if (r === 0 && c === 0) type = "spawn";
      else if (r === GA_SIZE - 1 && c === GA_SIZE - 1) type = "keep";
      grid.push({ row: r, col: c, type });
    }
  }
  return grid;
}

function setCells(grid: GaCell[], coords: { r: number; c: number }[], type: GaCell["type"]): GaCell[] {
  const next = grid.map((c) => ({ ...c }));
  coords.forEach(({ r, c }) => {
    const cell = next[r * GA_SIZE + c];
    if (cell) cell.type = type;
  });
  return next;
}

function clearNonAnchors(grid: GaCell[]): GaCell[] {
  return grid.map((cell) => (cell.type !== "spawn" && cell.type !== "keep" ? { ...cell, type: "clear" } : cell));
}

function gaCellClass(cell: GaCell) {
  return [
    "ga-cell",
    cell.type === "spawn" && "ga-spawn",
    cell.type === "keep" && "ga-keep",
    cell.type === "wall" && "ga-wall",
    cell.type === "path" && "ga-path",
  ]
    .filter(Boolean)
    .join(" ");
}

function gaCellIcon(cell: GaCell) {
  if (cell.type === "spawn") return "⛩️";
  if (cell.type === "keep") return "🏰";
  if (cell.type === "path") return "🔸";
  return "";
}

export default function TechPanel() {
  const [grid, setGrid] = useState<GaCell[]>(buildGrid);
  const [gen, setGen] = useState(0);
  const [bestFitness, setBestFitness] = useState(0);
  const [avgFitness, setAvgFitness] = useState(0);

  function reset() {
    setGen(0);
    setBestFitness(0);
    setAvgFitness(0);
    setGrid((prev) => clearNonAnchors(prev));
  }

  function runGeneration() {
    const nextGen = gen + 1;
    setGen(nextGen);

    let targetBest: number;
    let targetAvg: number;
    if (nextGen < 5) {
      targetBest = 16;
      targetAvg = 12.2;
    } else if (nextGen < 15) {
      targetBest = 20;
      targetAvg = 15.6;
    } else if (nextGen < 30) {
      targetBest = 24;
      targetAvg = 19.8;
    } else {
      targetBest = 28;
      targetAvg = 23.4;
    }
    setBestFitness(targetBest);
    setAvgFitness(targetAvg + (Math.random() * 1.5 - 0.75));

    let wallCoords: { r: number; c: number }[];
    let pathCoords: { r: number; c: number }[];
    if (nextGen < 5) {
      wallCoords = [{ r: 1, c: 2 }, { r: 2, c: 5 }, { r: 4, c: 1 }, { r: 5, c: 6 }, { r: 6, c: 3 }];
      pathCoords = [{ r: 0, c: 1 }, { r: 1, c: 1 }, { r: 2, c: 1 }, { r: 3, c: 1 }, { r: 3, c: 2 }, { r: 3, c: 3 }, { r: 3, c: 4 }, { r: 3, c: 5 }, { r: 4, c: 5 }, { r: 5, c: 5 }, { r: 6, c: 5 }, { r: 7, c: 5 }, { r: 7, c: 6 }];
    } else if (nextGen < 15) {
      wallCoords = [{ r: 1, c: 2 }, { r: 2, c: 2 }, { r: 3, c: 2 }, { r: 5, c: 5 }, { r: 6, c: 5 }, { r: 4, c: 5 }];
      pathCoords = [{ r: 0, c: 1 }, { r: 0, c: 2 }, { r: 0, c: 3 }, { r: 1, c: 3 }, { r: 2, c: 3 }, { r: 3, c: 3 }, { r: 4, c: 3 }, { r: 4, c: 4 }, { r: 4, c: 6 }, { r: 5, c: 6 }, { r: 6, c: 6 }, { r: 7, c: 6 }];
    } else if (nextGen < 30) {
      wallCoords = [{ r: 1, c: 0 }, { r: 1, c: 1 }, { r: 1, c: 2 }, { r: 1, c: 3 }, { r: 1, c: 4 }, { r: 1, c: 5 }, { r: 4, c: 2 }, { r: 4, c: 3 }, { r: 4, c: 4 }, { r: 4, c: 5 }, { r: 4, c: 6 }, { r: 4, c: 7 }];
      pathCoords = [{ r: 0, c: 1 }, { r: 0, c: 2 }, { r: 0, c: 3 }, { r: 0, c: 4 }, { r: 0, c: 5 }, { r: 0, c: 6 }, { r: 1, c: 6 }, { r: 2, c: 6 }, { r: 3, c: 6 }, { r: 3, c: 5 }, { r: 3, c: 4 }, { r: 3, c: 3 }, { r: 3, c: 2 }, { r: 3, c: 1 }, { r: 4, c: 1 }, { r: 5, c: 1 }, { r: 6, c: 1 }, { r: 7, c: 1 }, { r: 7, c: 2 }, { r: 7, c: 3 }, { r: 7, c: 4 }, { r: 7, c: 5 }, { r: 7, c: 6 }];
    } else {
      wallCoords = [{ r: 1, c: 0 }, { r: 1, c: 1 }, { r: 1, c: 2 }, { r: 1, c: 3 }, { r: 1, c: 4 }, { r: 1, c: 5 }, { r: 1, c: 6 }, { r: 4, c: 1 }, { r: 4, c: 2 }, { r: 4, c: 3 }, { r: 4, c: 4 }, { r: 4, c: 5 }, { r: 4, c: 6 }, { r: 4, c: 7 }, { r: 6, c: 0 }, { r: 6, c: 1 }];
      pathCoords = [{ r: 0, c: 1 }, { r: 0, c: 2 }, { r: 0, c: 3 }, { r: 0, c: 4 }, { r: 0, c: 5 }, { r: 0, c: 6 }, { r: 0, c: 7 }, { r: 1, c: 7 }, { r: 2, c: 7 }, { r: 3, c: 7 }, { r: 3, c: 6 }, { r: 3, c: 5 }, { r: 3, c: 4 }, { r: 3, c: 3 }, { r: 3, c: 2 }, { r: 3, c: 1 }, { r: 3, c: 0 }, { r: 4, c: 0 }, { r: 5, c: 0 }, { r: 5, c: 1 }, { r: 5, c: 2 }, { r: 5, c: 3 }, { r: 5, c: 4 }, { r: 5, c: 5 }, { r: 5, c: 6 }, { r: 6, c: 6 }, { r: 7, c: 6 }];
    }

    setGrid((prev) => {
      let next = clearNonAnchors(prev);
      next = setCells(next, wallCoords, "wall");
      next = setCells(next, pathCoords, "path");
      return next;
    });
  }

  return (
    <div className="tab-pane active" id="tab-tech">
      <div className="grid-2-col">
        <div className="panel glass">
          <h2>Godot 4 + C++20 Simulation Architecture</h2>
          <p>
            The simulation engine is isolated within a headless <strong>C++20</strong> core ({" "}
            <code>SimulationCore</code>), exposed to{" "}
            <strong>Godot 4</strong> via <strong>GDExtension</strong> (godot-cpp + native C++ modules).
            Android and iOS are reached via Godot's mobile export templates.
          </p>
          <ul>
            <li>
              <strong>EnTT ECS Engine</strong>: sparse-set component storage that maximizes memory cache hits on
              mobile processors — wave spawning, unit combat, and outpost HP all run in the C++ layer.
            </li>
            <li>
              <strong>FlatBuffers Serialization</strong>: generates zero-copy state snapshots for save/load and
              future multiplayer replication; the GDScript layer calls <code>save_state()</code>/
              <code>load_state()</code> across the GDExtension boundary.
            </li>
          </ul>

          <h3 style={{ marginTop: "1.5rem", marginBottom: "0.5rem" }}>Evolve Wall Placements</h3>
          <p className="panel-desc">
            The game runs a Genetic Algorithm (GA) to evolve wall layouts that maximize path length to the HQ within
            budget limits.
          </p>
          <div className="panel-dark ga-controls-box" style={{ marginTop: "1rem" }}>
            <div className="stat-row">
              <span>Generation:</span> <strong>{gen}</strong>
            </div>
            <div className="stat-row">
              <span>Best Fitness (Path Length):</span> <strong>{bestFitness}</strong>
            </div>
            <div className="stat-row">
              <span>Average Fitness:</span> <strong>{avgFitness.toFixed(1)}</strong>
            </div>
            <div className="btn-row" style={{ marginTop: "1rem", display: "flex", gap: "0.5rem" }}>
              <button className="btn btn-sm btn-primary" onClick={runGeneration}>
                🧬 Evolve Gen
              </button>
              <button className="btn btn-sm btn-secondary" onClick={reset}>
                🔄 Reset GA
              </button>
            </div>
          </div>
        </div>

        <div className="panel glass flex-center">
          <h3>Genetic Algorithm Maze Grid</h3>
          <p className="panel-desc" style={{ marginBottom: "1rem" }}>
            Evolved wall blockages (red) maximize winding pathways (gold) from the spawn (blue) to the HQ (purple).
          </p>
          <div className="ga-grid-container" style={{ display: "flex", justifyContent: "center" }}>
            <div
              style={{
                display: "grid",
                gridTemplateColumns: "repeat(8, 1fr)",
                gap: "2px",
                width: "320px",
                height: "320px",
                background: "rgba(0, 0, 0, 0.3)",
                border: "2px solid var(--border-color)",
                borderRadius: "4px",
                padding: "2px",
              }}
            >
              {grid.map((cell) => (
                <div key={cell.row + "-" + cell.col} className={gaCellClass(cell)}>
                  {gaCellIcon(cell)}
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
