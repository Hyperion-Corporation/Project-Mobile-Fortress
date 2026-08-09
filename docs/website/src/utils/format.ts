/** Shared formatting helpers for hub panels and docs chrome. */

export function formatPercent(value: number, digits = 0): string {
  return `${(value * 100).toFixed(digits)}%`;
}

export function formatYearRange(start: number, end: number): string {
  return `${start}–${end}`;
}

export function clamp(n: number, min: number, max: number): number {
  return Math.min(max, Math.max(min, n));
}
