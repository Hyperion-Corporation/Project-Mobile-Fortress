import { useMemo, useState } from "react";
import { UNIT_ROSTER, DEFAULT_CIVILIZATIONS } from "../../constants/fortress";
import type { CivilizationId, UnitDomain } from "../../interfaces/types";

/**
 * Live filterable browser over Mobile Fortress's real unit roster
 * (src/constants/fortress.ts) — the same data src/stories/ and the design
 * docs draw from. This is the island that actually mounts it inside the
 * docs site (see UnitRosterBoardWrapper.vue); Storybook (../../../stories/)
 * documents the component in isolation.
 */
const DOMAINS: Array<{ id: UnitDomain | "all"; label: string; icon: string }> = [
  { id: "all", label: "All domains", icon: "🗺️" },
  { id: "land", label: "Land", icon: "🛡️" },
  { id: "sea", label: "Sea", icon: "⚓" },
  { id: "coast", label: "Coast", icon: "🌊" },
];

export function UnitRosterBoard() {
  const [domain, setDomain] = useState<UnitDomain | "all">("all");
  const [civ, setCiv] = useState<CivilizationId | "all">("all");

  const filtered = useMemo(
    () =>
      UNIT_ROSTER.filter((u) => (domain === "all" ? true : u.domain === domain)).filter((u) =>
        civ === "all" ? true : u.civ === civ
      ),
    [domain, civ]
  );

  return (
    <div className="unit-roster-board">
      <div className="urb-filters">
        <div className="urb-filter-group" role="group" aria-label="Filter by domain">
          {DOMAINS.map((d) => (
            <button
              key={d.id}
              type="button"
              className={`urb-chip${domain === d.id ? " active" : ""}`}
              onClick={() => setDomain(d.id)}
            >
              <span aria-hidden="true">{d.icon}</span> {d.label}
            </button>
          ))}
        </div>
        <div className="urb-filter-group" role="group" aria-label="Filter by civilization">
          {(["all", DEFAULT_CIVILIZATIONS.primary, DEFAULT_CIVILIZATIONS.support] as const).map((c) => (
            <button
              key={c}
              type="button"
              className={`urb-chip${civ === c ? " active" : ""}`}
              onClick={() => setCiv(c)}
            >
              {c === "all" ? "All civs" : c}
            </button>
          ))}
        </div>
      </div>

      <ul className="urb-list">
        {filtered.map((u) => (
          <li key={u.id} className="urb-row">
            <span className="urb-name">{u.name}</span>
            <span className={`urb-badge urb-badge-${u.domain}`}>{u.domain}</span>
            <span className="urb-civ">{u.civ}</span>
          </li>
        ))}
        {filtered.length === 0 && <li className="urb-empty">No units match this filter.</li>}
      </ul>
    </div>
  );
}

export default UnitRosterBoard;
