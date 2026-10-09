/**
 * citadelRank.ts — Citadel rank / prestige tier system.
 *
 * Browser-safe: no Node.js imports. Parsing and tier logic only.
 * File loading is done in tests and the demo view uses Vite's ?raw import.
 */

export interface PrestigeTier {
  rank: number;
  prestige_required: number;
  title: string;
  historical_title: string;
  description: string;
}

export interface NextTierResult {
  current_rank: number;
  max_rank_reached: boolean;
  remaining_prestige: number;
  progress_ratio: number;
  next_title: string;
  next_prestige_required: number;
}

/** Parse PRESTIGE_TIERS from progression.gd source. */
export function parsePrestigeTiers(source: string): PrestigeTier[] {
  const tiers: PrestigeTier[] = [];
  const blockRe = /\{\s*"rank"\s*:\s*(\d+)\s*,\s*"prestige_required"\s*:\s*(\d+)\s*,\s*"title"\s*:\s*"([^"]+)"\s*,\s*"historical_title"\s*:\s*"([^"]+)"\s*,\s*"description"\s*:\s*"([^"]+)"\s*\}/g;
  let m: RegExpExecArray | null;
  while ((m = blockRe.exec(source)) !== null) {
    tiers.push({
      rank: parseInt(m[1], 10),
      prestige_required: parseInt(m[2], 10),
      title: m[3],
      historical_title: m[4],
      description: m[5],
    });
  }
  return tiers;
}

/** Get the current tier for a given prestige value. Mirrors get_prestige_tier. */
export function getPrestigeTier(tiers: PrestigeTier[], prestige: number): PrestigeTier {
  let active = tiers[0];
  for (const tier of tiers) {
    if (prestige >= tier.prestige_required) {
      active = tier;
    } else {
      break;
    }
  }
  return { ...active };
}

/** Get next tier info with progress. Mirrors get_next_prestige_tier. */
export function getNextPrestigeTier(tiers: PrestigeTier[], prestige: number): NextTierResult {
  const current = getPrestigeTier(tiers, prestige);
  const next = tiers.find((t) => t.rank === current.rank + 1);

  if (!next) {
    return {
      current_rank: current.rank,
      max_rank_reached: true,
      remaining_prestige: 0,
      progress_ratio: 1.0,
      next_title: current.title,
      next_prestige_required: current.prestige_required,
    };
  }

  const needed = Math.max(0, next.prestige_required - prestige);
  const span = Math.max(1, next.prestige_required - current.prestige_required);
  const progress = Math.min(1.0, Math.max(0.0, (prestige - current.prestige_required) / span));

  return {
    current_rank: current.rank,
    max_rank_reached: false,
    remaining_prestige: needed,
    progress_ratio: progress,
    next_title: next.title,
    next_prestige_required: next.prestige_required,
  };
}
