import { useState } from "react";

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
