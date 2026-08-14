/**
 * RunHistoryView — /dashboard/runs — ID3 skeleton: Run History
 *
 * Wave survival sparkline, session duration bars, and a sortable run table.
 * All derived metrics computed client-side from static run_history.json.
 */
import type React from "react";
import {
  useDashboardData,
  winRate,
  avgDuration,
  avgHqHp,
  fmtSeconds,
  waveSurvivalCounts,
} from "../../../hooks/useDashboardData";
import { EmptyState, RunRow, thStyle, tdStyle } from "./DashboardView";

const TOTAL_WAVES = 5;

export default function RunHistoryView() {
  const { runs, loading } = useDashboardData();

  const waveCounts = waveSurvivalCounts(runs, TOTAL_WAVES);
  const maxCount = Math.max(...waveCounts, 1);

  const dur = avgDuration(runs);
  const buckets = runs.length
    ? [
        { label: "< 5m",   count: runs.filter((r) => r.duration_s < 300).length },
        { label: "5–8m",   count: runs.filter((r) => r.duration_s >= 300 && r.duration_s < 480).length },
        { label: "8–10m",  count: runs.filter((r) => r.duration_s >= 480 && r.duration_s < 600).length },
        { label: "10m+",   count: runs.filter((r) => r.duration_s >= 600).length },
      ]
    : [];
  const maxBucket = Math.max(...buckets.map((b) => b.count), 1);

  return (
    <div className="dashboard-req-view" style={{ padding: "2rem 0" }}>
      {/* Header */}
      <div className="panel glass" style={{ marginBottom: "1.5rem" }}>
        <div style={{ display: "flex", alignItems: "baseline", gap: "0.75rem", flexWrap: "wrap" }}>
          <h1 style={{ margin: 0, fontSize: "1.5rem" }}>📈 Run History</h1>
          {loading && <span style={{ fontSize: "0.8rem", color: "var(--text-muted)" }}>Loading…</span>}
        </div>
        <p style={{ marginTop: "0.5rem", color: "var(--text-muted)", fontSize: "0.88rem" }}>
          {runs.length} runs logged · Win rate {winRate(runs)}
          {dur != null ? ` · Avg duration ${fmtSeconds(dur)}` : ""}
          {avgHqHp(runs) != null ? ` · Avg HQ HP (victories) ${avgHqHp(runs)}` : ""}
        </p>
      </div>

      {runs.length === 0 ? (
        <div className="panel glass">
          <EmptyState message="No run history yet. Export run_history.json from your playtest build to populate this view." />
        </div>
      ) : (
        <>
          {/* Charts row */}
          <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "1rem", marginBottom: "1.5rem" }}>
            {/* Wave survival sparkline */}
            <div className="panel glass">
              <h2 style={{ margin: "0 0 0.75rem", fontSize: "0.95rem" }}>Wave survival</h2>
              <p style={{ margin: "0 0 1rem", fontSize: "0.8rem", color: "var(--text-muted)" }}>
                Runs that reached each wave
              </p>
              <div style={{ display: "flex", alignItems: "flex-end", gap: "0.5rem", height: "80px" }}>
                {waveCounts.map((count, i) => (
                  <div key={i} style={{ flex: 1, display: "flex", flexDirection: "column", alignItems: "center", gap: "0.25rem" }}>
                    <span style={{ fontSize: "0.72rem", color: "var(--text-muted)" }}>{count}</span>
                    <div
                      style={{
                        width: "100%",
                        height: `${Math.round((count / maxCount) * 56)}px`,
                        background: count === runs.length ? "#3ca67a" : "var(--accent)",
                        borderRadius: "3px 3px 0 0",
                        opacity: 0.85,
                        minHeight: "4px",
                      }}
                    />
                    <span style={{ fontSize: "0.72rem", color: "var(--text-muted)" }}>W{i + 1}</span>
                  </div>
                ))}
              </div>
            </div>

            {/* Duration distribution */}
            <div className="panel glass">
              <h2 style={{ margin: "0 0 0.75rem", fontSize: "0.95rem" }}>Session duration</h2>
              <p style={{ margin: "0 0 1rem", fontSize: "0.8rem", color: "var(--text-muted)" }}>
                Target: 5–10 min for Slice-0
              </p>
              <div style={{ display: "flex", flexDirection: "column", gap: "0.5rem" }}>
                {buckets.map((b) => (
                  <div key={b.label} style={{ display: "flex", alignItems: "center", gap: "0.6rem" }}>
                    <span style={{ width: "40px", fontSize: "0.75rem", color: "var(--text-muted)", textAlign: "right" }}>{b.label}</span>
                    <div style={{ flex: 1, height: "16px", background: "rgba(0,0,0,0.2)", borderRadius: "3px", overflow: "hidden" }}>
                      <div
                        style={{
                          width: `${Math.round((b.count / maxBucket) * 100)}%`,
                          height: "100%",
                          background: "var(--accent)",
                          opacity: 0.85,
                          borderRadius: "3px",
                          transition: "width 0.3s ease",
                          minWidth: b.count > 0 ? "4px" : "0",
                        }}
                      />
                    </div>
                    <span style={{ width: "20px", fontSize: "0.75rem", color: "var(--text-muted)" }}>{b.count}</span>
                  </div>
                ))}
              </div>
            </div>
          </div>

          {/* Full run table */}
          <div className="panel glass" style={{ padding: 0, overflow: "hidden" }}>
            <div style={{ padding: "1rem 1.25rem 0.5rem", display: "flex", justifyContent: "space-between", alignItems: "center" }}>
              <h2 style={{ margin: 0, fontSize: "0.95rem" }}>All runs</h2>
              <span style={{ fontSize: "0.8rem", color: "var(--text-muted)" }}>{runs.length} total</span>
            </div>
            <div style={{ overflowX: "auto" }}>
              <table style={{ width: "100%", borderCollapse: "collapse", fontSize: "0.85rem" }}>
                <thead>
                  <tr style={{ background: "rgba(0,0,0,0.18)" }}>
                    {["Run ID", "Result", "Reason", "Waves", "Duration", "HQ HP", "Civ", "CI"].map((h) => (
                      <th key={h} style={thStyle}>{h}</th>
                    ))}
                  </tr>
                </thead>
                <tbody>
                  {[...runs].reverse().map((r) => (
                    <tr key={r.run_id} style={{ borderTop: "1px solid var(--border-color)" }}>
                      <td style={{ ...tdStyle }}>
                        <span style={{ fontSize: "0.78rem", color: "var(--text-muted)", fontFamily: "monospace" }}>
                          {r.run_id.slice(0, 19).replace("T", " ")}
                        </span>
                      </td>
                      <td style={tdStyle}>
                        <span style={{ color: r.victory ? "#3ca67a" : "#e05a5a", fontWeight: 700 }}>
                          {r.victory ? "✅ Win" : "❌ Loss"}
                        </span>
                      </td>
                      <td style={{ ...tdStyle, color: "var(--text-muted)", fontSize: "0.78rem" }}>
                        {r.reason.replace(/_/g, " ")}
                      </td>
                      <td style={{ ...tdStyle, textAlign: "center" }}>{r.wave_reached}</td>
                      <td style={tdStyle}>{fmtSeconds(r.duration_s)}</td>
                      <td style={{ ...tdStyle, textAlign: "center" }}>
                        <span style={{ color: r.hq_hp_remaining > 30 ? "#3ca67a" : r.hq_hp_remaining > 0 ? "var(--accent-gold)" : "#e05a5a" }}>
                          {r.hq_hp_remaining}
                        </span>
                      </td>
                      <td style={{ ...tdStyle, fontSize: "0.78rem", color: "var(--text-muted)" }}>
                        {r.primary_civ} / {r.support_civ}
                      </td>
                      <td style={tdStyle}>
                        {r.smoke_ci_status ? (
                          <span style={{ fontSize: "0.75rem", color: r.smoke_ci_status === "pass" ? "#3ca67a" : "var(--accent-gold)" }}>
                            {r.smoke_ci_status}
                          </span>
                        ) : "—"}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>

          {/* Export guide */}
          <div className="panel-dark" style={{ borderRadius: "6px", padding: "0.85rem 1rem", marginTop: "1rem", fontSize: "0.83rem", color: "var(--text-muted)" }}>
            <strong>How to add runs:</strong> After a playtest session, export{" "}
            <code>user://last_run_results.json</code> from Godot's OfflinePersistence and append the
            records to <code>docs/website/public/dashboard-data/run_history.json</code>, then commit.
          </div>
        </>
      )}
    </div>
  );
}
