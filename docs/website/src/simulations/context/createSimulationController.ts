import { generateConvergenceRun } from '../generator/convergence';
import { getSimulationScenario } from '../scenarios/scenarios';
import type { SimulationRun } from '../repository/types';

export interface SimulationController {
  scenarioId: string;
  run: SimulationRun;
  rerun(seed?: number): SimulationRun;
}

/** Lightweight controller for hub panels (framework-neutral). */
export function createSimulationController(scenarioId = 'coastal_balanced'): SimulationController {
  let scenario = getSimulationScenario(scenarioId);
  let run = generateConvergenceRun(scenario);

  return {
    get scenarioId() {
      return scenario.id;
    },
    get run() {
      return run;
    },
    rerun(seed?: number) {
      if (typeof seed === 'number') {
        scenario = { ...scenario, seed };
      }
      run = generateConvergenceRun(scenario);
      return run;
    },
  };
}
