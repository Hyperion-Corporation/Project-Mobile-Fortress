/**
 * dualFrontDemo.ts — ID8: Pure deterministic dual-front placement-and-raid sim.
 *
 * Framework-free TypeScript module. No Math.random without injectable seed.
 * Fixed timestep. Unit-testable.
 *
 * Two grids (land + sea), player places defenders with a budget, presses start,
 * raiders walk in along a path and are shot by placed defenders. Win if the raid
 * ends with HQ HP remaining; lose if HQ HP reaches 0.
 *
 * Slice 2 adds a hero with an active ability (area damage on auto-cooldown)
 * and a cross-front support unit that fires at both fronts with split damage.
 */

// ── Types ────────────────────────────────────────────────────────────────────

export type Front = "land" | "sea";
export type Phase = "placing" | "running" | "win" | "lose";
export type UnitKind = "defender" | "hero" | "cross_support";

export interface UnitDef {
  id: string;
  name: string;
  kind: UnitKind;
  front: Front | "both";
  cost: number;
  /** Currency used to pay for this unit ("land" or "sea"). */
  currency: "land" | "sea";
  hp: number;
  damage: number;
  /** Canonical range from unit_defs.gd (world units). */
  canonicalRange: number;
  /** Canonical cooldown from unit_defs.gd (seconds). */
  canonicalCooldown: number;
  /** Derived grid-cell range for the demo (Chebyshev distance). */
  range: number;
  /** Derived tick cooldown for the demo (1 tick = 100ms). */
  cooldown: number;
  /** Hero active ability cooldown (ticks). Absent for non-heroes. */
  activeCooldown?: number;
  /** Hero active ability damage (area). Absent for non-heroes. */
  activeDamage?: number;
  /** Damage multiplier vs raiders on the front the unit stands on. */
  ownEnvMult: number;
  /** Damage multiplier vs raiders on the opposite front. */
  crossEnvMult: number;
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
  /** Ticks until the hero's active ability is ready. Absent for non-heroes. */
  activeCooldownRemaining?: number;
  /** Which wallet was charged for this unit. Used for refund on removal. */
  paidFrom: Front;
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
// canonicalRange is in world units; canonicalCooldown is in seconds (from game).
// range = ceil(canonicalRange) for Chebyshev grid distance.
// cooldown = round(canonicalCooldown * 10) for 100ms ticks.
// ownEnvMult / crossEnvMult mirror the game's get_effective_damage rule.

export const UNIT_DEFS: UnitDef[] = [
  { id: "spearman", name: "Ming Garrison Spearman", kind: "defender", front: "land", cost: 10, currency: "land", hp: 40, damage: 8, canonicalRange: 1.6, canonicalCooldown: 0.7, range: 2, cooldown: 7, ownEnvMult: 1.0, crossEnvMult: 0.0 },
  { id: "cannon", name: "Fo-lang-ji Cannon Crew", kind: "defender", front: "land", cost: 18, currency: "land", hp: 30, damage: 14, canonicalRange: 2.8, canonicalCooldown: 1.2, range: 3, cooldown: 12, ownEnvMult: 1.0, crossEnvMult: 0.35 },
  { id: "arquebusier", name: "Portuguese Arquebusier", kind: "defender", front: "sea", cost: 12, currency: "sea", hp: 32, damage: 10, canonicalRange: 2.2, canonicalCooldown: 0.85, range: 2, cooldown: 9, ownEnvMult: 1.0, crossEnvMult: 0.25 },
  { id: "junk", name: "East Asian War Junk", kind: "defender", front: "sea", cost: 16, currency: "sea", hp: 45, damage: 11, canonicalRange: 1.8, canonicalCooldown: 0.9, range: 2, cooldown: 9, ownEnvMult: 1.0, crossEnvMult: 0.0 },
  { id: "hero_dias", name: "Capitão Dias (Hero)", kind: "hero", front: "both", cost: 26, currency: "sea", hp: 48, damage: 10, canonicalRange: 2.2, canonicalCooldown: 1.1, range: 2, cooldown: 11, ownEnvMult: 1.0, crossEnvMult: 0.65, activeCooldown: 100, activeDamage: 22 },
  { id: "hero_qi", name: "Commander Qi (Hero)", kind: "hero", front: "both", cost: 28, currency: "land", hp: 55, damage: 12, canonicalRange: 2.0, canonicalCooldown: 1.0, range: 2, cooldown: 10, ownEnvMult: 1.0, crossEnvMult: 0.5, activeCooldown: 80, activeDamage: 28 },
  { id: "cross_support", name: "Signal Battery", kind: "cross_support", front: "both", cost: 20, currency: "sea", hp: 28, damage: 6, canonicalRange: 12.0, canonicalCooldown: 1.1, range: 3, cooldown: 11, ownEnvMult: 0.55, crossEnvMult: 1.15 },
];

export const DEFAULT_CONFIG: DemoConfig = {
  cols: 6,
  rows: 3,
  pathRow: 1,
  landBudget: 60,
  seaBudget: 60,
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
  if (def.front !== "both" && def.front !== front) return `Unit is for ${def.front} front, not ${front}`;
  if (col < 0 || col >= config.cols) return "Column out of bounds";
  if (row < 0 || row >= config.rows) return "Row out of bounds";
  if (!config.placementRows.includes(row)) return "Cannot place on path row";

  const units = front === "land" ? state.landUnits : state.seaUnits;
  if (units.some((u) => u.col === col && u.row === row)) return "Cell occupied";

  // Own-wallet-first: charge the unit's currency first, fall back to clicked grid's wallet
  const ownWallet = def.currency === "land" ? state.landBudget : state.seaBudget;
  const gridWallet = front === "land" ? state.landBudget : state.seaBudget;
  const ownCurrencyMatchesGrid = def.currency === front;

  if (def.cost > ownWallet) {
    // Own wallet can't pay; try fallback to grid wallet (only if different)
    if (!ownCurrencyMatchesGrid && def.cost <= gridWallet) {
      // Fallback OK
    } else {
      return "Insufficient budget";
    }
  }

  return null;
}

/** Determine which wallet pays for a placement. Returns the front of the paying wallet. */
export function getPayingWallet(def: UnitDef, placedFront: Front, state: SimState): Front {
  const ownWallet = def.currency === "land" ? state.landBudget : state.seaBudget;
  if (def.cost <= ownWallet) return def.currency;
  return placedFront;
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
  const paidFrom = getPayingWallet(def, front, state);
  const unit: PlacedUnit = {
    uid: state.nextUid,
    defId,
    col,
    row,
    front,
    hp: def.hp,
    maxHp: def.hp,
    cooldownRemaining: 0,
    paidFrom,
    ...(def.activeCooldown != null ? { activeCooldownRemaining: 0 } : {}),
  };

  const next = { ...state, nextUid: state.nextUid + 1 };
  if (front === "land") {
    next.landUnits = [...state.landUnits, unit];
  } else {
    next.seaUnits = [...state.seaUnits, unit];
  }
  // Charge the paying wallet
  if (paidFrom === "land") {
    next.landBudget = state.landBudget - def.cost;
  } else {
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
    const next = {
      ...state,
      landUnits: state.landUnits.filter((u) => u.uid !== uid),
    };
    // Refund the wallet that was charged
    if (landMatch.paidFrom === "land") {
      next.landBudget = state.landBudget + def.cost;
    } else {
      next.seaBudget = state.seaBudget + def.cost;
    }
    return next;
  }

  const seaMatch = state.seaUnits.find((u) => u.uid === uid);
  if (seaMatch) {
    const def = getUnitDef(seaMatch.defId, config)!;
    const next = {
      ...state,
      seaUnits: state.seaUnits.filter((u) => u.uid !== uid),
    };
    // Refund the wallet that was charged
    if (seaMatch.paidFrom === "land") {
      next.landBudget = state.landBudget + def.cost;
    } else {
      next.seaBudget = state.seaBudget + def.cost;
    }
    return next;
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

    // Tick down hero ability cooldown
    const acr = unit.activeCooldownRemaining != null
      ? Math.max(0, unit.activeCooldownRemaining - 1)
      : undefined;

    if (unit.cooldownRemaining > 0) {
      updatedUnits.push({
        ...unit,
        cooldownRemaining: unit.cooldownRemaining - 1,
        ...(acr != null ? { activeCooldownRemaining: acr } : {}),
      });
      continue;
    }

    // Hero active ability: area damage to all raiders in range on the unit's front
    if (def.activeDamage != null && def.activeCooldown != null && (acr ?? 0) === 0) {
      const abilityTargets = raiders.filter((r) => {
        if (!r.alive || r.hp <= 0) return false;
        if (r.front !== unit.front) return false;
        const dx = Math.abs(r.col - unit.col);
        const dy = Math.abs(config.pathRow - unit.row);
        return Math.max(dx, dy) <= def.range;
      });
      if (abilityTargets.length > 0) {
        for (const t of abilityTargets) {
          t.hp -= def.activeDamage;
        }
        log.push(`Tick ${state.tick}: ${def.name} unleashes ability for ${def.activeDamage} on ${abilityTargets.length} raider(s)`);
        updatedUnits.push({
          ...unit,
          cooldownRemaining: def.cooldown,
          activeCooldownRemaining: def.activeCooldown,
        });
        continue;
      }
    }

    // Cross-support: fires at both fronts with env multipliers
    if (isCrossSupport(def)) {
      const ownTargets = raiders.filter((r) => {
        if (!r.alive || r.hp <= 0) return false;
        if (r.front !== unit.front) return false;
        const dx = Math.abs(r.col - unit.col);
        const dy = Math.abs(config.pathRow - unit.row);
        return Math.max(dx, dy) <= def.range;
      });
      const crossTargets = raiders.filter((r) => {
        if (!r.alive || r.hp <= 0) return false;
        if (r.front === unit.front) return false;
        const dx = Math.abs(r.col - unit.col);
        const dy = Math.abs(config.pathRow - unit.row);
        return Math.max(dx, dy) <= def.range;
      });
      const ownDmg = def.damage * def.ownEnvMult;
      const crossDmg = def.damage * def.crossEnvMult;
      let hit = false;
      if (ownTargets.length > 0) {
        const closest = ownTargets.sort((a, b) => a.col - b.col)[0];
        closest.hp -= ownDmg;
        log.push(`Tick ${state.tick}: ${def.name} hits ${unit.front} raider for ${ownDmg}`);
        hit = true;
      }
      if (crossTargets.length > 0) {
        const closest = crossTargets.sort((a, b) => a.col - b.col)[0];
        closest.hp -= crossDmg;
        const otherFront = unit.front === "land" ? "sea" : "land";
        log.push(`Tick ${state.tick}: ${def.name} hits ${otherFront} raider for ${crossDmg}`);
        hit = true;
      }
      if (hit) {
        updatedUnits.push({
          ...unit,
          cooldownRemaining: def.cooldown,
          ...(acr != null ? { activeCooldownRemaining: acr } : {}),
        });
      } else {
        updatedUnits.push({
          ...unit,
          cooldownRemaining: 0,
          ...(acr != null ? { activeCooldownRemaining: acr } : {}),
        });
      }
      continue;
    }

    // Normal defender: find closest alive raider on same front within range
    const target = findTarget(unit, def, raiders, config);
    if (target) {
      const dmg = def.damage * def.ownEnvMult;
      target.hp -= dmg;
      log.push(`Tick ${state.tick}: ${def.name} hits raider for ${dmg}`);
      updatedUnits.push({
        ...unit,
        cooldownRemaining: def.cooldown,
        ...(acr != null ? { activeCooldownRemaining: acr } : {}),
      });
    } else {
      updatedUnits.push({
        ...unit,
        cooldownRemaining: 0,
        ...(acr != null ? { activeCooldownRemaining: acr } : {}),
      });
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

// ── Unit classification helpers ──────────────────────────────────────────────

export function isHero(def: UnitDef): boolean {
  return def.kind === "hero";
}

export function isCrossSupport(def: UnitDef): boolean {
  return def.kind === "cross_support";
}

/** Returns 0..1 fraction of hero ability cooldown remaining (0 = ready). */
export function getAbilityCooldownFraction(unit: PlacedUnit, def: UnitDef): number {
  if (!isHero(def) || def.activeCooldown == null || def.activeCooldown === 0) return 0;
  return (unit.activeCooldownRemaining ?? 0) / def.activeCooldown;
}

/** Damage matrix: damage dealt when standing on front X vs target on front Y. */
export interface DamageMatrix {
  landVsLand: number;
  landVsSea: number;
  seaVsLand: number;
  seaVsSea: number;
}

export function getDamageMatrix(def: UnitDef): DamageMatrix {
  return {
    landVsLand: def.damage * def.ownEnvMult,
    landVsSea: def.damage * def.crossEnvMult,
    seaVsLand: def.damage * def.crossEnvMult,
    seaVsSea: def.damage * def.ownEnvMult,
  };
}
