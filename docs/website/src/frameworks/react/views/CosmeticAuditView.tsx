import { useState } from "react";
import { Link } from "react-router-dom";
import {
  COSMETIC_CATALOG,
  RARITY_PROBABILITIES,
  EPIC_PITY_THRESHOLD,
  LEGENDARY_PITY_THRESHOLD,
  DUPLICATE_TOKENS,
  TOKEN_EXPIRATION_DAYS,
  WARNING_EXPIRATION_DAYS,
  getItemProbabilities,
  simulatePull,
  runMonteCarloAudit,
  Rarity,
  AuditResult,
  LootboxPullResult,
  PityState,
} from "../../../simulations/cosmeticLootbox";
import "./CosmeticAuditView.css";

export default function CosmeticAuditView() {
  const [selectedRarity, setSelectedRarity] = useState<string>("all");
  const [pityState, setPityState] = useState<PityState>({
    pulls_since_epic: 0,
    pulls_since_legendary: 0,
    total_pulls: 0,
  });
  const [recentPulls, setRecentPulls] = useState<LootboxPullResult[]>([]);
  const [auditSample, setAuditSample] = useState<number>(10000);
  const [auditResult, setAuditResult] = useState<AuditResult | null>(null);
  const [isAuditing, setIsAuditing] = useState<boolean>(false);

  const itemProbs = getItemProbabilities();

  const filteredCatalog =
    selectedRarity === "all"
      ? COSMETIC_CATALOG
      : COSMETIC_CATALOG.filter((i) => i.rarity === selectedRarity);

  const handlePull = (count: number) => {
    let currentPity = { ...pityState };
    const pulls: LootboxPullResult[] = [];
    for (let i = 0; i < count; i++) {
      const res = simulatePull(currentPity);
      currentPity = res.pity_state;
      pulls.push(res);
    }
    setPityState(currentPity);
    setRecentPulls((prev) => [...pulls.reverse(), ...prev].slice(0, 20));
  };

  const handleRunAudit = () => {
    setIsAuditing(true);
    setTimeout(() => {
      const res = runMonteCarloAudit(auditSample);
      setAuditResult(res);
      setIsAuditing(false);
    }, 50);
  };

  return (
    <div className="cosmetic-audit-view">
      {/* Header & Navigation */}
      <div className="cosmetic-header">
        <div style={{ display: "flex", alignItems: "baseline", gap: "1rem", flexWrap: "wrap" }}>
          <h1 style={{ margin: 0, fontSize: "1.75rem" }}>🎁 Cosmetic Probability & Audit (M2 / Q9)</h1>
          <span className="compliance-badge gold">Regulatory Compliance</span>
        </div>
        <p style={{ color: "var(--text-muted, #a0a0a0)", marginTop: "0.5rem", fontSize: "0.95rem" }}>
          Official transparent probability disclosure, bad-luck protection rules, currency expiration policy,
          and automated statistical audit tooling for Mobile Fortress cosmetic skin lootboxes.
        </p>

        <div className="badge-row">
          <span className="compliance-badge green">✓ Strict Anti-P2W (0% Stat Power)</span>
          <span className="compliance-badge blue">✓ Kompu-Gacha Compliant (Standalone Items)</span>
          <span className="compliance-badge green">✓ Bad-Luck Protection Guarantee</span>
          <span className="compliance-badge gold">✓ Apple & Google Play Policy Aligned</span>
        </div>

        {/* Quick Nav Strip */}
        <div style={{ display: "flex", gap: "1rem", marginTop: "1rem", borderTop: "1px solid rgba(255,255,255,0.08)", paddingTop: "0.75rem", flexWrap: "wrap" }}>
          <Link to="/dashboard" style={{ color: "var(--text-muted)", fontSize: "0.83rem", textDecoration: "none" }}>📊 Dashboard Overview</Link>
          <Link to="/dashboard/runs" style={{ color: "var(--text-muted)", fontSize: "0.83rem", textDecoration: "none" }}>📜 Run History</Link>
          <Link to="/dashboard/ci" style={{ color: "var(--text-muted)", fontSize: "0.83rem", textDecoration: "none" }}>⚙️ CI Status</Link>
          <Link to="/dashboard/lore-map" style={{ color: "var(--text-muted)", fontSize: "0.83rem", textDecoration: "none" }}>🗺️ Lore Map</Link>
          <Link to="/dashboard/visualizer" style={{ color: "var(--text-muted)", fontSize: "0.83rem", textDecoration: "none" }}>🎭 Visualizer</Link>
          <Link to="/dashboard/demo" style={{ color: "var(--text-muted)", fontSize: "0.83rem", textDecoration: "none" }}>⚔️ Demo</Link>
          <span style={{ color: "var(--accent-gold)", fontSize: "0.83rem", fontWeight: 700 }}>🎁 Cosmetics & Audit</span>
        </div>
      </div>

      {/* Probability Disclosure Table */}
      <section style={{ marginBottom: "2.5rem" }}>
        <h2>📜 Disclosed Rarity & Drop Rates</h2>
        <p style={{ color: "var(--text-muted)", fontSize: "0.88rem" }}>
          Individual item probabilities are derived uniformly within each rarity pool. All rates are disclosed prior to purchase.
        </p>

        <table className="disclosure-table">
          <thead>
            <tr>
              <th>Rarity Tier</th>
              <th>Base Drop Rate</th>
              <th>Items in Pool</th>
              <th>Per-Item Rate</th>
              <th>Pity Guarantee</th>
              <th>Duplicate Tokens</th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <td><span className="rarity-pill common">Common</span></td>
              <td><strong>60.00%</strong></td>
              <td>4 items</td>
              <td>15.000%</td>
              <td>—</td>
              <td>+{DUPLICATE_TOKENS.common} Tokens</td>
            </tr>
            <tr>
              <td><span className="rarity-pill rare">Rare</span></td>
              <td><strong>27.00%</strong></td>
              <td>4 items</td>
              <td>6.750%</td>
              <td>—</td>
              <td>+{DUPLICATE_TOKENS.rare} Tokens</td>
            </tr>
            <tr>
              <td><span className="rarity-pill epic">Epic</span></td>
              <td><strong>10.00%</strong></td>
              <td>4 items</td>
              <td>2.500%</td>
              <td>Guaranteed ≤ {EPIC_PITY_THRESHOLD} pulls</td>
              <td>+{DUPLICATE_TOKENS.epic} Tokens</td>
            </tr>
            <tr>
              <td><span className="rarity-pill legendary">Legendary</span></td>
              <td><strong>3.00%</strong></td>
              <td>3 items</td>
              <td>1.000%</td>
              <td>Guaranteed ≤ {LEGENDARY_PITY_THRESHOLD} pulls</td>
              <td>+{DUPLICATE_TOKENS.legendary} Tokens</td>
            </tr>
          </tbody>
        </table>

        <div style={{ background: "rgba(255,255,255,0.02)", border: "1px solid rgba(255,255,255,0.08)", padding: "1rem", borderRadius: "6px", fontSize: "0.85rem" }}>
          <strong>Currency Expiration Policy:</strong> Unused cosmetic tokens expire {TOKEN_EXPIRATION_DAYS} days from receipt.
          In-game expiration countdown notifications commence {WARNING_EXPIRATION_DAYS} days before expiration. Tokens possess no cash value and cannot be redeemed for real currency.
        </div>
      </section>

      {/* Interactive Pull Simulator */}
      <section style={{ marginBottom: "2.5rem", background: "rgba(255,255,255,0.02)", border: "1px solid rgba(255,255,255,0.08)", padding: "1.5rem", borderRadius: "8px" }}>
        <h2>🎲 Interactive Pull Simulator</h2>
        <p style={{ color: "var(--text-muted)", fontSize: "0.88rem" }}>
          Test the random generator and observe bad-luck protection pity counters in real time.
        </p>

        <div style={{ display: "flex", gap: "1rem", margin: "1rem 0", alignItems: "center", flexWrap: "wrap" }}>
          <button className="audit-btn" onClick={() => handlePull(1)}>Open 1 Box</button>
          <button className="audit-btn" onClick={() => handlePull(10)}>Open 10 Boxes</button>
          <div style={{ display: "flex", gap: "1.5rem", fontSize: "0.85rem", color: "var(--text-muted)" }}>
            <span>Pulls since Epic: <strong>{pityState.pulls_since_epic} / {EPIC_PITY_THRESHOLD}</strong></span>
            <span>Pulls since Legendary: <strong>{pityState.pulls_since_legendary} / {LEGENDARY_PITY_THRESHOLD}</strong></span>
            <span>Total Pulls: <strong>{pityState.total_pulls}</strong></span>
          </div>
        </div>

        {recentPulls.length > 0 && (
          <div style={{ display: "flex", gap: "0.5rem", overflowX: "auto", padding: "0.75rem 0" }}>
            {recentPulls.slice(0, 10).map((p, idx) => (
              <div
                key={idx}
                style={{
                  minWidth: "140px",
                  padding: "0.75rem",
                  background: "rgba(0,0,0,0.3)",
                  border: `1px solid ${p.rarity === "legendary" ? "#f1c40f" : p.rarity === "epic" ? "#9b59b6" : "rgba(255,255,255,0.1)"}`,
                  borderRadius: "4px",
                  fontSize: "0.8rem",
                }}
              >
                <div style={{ fontWeight: 700, marginBottom: "0.25rem" }}>{p.item.name}</div>
                <span className={`rarity-pill ${p.rarity}`}>{p.rarity}</span>
                {p.is_pity && <span style={{ marginLeft: "0.35rem", fontSize: "0.7rem", color: "#f39c12" }}>★ PITY</span>}
              </div>
            ))}
          </div>
        )}
      </section>

      {/* Cosmetic Catalog Browser */}
      <section style={{ marginBottom: "2.5rem" }}>
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", flexWrap: "wrap", gap: "1rem" }}>
          <h2>🎨 Cosmetic Skin Catalog ({filteredCatalog.length} Items)</h2>
          <div style={{ display: "flex", gap: "0.5rem" }}>
            {["all", "common", "rare", "epic", "legendary"].map((r) => (
              <button
                key={r}
                onClick={() => setSelectedRarity(r)}
                style={{
                  background: selectedRarity === r ? "var(--accent-gold)" : "rgba(255,255,255,0.05)",
                  color: selectedRarity === r ? "#000" : "var(--text-color)",
                  border: "none",
                  padding: "0.35rem 0.75rem",
                  borderRadius: "4px",
                  fontSize: "0.8rem",
                  cursor: "pointer",
                  textTransform: "capitalize",
                }}
              >
                {r}
              </button>
            ))}
          </div>
        </div>

        <div className="catalog-grid">
          {filteredCatalog.map((item) => (
            <div key={item.id} className={`cosmetic-card ${item.rarity}`}>
              <div style={{ display: "flex", justifyContent: "space-between", alignItems: "baseline" }}>
                <span className={`rarity-pill ${item.rarity}`}>{item.rarity}</span>
                <span style={{ fontSize: "0.75rem", color: "var(--text-muted)" }}>
                  {(itemProbs[item.id] * 100).toFixed(3)}% drop
                </span>
              </div>
              <h3 style={{ margin: "0.25rem 0", fontSize: "1rem" }}>{item.name}</h3>
              <div style={{ fontSize: "0.75rem", color: "#3498db" }}>Target: {item.target_unit} ({item.category})</div>
              <p style={{ margin: 0, fontSize: "0.82rem", color: "var(--text-muted)" }}>{item.description}</p>
            </div>
          ))}
        </div>
      </section>

      {/* Q9 Monte Carlo Statistical Audit Tool */}
      <section className="audit-section">
        <h2>🔬 Statistical Goodness-of-Fit Audit Tool (Q9)</h2>
        <p style={{ color: "var(--text-muted)", fontSize: "0.9rem" }}>
          Automated compliance audit verifying that empirical RNG generation adheres to disclosed probabilities
          using Pearson's Chi-Square ($\chi^2$) goodness-of-fit test and checking that hard pity guarantees are never violated.
        </p>

        <div className="audit-controls">
          <label style={{ fontSize: "0.85rem" }}>
            Sample Size:&nbsp;
            <select
              value={auditSample}
              onChange={(e) => setAuditSample(Number(e.target.value))}
              style={{
                background: "rgba(255,255,255,0.08)",
                color: "#fff",
                border: "1px solid rgba(255,255,255,0.2)",
                padding: "0.4rem 0.6rem",
                borderRadius: "4px",
              }}
            >
              <option value={1000}>1,000 pulls</option>
              <option value={5000}>5,000 pulls</option>
              <option value={10000}>10,000 pulls</option>
              <option value={20000}>20,000 pulls</option>
            </select>
          </label>
          <button className="audit-btn" onClick={handleRunAudit} disabled={isAuditing}>
            {isAuditing ? "Auditing..." : "Run Monte Carlo Audit"}
          </button>
        </div>

        {auditResult && (
          <div>
            <div className={`verdict-banner ${auditResult.passed ? "pass" : "fail"}`}>
              <div>
                <strong>Audit Verdict: {auditResult.passed ? "PASS (COMPLIANT)" : "FAIL (AUDIT REJECTED)"}</strong>
                <div style={{ fontSize: "0.85rem", marginTop: "0.25rem" }}>
                  Chi-Square: {auditResult.chi_square_statistic} (df = 3) | Approx p-value: {auditResult.p_value_approx} | Pity Bounds: {auditResult.pity_compliant ? "ENFORCED" : "VIOLATED"}
                </div>
              </div>
              <span style={{ fontSize: "1.5rem" }}>{auditResult.passed ? "✓" : "✗"}</span>
            </div>

            <div className="audit-stats-grid">
              <div className="audit-stat-card">
                <div style={{ fontSize: "0.8rem", color: "var(--text-muted)" }}>Common Observed</div>
                <div className="value">{(auditResult.observed_percentages.common * 100).toFixed(2)}%</div>
                <div style={{ fontSize: "0.75rem", color: "var(--text-muted)" }}>Target: 60.00% ({auditResult.observed_counts.common} items)</div>
              </div>
              <div className="audit-stat-card">
                <div style={{ fontSize: "0.8rem", color: "var(--text-muted)" }}>Rare Observed</div>
                <div className="value">{(auditResult.observed_percentages.rare * 100).toFixed(2)}%</div>
                <div style={{ fontSize: "0.75rem", color: "var(--text-muted)" }}>Target: 27.00% ({auditResult.observed_counts.rare} items)</div>
              </div>
              <div className="audit-stat-card">
                <div style={{ fontSize: "0.8rem", color: "var(--text-muted)" }}>Epic Observed</div>
                <div className="value">{(auditResult.observed_percentages.epic * 100).toFixed(2)}%</div>
                <div style={{ fontSize: "0.75rem", color: "var(--text-muted)" }}>Target: 10.00% ({auditResult.observed_counts.epic} items)</div>
              </div>
              <div className="audit-stat-card">
                <div style={{ fontSize: "0.8rem", color: "var(--text-muted)" }}>Legendary Observed</div>
                <div className="value">{(auditResult.observed_percentages.legendary * 100).toFixed(2)}%</div>
                <div style={{ fontSize: "0.75rem", color: "var(--text-muted)" }}>Target: 3.00% ({auditResult.observed_counts.legendary} items)</div>
              </div>
            </div>

            <div style={{ display: "flex", gap: "2rem", fontSize: "0.85rem", color: "var(--text-muted)", marginTop: "1rem" }}>
              <span>Max pulls without Epic: <strong>{auditResult.max_streak_without_epic}</strong> (Threshold: {EPIC_PITY_THRESHOLD})</span>
              <span>Max pulls without Legendary: <strong>{auditResult.max_streak_without_legendary}</strong> (Threshold: {LEGENDARY_PITY_THRESHOLD})</span>
              <span>Kompu-Gacha Rule: <strong>{auditResult.anti_kompu_gacha_compliant ? "Passed" : "Failed"}</strong></span>
            </div>
          </div>
        )}
      </section>
    </div>
  );
}
