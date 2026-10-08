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
    expect(state.landBudget).toBe(40);
    state = placeUnit(state, "spearman", 0, 0, "land", CFG);
    expect(state.landBudget).toBe(30);
  });

  it("rejects placement when budget is insufficient", () => {
    let state = createState(CFG);
    state = placeUnit(state, "spearman", 0, 0, "land", CFG); // 40 - 10 = 30
    state = placeUnit(state, "spearman", 1, 0, "land", CFG); // 30 - 10 = 20
    state = placeUnit(state, "spearman", 2, 0, "land", CFG); // 20 - 10 = 10
    state = placeUnit(state, "spearman", 3, 0, "land", CFG); // 10 - 10 = 0
    expect(canPlace(state, "spearman", 4, 0, "land", CFG)).toBe("Insufficient budget");
  });

  it("refunds cost on removal", () => {
    let state = createState(CFG);
    state = placeUnit(state, "spearman", 0, 0, "land", CFG);
    expect(state.landBudget).toBe(30);
    const uid = state.landUnits[0].uid;
    state = removeUnit(state, uid, CFG);
    expect(state.landBudget).toBe(40);
    expect(state.landUnits).toHaveLength(0);
  });

  it("tracks land and sea budgets independently", () => {
    let state = createState(CFG);
    state = placeUnit(state, "spearman", 0, 0, "land", CFG);
    state = placeUnit(state, "arquebusier", 0, 0, "sea", CFG);
    expect(state.landBudget).toBe(30);
    expect(state.seaBudget).toBe(28);
  });
});

// ── Deterministic outcome ────────────────────────────────────────────────────

describe("deterministic outcome", () => {
  it("produces the same result for the same setup (fixed seed)", () => {
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

    expect(result1.phase).toBe(result2.phase);
    expect(result1.tick).toBe(result2.tick);
    expect(result1.hqHp).toBe(result2.hqHp);
    expect(result1.raiders.length).toBe(result2.raiders.length);
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
    expect(result.hqHp).toBeGreaterThan(0);
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
