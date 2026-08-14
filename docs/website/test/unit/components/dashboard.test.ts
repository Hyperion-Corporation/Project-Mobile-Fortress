/**
 * dashboard.test.ts — ID3 smoke tests
 *
 * Verifies that the four dashboard views and the shared data hook can be
 * imported without errors and that derived helper functions produce correct
 * output. DOM rendering is intentionally out of scope here — the existing
 * directives.test.tsx pattern covers mount tests; these are pure unit checks.
 */
import { describe, expect, it } from "vitest";

// ── Helper functions from useDashboardData ────────────────────────────────────

import {
  winRate,
  avgDuration,
  avgHqHp,
  fmtSeconds,
  waveSurvivalCounts,
  type RunRecord,
} from "../../../src/hooks/useDashboardData";

const SAMPLE_RUNS: RunRecord[] = [
  {
    run_id: "2026-08-11T14:22:00Z",
    victory: true,
    reason: "all_waves_cleared",
    duration_s: 487,
    primary_civ: "Ming",
    support_civ: "Portuguese",
    wave_reached: 5,
    hq_hp_remaining: 62,
    smoke_ci_status: "pass",
  },
  {
    run_id: "2026-08-11T15:01:00Z",
    victory: false,
    reason: "hq_destroyed",
    duration_s: 312,
    primary_civ: "Ming",
    support_civ: "Portuguese",
    wave_reached: 3,
    hq_hp_remaining: 0,
    smoke_ci_status: "pass",
  },
  {
    run_id: "2026-08-12T09:14:00Z",
    victory: true,
    reason: "all_waves_cleared",
    duration_s: 523,
    primary_civ: "Ming",
    support_civ: "Portuguese",
    wave_reached: 5,
    hq_hp_remaining: 45,
    smoke_ci_status: "pass",
  },
];

describe("useDashboardData helpers", () => {
  it("winRate returns — for empty runs", () => {
    expect(winRate([])).toBe("—");
  });

  it("winRate computes percentage correctly", () => {
    // 2/3 victories = 67%
    expect(winRate(SAMPLE_RUNS)).toBe("67%");
  });

  it("avgDuration returns null for empty runs", () => {
    expect(avgDuration([])).toBeNull();
  });

  it("avgDuration averages correctly", () => {
    // (487 + 312 + 523) / 3 = 440.67 → 441
    expect(avgDuration(SAMPLE_RUNS)).toBe(441);
  });

  it("avgHqHp considers victories only", () => {
    // victories: 62 + 45 = 107 / 2 = 53.5 → 54
    expect(avgHqHp(SAMPLE_RUNS)).toBe(54);
  });

  it("avgHqHp returns null when no victories", () => {
    const defeats: RunRecord[] = [{ ...SAMPLE_RUNS[1], victory: false }];
    expect(avgHqHp(defeats)).toBeNull();
  });

  it("fmtSeconds formats sub-minute correctly", () => {
    expect(fmtSeconds(45)).toBe("45s");
  });

  it("fmtSeconds formats minutes correctly", () => {
    expect(fmtSeconds(487)).toBe("8m 7s");
  });

  it("waveSurvivalCounts produces correct counts per wave", () => {
    // W1: all 3 reached (wave_reached > 0)
    // W2: all 3 (wave_reached > 1)
    // W3: all 3 (wave_reached > 2) — the defeat run had wave_reached: 3
    // W4: 2 runs (wave_reached > 3: 5 and 5)
    // W5: 0 runs (wave_reached > 4: none, 5 means last wave started not cleared for defeat)
    const counts = waveSurvivalCounts(SAMPLE_RUNS, 5);
    expect(counts).toHaveLength(5);
    expect(counts[0]).toBe(3); // reached W1
    expect(counts[1]).toBe(3); // reached W2
    expect(counts[2]).toBe(3); // reached W3
    expect(counts[3]).toBe(2); // reached W4 (wave_reached 5 > 3)
    expect(counts[4]).toBe(2); // reached W5 (wave_reached 5 > 4)
  });

  it("waveSurvivalCounts handles empty runs", () => {
    expect(waveSurvivalCounts([], 5)).toEqual([0, 0, 0, 0, 0]);
  });
});

// ── Import smoke: verify all four views can be imported ───────────────────────

describe("dashboard view imports smoke", () => {
  it("DashboardView module resolves", async () => {
    const mod = await import(
      "../../../src/frameworks/react/views/DashboardView"
    );
    expect(typeof mod.default).toBe("function");
  });

  it("RunHistoryView module resolves", async () => {
    const mod = await import(
      "../../../src/frameworks/react/views/RunHistoryView"
    );
    expect(typeof mod.default).toBe("function");
  });

  it("CiStatusView module resolves", async () => {
    const mod = await import(
      "../../../src/frameworks/react/views/CiStatusView"
    );
    expect(typeof mod.default).toBe("function");
  });

  it("PlaytestNotesView module resolves", async () => {
    const mod = await import(
      "../../../src/frameworks/react/views/PlaytestNotesView"
    );
    expect(typeof mod.default).toBe("function");
  });

  it("LoreMapView module resolves", async () => {
    const mod = await import(
      "../../../src/frameworks/react/views/LoreMapView"
    );
    expect(typeof mod.default).toBe("function");
  });

  it("UnitVisualizerView module resolves", async () => {
    const mod = await import(
      "../../../src/frameworks/react/views/UnitVisualizerView"
    );
    expect(typeof mod.default).toBe("function");
  });

  it("useDashboardData hook module resolves", async () => {
    const mod = await import("../../../src/hooks/useDashboardData");
    expect(typeof mod.useDashboardData).toBe("function");
    expect(typeof mod.winRate).toBe("function");
  });
});


