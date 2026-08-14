/**
 * CiStatusView — /dashboard/ci — ID3 skeleton: CI Status
 *
 * Renders one card per workflow in ci_status.json, with per-test rows.
 * Graceful "no data" state when the JSON file is absent.
 */
import { useDashboardData } from "../../../hooks/useDashboardData";
import { EmptyState } from "./DashboardView";

export default function CiStatusView() {
  const { ci, loading } = useDashboardData();

  return (
    <div className="dashboard-req-view" style={{ padding: "2rem 0" }}>
      {/* Header */}
      <div className="panel glass" style={{ marginBottom: "1.5rem" }}>
        <div style={{ display: "flex", alignItems: "baseline", gap: "0.75rem", flexWrap: "wrap" }}>
          <h1 style={{ margin: 0, fontSize: "1.5rem" }}>🔬 CI Status</h1>
          {loading && <span style={{ fontSize: "0.8rem", color: "var(--text-muted)" }}>Loading…</span>}
        </div>
        <p style={{ marginTop: "0.5rem", color: "var(--text-muted)", fontSize: "0.88rem" }}>
          Workflow results from committed <code>ci_status.json</code>.
          {ci ? ` Last updated: ${ci.updated.slice(0, 10)}.` : ""}
        </p>
      </div>

      {!ci ? (
        <div className="panel glass">
          <EmptyState message="No CI data yet. Commit docs/website/public/dashboard-data/ci_status.json with your latest workflow results." />
        </div>
      ) : (
        <div style={{ display: "grid", gap: "1rem" }}>
          {ci.workflows.map((wf) => {
            const passing = wf.status === "pass";
            const statusColor = passing ? "#3ca67a" : wf.status === "unknown" ? "var(--text-muted)" : "#e05a5a";
            return (
              <div key={wf.name} className="panel glass">
                {/* Workflow header */}
                <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", flexWrap: "wrap", gap: "0.5rem", marginBottom: wf.tests.length ? "0.75rem" : 0 }}>
                  <div style={{ display: "flex", alignItems: "center", gap: "0.6rem" }}>
                    <span style={{ fontSize: "1.1rem" }}>{passing ? "✅" : wf.status === "unknown" ? "❓" : "❌"}</span>
                    <strong style={{ fontSize: "0.95rem", fontFamily: "monospace" }}>{wf.name}</strong>
                  </div>
                  <div style={{ display: "flex", gap: "0.75rem", alignItems: "center" }}>
                    <span
                      style={{
                        fontSize: "0.75rem", fontWeight: 700,
                        color: statusColor,
                        background: statusColor + "22",
                        borderRadius: "4px", padding: "2px 8px",
                      }}
                    >
                      {wf.status.toUpperCase()}
                    </span>
                    <span style={{ fontSize: "0.78rem", color: "var(--text-muted)" }}>
                      Last run: {wf.last_run}
                    </span>
                  </div>
                </div>

                {/* Per-test rows */}
                {wf.tests.length > 0 && (
                  <div style={{ display: "grid", gap: "0.3rem" }}>
                    {wf.tests.map((t) => {
                      const tc = t.result === "pass" ? "#3ca67a" : t.result === "fail" ? "#e05a5a" : "var(--text-muted)";
                      return (
                        <div
                          key={t.name}
                          style={{
                            display: "flex", alignItems: "center", gap: "0.6rem",
                            padding: "0.3rem 0.5rem",
                            background: "rgba(0,0,0,0.15)",
                            borderRadius: "4px",
                            fontSize: "0.83rem",
                          }}
                        >
                          <span style={{ color: tc, minWidth: "14px" }}>
                            {t.result === "pass" ? "✓" : t.result === "fail" ? "✗" : "?"}
                          </span>
                          <span style={{ fontFamily: "monospace", flex: 1 }}>{t.name}</span>
                          <span style={{ color: tc, fontSize: "0.75rem", fontWeight: 700 }}>
                            {t.result}
                          </span>
                        </div>
                      );
                    })}
                  </div>
                )}
              </div>
            );
          })}
        </div>
      )}

      <div className="panel-dark" style={{ borderRadius: "6px", padding: "0.85rem 1rem", marginTop: "1rem", fontSize: "0.83rem", color: "var(--text-muted)" }}>
        <strong>How to update:</strong> After a CI run, update{" "}
        <code>docs/website/public/dashboard-data/ci_status.json</code> with the latest workflow
        results and commit. Automated update via a GitHub Actions step is planned for ID4.
      </div>
    </div>
  );
}
