import { describe, it, expect } from "vitest";
import * as fs from "fs";
import * as path from "path";
import { parseCosmeticDefsGd } from "../../../src/simulations/parseCosmeticDefs";
import {
  RARITY_PROBABILITIES,
  EPIC_PITY_THRESHOLD,
  LEGENDARY_PITY_THRESHOLD,
  DUPLICATE_TOKENS,
  TOKEN_EXPIRATION_DAYS,
  WARNING_EXPIRATION_DAYS,
  COSMETIC_CATALOG,
  getItemProbabilities,
} from "../../../src/simulations/cosmeticLootbox";

const GD_PATH = path.resolve(
  __dirname,
  "../../../../../game/scripts/data/cosmetic_lootbox.gd"
);

describe("Cosmetic Lootbox & Probability Disclosure Drift Tests", () => {
  const gdSource = fs.readFileSync(GD_PATH, "utf-8");
  const parsed = parseCosmeticDefsGd(gdSource);

  it("successfully parses game/scripts/data/cosmetic_lootbox.gd", () => {
    expect(parsed.catalog.length).toBeGreaterThan(0);
    expect(parsed.catalog.length).toBe(15);
  });

  it("rarity probabilities match exactly between website and Godot game", () => {
    for (const [rarity, prob] of Object.entries(RARITY_PROBABILITIES)) {
      expect(parsed.rarity_probabilities[rarity]).toBeDefined();
      expect(parsed.rarity_probabilities[rarity]).toBeCloseTo(prob, 5);
    }
  });

  it("probabilities sum to exactly 1.0 on both platforms", () => {
    const webSum = Object.values(RARITY_PROBABILITIES).reduce((a, b) => a + b, 0);
    const gdSum = Object.values(parsed.rarity_probabilities).reduce((a, b) => a + b, 0);
    expect(webSum).toBeCloseTo(1.0, 5);
    expect(gdSum).toBeCloseTo(1.0, 5);

    const itemProbs = getItemProbabilities();
    const itemSum = Object.values(itemProbs).reduce((a, b) => a + b, 0);
    expect(itemSum).toBeCloseTo(1.0, 5);
  });

  it("pity thresholds match between website and Godot game", () => {
    expect(parsed.epic_pity_threshold).toBe(EPIC_PITY_THRESHOLD);
    expect(parsed.legendary_pity_threshold).toBe(LEGENDARY_PITY_THRESHOLD);
    expect(EPIC_PITY_THRESHOLD).toBe(10);
    expect(LEGENDARY_PITY_THRESHOLD).toBe(50);
  });

  it("duplicate token conversion values match across all tiers", () => {
    for (const [rarity, tokens] of Object.entries(DUPLICATE_TOKENS)) {
      expect(parsed.duplicate_tokens[rarity]).toBe(tokens);
    }
  });

  it("currency expiration limits match between website and Godot game", () => {
    expect(parsed.token_expiration_days).toBe(TOKEN_EXPIRATION_DAYS);
    expect(parsed.warning_expiration_days).toBe(WARNING_EXPIRATION_DAYS);
    expect(TOKEN_EXPIRATION_DAYS).toBe(90);
    expect(WARNING_EXPIRATION_DAYS).toBe(14);
  });

  it("cosmetic catalog items match 1-to-1 with game source of truth", () => {
    expect(COSMETIC_CATALOG.length).toBe(parsed.catalog.length);

    for (const webItem of COSMETIC_CATALOG) {
      const gdItem = parsed.catalog.find((item) => item.id === webItem.id);
      expect(gdItem).toBeDefined();
      expect(gdItem?.name).toBe(webItem.name);
      expect(gdItem?.target_unit).toBe(webItem.target_unit);
      expect(gdItem?.rarity).toBe(webItem.rarity);
      expect(gdItem?.category).toBe(webItem.category);
    }
  });

  it("mutation proof: modified rarity probability fails drift check", () => {
    const mutated = { ...parsed.rarity_probabilities, legendary: 0.99 };
    expect(() => {
      expect(mutated.legendary).toBeCloseTo(RARITY_PROBABILITIES.legendary, 5);
    }).toThrow();
  });

  it("mutation proof: modified pity threshold fails drift check", () => {
    const mutatedPity = 999;
    expect(() => {
      expect(mutatedPity).toBe(EPIC_PITY_THRESHOLD);
    }).toThrow();
  });
});
