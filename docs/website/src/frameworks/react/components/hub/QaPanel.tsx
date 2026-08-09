import { useState } from "react";

export default function QaPanel() {
  const [ping, setPing] = useState(50);
  const [loss, setLoss] = useState(0);
  const [jitter, setJitter] = useState(5);

  const drift = ping * 0.05 + loss * 1.2 + jitter * 0.3;
  const desynced = ping > 120 || loss > 2.0 || jitter > 15;
  const logs = desynced
    ? [
        "[SYSTEM] Profiling diagnostics...",
        `[WARNING] Net ping: ${ping}ms exceeds substepping threshold.`,
        `[ERROR] Desync delta: ${drift.toFixed(1)} units. Snap client prediction position.`,
      ]
    : [
        "[SYSTEM] Profiling diagnostics...",
        "[FFI] JNI/Swift-C++-interop byte transfer checks completed.",
        `[SYSTEM] Delta packets: OK. Jitter: ${jitter}ms.`,
      ];

  return (
    <div className="tab-pane active" id="tab-qa">
      <div className="grid-2-col">
        <div className="panel glass">
          <h2>Automated Headless Audits &amp; Diagnostics</h2>
          <p>
            Headless C++ simulation passes run stress tests checking for Behavior Tree coordinate drifts, FFI
            boundary leakages, and network sync bounds.
          </p>
          <div className="panel-dark profile-panel" style={{ marginTop: "1.5rem" }}>
            <h4>Network Latency Profiler</h4>
            <div className="slider-group">
              <label>
                Simulated Latency (Ping): <span>{ping}ms</span>
              </label>
              <input
                type="range"
                min="10"
                max="300"
                value={ping}
                onChange={(e) => setPing(Number(e.target.value))}
                className="slider"
              />
            </div>
            <div className="slider-group">
              <label>
                Packet Loss Ratio: <span>{loss.toFixed(1)}%</span>
              </label>
              <input
                type="range"
                min="0"
                max="100"
                value={loss}
                onChange={(e) => setLoss(Number(e.target.value))}
                className="slider"
              />
            </div>
            <div className="slider-group">
              <label>
                Jitter (ms): <span>{jitter}ms</span>
              </label>
              <input
                type="range"
                min="0"
                max="50"
                value={jitter}
                onChange={(e) => setJitter(Number(e.target.value))}
                className="slider"
              />
            </div>
          </div>
        </div>

        <div className="panel glass flex-center">
          <h3>Replication Parity Dashboard</h3>
          <div className="qa-status-box">
            <div className={`alert-banner${desynced ? " warning" : ""}`}>
              <span>{desynced ? "⚠️ REPLICATION DESYNC DETECTED" : "🟢 REPLICATION SYNCHRONIZED"}</span>
            </div>
            <div className="stat-row" style={{ marginTop: "1rem" }}>
              <span>Sync State:</span> <strong>{desynced ? "Replication Drift" : "Perfect Parity"}</strong>
            </div>
            <div className="stat-row">
              <span>State Coordinates Drift:</span>
              <strong className="highlight" style={{ color: desynced ? "var(--accent)" : "var(--accent-2)" }}>
                {drift.toFixed(1)} units
              </strong>
            </div>
            <div
              className="panel-dark"
              style={{ marginTop: "1rem", fontFamily: "monospace", fontSize: "0.75rem", height: "100px", overflowY: "auto" }}
            >
              {logs.map((l, i) => (
                <div key={i}>{l}</div>
              ))}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
