/**
 * PlaytestNotesView — /dashboard/playtest — ID3 skeleton: Playtest Notes
 *
 * Shows VS10 gate progress and renders committed playtest session records.
 * Links to the VS10_PLAYTEST_PROTOCOL.md doc for session instructions.
 */
import { Link } from "react-router-dom";
import { useDashboardData } from "../../../hooks/useDashboardData";
import { EmptyState } from "./DashboardView";

export default function PlaytestNotesView() {
  const { playtest, loading } = useDashboardData();

  const sessions = playtest?.sessions ?? [];
  const required = playtest?.sessions_required ?? 2;
  const decision = playtest?.gate_decision ?? null;
  const gateProgress = `${sessions.length} / ${required} sessions recorded`;

  return (
    <div className="dashboard-req-view" style={{ padding: "2rem 0" }}>
      {/* Header */}
      <div className="panel glass" style={{ marginBottom: "1.5rem" }}>
        <div style={{ display: "flex", alignItems: "baseline", gap: "0.75rem", flexWrap: "wrap" }}>
          <h1 style={{ margin: 0, fontSize: "1.5rem" }}>📝 Playtest Notes</h1>
          <span
            style={{
              fontSize: "0.75rem", fontWeight: 700,
              color: decision === "pass" ? "#3ca67a" : "var(--accent-gold)",
              background: decision === "pass" ? "#3ca67a22" : "rgba(200,160,60,0.12)",
              borderRadius: "4px", padding: "2px 8px", letterSpacing: "0.04em",
            }}
          >
            {decision === "pass" ? "✅ Gate passed" : `VS10 — ${gateProgress}`}
          </span>
          {loading && <span style={{ fontSize: "0.8rem", color: "var(--text-muted)" }}>Loading…</span>}
        </div>
        <p style={{ marginTop: "0.5rem", color: "var(--text-muted)", fontSize: "0.88rem" }}>
          Minimum {required} collaborator sessions with a "shows promise" verdict required to pass the
          Slice-0 Phase 1a gate.{" "}
          <a
            href="https://github.com/Hyperion-Corporation/Project-Mobile-Fortress/blob/main/docs/moon/VS10_PLAYTEST_PROTOCOL.md"
            target="_blank"
            rel="noopener noreferrer"
            style={{ color: "var(--accent)" }}
          >
            Open playtest protocol ↗
          </a>
        </p>
      </div>

      {/* Gate decision banner */}
      {decision === "pass" && (
        <div
          className="panel glass"
          style={{ marginBottom: "1rem", background: "#3ca67a22", borderColor: "#3ca67a55", textAlign: "center", padding: "1.25rem" }}
        >
          <div style={{ fontSize: "1.5rem", marginBottom: "0.35rem" }}>🎉</div>
          <strong>VS10 gate passed — Phase 1a complete!</strong>
          <p style={{ margin: "0.25rem 0 0", fontSize: "0.85rem", color: "var(--text-muted)" }}>
            Proceed to G3+ polish, economy, and hero expansion per{" "}
            <Link to="/dashboard" style={{ color: "var(--accent)" }}>the roadmap</Link>.
          </p>
        </div>
      )}

      {/* Session cards */}
      {sessions.length === 0 ? (
        <div className="panel glass">
          <EmptyState message="No playtest sessions recorded yet. Run a session using the VS10 protocol, then commit your results to playtest_sessions.json." />
          <div style={{ paddingTop: "0.75rem", paddingBottom: "0.5rem", paddingLeft: "0.5rem" }}>
            <p style={{ fontSize: "0.83rem", color: "var(--text-muted)", margin: 0 }}>
              <strong>How to record a session:</strong>
            </p>
            <ol style={{ fontSize: "0.83rem", color: "var(--text-muted)", marginTop: "0.4rem", paddingLeft: "1.25rem" }}>
              <li>Fill in <code>docs/moon/VS10_PLAYTEST_PROTOCOL.md</code></li>
              <li>Add a session object to <code>public/dashboard-data/playtest_sessions.json</code></li>
              <li>Commit and push</li>
            </ol>
          </div>
        </div>
      ) : (
        <div style={{ display: "grid", gap: "1rem" }}>
          {sessions.map((s, i) => {
            const verdictColor =
              s.verdict === "shows_promise" ? "#3ca67a"
              : s.verdict === "needs_work" ? "var(--accent-gold)"
              : "#e05a5a";
            const verdictLabel =
              s.verdict === "shows_promise" ? "Shows promise ✅"
              : s.verdict === "needs_work" ? "Needs work 🟡"
              : "No ❌";
            return (
              <div key={i} className="panel glass">
                <div style={{ display: "flex", justifyContent: "space-between", flexWrap: "wrap", gap: "0.5rem", marginBottom: "0.75rem" }}>
                  <strong style={{ fontSize: "0.95rem" }}>Session {i + 1}</strong>
                  <span
                    style={{
                      fontSize: "0.75rem", fontWeight: 700,
                      color: verdictColor, background: verdictColor + "22",
                      borderRadius: "4px", padding: "2px 8px",
                    }}
                  >
                    {verdictLabel}
                  </span>
                </div>
                <div
                  style={{
                    display: "grid",
                    gridTemplateColumns: "repeat(auto-fill, minmax(160px, 1fr))",
                    gap: "0.5rem 1.25rem",
                    fontSize: "0.83rem",
                    marginBottom: "0.75rem",
                  }}
                >
                  {[
                    ["Date", s.date],
                    ["Tester", s.tester],
                    ["Platform", s.platform],
                    ["Build", s.build_commit.slice(0, 8)],
                    ["Hard criteria", s.hard_criteria_pass ? "✅ Pass" : "❌ Fail"],
                    ["Art/UX criteria", s.art_criteria_pass ? "✅ Pass" : "❌ Fail"],
                  ].map(([k, v]) => (
                    <div key={k}>
                      <span style={{ color: "var(--text-muted)", marginRight: "0.25rem" }}>{k}:</span>
                      <span style={{ fontWeight: 600 }}>{v}</span>
                    </div>
                  ))}
                </div>
                {s.notes && (
                  <div
                    className="panel-dark"
                    style={{ borderRadius: "6px", padding: "0.65rem 0.85rem", fontSize: "0.83rem", color: "var(--text-muted)" }}
                  >
                    {s.notes}
                  </div>
                )}
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
}
