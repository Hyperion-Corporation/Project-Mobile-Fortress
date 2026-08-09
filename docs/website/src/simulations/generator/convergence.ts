import type { SimulationRun, SimulationScenario } from '../repository/types';

/** Mulberry32 — deterministic PRNG for hub demos. */
function mulberry32(seed: number) {
  return function next() {
    let t = (seed += 0x6d2b79f5);
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

/** Generate a monotonic-ish cost curve for GA / pathing hub panels. */
export function generateConvergenceRun(scenario: SimulationScenario): SimulationRun {
  const rand = mulberry32(scenario.seed);
  const samples = [];
  let cost = scenario.initialCost;
  for (let i = 0; i < scenario.iterations; i++) {
    const improve = cost * scenario.convergenceRate * (0.55 + rand() * 0.9);
    cost = Math.max(12, cost - improve + (rand() - 0.45) * 2.5);
    samples.push({ iteration: i, cost: Number(cost.toFixed(2)) });
  }
  return { scenarioId: scenario.id, seed: scenario.seed, samples };
}
