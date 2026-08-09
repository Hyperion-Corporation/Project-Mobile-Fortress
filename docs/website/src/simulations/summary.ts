import type { SimulationSample } from './repository/types';

/**
 * Framework-neutral, single source of truth for describing GA-convergence
 * progress as an accessible status string (MFP7 — cross-framework parity
 * kit). Both the React host and the Aurelia island call this same function
 * against the same `src/simulations/` data so their `role="status"`
 * summaries never drift out of sync with each other.
 */
export function convergenceSummary(samples: SimulationSample[], revealCount: number): string {
  if (samples.length === 0) return 'No convergence data yet.';
  const visible = samples.slice(0, Math.max(0, revealCount));
  const current = visible[visible.length - 1];
  if (!current) return `Awaiting first iteration of ${samples.length}.`;
  const done = revealCount >= samples.length;
  return done
    ? `Converged to cost ${current.cost} after ${samples.length} iterations.`
    : `Iteration ${current.iteration} of ${samples.length}: cost ${current.cost}.`;
}
