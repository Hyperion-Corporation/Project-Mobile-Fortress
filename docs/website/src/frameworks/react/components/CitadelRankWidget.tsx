import { useState, useCallback } from "react";
import {
  getPrestigeTier,
  getNextPrestigeTier,
  type PrestigeTier,
} from "../../../simulations/citadelRank";
import "./CitadelRankWidget.css";

interface CitadelRankWidgetProps {
  tiers: PrestigeTier[];
}

export default function CitadelRankWidget({ tiers }: CitadelRankWidgetProps) {
  const [prestige, setPrestige] = useState(0);
  const current = getPrestigeTier(tiers, prestige);
  const next = getNextPrestigeTier(tiers, prestige);
  const maxPrestige = tiers[tiers.length - 1].prestige_required;

  const handleChange = useCallback((e: React.ChangeEvent<HTMLInputElement>) => {
    setPrestige(Math.max(0, Math.min(99999, Math.floor(Number(e.target.value) || 0))));
  }, []);

  const progressPct = Math.round(next.progress_ratio * 100);

  return (
    <section className="citadel-rank-widget" aria-label="Citadel rank progression">
      <h3>Citadel Rank</h3>

      <div className="crw-current">
        <div className="crw-rank-badge" data-testid="crw-rank-badge">
          <span className="crw-rank-num">Rank {current.rank}</span>
          <span className="crw-title">{current.title}</span>
          <span className="crw-historical">{current.historical_title}</span>
        </div>
        <p className="crw-description">{current.description}</p>
      </div>

      <div className="crw-control">
        <label htmlFor="crw-prestige-input">
          Prestige: <strong data-testid="crw-prestige-value">{prestige}</strong>
        </label>
        <input
          id="crw-prestige-input"
          type="range"
          min={0}
          max={maxPrestige}
          step={1}
          value={Math.min(prestige, maxPrestige)}
          onChange={handleChange}
          aria-label="Prestige slider"
          data-testid="crw-prestige-slider"
        />
        <input
          type="number"
          min={0}
          max={99999}
          value={prestige}
          onChange={handleChange}
          aria-label="Prestige value (number input)"
          data-testid="crw-prestige-number"
          className="crw-number-input"
        />
      </div>

      <div className="crw-progress" data-testid="crw-progress">
        {next.max_rank_reached ? (
          <div className="crw-max-rank">
            <span>🏆 Max rank reached!</span>
            <span className="crw-max-title">{current.title}</span>
          </div>
        ) : (
          <>
            <div className="crw-progress-bar">
              <div
                className="crw-progress-fill"
                style={{ width: `${progressPct}%` }}
                role="progressbar"
                aria-valuenow={progressPct}
                aria-valuemin={0}
                aria-valuemax={100}
                aria-label={`Progress to next rank: ${progressPct}%`}
                data-testid="crw-progress-fill"
              />
            </div>
            <div className="crw-progress-info">
              <span>Next: <strong>{next.next_title}</strong></span>
              <span data-testid="crw-remaining">{next.remaining_prestige} prestige needed</span>
              <span>{progressPct}%</span>
            </div>
          </>
        )}
      </div>

      <div className="crw-all-ranks">
        <h4>All Ranks</h4>
        <ol className="crw-rank-list">
          {tiers.map((t) => (
            <li
              key={t.rank}
              className={`crw-rank-item ${t.rank === current.rank ? "crw-active" : ""} ${t.rank < current.rank ? "crw-earned" : ""}`}
              data-testid={`crw-rank-${t.rank}`}
            >
              <span className="crw-rank-num">{t.rank}</span>
              <span className="crw-rank-title">{t.title}</span>
              <span className="crw-rank-threshold">{t.prestige_required}</span>
            </li>
          ))}
        </ol>
      </div>
    </section>
  );
}
