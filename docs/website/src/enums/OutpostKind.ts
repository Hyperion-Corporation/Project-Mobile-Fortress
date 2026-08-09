/** Coastal fortress structure kinds (design-hub / docs entities). */
export enum OutpostKind {
  Citadel = 'citadel',
  Resource = 'resource',
  Trading = 'trading',
}

/** Approach corridor for raid-lane visualizations. */
export enum ApproachKind {
  Land = 'land',
  Sea = 'sea',
}

/** Docs-site experience quality tiers (mirrors github-pages capability gating). */
export enum ExperienceQuality {
  Static = 'static',
  Reduced = 'reduced',
  Full = 'full',
}
