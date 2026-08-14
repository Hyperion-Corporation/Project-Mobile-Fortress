/**
 * LoreMapView — /dashboard/lore-map — ID6: Zoomable In-Game Lore & Coastal Map
 *
 * Interactive coastal fortress map with zoomable regional/district/outpost
 * views, flow-field vector overlay, and deep drill-down lore inspection.
 */
import { useState, useMemo } from "react";
import { Link } from "react-router-dom";
import { OUTPOSTS, RAID_LANES } from "../../apollo/data";
import { LORE_STORIES } from "../../../stories";

interface OutpostDetail {
  id: string;
  name: string;
  nameZh: string;
  kind: "citadel" | "resource" | "trading" | "defense";
  x: number; // 0-1 normalized
  y: number; // 0-1 normalized
  economicYield: string;
  garrison: string;
  strategicImportance: string;
  loreSnippet: string;
  civAffiliation: "Ming Dynasty" | "Portuguese Allies" | "Joint Coastal Defense";
  vulnerabilities: string;
}

const LORE_OUTPOSTS: OutpostDetail[] = [
  {
    id: "citadel",
    name: "Main HQ / Coastal Citadel",
    nameZh: "總兵府 · 靖海衛城",
    kind: "citadel",
    x: 0.5,
    y: 0.5,
    economicYield: "Garrison Command Center (No raw yield)",
    garrison: "Ming Spearmen & Portuguese Arquebusiers",
    strategicImportance: "Primary lose condition. Loss of the Citadel means the coastal command falls to the Wōkòu raid fleets.",
    loreSnippet:
      "Constructed during the Jiajing reign (1550s) under General Qi Jiguang's tactical reforms. The fortress integrates stone bastions with breech-loading Portuguese swivel guns (Folangji), anchoring the dual defense of river estuaries and maritime passages.",
    civAffiliation: "Joint Coastal Defense",
    vulnerabilities: "Direct concentrated assaults once outer outposts fall.",
  },
  {
    id: "resource-north",
    name: "Northern Grain Outpost",
    nameZh: "北嶺屯田營",
    kind: "resource",
    x: 0.42,
    y: 0.18,
    economicYield: "+15 Land Currency (兩) / min",
    garrison: "Ming Peasant Militia & Frontier Spearmen",
    strategicImportance: "Supplies the land garrison. Destruction reduces land unit deployment rates.",
    loreSnippet:
      "A fortified agrarian settlement guarding the river basin. Ming soldiers cultivate millet and rice while maintaining watchtowers to spot rōnin scout parties descending from the northern hills.",
    civAffiliation: "Ming Dynasty",
    vulnerabilities: "Flanking raids through the northern mountain corridor.",
  },
  {
    id: "resource-inland",
    name: "Inland Silk & Supply Depot",
    nameZh: "內陸絲庫棧",
    kind: "resource",
    x: 0.68,
    y: 0.42,
    economicYield: "+25 Land Currency (兩) / min",
    garrison: "Imperial Guard Crossbowmen",
    strategicImportance: "High-value trade depot providing vital funding for heavy land fortifications.",
    loreSnippet:
      "Stores raw silk, porcelain, and gunpowder barrels transported along the grand canal network. Its fortified courtyard was reinforced after the 1553 coastal incursions by mixed smuggler-raider bands.",
    civAffiliation: "Ming Dynasty",
    vulnerabilities: "Inland bypass routes if coastal chokepoints are bypassed.",
  },
  {
    id: "trading-cove",
    name: "Portuguese Trading Cove",
    nameZh: "葡商舶塢 · 聖約翰港",
    kind: "trading",
    x: 0.14,
    y: 0.55,
    economicYield: "+20 Naval Currency (兩) / min",
    garrison: "Portuguese Galleon Marines & Navigators",
    strategicImportance: "Supplies naval currency and enables maritime patrol vessels and caravel intercepts.",
    loreSnippet:
      "A secluded deep-water inlet where licensed Portuguese carracks moor with the tacit approval of Ming coastal authorities. Ships exchange Western firearms and navigational charts for silk and tea.",
    civAffiliation: "Portuguese Allies",
    vulnerabilities: "Vulnerable to sudden naval pincer maneuvers by Wōkòu junks.",
  },
  {
    id: "trading-strait",
    name: "Strait Trading Post & Lighthouse",
    nameZh: "海門巡檢司 · 望海燈臺",
    kind: "trading",
    x: 0.22,
    y: 0.82,
    economicYield: "+30 Naval Currency (兩) / min",
    garrison: "Ming Water Patrol & Mercenary Cannoneers",
    strategicImportance: "Controls the southern deep-water navigation strait, providing naval firepower coverage.",
    loreSnippet:
      "An ancient stone watchtower perched upon sea cliffs. Beacon fires lit here give the main fleet hours of advance warning when pirate fleets appear over the southern horizon.",
    civAffiliation: "Joint Coastal Defense",
    vulnerabilities: "Exposed to heavy coastal bombardment from seaward raiders.",
  },
];

export default function LoreMapView() {
  const [selectedId, setSelectedId] = useState<string>("citadel");
  const [zoomLevel, setZoomLevel] = useState<number>(1); // 1 = Regional, 2 = District, 3 = Outpost
  const [showFlowField, setShowFlowField] = useState<boolean>(true);
  const [showRaidLanes, setShowRaidLanes] = useState<boolean>(true);
  const [filterCiv, setFilterCiv] = useState<string>("all");

  const selectedNode = useMemo(
    () => LORE_OUTPOSTS.find((o) => o.id === selectedId) ?? LORE_OUTPOSTS[0],
    [selectedId]
  );

  const filteredOutposts = useMemo(() => {
    if (filterCiv === "all") return LORE_OUTPOSTS;
    return LORE_OUTPOSTS.filter((o) => o.civAffiliation.includes(filterCiv));
  }, [filterCiv]);

  // Transform coordinates based on zoom & selected node focus
  const mapTransform = useMemo(() => {
    if (zoomLevel === 1) {
      return { scale: 1, translateX: 0, translateY: 0 };
    }
    if (zoomLevel === 2) {
      const targetX = (selectedNode.x - 0.5) * -180;
      const targetY = (selectedNode.y - 0.5) * -120;
      return { scale: 1.6, translateX: targetX, translateY: targetY };
    }
    // Zoom level 3: focused on selected node
    const targetX = (selectedNode.x - 0.5) * -340;
    const targetY = (selectedNode.y - 0.5) * -220;
    return { scale: 2.3, translateX: targetX, translateY: targetY };
  }, [zoomLevel, selectedNode]);

  return (
    <div className="dashboard-req-view" style={{ padding: "2rem 0" }}>
      {/* Header & Breadcrumb */}
      <div className="panel glass" style={{ marginBottom: "1.5rem" }}>
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start", flexWrap: "wrap", gap: "1rem" }}>
          <div>
            <div style={{ display: "flex", alignItems: "baseline", gap: "0.75rem", flexWrap: "wrap" }}>
              <h1 style={{ margin: 0, fontSize: "1.5rem" }}>🗺️ Coastal Lore & Outpost Map</h1>
              <span style={{ background: "rgba(200,160,60,0.15)", color: "var(--accent-gold)", padding: "2px 8px", borderRadius: "4px", fontSize: "0.75rem", fontWeight: 700 }}>
                ID6 · Interactive Map
              </span>
            </div>
            <p style={{ marginTop: "0.5rem", color: "var(--text-muted)", fontSize: "0.88rem" }}>
              Explore the 1540s–1560s Wōkòu crisis coastal defense network, tactical flow fields, and historical Garrison lore.
            </p>
          </div>
          <div style={{ display: "flex", gap: "0.5rem" }}>
            <Link to="/dashboard" style={{ padding: "6px 14px", borderRadius: "4px", background: "rgba(255,255,255,0.06)", border: "1px solid var(--border)", fontSize: "0.85rem", color: "inherit", textDecoration: "none" }}>
              ← Overview
            </Link>
            <Link to="/dashboard/runs" style={{ padding: "6px 14px", borderRadius: "4px", background: "rgba(255,255,255,0.06)", border: "1px solid var(--border)", fontSize: "0.85rem", color: "inherit", textDecoration: "none" }}>
              Run History →
            </Link>
          </div>
        </div>

        {/* Quick Nav Strip */}
        <div style={{ display: "flex", gap: "1rem", marginTop: "1rem", borderTop: "1px solid rgba(255,255,255,0.08)", paddingTop: "0.75rem", flexWrap: "wrap" }}>
          <Link to="/dashboard" style={{ color: "var(--text-muted)", fontSize: "0.83rem", textDecoration: "none" }}>📊 Overview</Link>
          <Link to="/dashboard/runs" style={{ color: "var(--text-muted)", fontSize: "0.83rem", textDecoration: "none" }}>📜 Run History</Link>
          <Link to="/dashboard/ci" style={{ color: "var(--text-muted)", fontSize: "0.83rem", textDecoration: "none" }}>⚙️ CI Status</Link>
          <Link to="/dashboard/playtest" style={{ color: "var(--text-muted)", fontSize: "0.83rem", textDecoration: "none" }}>📝 Playtest Notes</Link>
          <span style={{ color: "var(--accent-gold)", fontSize: "0.83rem", fontWeight: 700 }}>🗺️ Lore Map</span>
          <Link to="/dashboard/requirements" style={{ color: "var(--text-muted)", fontSize: "0.83rem", textDecoration: "none" }}>📋 Requirements</Link>
        </div>
      </div>

      {/* Main Map + Inspector Layout */}
      <div style={{ display: "grid", gridTemplateColumns: "1fr 340px", gap: "1.5rem", alignItems: "start" }}>
        {/* Map Container */}
        <div className="panel glass" style={{ padding: "1.25rem", position: "relative", overflow: "hidden" }}>
          {/* Controls Bar */}
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "1rem", flexWrap: "wrap", gap: "0.75rem" }}>
            {/* Zoom Controls */}
            <div style={{ display: "flex", alignItems: "center", gap: "0.5rem" }}>
              <span style={{ fontSize: "0.8rem", color: "var(--text-muted)", fontWeight: 600 }}>ZOOM:</span>
              {[
                { lvl: 1, label: "Regional (1x)" },
                { lvl: 2, label: "District (1.6x)" },
                { lvl: 3, label: "Outpost (2.3x)" },
              ].map((b) => (
                <button
                  key={b.lvl}
                  onClick={() => setZoomLevel(b.lvl)}
                  style={{
                    padding: "4px 10px",
                    borderRadius: "4px",
                    border: "1px solid",
                    borderColor: zoomLevel === b.lvl ? "var(--accent-gold)" : "rgba(255,255,255,0.12)",
                    background: zoomLevel === b.lvl ? "rgba(200,160,60,0.15)" : "transparent",
                    color: zoomLevel === b.lvl ? "var(--accent-gold)" : "var(--text-muted)",
                    fontSize: "0.8rem",
                    cursor: "pointer",
                    fontWeight: zoomLevel === b.lvl ? 700 : 400,
                  }}
                >
                  {b.label}
                </button>
              ))}
            </div>

            {/* Layer Toggles */}
            <div style={{ display: "flex", alignItems: "center", gap: "0.75rem" }}>
              <label style={{ fontSize: "0.78rem", display: "flex", alignItems: "center", gap: "0.35rem", cursor: "pointer", color: "var(--text-muted)" }}>
                <input
                  type="checkbox"
                  checked={showFlowField}
                  onChange={(e) => setShowFlowField(e.target.checked)}
                />
                Flow Vectors
              </label>
              <label style={{ fontSize: "0.78rem", display: "flex", alignItems: "center", gap: "0.35rem", cursor: "pointer", color: "var(--text-muted)" }}>
                <input
                  type="checkbox"
                  checked={showRaidLanes}
                  onChange={(e) => setShowRaidLanes(e.target.checked)}
                />
                Raid Approaches
              </label>
            </div>
          </div>

          {/* SVG Map Canvas */}
          <div
            style={{
              width: "100%",
              height: "460px",
              background: "radial-gradient(ellipse at center, #142232 0%, #0d1622 70%, #080e16 100%)",
              borderRadius: "6px",
              border: "1px solid rgba(200,160,60,0.2)",
              position: "relative",
              overflow: "hidden",
            }}
          >
            <svg
              viewBox="0 0 720 460"
              style={{
                width: "100%",
                height: "100%",
                transform: `scale(${mapTransform.scale}) translate(${mapTransform.translateX}px, ${mapTransform.translateY}px)`,
                transformOrigin: "center center",
                transition: "transform 0.4s cubic-bezier(0.16, 1, 0.3, 1)",
              }}
            >
              <defs>
                {/* Coastal gradient */}
                <linearGradient id="seaGrad" x1="0" y1="0" x2="1" y2="0">
                  <stop offset="0%" stopColor="#0b1b2b" />
                  <stop offset="32%" stopColor="#132c45" />
                  <stop offset="42%" stopColor="#244458" />
                  <stop offset="50%" stopColor="#8c7755" />
                  <stop offset="58%" stopColor="#3d4e38" />
                  <stop offset="100%" stopColor="#2c3a28" />
                </linearGradient>

                {/* Grid pattern */}
                <pattern id="cartoGrid" width="40" height="40" patternUnits="userSpaceOnUse">
                  <path d="M 40 0 L 0 0 0 40" fill="none" stroke="rgba(255,255,255,0.03)" strokeWidth="0.5" />
                </pattern>

                {/* Flow Arrow Marker */}
                <marker id="arrow" viewBox="0 0 6 6" refX="3" refY="3" markerWidth="4" markerHeight="4" orient="auto">
                  <path d="M 0 0 L 6 3 L 0 6 z" fill="rgba(200,160,60,0.5)" />
                </marker>
                <marker id="raidArrow" viewBox="0 0 8 8" refX="4" refY="4" markerWidth="5" markerHeight="5" orient="auto">
                  <path d="M 0 1 L 8 4 L 0 7 z" fill="#d94b38" />
                </marker>
              </defs>

              {/* Base terrain */}
              <rect width="720" height="460" fill="url(#seaGrad)" />
              <rect width="720" height="460" fill="url(#cartoGrid)" />

              {/* Coastline shape */}
              <path
                d="M 280 0 Q 320 120 260 220 T 310 360 Q 340 420 300 460 L 720 460 L 720 0 Z"
                fill="#32422e"
                stroke="#9a815a"
                strokeWidth="2"
              />

              {/* Shoals & Sandbars */}
              <path d="M 220 180 Q 250 200 230 230 Q 210 240 200 210 Z" fill="#6d6044" opacity="0.6" />
              <path d="M 170 380 Q 210 400 180 430 Q 150 420 160 390 Z" fill="#6d6044" opacity="0.6" />

              {/* Historical Labels */}
              <text x="70" y="50" fill="rgba(255,255,255,0.25)" fontSize="14" fontFamily="serif" letterSpacing="4">
                EAST CHINA SEA · 東海
              </text>
              <text x="520" y="50" fill="rgba(255,255,255,0.25)" fontSize="14" fontFamily="serif" letterSpacing="4">
                ZHEJIANG GARRISON · 浙江
              </text>

              {/* Flow Field Vector Overlay */}
              {showFlowField && (
                <g opacity="0.45">
                  {/* Sea vectors */}
                  {[
                    { x: 80, y: 140, dx: 30, dy: 10 },
                    { x: 140, y: 180, dx: 35, dy: 12 },
                    { x: 200, y: 220, dx: 40, dy: 5 },
                    { x: 100, y: 290, dx: 35, dy: -8 },
                    { x: 180, y: 320, dx: 40, dy: -12 },
                    { x: 240, y: 340, dx: 30, dy: -15 },
                    { x: 90, y: 400, dx: 35, dy: -20 },
                  ].map((v, i) => (
                    <line
                      key={`sflow-${i}`}
                      x1={v.x}
                      y1={v.y}
                      x2={v.x + v.dx}
                      y2={v.y + v.dy}
                      stroke="#4ea2d9"
                      strokeWidth="1.5"
                      markerEnd="url(#arrow)"
                    />
                  ))}

                  {/* Land vectors */}
                  {[
                    { x: 340, y: 90, dx: 15, dy: 25 },
                    { x: 380, y: 140, dx: -10, dy: 25 },
                    { x: 560, y: 120, dx: -25, dy: 20 },
                    { x: 520, y: 210, dx: -30, dy: 10 },
                    { x: 600, y: 280, dx: -35, dy: -10 },
                    { x: 480, y: 350, dx: -20, dy: -25 },
                  ].map((v, i) => (
                    <line
                      key={`lflow-${i}`}
                      x1={v.x}
                      y1={v.y}
                      x2={v.x + v.dx}
                      y2={v.y + v.dy}
                      stroke="#d9b64e"
                      strokeWidth="1.5"
                      markerEnd="url(#arrow)"
                    />
                  ))}
                </g>
              )}

              {/* Raid Lanes Overlay */}
              {showRaidLanes && (
                <g>
                  {/* Northern Land Raid */}
                  <path
                    d="M 500 20 Q 420 80 360 230"
                    fill="none"
                    stroke="#d94b38"
                    strokeWidth="2.5"
                    strokeDasharray="6,4"
                    markerEnd="url(#raidArrow)"
                  />
                  {/* Western Naval Raid */}
                  <path
                    d="M 30 240 Q 150 250 360 230"
                    fill="none"
                    stroke="#d94b38"
                    strokeWidth="2.5"
                    strokeDasharray="6,4"
                    markerEnd="url(#raidArrow)"
                  />
                  {/* Southern Strait Raid */}
                  <path
                    d="M 80 430 Q 220 380 360 230"
                    fill="none"
                    stroke="#d94b38"
                    strokeWidth="2.5"
                    strokeDasharray="6,4"
                    markerEnd="url(#raidArrow)"
                  />
                </g>
              )}

              {/* Outpost Interactive Nodes */}
              {filteredOutposts.map((node) => {
                const cx = node.x * 720;
                const cy = node.y * 460;
                const isSelected = node.id === selectedId;

                const color =
                  node.kind === "citadel"
                    ? "#e5a93c"
                    : node.kind === "resource"
                    ? "#52b788"
                    : "#38a3a5";

                return (
                  <g
                    key={node.id}
                    onClick={() => setSelectedId(node.id)}
                    style={{ cursor: "pointer" }}
                  >
                    {/* Range / Pulse Ring */}
                    {isSelected && (
                      <circle
                        cx={cx}
                        cy={cy}
                        r="26"
                        fill={color}
                        fillOpacity="0.18"
                        stroke={color}
                        strokeWidth="1.5"
                        strokeDasharray="4,3"
                      />
                    )}

                    {/* Node base circle */}
                    <circle
                      cx={cx}
                      cy={cy}
                      r={isSelected ? "14" : "10"}
                      fill="#0d1622"
                      stroke={color}
                      strokeWidth={isSelected ? "3" : "2"}
                    />

                    {/* Inner icon / glyph */}
                    <circle
                      cx={cx}
                      cy={cy}
                      r={isSelected ? "6" : "4"}
                      fill={color}
                    />

                    {/* Node Text Label */}
                    <text
                      x={cx}
                      y={cy + (isSelected ? 26 : 20)}
                      textAnchor="middle"
                      fill={isSelected ? "#fff" : "rgba(255,255,255,0.8)"}
                      fontSize={isSelected ? "12" : "10"}
                      fontWeight={isSelected ? 700 : 500}
                      fontFamily="system-ui, sans-serif"
                    >
                      {node.name.split("/")[0].trim()}
                    </text>
                  </g>
                );
              })}

              {/* Compass Rose */}
              <g transform="translate(660, 400)">
                <circle r="22" fill="#0d1622" stroke="rgba(200,160,60,0.3)" strokeWidth="1" />
                <path d="M 0 -18 L 4 -4 L 18 0 L 4 4 L 0 18 L -4 4 L -18 0 L -4 -4 Z" fill="#c8a03c" opacity="0.7" />
                <text y="-22" textAnchor="middle" fill="#c8a03c" fontSize="9" fontWeight="bold">N</text>
              </g>
            </svg>
          </div>

          {/* Map Legend */}
          <div style={{ display: "flex", gap: "1.25rem", marginTop: "0.85rem", fontSize: "0.78rem", color: "var(--text-muted)", flexWrap: "wrap" }}>
            <span style={{ display: "flex", alignItems: "center", gap: "0.4rem" }}>
              <span style={{ width: "10px", height: "10px", borderRadius: "50%", background: "#e5a93c", display: "inline-block" }}></span>
              Citadel HQ
            </span>
            <span style={{ display: "flex", alignItems: "center", gap: "0.4rem" }}>
              <span style={{ width: "10px", height: "10px", borderRadius: "50%", background: "#52b788", display: "inline-block" }}></span>
              Resource Outpost (Land 兩)
            </span>
            <span style={{ display: "flex", alignItems: "center", gap: "0.4rem" }}>
              <span style={{ width: "10px", height: "10px", borderRadius: "50%", background: "#38a3a5", display: "inline-block" }}></span>
              Trading Outpost (Naval 兩)
            </span>
            <span style={{ display: "flex", alignItems: "center", gap: "0.4rem" }}>
              <span style={{ width: "14px", height: "2px", background: "#d94b38", display: "inline-block" }}></span>
              Wōkòu Raid Corridor
            </span>
          </div>
        </div>

        {/* Drill-Down Inspector Sidebar */}
        <div className="panel glass" style={{ padding: "1.25rem" }}>
          {/* Faction Filter */}
          <div style={{ marginBottom: "1rem" }}>
            <label style={{ fontSize: "0.75rem", fontWeight: 700, color: "var(--text-muted)", textTransform: "uppercase", letterSpacing: "0.06em", display: "block", marginBottom: "0.4rem" }}>
              Filter Outposts
            </label>
            <select
              value={filterCiv}
              onChange={(e) => setFilterCiv(e.target.value)}
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
              <option value="all">All Outposts ({LORE_OUTPOSTS.length})</option>
              <option value="Ming">Ming Dynasty Only</option>
              <option value="Portuguese">Portuguese Allies Only</option>
              <option value="Joint">Joint Defense</option>
            </select>
          </div>

          {/* Node Header */}
          <div style={{ borderTop: "1px solid rgba(255,255,255,0.08)", paddingTop: "0.75rem", marginBottom: "0.75rem" }}>
            <div style={{ fontSize: "0.75rem", color: "var(--accent-gold)", fontWeight: 700 }}>
              {selectedNode.nameZh}
            </div>
            <h2 style={{ margin: "0.2rem 0 0.5rem", fontSize: "1.15rem" }}>
              {selectedNode.name}
            </h2>
            <span
              style={{
                fontSize: "0.72rem",
                padding: "2px 6px",
                borderRadius: "3px",
                background: "rgba(255,255,255,0.08)",
                color: "var(--text-muted)",
                display: "inline-block",
              }}
            >
              {selectedNode.civAffiliation}
            </span>
          </div>

          {/* Node Lore Snippet */}
          <div style={{ fontSize: "0.84rem", lineHeight: 1.5, color: "var(--text)", marginBottom: "1rem", background: "rgba(0,0,0,0.2)", padding: "0.75rem", borderRadius: "4px", borderLeft: "3px solid var(--accent-gold)" }}>
            {selectedNode.loreSnippet}
          </div>

          {/* Strategic Specifications */}
          <div style={{ display: "flex", flexDirection: "column", gap: "0.6rem", fontSize: "0.82rem" }}>
            <div>
              <strong style={{ color: "var(--text-muted)", display: "block", fontSize: "0.74rem", textTransform: "uppercase" }}>
                Economic Output:
              </strong>
              <span style={{ color: "#52b788", fontWeight: 600 }}>{selectedNode.economicYield}</span>
            </div>

            <div>
              <strong style={{ color: "var(--text-muted)", display: "block", fontSize: "0.74rem", textTransform: "uppercase" }}>
                Garrison Defense:
              </strong>
              <span>{selectedNode.garrison}</span>
            </div>

            <div>
              <strong style={{ color: "var(--text-muted)", display: "block", fontSize: "0.74rem", textTransform: "uppercase" }}>
                Tactical Role:
              </strong>
              <span style={{ color: "var(--text-muted)" }}>{selectedNode.strategicImportance}</span>
            </div>

            <div>
              <strong style={{ color: "var(--text-muted)", display: "block", fontSize: "0.74rem", textTransform: "uppercase" }}>
                Vulnerabilities:
              </strong>
              <span style={{ color: "#e07a5f" }}>{selectedNode.vulnerabilities}</span>
            </div>
          </div>

          {/* Outpost Selector List */}
          <div style={{ marginTop: "1.25rem", borderTop: "1px solid rgba(255,255,255,0.08)", paddingTop: "0.75rem" }}>
            <div style={{ fontSize: "0.75rem", fontWeight: 700, color: "var(--text-muted)", textTransform: "uppercase", letterSpacing: "0.06em", marginBottom: "0.5rem" }}>
              Quick Select Outpost
            </div>
            <div style={{ display: "flex", flexDirection: "column", gap: "0.35rem" }}>
              {LORE_OUTPOSTS.map((o) => (
                <button
                  key={o.id}
                  onClick={() => setSelectedId(o.id)}
                  style={{
                    textAlign: "left",
                    padding: "6px 8px",
                    borderRadius: "4px",
                    border: "1px solid",
                    borderColor: selectedId === o.id ? "var(--accent-gold)" : "rgba(255,255,255,0.06)",
                    background: selectedId === o.id ? "rgba(200,160,60,0.12)" : "rgba(0,0,0,0.15)",
                    color: selectedId === o.id ? "var(--accent-gold)" : "inherit",
                    fontSize: "0.8rem",
                    cursor: "pointer",
                  }}
                >
                  {o.name}
                </button>
              ))}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
