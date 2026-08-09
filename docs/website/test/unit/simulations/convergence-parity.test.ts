import { describe, expect, it } from 'vitest';
import { convergenceSummary } from '../../../src/simulations/summary';
import { createSimulationController } from '../../../src/simulations/context/createSimulationController';
import { ConvergenceChartApp } from '../../../src/frameworks/aurelia/convergence-chart-app';

// MFP7 — cross-framework parity kit. ConvergenceStatus.tsx (React) and
// ConvergenceChartApp's `statusSummary` getter (Aurelia) both call
// convergenceSummary() directly, so this asserts the *shared source of
// truth* behaves correctly and that the Aurelia island's own getter (not
// just the underlying function) matches a React-side call with the same
// controller state — proving the two independently-rendered frameworks
// can't drift apart.
describe('convergence summary — cross-framework parity (MFP7)', () => {
  it('produces identical text for React and Aurelia from the same run', () => {
    const controller = createSimulationController();
    const { samples } = controller.run;

    // React side: ConvergenceStatus.tsx calls convergenceSummary() directly.
    const reactSummary = convergenceSummary(samples, samples.length);

    // Aurelia side: exercise the actual island class, not just the shared
    // helper, so a regression in how the getter wires its own state
    // (samples/revealCount) would fail this test too.
    const island = new ConvergenceChartApp();
    island.controller = controller;
    island.samples = samples;
    island.revealCount = samples.length;
    const aureliaSummary = island.statusSummary;

    expect(aureliaSummary).toBe(reactSummary);
    expect(reactSummary).toMatch(/^Converged to cost -?\d+(\.\d+)? after \d+ iterations\.$/);
  });

  it('describes in-progress and empty states consistently', () => {
    expect(convergenceSummary([], 0)).toBe('No convergence data yet.');

    const samples = [
      { iteration: 1, cost: 100 },
      { iteration: 2, cost: 80 },
      { iteration: 3, cost: 60 },
    ];
    expect(convergenceSummary(samples, 0)).toBe('Awaiting first iteration of 3.');
    expect(convergenceSummary(samples, 2)).toBe('Iteration 2 of 3: cost 80.');
    expect(convergenceSummary(samples, 3)).toBe('Converged to cost 60 after 3 iterations.');
  });
});
