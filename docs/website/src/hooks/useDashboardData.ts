/**
 * useDashboardData — shared data hook for the ID3 dashboard skeleton.
 *
 * Reads three static JSON files from /dashboard-data/ (committed to
 * public/dashboard-data/ in the Vite public root). Provides graceful
 * empty state when files are absent — expected in dev environments
 * before a collaborator has exported their first playtest batch.
 *
 * No live backend calls; all data is batch-committed by developers.
 * Live wiring is gated on backend.md B7 (ID4).
 */
import { useEffect, useState } from "react";

// ── RunRecord (mirrors DashboardRequirementsView.tsx) ─────────────────────────

export interface RunRecord {
  run_id: string;
  victory: boolean;
  reason: "hq_destroyed" | "all_waves_cleared" | "quit";
  duration_s: number;
  primary_civ: string;
  support_civ: string;
  wave_reached: number;
  hq_hp_remaining: number;
  smoke_ci_status?: "pass" | "fail" | "skipped";
}

// ── CI status ─────────────────────────────────────────────────────────────────

export interface CiTest {
  name: string;
  result: "pass" | "fail" | "unknown";
}

export interface CiWorkflow {
  name: string;
  status: "pass" | "fail" | "unknown";
  last_run: string;
  tests: CiTest[];
}

export interface CiStatus {
  updated: string;
  workflows: CiWorkflow[];
}

// ── Playtest sessions ─────────────────────────────────────────────────────────

export interface PlaytestSession {
  date: string;
  tester: string;
  platform: string;
  build_commit: string;
  hard_criteria_pass: boolean;
  art_criteria_pass: boolean;
  verdict: "shows_promise" | "needs_work" | "no";
  notes: string;
}

export interface PlaytestData {
  gate: string;
  sessions_required: number;
  sessions: PlaytestSession[];
  gate_decision: "pass" | "needs_work" | null;
}

// ── Hook ──────────────────────────────────────────────────────────────────────

export interface DashboardData {
  runs: RunRecord[];
  ci: CiStatus | null;
  playtest: PlaytestData | null;
  loading: boolean;
  error: string | null;
}

const BASE = "/dashboard-data";

async function fetchJson<T>(path: string): Promise<T | null> {
  try {
    const res = await fetch(path);
    if (!res.ok) return null;
    return (await res.json()) as T;
  } catch {
    return null;
  }
}

export function useDashboardData(): DashboardData {
  const [runs, setRuns] = useState<RunRecord[]>([]);
  const [ci, setCi] = useState<CiStatus | null>(null);
  const [playtest, setPlaytest] = useState<PlaytestData | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let cancelled = false;

    async function load() {
      setLoading(true);
      setError(null);
      try {
        const [runsData, ciData, playtestData] = await Promise.all([
          fetchJson<RunRecord[]>(`${BASE}/run_history.json`),
          fetchJson<CiStatus>(`${BASE}/ci_status.json`),
          fetchJson<PlaytestData>(`${BASE}/playtest_sessions.json`),
        ]);
        if (cancelled) return;
        setRuns(runsData ?? []);
        setCi(ciData);
        setPlaytest(playtestData);
      } catch (e) {
        if (!cancelled) setError(String(e));
      } finally {
        if (!cancelled) setLoading(false);
      }
    }

    load();
    return () => { cancelled = true; };
  }, []);

  return { runs, ci, playtest, loading, error };
}

// ── Derived helpers ───────────────────────────────────────────────────────────

/** Win rate as a 0–100 percentage string, or "—" if no runs. */
export function winRate(runs: RunRecord[]): string {
  if (!runs.length) return "—";
  const wins = runs.filter((r) => r.victory).length;
  return `${Math.round((wins / runs.length) * 100)}%`;
}

/** Average duration in seconds, or null. */
export function avgDuration(runs: RunRecord[]): number | null {
  if (!runs.length) return null;
  return Math.round(runs.reduce((a, r) => a + r.duration_s, 0) / runs.length);
}

/** Format seconds as "Xm Ys". */
export function fmtSeconds(s: number): string {
  const m = Math.floor(s / 60);
  const sec = s % 60;
  return m > 0 ? `${m}m ${sec}s` : `${sec}s`;
}

/** Average HQ HP remaining across victories only, or null. */
export function avgHqHp(runs: RunRecord[]): number | null {
  const victories = runs.filter((r) => r.victory);
  if (!victories.length) return null;
  return Math.round(victories.reduce((a, r) => a + r.hq_hp_remaining, 0) / victories.length);
}

/** Wave survival counts: how many runs reached each wave index. */
export function waveSurvivalCounts(runs: RunRecord[], totalWaves = 5): number[] {
  return Array.from({ length: totalWaves }, (_, i) =>
    runs.filter((r) => r.wave_reached > i).length
  );
}
