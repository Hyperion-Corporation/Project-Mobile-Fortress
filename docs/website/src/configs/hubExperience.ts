import { ExperienceQuality } from '../enums/OutpostKind';

/** Tunables for design-hub panels and island embeds. */
export const HUB_EXPERIENCE = {
  maxDevicePixelRatio: 1.75,
  reducedDevicePixelRatio: 1,
  defaultQuality: ExperienceQuality.Full,
  /** Default iframe height for Astro coastal flow-field island. */
  coastalFlowFieldHeight: '460px',
  /** Flow-field grid resolution for design-hub demos (not game-core authority). */
  flowFieldResolution: 14,
  flowFieldSeed: 1540,
} as const;
