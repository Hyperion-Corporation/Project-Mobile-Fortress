/**
 * parseUnitDefs.ts — Parse game/scripts/data/unit_defs.gd and extract the
 * playable unit catalog (defenders, heroes, cross-support) as structured data.
 *
 * Used by the drift test to verify the website's UNIT_DEFS match the game's
 * source of truth.
 */

export interface GdUnitEntry {
  id: string;
  name: string;
  front: string;
  kind: string;
  cost: number;
  currency: string;
  hp: number;
  damage: number;
  range: number;
  cooldown: number;
  own_env_mult: number;
  cross_env_mult: number;
  active_cooldown?: number;
  active_damage?: number;
  aura_radius?: number;
  aura_damage_bonus?: number;
}

const FRONT_MAP: Record<string, string> = {
  "Front.LAND": "land",
  "Front.SEA": "sea",
  "Front.BOTH": "both",
};

const KIND_MAP: Record<string, string> = {
  "Kind.DEFENDER": "defender",
  "Kind.HERO": "hero",
  "Kind.CROSS_SUPPORT": "cross_support",
  "Kind.RAIDER": "raider",
};

function extractBlock(source: string, id: string): string | null {
  const pattern = new RegExp(`"${id}"\\s*:\\s*\\{`, "g");
  const match = pattern.exec(source);
  if (!match) return null;
  const start = match.index + match[0].indexOf("{");
  let depth = 0;
  for (let i = start; i < source.length; i++) {
    if (source[i] === "{") depth++;
    if (source[i] === "}") {
      depth--;
      if (depth === 0) return source.slice(start + 1, i);
    }
  }
  return null;
}

function parseField(block: string, key: string): string | undefined {
  const re = new RegExp(`"${key}"\\s*:\\s*(.+)`);
  const m = re.exec(block);
  if (!m) return undefined;
  return m[1].trim().replace(/,\s*$/, "");
}

function parseNumeric(block: string, key: string): number | undefined {
  const raw = parseField(block, key);
  if (raw === undefined) return undefined;
  const n = parseFloat(raw);
  return isNaN(n) ? undefined : n;
}

function parseString(block: string, key: string): string | undefined {
  const raw = parseField(block, key);
  if (raw === undefined) return undefined;
  const m = /^"(.*)"$/.exec(raw);
  return m ? m[1] : raw;
}

function parseEnum(block: string, key: string, map: Record<string, string>): string | undefined {
  const raw = parseField(block, key);
  if (raw === undefined) return undefined;
  return map[raw] ?? raw;
}

export function parseUnitDefsGd(source: string): GdUnitEntry[] {
  const ids = [
    "spearman", "cannon", "arquebusier", "junk",
    "hero_dias", "hero_qi",
    "cross_support",
  ];

  const results: GdUnitEntry[] = [];
  for (const id of ids) {
    const block = extractBlock(source, id);
    if (!block) continue;

    const kind = parseEnum(block, "kind", KIND_MAP);
    if (kind === "raider") continue;

    const entry: GdUnitEntry = {
      id,
      name: parseString(block, "name") ?? "",
      front: parseEnum(block, "front", FRONT_MAP) ?? "land",
      kind: kind ?? "defender",
      cost: parseNumeric(block, "cost") ?? 0,
      currency: parseString(block, "currency") ?? "land",
      hp: parseNumeric(block, "hp") ?? 0,
      damage: parseNumeric(block, "damage") ?? 0,
      range: parseNumeric(block, "range") ?? 0,
      cooldown: parseNumeric(block, "cooldown") ?? 0,
      own_env_mult: parseNumeric(block, "own_env_mult") ?? 1.0,
      cross_env_mult: parseNumeric(block, "cross_env_mult") ?? 0.0,
    };

    const acd = parseNumeric(block, "active_cooldown");
    if (acd !== undefined) entry.active_cooldown = acd;
    const admg = parseNumeric(block, "active_damage");
    if (admg !== undefined) entry.active_damage = admg;
    const ar = parseNumeric(block, "aura_radius");
    if (ar !== undefined) entry.aura_radius = ar;
    const adb = parseNumeric(block, "aura_damage_bonus");
    if (adb !== undefined) entry.aura_damage_bonus = adb;

    results.push(entry);
  }

  return results;
}
