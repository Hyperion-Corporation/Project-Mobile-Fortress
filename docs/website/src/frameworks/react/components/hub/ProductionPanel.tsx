import { useState } from "react";

interface Sprint {
  title: string;
  timeline: string;
  goals: string[];
  deps: string;
}

const sprints: Record<number, Sprint> = {
  1: {
    title: "Slice-0 / Phase 1a: Dual-Front Prototype",
    timeline: "2026-08-11 (complete)",
    goals: [
      "Godot 4.7 project as primary game client (VS0 ✅).",
      "Dual land/sea GridFront core loop with C++ SimulationCore via GDExtension (VS1–VS5 ✅).",
      "Ukiyo-e-readable art palette + isometric tile atlas; offline save/load via FlatBuffers (VS7–VS8 ✅).",
      "Android debug APK export smoke; iOS export needs macOS host (VS9 ✅).",
    ],
    deps: "Godot 4.7 + CMake + godot-cpp installed locally.",
  },
  2: {
    title: "Phase 1: Single-Player Polish (G3+, economy, heroes)",
    timeline: "After VS10 playtest gate",
    goals: [
      "Flow-Field pathfinding depth replacing lane-waypoint stub (G3/S2).",
      "Turret upgrades, hero active ability polish, cross-front synergy tuning.",
      "Full HUD pass: wave counter, outpost HP strip, phase label legibility.",
    ],
    deps: "VS10 'shows promise' decision record from collaborator playtest.",
  },
  3: {
    title: "Phase 3/4: Cosmetics + Local Co-Op",
    timeline: "After Phase 1 fun gate",
    goals: [
      "Cosmetic skin lootbox UI (probability disclosure) — no gameplay power gacha.",
      "Asymmetric local Wi-Fi co-op: land player + sea player split.",
      "Clan/alliance UI: roster, contribution board.",
    ],
    deps: "Cosmetics track M1–M3 and co-op design doc sign-off.",
  },
  4: {
    title: "Phase 5+: ML & Dashboard (gated research)",
    timeline: "Post-launch / research track",
    goals: [
      "RL dynamic difficulty adjustment (DDA) A/B tested behind a flag.",
      "Swarm/evolutionary pathing experiments (A11).",
      "Internal developer dashboard (ID1 requirements → ID3 skeleton → ID4 backend, gated on Phase 7).",
    ],
    deps: "Live telemetry backend (backend.md B7) + named use-case for each ML system.",
  },
};

export default function ProductionPanel() {
  const [selected, setSelected] = useState(1);
  const current = sprints[selected];

  return (
    <div className="tab-pane active" id="tab-production">
      <div className="panel glass">
        <h2>Development Sprints &amp; Technical Pipelines</h2>
        <p className="panel-desc" style={{ marginBottom: "2rem" }}>
          Click on any sprint milestone below to view deliverables, active checklists, and technical dependencies.
        </p>

        <div className="sprints-interactive-grid">
          <div className="sprint-header-buttons">
            {Object.entries(sprints).map(([id, s]) => (
              <button
                key={id}
                className={`sprint-nav-btn${selected === Number(id) ? " active" : ""}`}
                onClick={() => setSelected(Number(id))}
              >
                {s.title}
              </button>
            ))}
          </div>

          <div className="sprint-display-panel panel-dark" key={selected}>
            <h4 style={{ color: "var(--accent-gold)", marginBottom: "0.3rem" }}>{current.title}</h4>
            <span
              style={{
                fontSize: "0.8rem",
                color: "var(--accent-2)",
                fontWeight: "bold",
                display: "block",
                marginBottom: "0.8rem",
              }}
            >
              {current.timeline}
            </span>
            <strong style={{ fontSize: "0.85rem", color: "var(--text)" }}>Sprint Deliverables Checklist:</strong>
            <ul className="roadmap-list">
              {current.goals.map((g, i) => (
                <li key={i}>{g}</li>
              ))}
            </ul>
            <div
              style={{
                marginTop: "1rem",
                borderTop: "1px solid var(--border-color)",
                paddingTop: "0.8rem",
                fontSize: "0.8rem",
                color: "var(--text-muted)",
              }}
            >
              <strong>Technical Dependencies:</strong> {current.deps}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
