/**
 * UnitVisualizerView — /dashboard/visualizer — ID7: Unit & Outpost Visualizer
 *
 * Interactive 2.5D/3D tactical model inspector with 360° rotation, action states,
 * lighting shader filters (Paper/Ink, Day Coastal, Dusk Wōkòu), and combat spec metrics.
 */
import { useState, useMemo } from "react";
import { Link } from "react-router-dom";
import { DEFAULT_CIVILIZATIONS } from "../../../constants/fortress";

interface UnitModelSpec {
  id: string;
  name: string;
  nameZh: string;
  civ: "Ming" | "Portuguese" | "Wōkòu Raider" | "Neutral";
  domain: "Land" | "Sea" | "Coastal / Cross-Front";
  role: string;
  hp: number;
  dps: number;
  range: number;
  cost: string;
  abilities: string[];
  description: string;
  visualType: "infantry" | "cannon" | "naval" | "hero" | "outpost" | "raider";
  primaryColor: string;
  accentColor: string;
}

const MODEL_SPECS: UnitModelSpec[] = [
  {
    id: "hero_qi",
    name: "General Qi Jiguang (Hero Commander)",
    nameZh: "戚繼光 · 總兵官",
    civ: "Ming",
    domain: "Land",
    role: "Aura Commander & Reposition Tactician",
    hp: 450,
    dps: 65,
    range: 120,
    cost: "Free (1 Hero Active)",
    abilities: ["Command Aura (+20% ally attack)", "Tactical Pulse (AoE slow & damage)", "Reposition Travel"],
    description: "Legendary Ming military strategist who reformed coastal garrisons into the renowned 'Mandarin Duck' (Yuan-yang) formation to counter Wōkòu pirate tactics.",
    visualType: "hero",
    primaryColor: "#c83220",
    accentColor: "#d4af37",
  },
  {
    id: "ming_spearmen",
    name: "Ming Garrison Spearmen",
    nameZh: "明軍長槍勇士",
    civ: "Ming",
    domain: "Land",
    role: "Frontline Chokepoint Defense",
    hp: 180,
    dps: 28,
    range: 48,
    cost: "40 Land 兩",
    abilities: ["Spear Wall (+30% vs rushing raiders)", "Outpost Guard bonus"],
    description: "Disciplined defenders equipped with 12-foot bamboo-reinforced pikes, forming unbreakable barriers across narrow coastal pathways.",
    visualType: "infantry",
    primaryColor: "#1d3557",
    accentColor: "#e63946",
  },
  {
    id: "folangji_cannon",
    name: "Fo-lang-ji Swivel Cannon",
    nameZh: "佛郎機子母砲",
    civ: "Ming",
    domain: "Coastal / Cross-Front",
    role: "Cross-Front Bombardment Artillery",
    hp: 220,
    dps: 52,
    range: 240,
    cost: "90 Land 兩",
    abilities: ["Breech-Loaded Rapid Fire", "Cross-Front Sea Strike"],
    description: "Breech-loading Portuguese swivel guns adopted by Ming arsenals, capable of rapid magazine swaps to rain grapeshot onto raider junks and land columns.",
    visualType: "cannon",
    primaryColor: "#457b9d",
    accentColor: "#d4af37",
  },
  {
    id: "portuguese_arquebusiers",
    name: "Portuguese Arquebusiers",
    nameZh: "葡商火繩銃手",
    civ: "Portuguese",
    domain: "Land",
    role: "Armor-Piercing Marksmen",
    hp: 120,
    dps: 45,
    range: 180,
    cost: "65 Land 兩",
    abilities: ["Armor Piercing Shot", "Volley Fire"],
    description: "Matchlock marksmen providing precision long-range firepower against heavily armored Japanese rōnin and pirate captains.",
    visualType: "infantry",
    primaryColor: "#2a9d8f",
    accentColor: "#e76f51",
  },
  {
    id: "ming_war_junk",
    name: "East Asian War Junk (Mengchong)",
    nameZh: "大明艨艟戰船",
    civ: "Ming",
    domain: "Sea",
    role: "Naval Intercept & Boarding Vessel",
    hp: 340,
    dps: 58,
    range: 160,
    cost: "80 Naval 兩",
    abilities: ["Ramming Prow", "Fire Arrow Volley"],
    description: "Sturdy multi-decked warships armed with catapult firepots and swivel guns, guarding river deltas and shallow shoals against pirate incursions.",
    visualType: "naval",
    primaryColor: "#264653",
    accentColor: "#f4a261",
  },
  {
    id: "western_galleon",
    name: "Western Armed Carrack",
    nameZh: "西洋克拉克帆船",
    civ: "Portuguese",
    domain: "Sea",
    role: "Heavy Naval Broadside",
    hp: 520,
    dps: 84,
    range: 220,
    cost: "140 Naval 兩",
    abilities: ["Port & Starboard Broadsides", "Naval Chokepoint Anchor"],
    description: "Deep-draft Portuguese merchant-warships equipped with multi-tier bronze culverins, commanding deep-water sea lanes.",
    visualType: "naval",
    primaryColor: "#1d3557",
    accentColor: "#e9c46a",
  },
  {
    id: "citadel_hq",
    name: "Main HQ / Coastal Citadel",
    nameZh: "靖海衛城 · 總兵府",
    civ: "Ming",
    domain: "Coastal / Cross-Front",
    role: "Core Bastion & Lose Condition",
    hp: 1000,
    dps: 30,
    range: 180,
    cost: "Initial Fortress",
    abilities: ["Bastion Garrison", "Final Emergency Battery"],
    description: "The primary fortified stone citadel coordinating all coastal defense outposts. Its destruction results in catastrophic defeat.",
    visualType: "outpost",
    primaryColor: "#e5a93c",
    accentColor: "#8b0000",
  },
  {
    id: "wokou_ronin",
    name: "Wōkòu Rōnin Raider",
    nameZh: "倭寇浪人武士",
    civ: "Wōkòu Raider",
    domain: "Land",
    role: "Fast Assault Shock Raider",
    hp: 110,
    dps: 38,
    range: 30,
    cost: "Enemy Raider",
    abilities: ["Nodachi Rush (Burst speed)", "Outpost Pillage"],
    description: "Masterless samurai and coastal bandits armed with sweeping nodachi blades, executing rapid pincer strikes against economic outposts.",
    visualType: "raider",
    primaryColor: "#8b263e",
    accentColor: "#ffffff",
  },
];

export default function UnitVisualizerView() {
  const [selectedId, setSelectedId] = useState<string>("hero_qi");
  const [rotationAngle, setRotationAngle] = useState<number>(35);
  const [pitchAngle, setPitchAngle] = useState<number>(25);
  const [animationState, setAnimationState] = useState<"idle" | "attack" | "march">("idle");
  const [shaderTheme, setShaderTheme] = useState<"paper" | "day" | "dusk">("dusk");
  const [showWireframe, setShowWireframe] = useState<boolean>(false);

  const selectedModel = useMemo(
    () => MODEL_SPECS.find((m) => m.id === selectedId) ?? MODEL_SPECS[0],
    [selectedId]
  );

  return (
    <div className="dashboard-req-view" style={{ padding: "2rem 0" }}>
      {/* Header */}
      <div className="panel glass" style={{ marginBottom: "1.5rem" }}>
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start", flexWrap: "wrap", gap: "1rem" }}>
          <div>
            <div style={{ display: "flex", alignItems: "baseline", gap: "0.75rem", flexWrap: "wrap" }}>
              <h1 style={{ margin: 0, fontSize: "1.5rem" }}>⚔️ Unit & Outpost Visualizer</h1>
              <span style={{ background: "rgba(200,160,60,0.15)", color: "var(--accent-gold)", padding: "2px 8px", borderRadius: "4px", fontSize: "0.75rem", fontWeight: 700 }}>
                ID7 · 2.5D Tactical View
              </span>
            </div>
            <p style={{ marginTop: "0.5rem", color: "var(--text-muted)", fontSize: "0.88rem" }}>
              Preview isometric unit models, animations, weapon ranges, and combat statistics for Mobile Fortress.
            </p>
          </div>
          <div style={{ display: "flex", gap: "0.5rem" }}>
            <Link to="/dashboard" style={{ padding: "6px 14px", borderRadius: "4px", background: "rgba(255,255,255,0.06)", border: "1px solid var(--border)", fontSize: "0.85rem", color: "inherit", textDecoration: "none" }}>
              ← Overview
            </Link>
            <Link to="/dashboard/lore-map" style={{ padding: "6px 14px", borderRadius: "4px", background: "rgba(255,255,255,0.06)", border: "1px solid var(--border)", fontSize: "0.85rem", color: "inherit", textDecoration: "none" }}>
              Lore Map →
            </Link>
          </div>
        </div>

        {/* Quick Nav Strip */}
        <div style={{ display: "flex", gap: "1rem", marginTop: "1rem", borderTop: "1px solid rgba(255,255,255,0.08)", paddingTop: "0.75rem", flexWrap: "wrap" }}>
          <Link to="/dashboard" style={{ color: "var(--text-muted)", fontSize: "0.83rem", textDecoration: "none" }}>📊 Overview</Link>
          <Link to="/dashboard/runs" style={{ color: "var(--text-muted)", fontSize: "0.83rem", textDecoration: "none" }}>📜 Run History</Link>
          <Link to="/dashboard/ci" style={{ color: "var(--text-muted)", fontSize: "0.83rem", textDecoration: "none" }}>⚙️ CI Status</Link>
          <Link to="/dashboard/playtest" style={{ color: "var(--text-muted)", fontSize: "0.83rem", textDecoration: "none" }}>📝 Playtest Notes</Link>
          <Link to="/dashboard/lore-map" style={{ color: "var(--text-muted)", fontSize: "0.83rem", textDecoration: "none" }}>🗺️ Lore Map</Link>
          <span style={{ color: "var(--accent-gold)", fontSize: "0.83rem", fontWeight: 700 }}>⚔️ Visualizer</span>
          <Link to="/dashboard/requirements" style={{ color: "var(--text-muted)", fontSize: "0.83rem", textDecoration: "none" }}>📋 Requirements</Link>
        </div>
      </div>

      {/* Main Grid: Visualizer Stage + Spec Inspector */}
      <div style={{ display: "grid", gridTemplateColumns: "1fr 340px", gap: "1.5rem", alignItems: "start" }}>
        {/* Stage Container */}
        <div className="panel glass" style={{ padding: "1.25rem" }}>
          {/* Top Controls: Animation & Shading */}
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "1rem", flexWrap: "wrap", gap: "0.75rem" }}>
            {/* Animation Selector */}
            <div style={{ display: "flex", alignItems: "center", gap: "0.4rem" }}>
              <span style={{ fontSize: "0.8rem", color: "var(--text-muted)", fontWeight: 600 }}>ACTION:</span>
              {(["idle", "attack", "march"] as const).map((st) => (
                <button
                  key={st}
                  onClick={() => setAnimationState(st)}
                  style={{
                    padding: "4px 10px",
                    borderRadius: "4px",
                    border: "1px solid",
                    borderColor: animationState === st ? "var(--accent-gold)" : "rgba(255,255,255,0.12)",
                    background: animationState === st ? "rgba(200,160,60,0.15)" : "transparent",
                    color: animationState === st ? "var(--accent-gold)" : "var(--text-muted)",
                    fontSize: "0.8rem",
                    cursor: "pointer",
                    textTransform: "capitalize",
                  }}
                >
                  {st}
                </button>
              ))}
            </div>

            {/* Shading Palette Filter */}
            <div style={{ display: "flex", alignItems: "center", gap: "0.4rem" }}>
              <span style={{ fontSize: "0.8rem", color: "var(--text-muted)", fontWeight: 600 }}>PALETTE:</span>
              {[
                { id: "paper", label: "Parchment / Ink" },
                { id: "day", label: "Coastal Day" },
                { id: "dusk", label: "Dusk Wōkòu" },
              ].map((p) => (
                <button
                  key={p.id}
                  onClick={() => setShaderTheme(p.id as any)}
                  style={{
                    padding: "4px 8px",
                    borderRadius: "4px",
                    border: "1px solid",
                    borderColor: shaderTheme === p.id ? "var(--accent-gold)" : "rgba(255,255,255,0.12)",
                    background: shaderTheme === p.id ? "rgba(200,160,60,0.15)" : "transparent",
                    color: shaderTheme === p.id ? "var(--accent-gold)" : "var(--text-muted)",
                    fontSize: "0.78rem",
                    cursor: "pointer",
                  }}
                >
                  {p.label}
                </button>
              ))}
            </div>
          </div>

          {/* 3D Isometric Viewport */}
          <div
            style={{
              width: "100%",
              height: "440px",
              borderRadius: "6px",
              border: "1px solid rgba(200,160,60,0.25)",
              position: "relative",
              overflow: "hidden",
              background:
                shaderTheme === "paper"
                  ? "radial-gradient(ellipse at center, #eee4d0 0%, #ddccae 70%, #caa77f 100%)"
                  : shaderTheme === "day"
                  ? "radial-gradient(ellipse at center, #1b3d5c 0%, #0e2439 70%, #071320 100%)"
                  : "radial-gradient(ellipse at center, #261522 0%, #170d18 70%, #0c060d 100%)",
            }}
          >
            {/* SVG Tactical Model Rendering */}
            <svg
              viewBox="0 0 600 440"
              style={{
                width: "100%",
                height: "100%",
              }}
            >
              <defs>
                {/* Isometric Grid Floor */}
                <pattern id="isoGrid" width="60" height="30" patternUnits="userSpaceOnUse">
                  <path d="M 0 15 L 30 0 L 60 15 L 30 30 Z" fill="none" stroke="rgba(255,255,255,0.06)" strokeWidth="0.8" />
                </pattern>

                {/* Glow filter */}
                <filter id="heroGlow" x="-20%" y="-20%" width="140%" height="140%">
                  <feGaussianBlur stdDeviation="6" result="blur" />
                  <feComposite in="SourceGraphic" in2="blur" operator="over" />
                </filter>
              </defs>

              {/* Floor grid */}
              <rect width="600" height="440" fill="url(#isoGrid)" />

              {/* Unit Range Projection Ring on Floor */}
              <ellipse
                cx="300"
                cy="280"
                rx={selectedModel.range * 1.1}
                ry={selectedModel.range * 0.55}
                fill={selectedModel.primaryColor}
                fillOpacity="0.08"
                stroke={selectedModel.primaryColor}
                strokeWidth="1.5"
                strokeDasharray="6,4"
              />

              {/* Shadow underneath model */}
              <ellipse
                cx="300"
                cy="285"
                rx="65"
                ry="28"
                fill="rgba(0,0,0,0.45)"
              />

              {/* Rendered 2.5D / Isometric Tactical Glyph */}
              <g
                transform={`translate(300, 240) rotate(${rotationAngle * 0.2})`}
                filter={selectedModel.visualType === "hero" ? "url(#heroGlow)" : undefined}
              >
                {/* Base Pedestal */}
                <polygon
                  points="-50,20 0,45 50,20 0,-5"
                  fill="#1f2937"
                  stroke={selectedModel.accentColor}
                  strokeWidth="2"
                />

                {/* Tactical Silhouette Shape based on type */}
                {selectedModel.visualType === "hero" && (
                  <g transform={animationState === "attack" ? "translate(0, -10)" : "translate(0, 0)"}>
                    {/* Cape / Armor */}
                    <path d="M -30,-40 L 30,-40 L 40,15 L -40,15 Z" fill={selectedModel.primaryColor} stroke="#000" strokeWidth="2" />
                    {/* Torso */}
                    <rect x="-18" y="-70" width="36" height="45" rx="4" fill="#333" stroke={selectedModel.accentColor} strokeWidth="2" />
                    {/* Head / Ming Helm */}
                    <circle cx="0" cy="-90" r="16" fill="#c8a03c" stroke="#8b0000" strokeWidth="2" />
                    {/* Helm Plume */}
                    <path d="M -4,-106 Q 0,-125 12,-115 Q 4,-106 0,-106 Z" fill="#d90429" />
                    {/* Halberd / Spear Weapon */}
                    <line x1="28" y1="-120" x2="28" y2="30" stroke="#c8a03c" strokeWidth="4" />
                    <polygon points="24,-120 28,-145 32,-120" fill="#e0e1dd" />
                  </g>
                )}

                {selectedModel.visualType === "infantry" && (
                  <g transform={animationState === "march" ? "translate(0, -6)" : "translate(0, 0)"}>
                    <rect x="-14" y="-55" width="28" height="40" rx="3" fill={selectedModel.primaryColor} stroke="#000" strokeWidth="1.5" />
                    <circle cx="0" cy="-72" r="14" fill="#d4a373" stroke="#222" strokeWidth="1.5" />
                    {/* Spear */}
                    <line x1="20" y1="-110" x2="20" y2="20" stroke="#8d99ae" strokeWidth="3" />
                    <polygon points="17,-110 20,-130 23,-110" fill="#f8f9fa" />
                  </g>
                )}

                {selectedModel.visualType === "cannon" && (
                  <g>
                    {/* Carriage */}
                    <polygon points="-40,10 40,10 25,-15 -25,-15" fill="#5c4033" stroke="#000" strokeWidth="2" />
                    {/* Barrel */}
                    <rect x="-12" y="-45" width="24" height="60" rx="4" fill="#4a4e69" stroke={selectedModel.accentColor} strokeWidth="2" transform="rotate(-30)" />
                    {/* Swivel Mount */}
                    <circle cx="0" cy="-5" r="8" fill="#222" />
                  </g>
                )}

                {selectedModel.visualType === "naval" && (
                  <g>
                    {/* Ship Hull */}
                    <path d="M -60,0 Q 0,25 60,0 L 45,-25 L -45,-25 Z" fill="#582f0e" stroke="#000" strokeWidth="2" />
                    {/* Mast */}
                    <line x1="0" y1="-95" x2="0" y2="-20" stroke="#7f4f24" strokeWidth="4" />
                    {/* Sail */}
                    <path d="M 0,-90 Q 30,-60 0,-30 Z" fill={selectedModel.primaryColor} stroke={selectedModel.accentColor} strokeWidth="2" />
                  </g>
                )}

                {selectedModel.visualType === "outpost" && (
                  <g>
                    {/* Bastion Tower */}
                    <polygon points="-45,0 45,0 35,-60 -35,-60" fill="#3a4042" stroke={selectedModel.accentColor} strokeWidth="2" />
                    {/* Battlement top */}
                    <rect x="-40" y="-75" width="80" height="18" fill="#4f5d60" stroke="#000" strokeWidth="1.5" />
                    {/* Flagpole */}
                    <line x1="0" y1="-110" x2="0" y2="-75" stroke="#d4af37" strokeWidth="3" />
                    <polygon points="0,-110 25,-100 0,-90" fill="#d90429" />
                  </g>
                )}

                {selectedModel.visualType === "raider" && (
                  <g transform={animationState === "attack" ? "translate(10, -5)" : "translate(0, 0)"}>
                    {/* Ronin Body */}
                    <rect x="-15" y="-55" width="30" height="42" fill="#8b263e" stroke="#000" strokeWidth="1.5" />
                    <circle cx="0" cy="-70" r="13" fill="#e0a96d" />
                    {/* Straw Kasa Hat */}
                    <polygon points="-24,-76 24,-76 0,-92" fill="#c2a649" stroke="#000" strokeWidth="1.5" />
                    {/* Curved Katana */}
                    <path d="M 12,-40 Q 35,-65 45,-95" fill="none" stroke="#f4f4f2" strokeWidth="3.5" />
                  </g>
                )}
              </g>

              {/* In-Canvas Title Overlay */}
              <text x="30" y="45" fill="rgba(255,255,255,0.9)" fontSize="18" fontWeight="bold">
                {selectedModel.name}
              </text>
              <text x="30" y="68" fill="var(--accent-gold)" fontSize="13" fontWeight="600">
                {selectedModel.nameZh} · {selectedModel.civ}
              </text>
            </svg>

            {/* Bottom Slider: Rotation Control */}
            <div
              style={{
                position: "absolute",
                bottom: "12px",
                left: "20px",
                right: "20px",
                background: "rgba(0,0,0,0.65)",
                padding: "8px 14px",
                borderRadius: "6px",
                display: "flex",
                alignItems: "center",
                gap: "1rem",
              }}
            >
              <span style={{ fontSize: "0.78rem", color: "var(--text-muted)", fontWeight: 700 }}>ROTATE 360°:</span>
              <input
                type="range"
                min="-180"
                max="180"
                value={rotationAngle}
                onChange={(e) => setRotationAngle(Number(e.target.value))}
                style={{ flex: 1, accentColor: "var(--accent-gold)", cursor: "pointer" }}
              />
              <span style={{ fontSize: "0.8rem", color: "var(--accent-gold)", minWidth: "40px", textAlign: "right" }}>
                {rotationAngle}°
              </span>
            </div>
          </div>
        </div>

        {/* Tactical Spec Inspector Sidebar */}
        <div className="panel glass" style={{ padding: "1.25rem" }}>
          {/* Model Selector Dropdown */}
          <div style={{ marginBottom: "1rem" }}>
            <label style={{ fontSize: "0.75rem", fontWeight: 700, color: "var(--text-muted)", textTransform: "uppercase", letterSpacing: "0.06em", display: "block", marginBottom: "0.4rem" }}>
              Select Unit / Model
            </label>
            <select
              value={selectedId}
              onChange={(e) => setSelectedId(e.target.value)}
              style={{
                width: "100%",
                padding: "6px 8px",
                borderRadius: "4px",
                background: "rgba(0,0,0,0.3)",
                border: "1px solid var(--border)",
                color: "var(--text)",
                fontSize: "0.85rem",
              }}
            >
              {MODEL_SPECS.map((m) => (
                <option key={m.id} value={m.id}>
                  {m.name} ({m.domain})
                </option>
              ))}
            </select>
          </div>

          {/* Combat Metrics Grid */}
          <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "0.6rem", marginBottom: "1rem" }}>
            <div style={{ background: "rgba(0,0,0,0.2)", padding: "8px", borderRadius: "4px", textAlign: "center" }}>
              <div style={{ fontSize: "0.72rem", color: "var(--text-muted)", textTransform: "uppercase" }}>Health (HP)</div>
              <div style={{ fontSize: "1.2rem", fontWeight: 700, color: "#52b788" }}>{selectedModel.hp}</div>
            </div>
            <div style={{ background: "rgba(0,0,0,0.2)", padding: "8px", borderRadius: "4px", textAlign: "center" }}>
              <div style={{ fontSize: "0.72rem", color: "var(--text-muted)", textTransform: "uppercase" }}>DPS Attack</div>
              <div style={{ fontSize: "1.2rem", fontWeight: 700, color: "#e63946" }}>{selectedModel.dps}</div>
            </div>
            <div style={{ background: "rgba(0,0,0,0.2)", padding: "8px", borderRadius: "4px", textAlign: "center" }}>
              <div style={{ fontSize: "0.72rem", color: "var(--text-muted)", textTransform: "uppercase" }}>Attack Range</div>
              <div style={{ fontSize: "1.2rem", fontWeight: 700, color: "#4ea2d9" }}>{selectedModel.range}px</div>
            </div>
            <div style={{ background: "rgba(0,0,0,0.2)", padding: "8px", borderRadius: "4px", textAlign: "center" }}>
              <div style={{ fontSize: "0.72rem", color: "var(--text-muted)", textTransform: "uppercase" }}>Deployment Cost</div>
              <div style={{ fontSize: "0.95rem", fontWeight: 700, color: "var(--accent-gold)", marginTop: "3px" }}>{selectedModel.cost}</div>
            </div>
          </div>

          {/* Role & Domain Badges */}
          <div style={{ display: "flex", gap: "0.5rem", flexWrap: "wrap", marginBottom: "0.75rem" }}>
            <span style={{ fontSize: "0.72rem", background: "rgba(255,255,255,0.08)", padding: "2px 6px", borderRadius: "3px", color: "var(--text-muted)" }}>
              {selectedModel.domain}
            </span>
            <span style={{ fontSize: "0.72rem", background: "rgba(200,160,60,0.12)", color: "var(--accent-gold)", padding: "2px 6px", borderRadius: "3px" }}>
              {selectedModel.role}
            </span>
          </div>

          {/* Abilities List */}
          <div style={{ marginBottom: "1rem" }}>
            <strong style={{ fontSize: "0.75rem", color: "var(--text-muted)", textTransform: "uppercase", display: "block", marginBottom: "0.35rem" }}>
              Tactical Abilities:
            </strong>
            <ul style={{ margin: 0, paddingLeft: "1.1rem", fontSize: "0.82rem", lineHeight: 1.4, color: "var(--text)" }}>
              {selectedModel.abilities.map((ab, idx) => (
                <li key={idx} style={{ marginBottom: "0.2rem" }}>{ab}</li>
              ))}
            </ul>
          </div>

          {/* Lore / Historical Context */}
          <div style={{ fontSize: "0.82rem", lineHeight: 1.5, color: "var(--text-muted)", background: "rgba(0,0,0,0.15)", padding: "0.75rem", borderRadius: "4px", borderLeft: "3px solid var(--accent-gold)" }}>
            {selectedModel.description}
          </div>
        </div>
      </div>
    </div>
  );
}
