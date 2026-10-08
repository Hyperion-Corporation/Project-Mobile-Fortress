import { describe, it, expect } from "vitest";
import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { UNIT_DEFS, getUnitDef } from "../../../src/simulations/dualFrontDemo";
import { parseUnitDefsGd } from "../../../src/simulations/parseUnitDefs";

const REPO_ROOT = resolve(__dirname, "../../../../..");
const UNIT_DEFS_PATH = resolve(REPO_ROOT, "game/scripts/data/unit_defs.gd");

function loadGameCatalog() {
  const source = readFileSync(UNIT_DEFS_PATH, "utf-8");
  return parseUnitDefsGd(source);
}

describe("unit_defs.gd drift test", () => {
  const gameUnits = loadGameCatalog();

  it("parses all 7 playable units from unit_defs.gd", () => {
    expect(gameUnits.length).toBe(7);
    const ids = gameUnits.map((u) => u.id).sort();
    expect(ids).toEqual([
      "arquebusier", "cannon", "cross_support", "hero_dias", "hero_qi", "junk", "spearman",
    ]);
  });

  it("website has all units the game defines", () => {
    for (const g of gameUnits) {
      expect(getUnitDef(g.id), `missing unit: ${g.id}`).toBeDefined();
    }
  });

  it("cost matches for every shared unit", () => {
    for (const g of gameUnits) {
      const w = getUnitDef(g.id)!;
      expect(w.cost, `${g.id} cost`).toBe(g.cost);
    }
  });

  it("damage matches for every shared unit", () => {
    for (const g of gameUnits) {
      const w = getUnitDef(g.id)!;
      expect(w.damage, `${g.id} damage`).toBe(g.damage);
    }
  });

  it("own_env_mult matches for every shared unit", () => {
    for (const g of gameUnits) {
      const w = getUnitDef(g.id)!;
      expect(w.ownEnvMult, `${g.id} ownEnvMult`).toBeCloseTo(g.own_env_mult, 5);
    }
  });

  it("cross_env_mult matches for every shared unit", () => {
    for (const g of gameUnits) {
      const w = getUnitDef(g.id)!;
      expect(w.crossEnvMult, `${g.id} crossEnvMult`).toBeCloseTo(g.cross_env_mult, 5);
    }
  });

  it("currency matches for every shared unit", () => {
    for (const g of gameUnits) {
      const w = getUnitDef(g.id)!;
      expect(w.currency, `${g.id} currency`).toBe(g.currency);
    }
  });

  it("front matches for every shared unit", () => {
    for (const g of gameUnits) {
      const w = getUnitDef(g.id)!;
      expect(w.front, `${g.id} front`).toBe(g.front);
    }
  });

  it("kind matches for every shared unit", () => {
    for (const g of gameUnits) {
      const w = getUnitDef(g.id)!;
      expect(w.kind, `${g.id} kind`).toBe(g.kind);
    }
  });

  it("active_damage matches for heroes", () => {
    for (const g of gameUnits) {
      if (g.kind !== "hero") continue;
      const w = getUnitDef(g.id)!;
      expect(w.activeDamage, `${g.id} activeDamage`).toBe(g.active_damage);
    }
  });

  it("website has no extra playable units beyond the game catalog", () => {
    const gameIds = new Set(gameUnits.map((u) => u.id));
    for (const w of UNIT_DEFS) {
      expect(gameIds.has(w.id), `extra website unit: ${w.id}`).toBe(true);
    }
  });
});
