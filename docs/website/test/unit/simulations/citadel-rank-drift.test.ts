import { describe, it, expect } from "vitest";
import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { parsePrestigeTiers, getPrestigeTier, getNextPrestigeTier } from "../../../src/simulations/citadelRank";

const REPO_ROOT = resolve(__dirname, "../../../../..");
const PROGRESSION_PATH = resolve(REPO_ROOT, "game/scripts/data/progression.gd");

function loadGameTiers() {
  const source = readFileSync(PROGRESSION_PATH, "utf-8");
  return parsePrestigeTiers(source);
}

describe("progression.gd drift test", () => {
  const gameTiers = loadGameTiers();

  it("parses all 6 prestige tiers from progression.gd", () => {
    expect(gameTiers.length).toBe(6);
  });

  it("tier ranks are 0-5 in order", () => {
    expect(gameTiers.map((t) => t.rank)).toEqual([0, 1, 2, 3, 4, 5]);
  });

  it("tier thresholds match game data", () => {
    expect(gameTiers.map((t) => t.prestige_required)).toEqual([0, 250, 750, 1500, 3000, 5000]);
  });

  it("tier titles match game data", () => {
    expect(gameTiers.map((t) => t.title)).toEqual([
      "Coastal Beacon",
      "Sentry Bastion",
      "Garrison Fortress",
      "Maritime Citadel",
      "Commander Headquarters",
      "Imperial Coastal Stronghold",
    ]);
  });

  it("tier historical titles match game data", () => {
    expect(gameTiers.map((t) => t.historical_title)).toEqual([
      "烽火台 (Fenghuotai)",
      "哨所堡 (Shaosuobao)",
      "千户所城 (Qianhusuo)",
      "卫城 (Weicheng)",
      "总兵督府 (Zongbing Dufu)",
      "海防总要塞 (Haifang Zongyaosai)",
    ]);
  });

  it("getPrestigeTier returns correct tier at threshold boundaries", () => {
    expect(getPrestigeTier(gameTiers, 0).rank).toBe(0);
    expect(getPrestigeTier(gameTiers, 249).rank).toBe(0);
    expect(getPrestigeTier(gameTiers, 250).rank).toBe(1);
    expect(getPrestigeTier(gameTiers, 749).rank).toBe(1);
    expect(getPrestigeTier(gameTiers, 750).rank).toBe(2);
    expect(getPrestigeTier(gameTiers, 5000).rank).toBe(5);
    expect(getPrestigeTier(gameTiers, 99999).rank).toBe(5);
  });

  it("getNextPrestigeTier returns max_rank_reached at rank 5", () => {
    const result = getNextPrestigeTier(gameTiers, 5000);
    expect(result.max_rank_reached).toBe(true);
    expect(result.current_rank).toBe(5);
    expect(result.remaining_prestige).toBe(0);
    expect(result.progress_ratio).toBe(1.0);
  });

  it("getNextPrestigeTier computes correct progress just below threshold", () => {
    const result = getNextPrestigeTier(gameTiers, 749);
    expect(result.max_rank_reached).toBe(false);
    expect(result.current_rank).toBe(1);
    expect(result.next_title).toBe("Garrison Fortress");
    expect(result.next_prestige_required).toBe(750);
    expect(result.remaining_prestige).toBe(1);
    // progress = (749 - 250) / (750 - 250) = 499/500 = 0.998
    expect(result.progress_ratio).toBeCloseTo(0.998, 3);
  });

  it("getNextPrestigeTier computes correct progress at mid-point", () => {
    const result = getNextPrestigeTier(gameTiers, 1125);
    expect(result.current_rank).toBe(2);
    expect(result.next_title).toBe("Maritime Citadel");
    // progress = (1125 - 750) / (1500 - 750) = 375/750 = 0.5
    expect(result.progress_ratio).toBeCloseTo(0.5, 5);
    expect(result.remaining_prestige).toBe(375);
  });
});
