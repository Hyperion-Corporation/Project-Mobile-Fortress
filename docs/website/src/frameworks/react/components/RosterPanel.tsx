import { UNIT_DEFS, getDamageMatrix, isHero, isCrossSupport, type UnitDef, type DamageMatrix } from "../../../simulations/dualFrontDemo";
import "./RosterPanel.css";

function DamageMatrixTable({ def, matrix }: { def: UnitDef; matrix: DamageMatrix }) {
  const canStandLand = def.front === "land" || def.front === "both";
  const canStandSea = def.front === "sea" || def.front === "both";

  return (
    <table className="roster-matrix" aria-label={`Damage matrix for ${def.name}`}>
      <thead>
        <tr>
          <th></th>
          <th scope="col" title="Target on land">🛡️ Land</th>
          <th scope="col" title="Target on sea">⚓ Sea</th>
        </tr>
      </thead>
      <tbody>
        <tr className={canStandLand ? "" : "roster-unavailable"}>
          <th scope="row">🛡️ Land</th>
          <td className={matrix.landVsLand > 0 ? "" : "roster-zero"}>{canStandLand ? matrix.landVsLand : "—"}</td>
          <td className={matrix.landVsSea > 0 ? "" : "roster-zero"}>{canStandLand ? matrix.landVsSea : "—"}</td>
        </tr>
        <tr className={canStandSea ? "" : "roster-unavailable"}>
          <th scope="row">⚓ Sea</th>
          <td className={matrix.seaVsLand > 0 ? "" : "roster-zero"}>{canStandSea ? matrix.seaVsLand : "—"}</td>
          <td className={matrix.seaVsSea > 0 ? "" : "roster-zero"}>{canStandSea ? matrix.seaVsSea : "—"}</td>
        </tr>
      </tbody>
    </table>
  );
}

function RosterCard({ def }: { def: UnitDef }) {
  const matrix = getDamageMatrix(def);
  const currencySymbol = def.currency === "land" ? "🌾" : "⚓";
  const heroTag = isHero(def) ? " ⭐" : "";
  const crossTag = isCrossSupport(def) ? " 🔗" : "";

  return (
    <div className={`roster-card roster-${def.kind}`} data-testid={`roster-${def.id}`}>
      <div className="roster-header">
        <span className="roster-name">{def.name}{heroTag}{crossTag}</span>
        <span className="roster-cost">{currencySymbol} {def.cost}</span>
      </div>
      <div className="roster-stats">
        <span title="Damage">⚔️ {def.damage}</span>
        <span title="Range">🎯 {def.range}</span>
        <span title="Cooldown">⏱️ {def.cooldown}</span>
        <span title="HP">❤️ {def.hp}</span>
      </div>
      {isHero(def) && def.activeDamage != null && def.activeCooldown != null && (
        <div className="roster-ability" title="Hero active ability">
          ⭐ Ability: {def.activeDamage} AoE, CD {def.activeCooldown}
        </div>
      )}
      <DamageMatrixTable def={def} matrix={matrix} />
    </div>
  );
}

export default function RosterPanel() {
  const defenders = UNIT_DEFS.filter((d) => d.kind === "defender");
  const heroes = UNIT_DEFS.filter((d) => d.kind === "hero");
  const crossSupport = UNIT_DEFS.filter((d) => d.kind === "cross_support");

  return (
    <section className="roster-panel" aria-label="Unit roster and damage matrix">
      <h3>Unit Roster</h3>
      <div className="roster-section">
        <h4>Defenders</h4>
        <div className="roster-grid">
          {defenders.map((d) => <RosterCard key={d.id} def={d} />)}
        </div>
      </div>
      <div className="roster-section">
        <h4>Heroes</h4>
        <div className="roster-grid">
          {heroes.map((d) => <RosterCard key={d.id} def={d} />)}
        </div>
      </div>
      <div className="roster-section">
        <h4>Cross-Front Support</h4>
        <div className="roster-grid">
          {crossSupport.map((d) => <RosterCard key={d.id} def={d} />)}
        </div>
      </div>
    </section>
  );
}
