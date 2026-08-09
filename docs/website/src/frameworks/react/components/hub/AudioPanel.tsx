import { useEffect, useMemo, useRef, useState } from "react";

export default function AudioPanel() {
  const [enemyCount, setEnemyCount] = useState(2);
  const [healthLoss, setHealthLoss] = useState(0);
  const [boss, setBoss] = useState(0);
  const [waveHeights, setWaveHeights] = useState<number[]>(() => Array.from({ length: 20 }, () => 8));
  const rafRef = useRef(0);
  const timeoutRef = useRef<ReturnType<typeof setTimeout> | null>(null);

  const bossText = boss === 1 ? "Wōkòu Warlord" : boss === 2 ? "Pirate Fleet Admiral" : "None";
  const bossMod = boss === 1 ? 0.15 : boss === 2 ? 0.4 : 0;
  const excitement = Math.min(1, Math.max(0, enemyCount * 0.008 + healthLoss * 0.003 + bossMod));
  const state = excitement > 0.6 ? "Peak Siege Roar" : excitement > 0.25 ? "Night Defense" : "Day Preparation";
  const desc =
    excitement > 0.6
      ? "Executing heavy, rapid Taiko drum rolls and sweeping battle vocal loops!"
      : excitement > 0.25
        ? "Triggering light Taiko percussion tracks and dynamic Shamisen riffs."
        : "Playing ambient forest wind, rustling bamboo, and soft Shakuhachi flute loops.";
  const activeClass = excitement > 0.6 ? "active-warn" : excitement > 0.25 ? "active-gold" : "";

  const excitementRef = useRef(excitement);
  excitementRef.current = excitement;

  useEffect(() => {
    function animate() {
      const E = excitementRef.current;
      setWaveHeights(
        Array.from({ length: 20 }, () => {
          const base = 5 + E * 40;
          const variance = Math.random() * (10 + E * 30);
          return Math.min(75, base + variance);
        })
      );
      timeoutRef.current = setTimeout(() => {
        rafRef.current = requestAnimationFrame(animate);
      }, 120);
    }
    animate();
    return () => {
      if (rafRef.current) cancelAnimationFrame(rafRef.current);
      if (timeoutRef.current) clearTimeout(timeoutRef.current);
    };
  }, []);

  const wavesKey = useMemo(() => waveHeights.map((_, i) => i), [waveHeights.length]);

  return (
    <div className="tab-pane active" id="tab-audio">
      <div className="grid-2-col">
        <div className="panel glass">
          <h2>Dynamic Taiko Percussion &amp; Ambience</h2>
          <p>
            Ambient nature sounds and high-energy Taiko drums scale dynamically. The audio layers adjust using a
            centralized <strong>Excitement Scale</strong> ($E$) computed by the game loop:
          </p>
          <p className="math-formula">
            {"$$E = w_1 \\cdot \\text{EnemiesOnScreen} + w_2 \\cdot \\text{HQHealthLoss} + w_3 \\cdot \\text{BossPresence}$$"}
          </p>
          <div className="panel-dark profile-panel" style={{ marginTop: "1rem" }}>
            <h4>Pitch Excitement Modulators</h4>
            <div className="slider-group">
              <label>
                Active Enemies on Screen: <span>{enemyCount}</span>
              </label>
              <input
                type="range"
                min="0"
                max="60"
                value={enemyCount}
                onChange={(e) => setEnemyCount(Number(e.target.value))}
                className="slider"
              />
            </div>
            <div className="slider-group">
              <label>
                Fortress HQ Health Loss: <span>{healthLoss}%</span>
              </label>
              <input
                type="range"
                min="0"
                max="100"
                value={healthLoss}
                onChange={(e) => setHealthLoss(Number(e.target.value))}
                className="slider"
              />
            </div>
            <div className="slider-group">
              <label>
                On-Pitch Boss Presence: <span>{bossText}</span>
              </label>
              <input
                type="range"
                min="0"
                max="2"
                value={boss}
                onChange={(e) => setBoss(Number(e.target.value))}
                className="slider"
              />
            </div>
          </div>
        </div>

        <div className="panel glass flex-center">
          <h3>MetaSound Excitement Waveform</h3>
          <div className="audio-visualization-box panel-dark">
            <div className="wave-visualizer-container">
              <div className="audio-wave">
                {wavesKey.map((i) => (
                  <div
                    key={i}
                    className={`wave-bar${activeClass ? " " + activeClass : ""}`}
                    style={{ height: waveHeights[i] + "px" }}
                  />
                ))}
              </div>
            </div>
            <div className="stat-row" style={{ marginTop: "1rem" }}>
              <span>Atmosphere State:</span> <strong className="highlight">{state}</strong>
            </div>
            <div className="stat-row">
              <span>Calculated Excitement ($E$):</span> <strong>{excitement.toFixed(2)}</strong>
            </div>
            <div className="ai-speech" style={{ marginTop: "1rem" }}>
              <strong>Active Audio Track:</strong>
              <p>{desc}</p>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
