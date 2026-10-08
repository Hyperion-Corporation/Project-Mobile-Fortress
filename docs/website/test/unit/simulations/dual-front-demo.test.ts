/**
 * dual-front-demo.test.ts — ID8: Pure simulation unit tests.
 *
 * Covers: placement validation, budget enforcement, deterministic outcome
 * for a fixed setup, win and lose paths.
 */
import { describe, expect, it } from "vitest";
import {
  createState,
  placeUnit,
  removeUnit,
  canPlace,
  startRun,
  tick,
  runToEnd,
  getUnitDef,
  isHero,
  isCrossSupport,
  getAbilityCooldownFraction,
  DEFAULT_CONFIG,
} from "../../../src/simulations/dualFrontDemo";

const CFG = DEFAULT_CONFIG;

// ── Placement validation ─────────────────────────────────────────────────────

describe("placement validation", () => {
  it("allows placement on valid placement rows", () => {
    const state = createState(CFG);
    expect(canPlace(state, "spearman", 0, 0, "land", CFG)).toBeNull();
    expect(canPlace(state, "spearman", 0, 2, "land", CFG)).toBeNull();
  });

  it("rejects placement on the path row", () => {
    const state = createState(CFG);
    expect(canPlace(state, "spearman", 0, 1, "land", CFG)).toBe("Cannot place on path row");
  });

  it("rejects placement on occupied cells", () => {
    let state = createState(CFG);
    state = placeUnit(state, "spearman", 0, 0, "land", CFG);
    expect(canPlace(state, "cannon", 0, 0, "land", CFG)).toBe("Cell occupied");
  });

  it("rejects placement out of bounds", () => {
    const state = createState(CFG);
    expect(canPlace(state, "spearman", -1, 0, "land", CFG)).toBe("Column out of bounds");
    expect(canPlace(state, "spearman", CFG.cols, 0, "land", CFG)).toBe("Column out of bounds");
    expect(canPlace(state, "spearman", 0, -1, "land", CFG)).toBe("Row out of bounds");
    expect(canPlace(state, "spearman", 0, CFG.rows, "land", CFG)).toBe("Row out of bounds");
  });

  it("rejects wrong-front units", () => {
    const state = createState(CFG);
    expect(canPlace(state, "spearman", 0, 0, "sea", CFG)).toBe("Unit is for land front, not sea");
    expect(canPlace(state, "arquebusier", 0, 0, "land", CFG)).toBe("Unit is for sea front, not land");
  });

  it("rejects unknown unit ids", () => {
    const state = createState(CFG);
    expect(canPlace(state, "nonexistent", 0, 0, "land", CFG)).toBe("Unknown unit");
  });
});

// ── Budget enforcement ───────────────────────────────────────────────────────

describe("budget enforcement", () => {
  it("deducts cost on placement", () => {
    let state = createState(CFG);
    expect(state.landBudget).toBe(60);
    state = placeUnit(state, "spearman", 0, 0, "land", CFG);
    expect(state.landBudget).toBe(50);
  });

  it("rejects placement when budget is insufficient", () => {
    let state = createState(CFG);
    state = placeUnit(state, "spearman", 0, 0, "land", CFG); // 60 - 10 = 50
    state = placeUnit(state, "spearman", 1, 0, "land", CFG); // 50 - 10 = 40
    state = placeUnit(state, "spearman", 2, 0, "land", CFG); // 40 - 10 = 30
    state = placeUnit(state, "spearman", 3, 0, "land", CFG); // 30 - 10 = 20
    state = placeUnit(state, "spearman", 4, 0, "land", CFG); // 20 - 10 = 10
    state = placeUnit(state, "spearman", 5, 0, "land", CFG); // 10 - 10 = 0
    expect(canPlace(state, "spearman", 0, 2, "land", CFG)).toBe("Insufficient budget");
  });

  it("refunds cost on removal", () => {
    let state = createState(CFG);
    state = placeUnit(state, "spearman", 0, 0, "land", CFG);
    expect(state.landBudget).toBe(50);
    const uid = state.landUnits[0].uid;
    state = removeUnit(state, uid, CFG);
    expect(state.landBudget).toBe(60);
    expect(state.landUnits).toHaveLength(0);
  });

  it("tracks land and sea budgets independently", () => {
    let state = createState(CFG);
    state = placeUnit(state, "spearman", 0, 0, "land", CFG);
    state = placeUnit(state, "arquebusier", 0, 0, "sea", CFG);
    expect(state.landBudget).toBe(50);
    expect(state.seaBudget).toBe(48);
  });
});

// ── Deterministic outcome ────────────────────────────────────────────────────

describe("deterministic outcome", () => {
  it("produces the same result for the same setup (no randomness)", () => {
    let state1 = createState(CFG);
    state1 = placeUnit(state1, "spearman", 1, 0, "land", CFG);
    state1 = placeUnit(state1, "spearman", 1, 2, "land", CFG);
    state1 = placeUnit(state1, "spearman", 3, 0, "land", CFG);
    state1 = placeUnit(state1, "arquebusier", 1, 0, "sea", CFG);
    state1 = placeUnit(state1, "arquebusier", 1, 2, "sea", CFG);
    state1 = placeUnit(state1, "arquebusier", 3, 0, "sea", CFG);
    state1 = startRun(state1);
    const result1 = runToEnd(state1, CFG);

    let state2 = createState(CFG);
    state2 = placeUnit(state2, "spearman", 1, 0, "land", CFG);
    state2 = placeUnit(state2, "spearman", 1, 2, "land", CFG);
    state2 = placeUnit(state2, "spearman", 3, 0, "land", CFG);
    state2 = placeUnit(state2, "arquebusier", 1, 0, "sea", CFG);
    state2 = placeUnit(state2, "arquebusier", 1, 2, "sea", CFG);
    state2 = placeUnit(state2, "arquebusier", 3, 0, "sea", CFG);
    state2 = startRun(state2);
    const result2 = runToEnd(state2, CFG);

    expect(result1).toEqual(result2);
    expect(result1.phase).toBe("win");
  });
});

// ── Win path ─────────────────────────────────────────────────────────────────

describe("win path", () => {
  it("wins when all raiders are killed before reaching HQ", () => {
    // Place enough defenders to kill all raiders
    let state = createState(CFG);
    // Land: 2 cannons (dmg 14, range 3, cd 12) can cover the path
    state = placeUnit(state, "cannon", 2, 0, "land", CFG);
    state = placeUnit(state, "cannon", 2, 2, "land", CFG);
    // Sea: 2 junks (dmg 11, range 2, cd 9)
    state = placeUnit(state, "junk", 2, 0, "sea", CFG);
    state = placeUnit(state, "junk", 2, 2, "sea", CFG);
    state = startRun(state);

    const result = runToEnd(state, CFG, 500);
    expect(result.phase).toBe("win");
    expect(result.hqHp).toBe(CFG.hqHp);
  });
});

// ── Lose path ────────────────────────────────────────────────────────────────

describe("lose path", () => {
  it("loses when no defenders are placed (raiders reach HQ)", () => {
    let state = createState(CFG);
    state = startRun(state);

    const result = runToEnd(state, CFG, 500);
    expect(result.phase).toBe("lose");
    expect(result.hqHp).toBeLessThanOrEqual(0);
  });
});

// ── Phase transitions ────────────────────────────────────────────────────────

describe("phase transitions", () => {
  it("starts in placing phase", () => {
    const state = createState(CFG);
    expect(state.phase).toBe("placing");
  });

  it("transitions to running on startRun", () => {
    let state = createState(CFG);
    state = startRun(state);
    expect(state.phase).toBe("running");
  });

  it("cannot place units during running phase", () => {
    let state = createState(CFG);
    state = startRun(state);
    const before = { ...state };
    state = placeUnit(state, "spearman", 0, 0, "land", CFG);
    expect(state).toEqual(before);
  });

  it("cannot startRun when not in placing phase", () => {
    let state = createState(CFG);
    state = startRun(state);
    const before = { ...state };
    state = startRun(state);
    expect(state.phase).toBe(before.phase);
  });
});

// ── Unit definitions ─────────────────────────────────────────────────────────

describe("unit definitions", () => {
  it("getUnitDef returns the correct definition", () => {
    const def = getUnitDef("spearman", CFG);
    expect(def).toBeDefined();
    expect(def!.name).toBe("Ming Garrison Spearman");
    expect(def!.front).toBe("land");
    expect(def!.cost).toBe(10);
  });

  it("getUnitDef returns undefined for unknown ids", () => {
    expect(getUnitDef("nonexistent", CFG)).toBeUndefined();
  });
});

// ── Tick behavior ────────────────────────────────────────────────────────────

describe("tick behavior", () => {
  it("does nothing in placing phase", () => {
    const state = createState(CFG);
    const next = tick(state, CFG);
    expect(next).toEqual(state);
  });

  it("increments tick counter", () => {
    let state = createState(CFG);
    state = startRun(state);
    state = tick(state, CFG);
    expect(state.tick).toBe(1);
    state = tick(state, CFG);
    expect(state.tick).toBe(2);
  });

  it("spawns raiders at the correct tick", () => {
    let state = createState(CFG);
    state = startRun(state);
    // First land raider spawns at tick 5
    for (let i = 0; i < 5; i++) {
      state = tick(state, CFG);
    }
    const landRaiders = state.raiders.filter((r) => r.front === "land");
    expect(landRaiders.length).toBeGreaterThanOrEqual(1);
  });
});

describe("raid schedule regressions", () => {
  it("spawns each front at its configured tick, even with interleaved wave entries", () => {
    let state = startRun(createState(CFG));
    for (let t = 1; t <= 53; t++) {
      state = tick(state, CFG);
      for (const front of ["land", "sea"] as const) {
        expect(state.raiders.filter((r) => r.front === front)).toHaveLength(
          CFG.waves.filter((w) => w.front === front && w.spawnTick <= t).length,
        );
      }
    }
  });
});

// ── Hero ability ──────────────────────────────────────────────────────────────

describe("hero ability", () => {
  it("hero_qi is classified as a hero", () => {
    const def = getUnitDef("hero_qi", CFG)!;
    expect(def).toBeDefined();
    expect(def.activeCooldown).toBe(80);
    expect(def.activeDamage).toBe(28);
  });

  it("hero starts with ability ready (activeCooldownRemaining = 0)", () => {
    let state = createState(CFG);
    state = placeUnit(state, "hero_qi", 2, 0, "land", CFG);
    expect(state.landUnits[0].activeCooldownRemaining).toBe(0);
  });

  it("hero ability damages every in-range land raider and leaves sea raiders untouched", () => {
    const config = { ...CFG, waves: [
      { front: "land" as const, spawnTick: 1, hp: 100, damage: 1, speed: 0 },
      { front: "land" as const, spawnTick: 1, hp: 100, damage: 1, speed: 0 },
      { front: "sea" as const, spawnTick: 1, hp: 100, damage: 1, speed: 0 },
    ] };
    let state = placeUnit(createState(config), "hero_qi", 2, 0, "land", config);
    state = tick(startRun(state), config);
    expect(state.raiders.filter(r => r.front === "land").map(r => r.hp)).toEqual([72, 72]);
    expect(state.raiders.filter(r => r.front === "sea").map(r => r.hp)).toEqual([100]);
    expect(state.landUnits[0].activeCooldownRemaining).toBe(80);
  });

  it("hero ability goes on cooldown after triggering", () => {
    let state = createState(CFG);
    state = placeUnit(state, "hero_qi", 2, 0, "land", CFG);
    state = startRun(state);

    // Advance to tick 5 so raider spawns and ability fires
    for (let i = 0; i < 5; i++) state = tick(state, CFG);

    const hero = state.landUnits[0];
    expect(hero.activeCooldownRemaining).toBeGreaterThan(0);
    expect(hero.activeCooldownRemaining).toBeLessThanOrEqual(80);
  });

  it("hero ability does not fire at raiders on the opposite front", () => {
    let state = createState(CFG);
    state = placeUnit(state, "hero_qi", 2, 0, "land", CFG);
    state = startRun(state);

    // Advance to tick 8 so a sea raider spawns (no land raiders yet after tick 5)
    for (let i = 0; i < 8; i++) state = tick(state, CFG);

    // Sea raiders should not have been hit by the hero's ability
    const seaRaiders = state.raiders.filter((r) => r.front === "sea");
    for (const r of seaRaiders) {
      expect(r.hp).toBe(r.maxHp);
    }
  });
});

// ── Cross-support ─────────────────────────────────────────────────────────────

describe("cross-support unit", () => {
  it("cross_support can be placed on either front", () => {
    let state = createState(CFG);
    expect(canPlace(state, "cross_support", 0, 0, "land", CFG)).toBeNull();
    expect(canPlace(state, "cross_support", 0, 0, "sea", CFG)).toBeNull();
  });

  it("cross_support is classified correctly", () => {
    const def = getUnitDef("cross_support", CFG)!;
    expect(def).toBeDefined();
    expect(def.front).toBe("both");
    expect(def.ownEnvMult).toBe(0.55);
    expect(def.crossEnvMult).toBe(1.15);
  });

  it.each(["land", "sea"] as const)("cross_support on %s deals exact single-hit damage to each front", (front) => {
    const config = { ...CFG, waves: [
      { front: "land" as const, spawnTick: 1, hp: 100, damage: 1, speed: 0 },
      { front: "sea" as const, spawnTick: 1, hp: 100, damage: 1, speed: 0 },
    ] };
    let state = placeUnit(createState(config), "cross_support", 3, 0, front, config);
    state = tick(startRun(state), config);
    expect(state.raiders.filter(r => r.front === front).map(r => r.hp)).toEqual([97]);
    expect(state.raiders.filter(r => r.front !== front).map(r => r.hp)).toEqual([93]);
  });

  it("cross_support deals reduced damage to own front and boosted to cross front", () => {
    const def = getUnitDef("cross_support", CFG)!;
    const ownDmg = Math.round(def.damage * def.ownEnvMult!);
    const crossDmg = Math.round(def.damage * def.crossEnvMult!);
    expect(ownDmg).toBe(3);
    expect(crossDmg).toBe(7);
  });
});

// ── Unit classification helpers ──────────────────────────────────────────────

describe("unit classification", () => {
  it("isHero returns true only for heroes", () => {
    expect(isHero(getUnitDef("hero_qi", CFG)!)).toBe(true);
    expect(isHero(getUnitDef("spearman", CFG)!)).toBe(false);
    expect(isHero(getUnitDef("cross_support", CFG)!)).toBe(false);
  });

  it("isCrossSupport returns true only for cross-support", () => {
    expect(isCrossSupport(getUnitDef("cross_support", CFG)!)).toBe(true);
    expect(isCrossSupport(getUnitDef("spearman", CFG)!)).toBe(false);
    expect(isCrossSupport(getUnitDef("hero_qi", CFG)!)).toBe(false);
  });

  it("getAbilityCooldownFraction returns 0..1", () => {
    let state = createState(CFG);
    state = placeUnit(state, "hero_qi", 2, 0, "land", CFG);
    const hero = state.landUnits[0];
    const def = getUnitDef("hero_qi", CFG)!;
    expect(getAbilityCooldownFraction(hero, def)).toBe(0);
  });
});
