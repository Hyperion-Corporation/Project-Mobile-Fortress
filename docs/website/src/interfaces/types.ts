import type { ApproachKind, OutpostKind } from '../enums/OutpostKind';

export type CivilizationId =
  | 'ming'
  | 'joseon'
  | 'japan'
  | 'portuguese'
  | 'spanish'
  | 'dutch'
  | 'british'
  | 'french';

export type UnitDomain = 'land' | 'sea' | 'coast';

export interface UnitRosterEntry {
  id: string;
  name: string;
  civ: CivilizationId;
  domain: UnitDomain;
}

export interface OutpostNode {
  id: string;
  kind: OutpostKind;
  label: string;
  /** 0–1 map position for hub diagrams. */
  x: number;
  y: number;
}

export interface RaidLane {
  id: string;
  approach: ApproachKind;
  label: string;
  /** Polyline points in normalized map space. */
  points: Array<{ x: number; y: number }>;
}

export interface LoreStory {
  id: string;
  title: string;
  era: string;
  summary: string;
  tags: string[];
  /** Optional path into docs portal. */
  docPath?: string;
}
