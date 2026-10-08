/**
 * DualFrontDemoView — /dashboard/demo — ID8: Interactive dual-front placement-and-raid demo.
 *
 * Two grids (land + sea). Player places defenders with a budget, presses Start,
 * raiders walk in along a path and are shot by placed defenders.
 * Win if all raiders die; lose if HQ HP reaches 0.
 */
import { useState, useCallback, useEffect, useRef } from "react";
import { Link } from "react-router-dom";
import {
  createState,
  placeUnit,
  removeUnit,
  startRun,
  tick,
  runToEnd,
  canPlace,
  getUnitDef,
  DEFAULT_CONFIG,
  type SimState,
  type Front,
  type DemoConfig,
  type PlacedUnit,
  type Raider,
} from "../../../simulations/dualFrontDemo";

const TICK_MS = 100;
const CONFIG = DEFAULT_CONFIG;

const prefersReducedMotion = (): boolean =>
  typeof window !== "undefined" &&
  typeof window.matchMedia === "function" &&
  window.matchMedia("(prefers-reduced-motion: reduce)").matches;

export default function DualFrontDemoView() {
  const [state, setState] = useState<SimState>(() => createState(CONFIG));
  const [selectedUnit, setSelectedUnit] = useState<string>("spearman");
  const [running, setRunning] = useState(false);
  const timerRef = useRef<ReturnType<typeof setInterval> | null>(null);
  const [reducedMotion, setReducedMotion] = useState(false);

  useEffect(() => {
    setReducedMotion(prefersReducedMotion());
    if (typeof window.matchMedia !== "function") return;
    const mq = window.matchMedia("(prefers-reduced-motion: reduce)");
    const handler = () => setReducedMotion(mq.matches);
    mq.addEventListener("change", handler);
    return () => mq.removeEventListener("change", handler);
  }, []);

  const stopTimer = useCallback(() => {
    if (timerRef.current !== null) {
      clearInterval(timerRef.current);
      timerRef.current = null;
    }
    setRunning(false);
  }, []);

  useEffect(() => {
    return () => {
      if (timerRef.current !== null) clearInterval(timerRef.current);
    };
  }, []);

  const handleCellClick = useCallback(
    (front: Front, col: number, row: number) => {
      if (state.phase !== "placing") return;
      setState((prev) => {
        const existing = (front === "land" ? prev.landUnits : prev.seaUnits).find(
          (u) => u.col === col && u.row === row,
        );
        if (existing) return removeUnit(prev, existing.uid, CONFIG);
        return placeUnit(prev, selectedUnit, col, row, front, CONFIG);
      });
    },
    [state.phase, selectedUnit],
  );

  const handleStart = useCallback(() => {
    setState((prev) => {
      if (prev.phase !== "placing") return prev;
      const next = startRun(prev);
      return next;
    });
    setRunning(true);
  }, []);

  useEffect(() => {
    if (!running || state.phase !== "running") {
      if (state.phase !== "running") stopTimer();
      return;
    }

    if (reducedMotion) {
      const final = runToEnd(state, CONFIG, 500);
      setState(final);
      stopTimer();
      return;
    }

    timerRef.current = setInterval(() => {
      setState((prev) => {
        if (prev.phase !== "running") return prev;
        return tick(prev, CONFIG);
      });
    }, TICK_MS);

    return () => {
      if (timerRef.current !== null) {
        clearInterval(timerRef.current);
        timerRef.current = null;
      }
    };
  }, [running, state.phase, reducedMotion, stopTimer]);

  const handleReset = useCallback(() => {
    stopTimer();
    setState(createState(CONFIG));
    setSelectedUnit("spearman");
  }, [stopTimer]);

  const handleSkipToEnd = useCallback(() => {
    stopTimer();
    setState((prev) => {
      if (prev.phase !== "running") return prev;
      return runToEnd(prev, CONFIG, 500);
    });
  }, [stopTimer]);

  const landUnits = state.landUnits;
  const seaUnits = state.seaUnits;
  const landRaiders = state.raiders.filter((r) => r.front === "land" && r.alive && r.hp > 0);
  const seaRaiders = state.raiders.filter((r) => r.front === "sea" && r.alive && r.hp > 0);

  const phaseLabel =
    state.phase === "placing"
      ? "🔨 Placement Phase"
      : state.phase === "running"
        ? "⚔️ Combat"
        : state.phase === "win"
          ? "🏆 Victory!"
          : "💀 Defeat";

  const phaseColor =
    state.phase === "win"
      ? "var(--accent-gold)"
      : state.phase === "lose"
        ? "#c23b22"
        : "var(--text-muted)";

  return (
    <div className="dashboard-req-view" style={{ padding: "2rem 0" }}>
      {/* Header */}
      <div className="panel glass" style={{ marginBottom: "1.5rem" }}>
        <div style={{ display: "flex", alignItems: "baseline", gap: "0.75rem", flexWrap: "wrap" }}>
          <h1 style={{ margin: 0, fontSize: "1.5rem" }}>⚔️ Dual-Front Demo</h1>
          <span style={badgeStyle("var(--accent-gold)", "rgba(200,160,60,0.12)")}>
            ID8 · Interactive
          </span>
          <span style={{ fontSize: "0.88rem", color: phaseColor, fontWeight: 700 }}>
            {phaseLabel}
          </span>
        </div>
        <p style={{ marginTop: "0.6rem", color: "var(--text-muted)", fontSize: "0.88rem" }}>
          Place defenders on the land and sea grids, then start the raid. Defenders auto-fire at
          raiders in range. Protect the HQ!
        </p>
        <div style={{ display: "flex", gap: "1rem", marginTop: "0.75rem", borderTop: "1px solid rgba(255,255,255,0.08)", paddingTop: "0.75rem", flexWrap: "wrap" }}>
          <Link to="/dashboard" style={{ color: "var(--text-muted)", fontSize: "0.83rem", textDecoration: "none" }}>📊 Overview</Link>
          <Link to="/dashboard/lore-map" style={{ color: "var(--text-muted)", fontSize: "0.83rem", textDecoration: "none" }}>🗺️ Lore Map</Link>
          <Link to="/dashboard/visualizer" style={{ color: "var(--text-muted)", fontSize: "0.83rem", textDecoration: "none" }}>🎭 Unit Visualizer</Link>
          <span style={{ color: "var(--accent-gold)", fontSize: "0.83rem", fontWeight: 700 }}>⚔️ Demo</span>
        </div>
      </div>

      {/* Status bar */}
      <div className="panel glass" style={{ marginBottom: "1rem", display: "flex", gap: "1.5rem", flexWrap: "wrap", alignItems: "center", padding: "0.75rem 1.25rem" }}>
        <span style={{ fontSize: "0.85rem" }}>
          🏯 HQ: <strong style={{ color: state.hqHp < state.maxHqHp * 0.3 ? "#c23b22" : "var(--accent-gold)" }}>{state.hqHp}</strong>/{state.maxHqHp}
        </span>
        <span style={{ fontSize: "0.85rem" }}>
          🟫 Land 兩: <strong>{state.landBudget}</strong>
        </span>
        <span style={{ fontSize: "0.85rem" }}>
          🌊 Sea 兩: <strong>{state.seaBudget}</strong>
        </span>
        {state.phase === "running" && (
          <span style={{ fontSize: "0.85rem" }}>
            Tick: <strong>{state.tick}</strong>
          </span>
        )}
      </div>

      {/* Grids */}
      <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(280px, 1fr))", gap: "1rem", marginBottom: "1rem" }}>
        <FrontGrid
          title="🟫 Land Front"
          front="land"
          config={CONFIG}
          units={landUnits}
          raiders={landRaiders}
          phase={state.phase}
          onCellClick={handleCellClick}
          selectedUnit={selectedUnit}
          state={state}
        />
        <FrontGrid
          title="🌊 Sea Front"
          front="sea"
          config={CONFIG}
          units={seaUnits}
          raiders={seaRaiders}
          phase={state.phase}
          onCellClick={handleCellClick}
          selectedUnit={selectedUnit}
          state={state}
        />
      </div>

      {/* Controls */}
      <div className="panel glass" style={{ padding: "1rem 1.25rem", marginBottom: "1rem" }}>
        <div style={{ display: "flex", gap: "0.75rem", flexWrap: "wrap", alignItems: "center" }}>
          {state.phase === "placing" && (
            <>
              <span style={{ fontSize: "0.85rem", color: "var(--text-muted)" }}>Select unit:</span>
              {CONFIG.unitDefs.map((def) => {
                const budget = def.front === "land" ? state.landBudget : state.seaBudget;
                const affordable = def.cost <= budget;
                return (
                  <button
                    key={def.id}
                    onClick={() => setSelectedUnit(def.id)}
                    className="btn btn-sm"
                    style={{
                      background: selectedUnit === def.id ? "var(--accent-gold)" : "rgba(255,255,255,0.06)",
                      color: selectedUnit === def.id ? "#1a1a2e" : affordable ? "var(--text)" : "var(--text-muted)",
                      border: `1px solid ${selectedUnit === def.id ? "var(--accent-gold)" : "rgba(255,255,255,0.12)"}`,
                      opacity: affordable ? 1 : 0.5,
                      cursor: affordable ? "pointer" : "not-allowed",
                      fontSize: "0.8rem",
                      padding: "0.3rem 0.6rem",
                      borderRadius: "4px",
                    }}
                    disabled={!affordable}
                    aria-pressed={selectedUnit === def.id}
                    title={`${def.name} — Cost: ${def.cost}, Dmg: ${def.damage}, Range: ${def.range}`}
                  >
                    {def.name.split(" ").slice(-1)[0]} ({def.cost}兩)
                  </button>
                );
              })}
            </>
          )}
          <div style={{ marginLeft: "auto", display: "flex", gap: "0.5rem" }}>
            {state.phase === "placing" && (
              <button className="btn btn-primary btn-sm" onClick={handleStart} style={{ fontSize: "0.85rem" }}>
                ▶ Start Raid
              </button>
            )}
            {state.phase === "running" && (
              <button className="btn btn-sm" onClick={handleSkipToEnd} style={{ fontSize: "0.85rem", background: "rgba(255,255,255,0.06)", color: "var(--text)", border: "1px solid rgba(255,255,255,0.12)", borderRadius: "4px", padding: "0.3rem 0.6rem" }}>
                ⏩ Skip
              </button>
            )}
            {(state.phase === "win" || state.phase === "lose") && (
              <button className="btn btn-primary btn-sm" onClick={handleReset} style={{ fontSize: "0.85rem" }}>
                🔄 Play Again
              </button>
            )}
            {state.phase !== "placing" && state.phase !== "running" && (
              <button className="btn btn-sm" onClick={handleReset} style={{ fontSize: "0.85rem", background: "rgba(255,255,255,0.06)", color: "var(--text)", border: "1px solid rgba(255,255,255,0.12)", borderRadius: "4px", padding: "0.3rem 0.6rem" }}>
                🔄 Reset
              </button>
            )}
          </div>
        </div>
      </div>

      {/* Result overlay */}
      {(state.phase === "win" || state.phase === "lose") && (
        <div
          className="panel glass"
          style={{
            padding: "1.5rem",
            textAlign: "center",
            borderColor: state.phase === "win" ? "var(--accent-gold)" : "#c23b22",
            borderWidth: "2px",
            borderStyle: "solid",
          }}
          role="status"
          aria-live="polite"
        >
          <h2 style={{ margin: "0 0 0.5rem", color: state.phase === "win" ? "var(--accent-gold)" : "#c23b22" }}>
            {state.phase === "win" ? "🏆 Victory!" : "💀 Defeat"}
          </h2>
          <p style={{ margin: 0, color: "var(--text-muted)", fontSize: "0.9rem" }}>
            {state.phase === "win"
              ? `All raiders defeated in ${state.tick} ticks. HQ HP: ${state.hqHp}/${state.maxHqHp}`
              : `HQ destroyed at tick ${state.tick}. Some raiders got through.`}
          </p>
        </div>
      )}

      {/* Instructions */}
      {state.phase === "placing" && (
        <div className="panel glass" style={{ padding: "1rem 1.25rem", marginTop: "1rem" }}>
          <h3 style={{ margin: "0 0 0.5rem", fontSize: "0.95rem" }}>How to play</h3>
          <ol style={{ margin: 0, paddingLeft: "1.25rem", color: "var(--text-muted)", fontSize: "0.85rem", lineHeight: 1.6 }}>
            <li>Select a unit type from the palette above</li>
            <li>Click cells on the <strong>top or bottom row</strong> of each grid to place defenders</li>
            <li>Click a placed unit to remove it (refund cost)</li>
            <li>Press <strong>▶ Start Raid</strong> — raiders advance along the middle row</li>
            <li>Defenders auto-fire at raiders within range. Protect the HQ!</li>
          </ol>
          <p style={{ margin: "0.5rem 0 0", color: "var(--text-muted)", fontSize: "0.8rem" }}>
            Keyboard: Tab to cells, Enter/Space to place or remove. Units mirror the game&apos;s real roster (unit_defs.gd).
          </p>
        </div>
      )}
    </div>
  );
}

// ── Grid sub-component ───────────────────────────────────────────────────────

interface FrontGridProps {
  title: string;
  front: Front;
  config: DemoConfig;
  units: PlacedUnit[];
  raiders: Raider[];
  phase: SimState["phase"];
  onCellClick: (front: Front, col: number, row: number) => void;
  selectedUnit: string;
  state: SimState;
}

function FrontGrid({ title, front, config, units, raiders, phase, onCellClick, selectedUnit, state }: FrontGridProps) {
  const cells: React.ReactNode[] = [];

  for (let row = 0; row < config.rows; row++) {
    for (let col = 0; col < config.cols; col++) {
      const isPath = row === config.pathRow;
      const unit = units.find((u) => u.col === col && u.row === row);
      const raider = raiders.find(
        (r) => r.front === front && Math.floor(r.col) === col && Math.abs(r.col - col) < 0.99,
      );
      const isHq = col === config.cols - 1 && isPath;
      const canPlaceHere = phase === "placing" && !isPath && !unit;
      const placementErr = canPlaceHere ? canPlace(state, selectedUnit, col, row, front, config) : null;
      const isValidPlacement = canPlaceHere && placementErr === null;

      let bg = "rgba(255,255,255,0.03)";
      let content: React.ReactNode = null;
      let ariaLabel = `${front} grid, column ${col + 1}, row ${row + 1}`;

      if (isHq) {
        bg = "rgba(201,162,39,0.2)";
        content = <span style={{ fontSize: "1.1rem" }}>🏯</span>;
        ariaLabel += ", HQ";
      } else if (isPath) {
        bg = "rgba(255,255,255,0.06)";
        ariaLabel += ", raider path";
      }

      if (unit) {
        const def = getUnitDef(unit.defId, config)!;
        const hpPct = unit.hp / unit.maxHp;
        bg = front === "land" ? "rgba(194,59,34,0.25)" : "rgba(61,90,128,0.3)";
        content = (
          <div style={{ textAlign: "center", lineHeight: 1.1 }}>
            <div style={{ fontSize: "0.9rem" }}>{front === "land" ? "🛡️" : "⚓"}</div>
            <div style={{ fontSize: "0.55rem", color: "var(--text-muted)", overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap", maxWidth: "100%" }}>
              {def.name.split(" ").slice(-1)[0]}
            </div>
            {hpPct < 1 && (
              <div style={{ height: "2px", background: "rgba(255,255,255,0.15)", borderRadius: "1px", marginTop: "1px" }}>
                <div style={{ height: "100%", width: `${hpPct * 100}%`, background: hpPct > 0.5 ? "#6b8f71" : "#c23b22", borderRadius: "1px" }} />
              </div>
            )}
          </div>
        );
        ariaLabel += `, ${def.name}, HP ${unit.hp}/${unit.maxHp}`;
      }

      if (raider) {
        const hpPct = raider.hp / raider.maxHp;
        bg = "rgba(43,43,43,0.4)";
        content = (
          <div style={{ textAlign: "center", lineHeight: 1.1 }}>
            <div style={{ fontSize: "0.9rem" }}>{front === "land" ? "👹" : "🏴‍☠️"}</div>
            {hpPct < 1 && (
              <div style={{ height: "2px", background: "rgba(255,255,255,0.15)", borderRadius: "1px", marginTop: "1px" }}>
                <div style={{ height: "100%", width: `${hpPct * 100}%`, background: "#c23b22", borderRadius: "1px" }} />
              </div>
            )}
          </div>
        );
        ariaLabel += `, raider, HP ${raider.hp}/${raider.maxHp}`;
      }

      if (isValidPlacement && !unit && !raider) {
        bg = "rgba(107,143,113,0.12)";
      }

      cells.push(
        <button
          key={`${row}-${col}`}
          onClick={() => onCellClick(front, col, row)}
          disabled={phase === "running" || (phase !== "placing")}
          aria-label={ariaLabel}
          style={{
            width: "100%",
            aspectRatio: "1",
            background: bg,
            border: `1px solid ${isValidPlacement ? "rgba(107,143,113,0.3)" : "rgba(255,255,255,0.08)"}`,
            borderRadius: "4px",
            cursor: phase === "placing" && (canPlaceHere || unit) ? "pointer" : "default",
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            padding: "2px",
            minHeight: "44px",
            position: "relative",
            transition: "background 0.15s",
          }}
          className="demo-grid-cell"
        >
          {content}
        </button>,
      );
    }
  }

  return (
    <div className="panel glass" style={{ padding: "1rem" }}>
      <h3 style={{ margin: "0 0 0.75rem", fontSize: "0.95rem" }}>{title}</h3>
      <div
        style={{
          display: "grid",
          gridTemplateColumns: `repeat(${config.cols}, 1fr)`,
          gap: "3px",
        }}
        role="grid"
        aria-label={`${title} grid`}
      >
        {cells}
      </div>
      <div style={{ marginTop: "0.5rem", display: "flex", gap: "0.75rem", fontSize: "0.75rem", color: "var(--text-muted)" }}>
        <span>← Raiders enter</span>
        <span style={{ marginLeft: "auto" }}>HQ →</span>
      </div>
    </div>
  );
}

// ── Helpers ──────────────────────────────────────────────────────────────────

function badgeStyle(color: string, bg: string): React.CSSProperties {
  return {
    display: "inline-block",
    padding: "0.15rem 0.5rem",
    borderRadius: "999px",
    fontSize: "0.75rem",
    fontWeight: 600,
    color,
    background: bg,
    border: `1px solid ${color}33`,
  };
}
