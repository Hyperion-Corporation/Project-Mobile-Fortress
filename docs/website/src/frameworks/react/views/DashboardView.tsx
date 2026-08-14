/**
 * DashboardView — /dashboard — ID3 skeleton: Overview
 *
 * Gate-status summary, CI summary card, last-run card, and the 5 most
 * recent run-history rows. All data from static /dashboard-data/ JSON.
 */
import { Link } from "react-router-dom";
import {
  useDashboardData,
  winRate,
  avgDuration,
  fmtSeconds,
} from "../../../hooks/useDashboardData";

export default function DashboardView() {
  const { runs, ci, playtest, loading } = useDashboardData();

  const lastRun = runs[runs.length - 1] ?? null;
  const sessionsLogged = playtest?.sessions.length ?? 0;
  const sessionsRequired = playtest?.sessions_required ?? 2;
  const gateDecision = playtest?.gate_decision ?? null;

  const overallCiPass =
    ci?.workflows.every((w) => w.status === "pass") ?? null;

  return (
    <div className="dashboard-req-view" style={{ padding: "2rem 0" }}>
      {/* Header */}
      <div className="panel glass" style={{ marginBottom: "1.5rem" }}>
        <div style={{ display: "flex", alignItems: "baseline", gap: "0.75rem", flexWrap: "wrap" }}>
          <h1 style={{ margin: 0, fontSize: "1.5rem" }}>📊 Dashboard</h1>
          <span style={badgeStyle("var(--accent-gold)", "rgba(200,160,60,0.12)")}>
            Slice-0 · Phase 1a
          </span>
          {loading && <span style={{ fontSize: "0.8rem", color: "var(--text-muted)" }}>Loading…</span>}
        </div>
        <p style={{ marginTop: "0.6rem", color: "var(--text-muted)", fontSize: "0.88rem" }}>
          P0 metrics from committed batch JSON — no live backend required.
        </p>

        {/* Quick Nav Strip */}
        <div style={{ display: "flex", gap: "1rem", marginTop: "0.75rem", borderTop: "1px solid rgba(255,255,255,0.08)", paddingTop: "0.75rem", flexWrap: "wrap" }}>
          <span style={{ color: "var(--accent-gold)", fontSize: "0.83rem", fontWeight: 700 }}>📊 Overview</span>
          <Link to="/dashboard/runs" style={{ color: "var(--text-muted)", fontSize: "0.83rem", textDecoration: "none" }}>📜 Run History</Link>
          <Link to="/dashboard/ci" style={{ color: "var(--text-muted)", fontSize: "0.83rem", textDecoration: "none" }}>⚙️ CI Status</Link>
          <Link to="/dashboard/playtest" style={{ color: "var(--text-muted)", fontSize: "0.83rem", textDecoration: "none" }}>📝 Playtest Notes</Link>
          <Link to="/dashboard/lore-map" style={{ color: "var(--text-muted)", fontSize: "0.83rem", textDecoration: "none" }}>🗺️ Lore Map</Link>
          <Link to="/dashboard/requirements" style={{ color: "var(--text-muted)", fontSize: "0.83rem", textDecoration: "none" }}>📋 Requirements</Link>
        </div>
      </div>

      {/* Gate status + summary cards */}
      <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fill, minmax(210px, 1fr))", gap: "1rem", marginBottom: "1.5rem" }}>
        {/* VS10 gate card */}
        <div className="panel glass" style={{ textAlign: "center" }}>
          <div style={{ fontSize: "0.75rem", fontWeight: 700, color: "var(--text-muted)", textTransform: "uppercase", letterSpacing: "0.06em", marginBottom: "0.5rem" }}>
            VS10 Gate
          </div>
          <div style={{ fontSize: "2rem", lineHeight: 1, marginBottom: "0.35rem" }}>
            {gateDecision === "pass" ? "✅" : sessionsLogged >= sessionsRequired ? "🟡" : "⏳"}
          </div>
          <div style={{ fontWeight: 700, fontSize: "0.95rem" }}>
            {gateDecision === "pass"
              ? "Passed"
              : `${sessionsLogged} / ${sessionsRequired} sessions`}
          </div>
          <div style={{ fontSize: "0.8rem", color: "var(--text-muted)", marginTop: "0.25rem" }}>
            {gateDecision === "pass" ? "Phase 1a complete" : "Awaiting playtest"}
          </div>
        </div>

        {/* CI status card */}
        <div className="panel glass" style={{ textAlign: "center" }}>
          <div style={{ fontSize: "0.75rem", fontWeight: 700, color: "var(--text-muted)", textTransform: "uppercase", letterSpacing: "0.06em", marginBottom: "0.5rem" }}>
            CI Status
          </div>
          <div style={{ fontSize: "2rem", lineHeight: 1, marginBottom: "0.35rem" }}>
            {overallCiPass === null ? "❓" : overallCiPass ? "✅" : "❌"}
          </div>
          <div style={{ fontWeight: 700, fontSize: "0.95rem" }}>
            {overallCiPass === null ? "No data" : overallCiPass ? "All pass" : "Failing"}
          </div>
          <div style={{ fontSize: "0.8rem", color: "var(--text-muted)", marginTop: "0.25rem" }}>
            {ci ? `Updated ${ci.updated.slice(0, 10)}` : "—"}
          </div>
        </div>

        {/* Last run card */}
        <div className="panel glass" style={{ textAlign: "center" }}>
          <div style={{ fontSize: "0.75rem", fontWeight: 700, color: "var(--text-muted)", textTransform: "uppercase", letterSpacing: "0.06em", marginBottom: "0.5rem" }}>
            Last Run
          </div>
          {lastRun ? (
            <>
              <div style={{ fontSize: "2rem", lineHeight: 1, marginBottom: "0.35rem" }}>
                {lastRun.victory ? "🏆" : "💥"}
              </div>
              <div style={{ fontWeight: 700, fontSize: "0.95rem" }}>
                {lastRun.victory ? "Victory" : "Defeat"}
              </div>
              <div style={{ fontSize: "0.8rem", color: "var(--text-muted)", marginTop: "0.25rem" }}>
                Wave {lastRun.wave_reached} · {fmtSeconds(lastRun.duration_s)} · {lastRun.hq_hp_remaining} HP
              </div>
            </>
          ) : (
            <>
              <div style={{ fontSize: "2rem", lineHeight: 1, marginBottom: "0.35rem" }}>—</div>
              <div style={{ fontWeight: 700, fontSize: "0.95rem" }}>No runs yet</div>
              <div style={{ fontSize: "0.8rem", color: "var(--text-muted)", marginTop: "0.25rem" }}>
                Export run_history.json to populate
              </div>
            </>
          )}
        </div>

        {/* Total sessions card */}
        <div className="panel glass" style={{ textAlign: "center" }}>
          <div style={{ fontSize: "0.75rem", fontWeight: 700, color: "var(--text-muted)", textTransform: "uppercase", letterSpacing: "0.06em", marginBottom: "0.5rem" }}>
            Win Rate
          </div>
          <div style={{ fontSize: "2rem", lineHeight: 1, marginBottom: "0.35rem", fontFamily: "var(--font-display)", fontWeight: 700, color: "var(--accent-gold)" }}>
            {winRate(runs)}
          </div>
          <div style={{ fontWeight: 700, fontSize: "0.95rem" }}>{runs.length} runs</div>
          <div style={{ fontSize: "0.8rem", color: "var(--text-muted)", marginTop: "0.25rem" }}>
            {runs.length ? `Avg ${fmtSeconds(avgDuration(runs)!)}` : "No data yet"}
          </div>
        </div>
      </div>

      {/* Recent run history */}
      <div className="panel glass" style={{ marginBottom: "1.5rem" }}>
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "0.75rem" }}>
          <h2 style={{ margin: 0, fontSize: "1rem" }}>Recent Runs</h2>
          <Link to="/dashboard/runs" style={{ fontSize: "0.83rem", color: "var(--accent)" }}>
            View all →
          </Link>
        </div>

        {runs.length === 0 ? (
          <EmptyState message="No run history yet. Export run_history.json from your playtest build." />
        ) : (
          <div style={{ overflowX: "auto" }}>
            <table style={{ width: "100%", borderCollapse: "collapse", fontSize: "0.85rem" }}>
              <thead>
                <tr style={{ background: "rgba(0,0,0,0.18)" }}>
                  {["Run ID", "Result", "Waves", "Duration", "HQ HP", "CI"].map((h) => (
                    <th key={h} style={thStyle}>{h}</th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {[...runs].reverse().slice(0, 5).map((r) => (
                  <RunRow key={r.run_id} run={r} />
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {/* Quick links */}
      <div style={{ display: "flex", gap: "0.75rem", flexWrap: "wrap" }}>
        <Link to="/dashboard/runs" className="btn btn-secondary btn-sm">📈 Run History</Link>
        <Link to="/dashboard/ci" className="btn btn-secondary btn-sm">🔬 CI Status</Link>
        <Link to="/dashboard/playtest" className="btn btn-secondary btn-sm">📝 Playtest Notes</Link>
        <Link to="/dashboard/requirements" className="btn btn-secondary btn-sm">📋 Requirements</Link>
      </div>
    </div>
  );
}

// ── Shared sub-components ─────────────────────────────────────────────────────

export function RunRow({ run }: { run: import("../../../hooks/useDashboardData").RunRecord }) {
  return (
    <tr style={{ borderTop: "1px solid var(--border-color)" }}>
      <td style={tdStyle}>
        <span style={{ fontSize: "0.78rem", color: "var(--text-muted)", fontFamily: "monospace" }}>
          {run.run_id.slice(0, 19).replace("T", " ")}
        </span>
      </td>
      <td style={tdStyle}>
        <span style={{ color: run.victory ? "#3ca67a" : "#e05a5a", fontWeight: 700 }}>
          {run.victory ? "✅ Win" : "❌ Loss"}
        </span>
      </td>
      <td style={{ ...tdStyle, textAlign: "center" }}>{run.wave_reached}</td>
      <td style={tdStyle}>{fmtSeconds(run.duration_s)}</td>
      <td style={{ ...tdStyle, textAlign: "center" }}>
        <span style={{ color: run.hq_hp_remaining > 30 ? "#3ca67a" : run.hq_hp_remaining > 0 ? "var(--accent-gold)" : "#e05a5a" }}>
          {run.hq_hp_remaining}
        </span>
      </td>
      <td style={tdStyle}>
        {run.smoke_ci_status ? (
          <span style={{ fontSize: "0.75rem", color: run.smoke_ci_status === "pass" ? "#3ca67a" : "var(--accent-gold)" }}>
            {run.smoke_ci_status}
          </span>
        ) : "—"}
      </td>
    </tr>
  );
}

export function EmptyState({ message }: { message: string }) {
  return (
    <div style={{ padding: "1.5rem", textAlign: "center", color: "var(--text-muted)", fontSize: "0.88rem" }}>
      {message}
    </div>
  );
}

// ── Style helpers ─────────────────────────────────────────────────────────────

export const thStyle: React.CSSProperties = {
  textAlign: "left", padding: "0.5rem 0.75rem",
  fontSize: "0.75rem", fontWeight: 700,
  color: "var(--text-muted)", textTransform: "uppercase",
  letterSpacing: "0.05em", whiteSpace: "nowrap",
};

export const tdStyle: React.CSSProperties = {
  padding: "0.5rem 0.75rem", verticalAlign: "middle",
};

function badgeStyle(color: string, bg: string): React.CSSProperties {
  return {
    fontSize: "0.75rem", fontWeight: 700, color, background: bg,
    borderRadius: "4px", padding: "2px 8px", letterSpacing: "0.04em",
  };
}

import type React from "react";
