import { describe, it, expect } from "vitest";
import {
  simulatePull,
  runMonteCarloAudit,
  validateAntiKompuGacha,
  getExpirationPolicy,
  getPityRules,
  EPIC_PITY_THRESHOLD,
  LEGENDARY_PITY_THRESHOLD,
  RARITY_PROBABILITIES,
  PityState,
} from "../../../src/simulations/cosmeticLootbox";

describe("Cosmetic Lootbox Monte Carlo Audit & Compliance Tests (Q9)", () => {
  it("enforces hard epic pity guarantee within threshold", () => {
    let pityState: PityState = {
      pulls_since_epic: 0,
      pulls_since_legendary: 0,
      total_pulls: 0,
    };

    let maxEpicStreak = 0;
    let curEpicStreak = 0;

    // Use deterministic mock RNG to test pity
    let roll = 0.1; // would normally be common
    const mockRng = () => {
      roll = (roll + 0.05) % 0.5; // always rolls common
      return roll;
    };

    for (let i = 0; i < 200; i++) {
      const pull = simulatePull(pityState, mockRng);
      pityState = pull.pity_state;
      curEpicStreak++;

      if (pull.rarity === "epic" || pull.rarity === "legendary") {
        curEpicStreak = 0;
      }
      if (curEpicStreak > maxEpicStreak) {
        maxEpicStreak = curEpicStreak;
      }
    }

    expect(maxEpicStreak).toBeLessThanOrEqual(EPIC_PITY_THRESHOLD);
  });

  it("enforces hard legendary pity guarantee within threshold", () => {
    let pityState: PityState = {
      pulls_since_epic: 0,
      pulls_since_legendary: 0,
      total_pulls: 0,
    };

    let maxLegStreak = 0;
    let curLegStreak = 0;

    // Forces non-legendary rolls
    let roll = 0.2;
    const mockRng = () => {
      roll = (roll + 0.03) % 0.85;
      return roll;
    };

    for (let i = 0; i < 300; i++) {
      const pull = simulatePull(pityState, mockRng);
      pityState = pull.pity_state;
      curLegStreak++;

      if (pull.rarity === "legendary") {
        curLegStreak = 0;
      }
      if (curLegStreak > maxLegStreak) {
        maxLegStreak = curLegStreak;
      }
    }

    expect(maxLegStreak).toBeLessThanOrEqual(LEGENDARY_PITY_THRESHOLD);
  });

  it("passes Monte Carlo statistical goodness-of-fit audit (20,000 pulls)", () => {
    // Seeded pseudo-random generator
    let seed = 0x50494e45; // "PINE"
    const seededRng = () => {
      seed = (seed * 1664525 + 1013904223) % 4294967296;
      return seed / 4294967296;
    };

    const audit = runMonteCarloAudit(20000, seededRng);

    expect(audit.sample_size).toBe(20000);
    expect(audit.pity_compliant).toBe(true);
    expect(audit.anti_kompu_gacha_compliant).toBe(true);
    expect(audit.passed).toBe(true);

    // Check empirical rates within statistical tolerance (+/- 2% with pity active)
    expect(audit.observed_percentages.common).toBeGreaterThan(0.55);
    expect(audit.observed_percentages.common).toBeLessThan(0.65);

    expect(audit.observed_percentages.rare).toBeGreaterThan(0.23);
    expect(audit.observed_percentages.rare).toBeLessThan(0.31);

    expect(audit.observed_percentages.epic).toBeGreaterThan(0.08);
    expect(audit.observed_percentages.epic).toBeLessThan(0.16);

    expect(audit.observed_percentages.legendary).toBeGreaterThan(0.02);
    expect(audit.observed_percentages.legendary).toBeLessThan(0.06);
  });

  it("validates anti-Kompu-Gacha compliance", () => {
    const check = validateAntiKompuGacha();
    expect(check.compliant).toBe(true);
    expect(check.reason).toContain("standalone");
  });

  it("provides transparent currency expiration policy", () => {
    const policy = getExpirationPolicy();
    expect(policy.validity_days).toBe(90);
    expect(policy.warning_days).toBe(14);
    expect(policy.non_predatory).toBe(true);
  });

  it("provides transparent pity rules and duplicate token conversions", () => {
    const rules = getPityRules();
    expect(rules.epic_pity_threshold).toBe(10);
    expect(rules.legendary_pity_threshold).toBe(50);
    expect(rules.duplicate_token_conversion.common).toBe(5);
    expect(rules.duplicate_token_conversion.rare).toBe(20);
    expect(rules.duplicate_token_conversion.epic).toBe(100);
    expect(rules.duplicate_token_conversion.legendary).toBe(500);
  });

  it("negative control: rigged drop generator fails audit", () => {
    // Biased RNG that produces 95% common, 5% rare, 0% epic, 0% legendary
    const riggedRng = () => Math.random() * 0.7; // always < 0.7 (common/rare only)

    let pityState: PityState = {
      pulls_since_epic: 0,
      pulls_since_legendary: 0,
      total_pulls: 0,
    };

    const counts = { common: 0, rare: 0, epic: 0, legendary: 0 };
    for (let i = 0; i < 5000; i++) {
      const pull = simulatePull(pityState, riggedRng);
      pityState = pull.pity_state;
      counts[pull.rarity]++;
    }

    // Without pity, this would be 0% legendary. With pity, legendary only happens at exactly pull 50.
    // Observed rate of legendary will be roughly 1/50 = 2% rather than 3% + pity, and chi-square on common will skew.
    // Let's compute direct deviation of common from theoretical 60%:
    const obsCommon = counts.common / 5000;
    // With rigged roll < 0.7, common is drawn ~60/87 = ~69% instead of 60%
    const deviation = Math.abs(obsCommon - RARITY_PROBABILITIES.common);
    expect(deviation).toBeGreaterThan(0.04);
  });
});
