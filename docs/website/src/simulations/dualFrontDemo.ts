/**
 * dualFrontDemo.ts — ID8: Pure deterministic dual-front placement-and-raid sim.
 *
 * Framework-free TypeScript module. No Math.random without injectable seed.
 * Fixed timestep. Unit-testable.
 *
 * Two grids (land + sea), player places defenders with a budget, presses start,
 * raiders walk in along a path and are shot by placed defenders. Win if the raid
 * ends with HQ HP remaining; lose if HQ HP reaches 0.
 */

// ── Types ────────────────────────────────────────────────────────────────────

export type Front = "land" | "sea";
export type Phase = "placing" | "running" | "win" | "lose";

export interface UnitDef {
  id: string;
  name: string;
  front: Front;
  cost: number;
  hp: number;
  damage: number;
  range: number;
  cooldown: number;
}

export interface PlacedUnit {
  uid: number;
  defId: string;
  col: number;
  row: number;
  front: Front;
  hp: number;
  maxHp: number;
  cooldownRemaining: number;
}

export interface Raider {
  uid: number;
  front: Front;
  hp: number;
  maxHp: number;
  damage: number;
  /** Fractional column position along the path (row is fixed to PATH_ROW). */
  col: number;
  speed: number;
  alive: boolean;
}

export interface WaveEntry {
  front: Front;
  /** Tick number at which this raider spawns. */
  spawnTick: number;
  hp: number;
  damage: number;
  speed: number;
}

export interface DemoConfig {
  cols: number;
  rows: number;
  pathRow: number;
  landBudget: number;
  seaBudget: number;
  hqHp: number;
  /** Placement rows — cells where the player can place defenders. */
  placementRows: number[];
  waves: WaveEntry[];
  unitDefs: UnitDef[];
}

export interface SimState {
  phase: Phase;
  tick: number;
  landBudget: number;
  seaBudget: number;
  landUnits: PlacedUnit[];
  seaUnits: PlacedUnit[];
  raiders: Raider[];
  hqHp: number;
  maxHqHp: number;
  nextUid: number;
  /** Raiders spawned so far (index into waves array). */
  spawnedCount: number;
  log: string[];
}

// Roster names, costs, HP and damage follow game/scripts/data/unit_defs.gd.
// Range is simplified for this grid; cooldowns are rounded to 100 ms ticks.

export const UNIT_DEFS: UnitDef[] = [
  { id: "spearman", name: "Ming Garrison Spearman", front: "land", cost: 10, hp: 40, damage: 8, range: 2, cooldown: 7 },
  { id: "cannon", name: "Fo-lang-ji Cannon Crew", front: "land", cost: 18, hp: 30, damage: 14, range: 3, cooldown: 12 },
  { id: "arquebusier", name: "Portuguese Arquebusier", front: "sea", cost: 12, hp: 32, damage: 10, range: 2, cooldown: 9 },
  { id: "junk", name: "East Asian War Junk", front: "sea", cost: 16, hp: 45, damage: 11, range: 2, cooldown: 9 },
];

export const DEFAULT_CONFIG: DemoConfig = {
  cols: 6,
  rows: 3,
  pathRow: 1,
  landBudget: 40,
  seaBudget: 40,
  hqHp: 50,
  placementRows: [0, 2],
  waves: buildWaves(),
  unitDefs: UNIT_DEFS,
};

function buildWaves(): WaveEntry[] {
  const entries: WaveEntry[] = [];
  // Land raiders: 4 raiders, staggered every 15 ticks
  for (let i = 0; i < 4; i++) {
    entries.push({ front: "land", spawnTick: 5 + i * 15, hp: 28, damage: 8, speed: 1 / 8 });
  }
  // Sea raiders: 4 raiders, staggered every 15 ticks, offset by 8 ticks
  for (let i = 0; i < 4; i++) {
    entries.push({ front: "sea", spawnTick: 8 + i * 15, hp: 32, damage: 9, speed: 1 / 10 });
  }
  return entries;
}

// ── Sim lifecycle ────────────────────────────────────────────────────────────

export function createState(config: DemoConfig = DEFAULT_CONFIG): SimState {
  return {
    phase: "placing",
    tick: 0,
    landBudget: config.landBudget,
    seaBudget: config.seaBudget,
    landUnits: [],
    seaUnits: [],
    raiders: [],
    hqHp: config.hqHp,
    maxHqHp: config.hqHp,
    nextUid: 1,
    spawnedCount: 0,
    log: [],
  };
}

export function getUnitDef(defId: string, config: DemoConfig = DEFAULT_CONFIG): UnitDef | undefined {
  return config.unitDefs.find((d) => d.id === defId);
}

export function canPlace(
  state: SimState,
  defId: string,
  col: number,
  row: number,
  front: Front,
  config: DemoConfig = DEFAULT_CONFIG,
): string | null {
  if (state.phase !== "placing") return "Not in placement phase";
  const def = getUnitDef(defId, config);
  if (!def) return "Unknown unit";
  if (def.front !== front) return `Unit is for ${def.front} front, not ${front}`;
  if (col < 0 || col >= config.cols) return "Column out of bounds";
  if (row < 0 || row >= config.rows) return "Row out of bounds";
  if (!config.placementRows.includes(row)) return "Cannot place on path row";

  const units = front === "land" ? state.landUnits : state.seaUnits;
  if (units.some((u) => u.col === col && u.row === row)) return "Cell occupied";

  const budget = front === "land" ? state.landBudget : state.seaBudget;
  if (def.cost > budget) return "Insufficient budget";

  return null;
}

export function placeUnit(
  state: SimState,
  defId: string,
  col: number,
  row: number,
  front: Front,
  config: DemoConfig = DEFAULT_CONFIG,
): SimState {
  const err = canPlace(state, defId, col, row, front, config);
  if (err) return state;

  const def = getUnitDef(defId, config)!;
  const unit: PlacedUnit = {
    uid: state.nextUid,
    defId,
    col,
    row,
    front,
    hp: def.hp,
    maxHp: def.hp,
    cooldownRemaining: 0,
  };

  const next = { ...state, nextUid: state.nextUid + 1 };
  if (front === "land") {
    next.landUnits = [...state.landUnits, unit];
    next.landBudget = state.landBudget - def.cost;
  } else {
    next.seaUnits = [...state.seaUnits, unit];
    next.seaBudget = state.seaBudget - def.cost;
  }
  return next;
}

export function removeUnit(
  state: SimState,
  uid: number,
  config: DemoConfig = DEFAULT_CONFIG,
): SimState {
  if (state.phase !== "placing") return state;

  const landMatch = state.landUnits.find((u) => u.uid === uid);
  if (landMatch) {
    const def = getUnitDef(landMatch.defId, config)!;
    return {
      ...state,
      landUnits: state.landUnits.filter((u) => u.uid !== uid),
      landBudget: state.landBudget + def.cost,
    };
  }

  const seaMatch = state.seaUnits.find((u) => u.uid === uid);
  if (seaMatch) {
    const def = getUnitDef(seaMatch.defId, config)!;
    return {
      ...state,
      seaUnits: state.seaUnits.filter((u) => u.uid !== uid),
      seaBudget: state.seaBudget + def.cost,
    };
  }

  return state;
}

export function startRun(state: SimState): SimState {
  if (state.phase !== "placing") return state;
  return { ...state, phase: "running", tick: 0, spawnedCount: 0, log: ["— Run started —"] };
}

// ── Tick (pure, deterministic) ───────────────────────────────────────────────

/**
 * Advance the simulation by one tick. Pure function — returns a new state.
 * Deterministic: same input state + config → same output state.
 */
export function tick(state: SimState, config: DemoConfig = DEFAULT_CONFIG): SimState {
  if (state.phase !== "running") return state;

  let s = { ...state, tick: state.tick + 1, log: [...state.log] };

  // 1. Spawn raiders due this tick
  s = spawnDue(s, config);

  // 2. Move raiders
  s = moveRaiders(s, config);

  // 3. Defenders fire
  s = defendersFire(s, config);

  // 4. Remove dead raiders
  s = { ...s, raiders: s.raiders.map((r) => (r.hp <= 0 ? { ...r, alive: false } : r)) };

  // 5. Check raiders reaching HQ
  s = checkHqDamage(s, config);

  // 6. Check win/lose
  s = checkEndConditions(s, config);

  return s;
}

function spawnDue(state: SimState, config: DemoConfig): SimState {
  const newRaiders: Raider[] = [];
  let spawned = state.spawnedCount;

  // Accept waves grouped by front as well as chronologically ordered input.
  const waves = [...config.waves].sort((a, b) => a.spawnTick - b.spawnTick);
  for (let i = state.spawnedCount; i < waves.length; i++) {
    const w = waves[i];
    if (w.spawnTick > state.tick) break;
    newRaiders.push({
      uid: state.nextUid + newRaiders.length,
      front: w.front,
      hp: w.hp,
      maxHp: w.hp,
      damage: w.damage,
      col: 0,
      speed: w.speed,
      alive: true,
    });
    spawned = i + 1;
  }

  if (newRaiders.length === 0) return state;
  return {
    ...state,
    raiders: [...state.raiders, ...newRaiders],
    spawnedCount: spawned,
    nextUid: state.nextUid + newRaiders.length,
    log: [...state.log, `Tick ${state.tick}: ${newRaiders.length} raider(s) spawned`],
  };
}

function moveRaiders(state: SimState, _config: DemoConfig): SimState {
  const moved = state.raiders.map((r) => {
    if (!r.alive || r.hp <= 0) return r;
    return { ...r, col: r.col + r.speed };
  });
  return { ...state, raiders: moved };
}

function defendersFire(state: SimState, config: DemoConfig): SimState {
  const allUnits = [...state.landUnits, ...state.seaUnits];
  const raiders = state.raiders.map((r) => ({ ...r }));
  const log = [...state.log];
  const updatedUnits: PlacedUnit[] = [];

  for (const unit of allUnits) {
    const def = getUnitDef(unit.defId, config)!;

    if (unit.cooldownRemaining > 0) {
      updatedUnits.push({ ...unit, cooldownRemaining: unit.cooldownRemaining - 1 });
      continue;
    }

    // Find target: closest alive raider on same front within range
    const target = findTarget(unit, def, raiders, config);
    if (target) {
      target.hp -= def.damage;
      log.push(`Tick ${state.tick}: ${def.name} hits raider for ${def.damage}`);
      updatedUnits.push({ ...unit, cooldownRemaining: def.cooldown });
    } else {
      updatedUnits.push({ ...unit, cooldownRemaining: 0 });
    }
  }

  const landUnits = updatedUnits.filter((u) => u.front === "land");
  const seaUnits = updatedUnits.filter((u) => u.front === "sea");

  return { ...state, landUnits, seaUnits, raiders, log };
}

function findTarget(
  unit: PlacedUnit,
  def: UnitDef,
  raiders: Raider[],
  config: DemoConfig,
): Raider | null {
  let best: Raider | null = null;
  let bestCol = Infinity;

  for (const r of raiders) {
    if (!r.alive || r.hp <= 0) continue;
    if (r.front !== unit.front) continue;

    // Distance: Chebyshev from unit cell to raider position
    const dx = Math.abs(r.col - unit.col);
    const dy = Math.abs(config.pathRow - unit.row);
    const dist = Math.max(dx, dy);

    if (dist <= def.range && r.col < bestCol) {
      best = r;
      bestCol = r.col;
    }
  }

  return best;
}

function checkHqDamage(state: SimState, config: DemoConfig): SimState {
  let hqHp = state.hqHp;
  const log = [...state.log];

  const raiders = state.raiders.map((r) => {
    if (r.alive && r.col >= config.cols) {
      hqHp -= r.damage;
      log.push(`Tick ${state.tick}: raider reached HQ! -${r.damage} HP`);
      return { ...r, alive: false, hp: 0 };
    }
    return r;
  });

  return { ...state, hqHp, raiders, log };
}

function checkEndConditions(state: SimState, config: DemoConfig): SimState {
  if (state.hqHp <= 0) {
    return { ...state, phase: "lose", log: [...state.log, "— HQ destroyed! DEFEAT —"] };
  }

  const allSpawned = state.spawnedCount >= config.waves.length;
  const allDead = state.raiders.every((r) => !r.alive || r.hp <= 0);

  if (allSpawned && allDead) {
    return { ...state, phase: "win", log: [...state.log, "— Raid survived! VICTORY —"] };
  }

  return state;
}

// ── Run-to-completion helper (for tests) ─────────────────────────────────────

/**
 * Run ticks until the simulation ends (win/lose) or maxTicks is reached.
 * Returns the final state.
 */
export function runToEnd(state: SimState, config: DemoConfig = DEFAULT_CONFIG, maxTicks = 500): SimState {
  let s = state;
  let ticks = 0;
  while (s.phase === "running" && ticks < maxTicks) {
    s = tick(s, config);
    ticks++;
  }
  return s;
}
