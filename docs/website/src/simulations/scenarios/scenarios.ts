import type { SimulationScenario } from '../repository/types';

export const SIMULATION_SCENARIOS: SimulationScenario[] = [
  {
    id: 'coastal_balanced',
    name: 'Balanced coastal defense',
    description: 'Even investment across land corridors and Fo-lang-ji coastal arcs.',
    seed: 1540,
    iterations: 28,
    initialCost: 148,
    convergenceRate: 0.09,
  },
  {
    id: 'sea_heavy',
    name: 'Sea-lane pressure',
    description: 'Naval approaches dominate; trading outposts under early threat.',
    seed: 1555,
    iterations: 28,
    initialCost: 164,
    convergenceRate: 0.075,
  },
  {
    id: 'land_siege',
    name: 'Land siege lanes',
    description: 'Intensified land raids testing resource-outpost coverage.',
    seed: 1560,
    iterations: 28,
    initialCost: 139,
    convergenceRate: 0.115,
  },
];

export function getSimulationScenario(id: string): SimulationScenario {
  return SIMULATION_SCENARIOS.find((s) => s.id === id) ?? SIMULATION_SCENARIOS[0];
}
