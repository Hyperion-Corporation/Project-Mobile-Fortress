/**
 * parseCosmeticDefs.ts — Parse game/scripts/data/cosmetic_lootbox.gd and extract
 * the cosmetic lootbox catalog, probability disclosures, pity rules, and duplicate tokens.
 *
 * Used by unit drift tests to verify the website's transparency model matches the
 * Godot game's source of truth.
 */

export interface GdCosmeticItem {
  id: string;
  name: string;
  target_unit: string;
  rarity: string;
  category: string;
  description: string;
}

export interface GdCosmeticDefs {
  rarity_probabilities: Record<string, number>;
  epic_pity_threshold: number;
  legendary_pity_threshold: number;
  duplicate_tokens: Record<string, number>;
  token_expiration_days: number;
  warning_expiration_days: number;
  catalog: GdCosmeticItem[];
}

export function parseCosmeticDefsGd(source: string): GdCosmeticDefs {
  // Extract RARITY_PROBABILITIES
  const rarityProbs: Record<string, number> = {};
  const probBlockMatch = source.match(/const RARITY_PROBABILITIES:\s*Dictionary\s*=\s*\{([\s\S]*?)\}/);
  if (probBlockMatch) {
    const lines = probBlockMatch[1].split("\n");
    for (const line of lines) {
      const m = line.match(/(RARITY_\w+|\w+)\s*:\s*([\d.]+)/);
      if (m) {
        const key = m[1].replace("RARITY_", "").toLowerCase();
        rarityProbs[key] = parseFloat(m[2]);
      }
    }
  }

  // Extract Pity Thresholds
  let epicPity = 10;
  const epicMatch = source.match(/const EPIC_PITY_THRESHOLD\s*:=\s*(\d+)/);
  if (epicMatch) epicPity = parseInt(epicMatch[1], 10);

  let legPity = 50;
  const legMatch = source.match(/const LEGENDARY_PITY_THRESHOLD\s*:=\s*(\d+)/);
  if (legMatch) legPity = parseInt(legMatch[1], 10);

  // Extract Duplicate Tokens
  const dupTokens: Record<string, number> = {};
  const dupMatch = source.match(/const DUPLICATE_TOKENS:\s*Dictionary\s*=\s*\{([\s\S]*?)\}/);
  if (dupMatch) {
    const lines = dupMatch[1].split("\n");
    for (const line of lines) {
      const m = line.match(/(RARITY_\w+|\w+)\s*:\s*(\d+)/);
      if (m) {
        const key = m[1].replace("RARITY_", "").toLowerCase();
        dupTokens[key] = parseInt(m[2], 10);
      }
    }
  }

  // Extract Expiration Days
  let tokenExpDays = 90;
  const expMatch = source.match(/const TOKEN_EXPIRATION_DAYS\s*:=\s*(\d+)/);
  if (expMatch) tokenExpDays = parseInt(expMatch[1], 10);

  let warnExpDays = 14;
  const warnMatch = source.match(/const WARNING_EXPIRATION_DAYS\s*:=\s*(\d+)/);
  if (warnMatch) warnExpDays = parseInt(warnMatch[1], 10);

  // Extract COSMETIC_CATALOG
  const catalog: GdCosmeticItem[] = [];
  const catalogMatch = source.match(/const COSMETIC_CATALOG:\s*Array\[Dictionary\]\s*=\s*\[([\s\S]*?)\]\s*\n\s*\n/);
  if (catalogMatch) {
    const catalogContent = catalogMatch[1];
    // Find all item dictionary blocks: { ... }
    const itemRegex = /\{([\s\S]*?)\}/g;
    let match: RegExpExecArray | null;
    while ((match = itemRegex.exec(catalogContent)) !== null) {
      const block = match[1];
      const idM = block.match(/"id"\s*:\s*"([^"]+)"/);
      const nameM = block.match(/"name"\s*:\s*"([^"]+)"/);
      const unitM = block.match(/"target_unit"\s*:\s*"([^"]+)"/);
      const rarityM = block.match(/"rarity"\s*:\s*(RARITY_\w+|"[^"]+")/);
      const catM = block.match(/"category"\s*:\s*"([^"]+)"/);
      const descM = block.match(/"description"\s*:\s*"([^"]+)"/);

      if (idM && nameM && unitM && rarityM) {
        let rarityVal = rarityM[1].replace(/"/g, "");
        if (rarityVal.startsWith("RARITY_")) {
          rarityVal = rarityVal.replace("RARITY_", "").toLowerCase();
        }
        catalog.push({
          id: idM[1],
          name: nameM[1],
          target_unit: unitM[1],
          rarity: rarityVal,
          category: catM ? catM[1] : "unit_skin",
          description: descM ? descM[1] : "",
        });
      }
    }
  }

  return {
    rarity_probabilities: rarityProbs,
    epic_pity_threshold: epicPity,
    legendary_pity_threshold: legPity,
    duplicate_tokens: dupTokens,
    token_expiration_days: tokenExpDays,
    warning_expiration_days: warnExpDays,
    catalog,
  };
}
