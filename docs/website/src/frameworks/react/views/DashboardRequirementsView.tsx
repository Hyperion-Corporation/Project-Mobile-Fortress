/**
 * DashboardRequirementsView — ID1 (internal_dashboard.md §Part A)
 *
 * Static requirements page for the developer dashboard. Defines which game/product
 * metrics matter first for a 3-human team, the run history data schema, and the
 * scope boundary (no live telemetry until backend.md B7 exists).
 *
 * Route: /dashboard/requirements
 * Status: ID1 — In Progress (🚧)
 */
import { useState } from "react";
import type React from "react";

// ── Slice-0 run history schema (offline JSON from OfflinePersistence) ─────────

interface RunRecord {
  run_id: string;
  victory: boolean;
  reason: "hq_destroyed" | "all_waves_cleared" | "quit";
  duration_s: number;
  primary_civ: string;
  support_civ: string;
  wave_reached: number;
  hq_hp_remaining: number;
  smoke_ci_status?: "pass" | "fail" | "skipped";
}

const EXAMPLE_RUNS: RunRecord[] = [
  {
    run_id: "2026-08-11T14:22:00Z",
    victory: true,
    reason: "all_waves_cleared",
    duration_s: 487,
    primary_civ: "Ming",
    support_civ: "Portuguese",
    wave_reached: 5,
    hq_hp_remaining: 62,
    smoke_ci_status: "pass",
  },
  {
    run_id: "2026-08-11T15:01:00Z",
    victory: false,
    reason: "hq_destroyed",
    duration_s: 312,
    primary_civ: "Ming",
    support_civ: "Portuguese",
    wave_reached: 3,
    hq_hp_remaining: 0,
    smoke_ci_status: "pass",
  },
  {
    run_id: "2026-08-12T09:14:00Z",
    victory: true,
    reason: "all_waves_cleared",
    duration_s: 523,
    primary_civ: "Ming",
    support_civ: "Portuguese",
    wave_reached: 5,
    hq_hp_remaining: 45,
    smoke_ci_status: "pass",
  },
];

// ── Metric categories ─────────────────────────────────────────────────────────

interface MetricRow {
  id: string;
  name: string;
  source: string;
  priority: "P0" | "P1" | "P2";
  status: "static-local" | "requires-backend" | "research";
  notes: string;
}

const METRICS: MetricRow[] = [
  {
    id: "M1",
    name: "Playtest session notes",
    source: "Manual collaborator entry (markdown/JSON)",
    priority: "P0",
    status: "static-local",
    notes: "Three humans; async notes committed to repo. Dashboard reads from a static JSON file.",
  },
  {
    id: "M2",
    name: "Smoke / CI status",
    source: "GitHub Actions — ci.yml workflow badge + run logs",
    priority: "P0",
    status: "static-local",
    notes: "Badge already live. Dashboard can embed or link the Actions summary via static fetch at build time.",
  },
  {
    id: "M3",
    name: "Slice-0 run history",
    source: "OfflinePersistence — user://last_run_results.json (exported via script)",
    priority: "P0",
    status: "static-local",
    notes: "Schema defined on this page. Devs export a JSON batch after playtesting; dashboard reads it statically.",
  },
  {
    id: "M4",
    name: "Wave survival rate",
    source: "Derived from run history (wave_reached / total_waves)",
    priority: "P1",
    status: "static-local",
    notes: "Computed client-side from M3 batch data; no backend needed.",
  },
  {
    id: "M5",
    name: "Session duration distribution",
    source: "Derived from run history (duration_s)",
    priority: "P1",
    status: "static-local",
    notes: "Shows whether runs feel too short/long — key for Slice-0 fun gate.",
  },
  {
    id: "M6",
    name: "HQ HP at session end",
    source: "Derived from run history (hq_hp_remaining)",
    priority: "P1",
    status: "static-local",
    notes: "Proxy for difficulty balance; histogram useful before numerical DDA.",
  },
  {
    id: "M7",
    name: "Retention / return rate",
    source: "Live telemetry — requires backend B7",
    priority: "P2",
    status: "requires-backend",
    notes: "Out of scope until backend.md B7 (Leaderboards REST API) ships.",
  },
  {
    id: "M8",
    name: "Monetization conversion (cosmetics)",
    source: "Live telemetry — requires backend B7",
    priority: "P2",
    status: "requires-backend",
    notes: "Deferred — no shop UI in Slice-0.",
  },
  {
    id: "M9",
    name: "Community sentiment (Reddit/X)",
    source: "Scraper — ID10 research backlog",
    priority: "P2",
    status: "research",
    notes: "Research only; ToS and data-retention review required before commitment.",
  },
];

const PRIORITY_COLOR: Record<MetricRow["priority"], string> = {
  P0: "var(--accent-gold)",
  P1: "var(--accent-2)",
  P2: "var(--text-muted)",
};

const STATUS_BADGE: Record<MetricRow["status"], { label: string; color: string }> = {
  "static-local":     { label: "Static / local", color: "#3ca67a" },
  "requires-backend": { label: "Needs backend",  color: "#e07b3a" },
  research:           { label: "Research",        color: "#7a7aaa" },
};

// ── Shared styles ─────────────────────────────────────────────────────────────

const thStyle: React.CSSProperties = {
  textAlign: "left",
  padding: "0.55rem 0.85rem",
  fontSize: "0.78rem",
  fontWeight: 700,
  color: "var(--text-muted)",
  textTransform: "uppercase",
  letterSpacing: "0.05em",
  whiteSpace: "nowrap",
};

const tdStyle: React.CSSProperties = {
  padding: "0.55rem 0.85rem",
  verticalAlign: "top",
};

// ── Component ─────────────────────────────────────────────────────────────────

export default function DashboardRequirementsView() {
  const [activeSection, setActiveSection] = useState<"metrics" | "schema" | "scope">("metrics");

  const p0 = METRICS.filter((m) => m.priority === "P0");
  const p1 = METRICS.filter((m) => m.priority === "P1");
  const p2 = METRICS.filter((m) => m.priority === "P2");

  return (
    <div className="dashboard-req-view" style={{ padding: "2rem 0" }}>

      {/* ── Header ── */}
      <div className="panel glass" style={{ marginBottom: "1.5rem" }}>
        <div style={{ display: "flex", alignItems: "baseline", gap: "0.75rem", flexWrap: "wrap" }}>
          <h1 style={{ margin: 0, fontSize: "1.5rem" }}>📊 Dashboard Requirements</h1>
          <span
            style={{
              fontSize: "0.75rem",
              fontWeight: 700,
              color: "var(--accent-gold)",
              background: "rgba(200,160,60,0.12)",
              borderRadius: "4px",
              padding: "2px 8px",
              letterSpacing: "0.04em",
            }}
          >
            ID1 — 🚧 In Progress
          </span>
        </div>
        <p style={{ marginTop: "0.75rem", color: "var(--text-muted)", fontSize: "0.9rem" }}>
          Defines which game/product metrics matter first for a <strong>3-human team</strong> (owner + 2
          collaborators). Scope: <strong>static / local / batch</strong> — no live telemetry ingestion until{" "}
          <code>backend.md B7</code> (Leaderboards REST API) exists. Roadmap source:{" "}
          <code>docs/moon/roadmaps/internal_dashboard.md</code> §ID1.
        </p>
        <div style={{ display: "flex", gap: "0.5rem", flexWrap: "wrap", marginTop: "0.5rem" }}>
          {(["metrics", "schema", "scope"] as const).map((s) => (
            <button
              key={s}
              id={`dash-req-tab-${s}`}
              className={`btn btn-sm${activeSection === s ? " btn-primary" : " btn-secondary"}`}
              onClick={() => setActiveSection(s)}
            >
              {s === "metrics" && "📋 Metric Priorities"}
              {s === "schema"  && "📄 Run History Schema"}
              {s === "scope"   && "🚧 Scope & Sequence"}
            </button>
          ))}
        </div>
      </div>

      {/* ── Metrics ── */}
      {activeSection === "metrics" && (
        <div>
          <p style={{ color: "var(--text-muted)", fontSize: "0.88rem", marginBottom: "1.25rem" }}>
            <strong>P0</strong> — needed for VS10 playtest gate &middot;{" "}
            <strong>P1</strong> — useful once runs accumulate &middot;{" "}
            <strong>P2</strong> — deferred until backend or research commitment
          </p>

          {([
            { label: "P0 — Playtest Gate (static/local)", rows: p0 },
            { label: "P1 — Polish Signal (static/local)", rows: p1 },
            { label: "P2 — Deferred / Research",          rows: p2 },
          ] as const).map(({ label, rows }) => (
            <div key={label} style={{ marginBottom: "1.5rem" }}>
              <h3
                style={{
                  fontSize: "0.85rem",
                  fontWeight: 700,
                  color: "var(--text-muted)",
                  textTransform: "uppercase",
                  letterSpacing: "0.06em",
                  marginBottom: "0.5rem",
                }}
              >
                {label}
              </h3>
              <div className="panel glass" style={{ padding: 0, overflow: "hidden" }}>
                <table style={{ width: "100%", borderCollapse: "collapse", fontSize: "0.87rem" }}>
                  <thead>
                    <tr style={{ background: "rgba(0,0,0,0.2)" }}>
                      <th style={thStyle}>ID</th>
                      <th style={thStyle}>Metric</th>
                      <th style={thStyle}>Source</th>
                      <th style={thStyle}>Status</th>
                      <th style={thStyle}>Notes</th>
                    </tr>
                  </thead>
                  <tbody>
                    {rows.map((m) => (
                      <tr key={m.id} style={{ borderTop: "1px solid var(--border-color)" }}>
                        <td style={{ ...tdStyle, color: PRIORITY_COLOR[m.priority], fontWeight: 700 }}>{m.id}</td>
                        <td style={{ ...tdStyle, fontWeight: 600 }}>{m.name}</td>
                        <td style={{ ...tdStyle, color: "var(--text-muted)" }}>{m.source}</td>
                        <td style={tdStyle}>
                          <span
                            style={{
                              fontSize: "0.75rem",
                              fontWeight: 700,
                              color: STATUS_BADGE[m.status].color,
                              background: STATUS_BADGE[m.status].color + "22",
                              borderRadius: "4px",
                              padding: "2px 7px",
                              whiteSpace: "nowrap",
                            }}
                          >
                            {STATUS_BADGE[m.status].label}
                          </span>
                        </td>
                        <td style={{ ...tdStyle, color: "var(--text-muted)" }}>{m.notes}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* ── Schema ── */}
      {activeSection === "schema" && (
        <div>
          <div className="panel glass" style={{ marginBottom: "1.25rem" }}>
            <h2 style={{ marginTop: 0, fontSize: "1.1rem" }}>Slice-0 Run History Schema</h2>
            <p style={{ color: "var(--text-muted)", fontSize: "0.88rem" }}>
              Written by <code>OfflinePersistence</code> to <code>user://last_run_results.json</code> at
              session end. Devs export a batch JSON array after playtesting; the dashboard reads it
              statically. Schema source: <code>core/scripts/game_session.gd</code>.
            </p>
            <pre
              style={{
                background: "rgba(0,0,0,0.35)",
                borderRadius: "6px",
                padding: "1rem",
                fontSize: "0.82rem",
                overflowX: "auto",
                color: "var(--text)",
                lineHeight: 1.6,
              }}
            >{`// RunRecord — one entry per completed or quit session
{
  "run_id":           string,   // ISO-8601 UTC timestamp (unique key)
  "victory":          boolean,
  "reason":           "hq_destroyed" | "all_waves_cleared" | "quit",
  "duration_s":       number,   // wall-clock seconds
  "primary_civ":      string,   // "Ming" | future civs
  "support_civ":      string,   // "Portuguese" | alternates
  "wave_reached":     number,   // last wave index that started combat
  "hq_hp_remaining":  number,   // 0–100
  "smoke_ci_status":  "pass" | "fail" | "skipped"  // optional
}`}</pre>
          </div>

          <div className="panel glass">
            <h3 style={{ marginTop: 0, fontSize: "1rem" }}>Example batch (3 runs)</h3>
            <div style={{ display: "grid", gap: "0.75rem" }}>
              {EXAMPLE_RUNS.map((run) => (
                <div
                  key={run.run_id}
                  className="panel-dark"
                  style={{
                    borderRadius: "6px",
                    padding: "0.75rem 1rem",
                    display: "grid",
                    gridTemplateColumns: "repeat(auto-fill, minmax(160px, 1fr))",
                    gap: "0.4rem 1.25rem",
                    fontSize: "0.82rem",
                  }}
                >
                  {(Object.entries(run) as [keyof RunRecord, RunRecord[keyof RunRecord]][]).map(([k, v]) => (
                    <div key={k}>
                      <span style={{ color: "var(--text-muted)", marginRight: "0.3rem" }}>{k}:</span>
                      <span
                        style={{
                          fontWeight: 600,
                          color:
                            k === "victory"
                              ? v ? "#3ca67a" : "#e05a5a"
                              : k === "smoke_ci_status"
                              ? v === "pass" ? "#3ca67a" : "var(--accent-gold)"
                              : "var(--text)",
                        }}
                      >
                        {String(v)}
                      </span>
                    </div>
                  ))}
                </div>
              ))}
            </div>
          </div>
        </div>
      )}

      {/* ── Scope & Sequence ── */}
      {activeSection === "scope" && (
        <div>
          <div className="panel glass" style={{ marginBottom: "1.25rem" }}>
            <h2 style={{ marginTop: 0, fontSize: "1.1rem" }}>Scope Boundary & Sequence</h2>
            <p style={{ color: "var(--text-muted)", fontSize: "0.88rem" }}>
              Per <code>ROADMAP.md</code> §Phase 7 and <code>internal_dashboard.md</code> §ID-G1: dashboard
              UI code (ID3) may not land until these requirements (ID1) and IA/wireframes (ID2) are signed
              off. ID4 backend wiring waits for <code>backend.md B7</code>.
            </p>
          </div>

          {[
            {
              id: "ID1", label: "Requirements (this page)", status: "🚧 In Progress", color: "#e0a030",
              note: "Define P0–P2 metrics + run history schema for a 3-human team. Done when this page is committed.",
            },
            {
              id: "ID2", label: "IA & wireframes", status: "📋 Pending", color: "var(--text-muted)",
              note: "Information architecture + wireframes for the dashboard surface in the React host. Depends on ID1.",
            },
            {
              id: "ID3", label: "Dashboard skeleton", status: "📋 Pending", color: "var(--text-muted)",
              note: "New React view rendering P0 metrics from static batch JSON. Depends on ID1 + ID2 + MFP1–MFP3.",
            },
            {
              id: "ID4", label: "Backend wiring", status: "⏸ Blocked", color: "#7a7aaa",
              note: "Wire to a real analytics API. Blocked on backend.md B7 (Leaderboards REST API).",
            },
            {
              id: "ID5", label: "Real-time WebSocket", status: "❌ Rejected for v1", color: "#cc4444",
              note: "Polling/batch refresh is sufficient until a demonstrated sub-minute need exists.",
            },
          ].map((row) => (
            <div
              key={row.id}
              className="panel glass"
              style={{ marginBottom: "0.75rem", display: "flex", gap: "1rem", alignItems: "flex-start" }}
            >
              <div style={{ minWidth: "40px", fontWeight: 700, fontSize: "0.9rem", color: row.color, paddingTop: "0.1rem" }}>
                {row.id}
              </div>
              <div style={{ flex: 1 }}>
                <div style={{ display: "flex", gap: "0.5rem", alignItems: "center", flexWrap: "wrap" }}>
                  <strong style={{ fontSize: "0.95rem" }}>{row.label}</strong>
                  <span style={{ fontSize: "0.8rem", color: row.color }}>{row.status}</span>
                </div>
                <p style={{ margin: "0.25rem 0 0", fontSize: "0.85rem", color: "var(--text-muted)" }}>{row.note}</p>
              </div>
            </div>
          ))}

          <div
            className="panel-dark"
            style={{ borderRadius: "6px", padding: "0.85rem 1rem", fontSize: "0.83rem", color: "var(--text-muted)", marginTop: "0.5rem" }}
          >
            <strong>Out of scope (T14):</strong> ID6 lore map, ID7 3D viewer, ID8 interactive demos, ID9/ID10
            review ingestion, ID11 ML signal surface, WASM MFP12–14, live remote hosting, game HUD. See{" "}
            <code>docs/moon/roadmaps/internal_dashboard.md</code> for the full deliverable index.
          </div>
        </div>
      )}
    </div>
  );
}
