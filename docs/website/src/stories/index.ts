import type { LoreStory } from '../interfaces/types';
import { WOKOU_CRISIS } from './wokouCrisis';
import { COASTAL_FORTRESS } from './coastalFortress';
import { ALLIED_CIVILIZATIONS } from './alliedCivilizations';

/** Catalog of in-world lore for the docs site / design hub. */
export const LORE_STORIES: LoreStory[] = [WOKOU_CRISIS, COASTAL_FORTRESS, ALLIED_CIVILIZATIONS];

export function getLoreStory(id: string): LoreStory | undefined {
  return LORE_STORIES.find((s) => s.id === id);
}

export { WOKOU_CRISIS, COASTAL_FORTRESS, ALLIED_CIVILIZATIONS };
