import type { CivilizationId, UnitRosterEntry } from '../interfaces/types';

/** Default player civ pair for the coastal TD fantasy. */
export const DEFAULT_CIVILIZATIONS = {
  primary: 'ming' as CivilizationId,
  support: 'portuguese' as CivilizationId,
} as const;

/** Illustrative unit roster labels for docs / hub (not authoritative combat stats). */
export const UNIT_ROSTER: UnitRosterEntry[] = [
  { id: 'ming_spearmen', name: 'Ming Garrison Spearmen', civ: 'ming', domain: 'land' },
  { id: 'folangji_crew', name: 'Fo-lang-ji Cannon Crew', civ: 'ming', domain: 'coast' },
  { id: 'east_asian_archers', name: 'East Asian Archers', civ: 'ming', domain: 'land' },
  { id: 'veteran_commanders', name: 'Veteran Commanders', civ: 'ming', domain: 'land' },
  { id: 'portuguese_arquebusiers', name: 'Portuguese Arquebusiers', civ: 'portuguese', domain: 'land' },
  { id: 'war_junks', name: 'East Asian War Junks', civ: 'ming', domain: 'sea' },
  { id: 'western_galleons', name: 'Western Galleons', civ: 'portuguese', domain: 'sea' },
];

/** Setting window used across design docs and stories. */
export const SETTING_ERA = {
  label: '1540s–1560s Wōkòu crisis',
  startYear: 1540,
  endYear: 1560,
  region: 'East Asian coast',
} as const;
