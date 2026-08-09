import { OutpostKind, ApproachKind } from "../../enums/OutpostKind";
import { LORE_STORIES } from "../../stories";
import type { LoreStory, OutpostNode, RaidLane } from "../../interfaces/types";

/**
 * Coastal fortress network layout backing the Apollo/GraphQL island — the
 * same Main HQ/Citadel + Resource/Trading Outpost model AGENTS.md's game
 * overview describes, laid out on the 0–1 map space `OutpostNode`/`RaidLane`
 * use elsewhere in this site.
 */
export const OUTPOSTS: OutpostNode[] = [
  { id: "citadel", kind: OutpostKind.Citadel, label: "Main HQ / Citadel", x: 0.5, y: 0.5 },
  { id: "resource-north", kind: OutpostKind.Resource, label: "Northern Grain Outpost", x: 0.42, y: 0.18 },
  { id: "resource-inland", kind: OutpostKind.Resource, label: "Inland Silk Outpost", x: 0.68, y: 0.42 },
  { id: "trading-cove", kind: OutpostKind.Trading, label: "Trading Cove", x: 0.14, y: 0.55 },
  { id: "trading-strait", kind: OutpostKind.Trading, label: "Strait Trading Post", x: 0.22, y: 0.82 },
];

export const RAID_LANES: RaidLane[] = [
  {
    id: "land-north",
    approach: ApproachKind.Land,
    label: "Northern land corridor",
    points: [
      { x: 0.05, y: 0.1 },
      { x: 0.3, y: 0.28 },
      { x: 0.5, y: 0.5 },
    ],
  },
  {
    id: "sea-west",
    approach: ApproachKind.Sea,
    label: "Western sea approach",
    points: [
      { x: 0.02, y: 0.6 },
      { x: 0.2, y: 0.55 },
      { x: 0.5, y: 0.5 },
    ],
  },
  {
    id: "sea-south",
    approach: ApproachKind.Sea,
    label: "Southern strait approach",
    points: [
      { x: 0.1, y: 0.9 },
      { x: 0.3, y: 0.7 },
      { x: 0.5, y: 0.5 },
    ],
  },
];

export function getOutposts(): OutpostNode[] {
  return OUTPOSTS;
}

export function getRaidLanes(): RaidLane[] {
  return RAID_LANES;
}

export function getLoreStories(): LoreStory[] {
  return LORE_STORIES;
}

export function getLoreStoryById(id: string): LoreStory | null {
  return LORE_STORIES.find((s) => s.id === id) ?? null;
}
