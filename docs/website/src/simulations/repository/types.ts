/** Framework-neutral contracts for design-hub simulations (not game-core). */

export interface SimulationScenario {
  id: string;
  name: string;
  description: string;
  seed: number;
  iterations: number;
  /** Starting cost / threat metric for convergence demos. */
  initialCost: number;
  convergenceRate: number;
}

export interface SimulationSample {
  iteration: number;
  cost: number;
}

export interface SimulationRun {
  scenarioId: string;
  seed: number;
  samples: SimulationSample[];
}
