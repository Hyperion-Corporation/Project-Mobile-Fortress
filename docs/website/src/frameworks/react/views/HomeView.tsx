import { useEffect, useMemo, useRef, useState, type ComponentType } from "react";
import { Link } from "react-router-dom";
import DesignPanel from "../components/hub/DesignPanel";
import TechPanel from "../components/hub/TechPanel";
import AudioPanel from "../components/hub/AudioPanel";
import ProductionPanel from "../components/hub/ProductionPanel";
import QaPanel from "../components/hub/QaPanel";
import CoastalFlowFieldWrapper from "../../astro/components/CoastalFlowFieldWrapper";
import UnitRosterBoard from "../UnitRosterBoard";
import ConvergenceChartWrapper from "../../aurelia/ConvergenceChartWrapper";
import ApolloLorePanel from "../../apollo/ApolloLorePanel";
import { siteBaseUrl } from "../../../utils/baseUrl";

interface Tab {
  id: string;
  nav: string;
  icon: string;
  label: string;
  component: ComponentType;
}

const TABS: Tab[] = [
  { id: "design", nav: "Design", icon: "🏮", label: "Design Hub", component: DesignPanel },
  { id: "tech", nav: "Tech", icon: "⚙️", label: "Technical Blueprint", component: TechPanel },
  { id: "audio", nav: "Audio", icon: "🔊", label: "Acoustic Design", component: AudioPanel },
  { id: "production", nav: "Production", icon: "📅", label: "Production Roadmap", component: ProductionPanel },
  { id: "qa", nav: "QA", icon: "🔬", label: "QA Test Suite", component: QaPanel },
];

const PHASES = [
  {
    title: "Phase 1: Native Parity & Setup",
    date: "Weeks 1-4",
    desc: "Synchronize game state kinds across Kotlin Android client and Swift iOS client. Integrate shared levels asset JSON reading schemas.",
  },
  {
    title: "Phase 2: C++ Core Simulation Engine",
    date: "Weeks 5-8",
    desc: "Scaffold headless core simulation using EnTT ECS. Establish JNI/Swift-C++-interop bindings and FlatBuffers zero-copy serialization buffers.",
  },
  {
    title: "Phase 3: Cooperative Netcode & AWS",
    date: "Weeks 9-12",
    desc: "Write UDP sockets replication channels. Establish latency-graduated matchmaking queues on AWS GameLift FlexMatch.",
  },
  {
    title: "Phase 4: ML & Mathematical Optimizations",
    date: "Weeks 13-16",
    desc: "Deploy Genetic Algorithms for dynamic HQ layout generation, WFC PCG, and Contextual Bandits for storefront optimization.",
  },
];

const NUM_PETALS = 40;

class Petal {
  x = 0;
  y = 0;
  size = 0;
  speedX = 0;
  speedY = 0;
  rotation = 0;
  rotationSpeed = 0;
  opacity = 0;
  constructor(
    private width: number,
    private height: number
  ) {
    this.reset();
    this.y = Math.random() * height;
  }
  reset() {
    this.x = Math.random() * this.width;
    this.y = -20;
    this.size = Math.random() * 8 + 6;
    this.speedY = Math.random() * 1.5 + 0.8;
    this.speedX = Math.random() * 1.5 - 0.5;
    this.rotation = Math.random() * 360;
    this.rotationSpeed = Math.random() * 1.5 - 0.75;
    this.opacity = Math.random() * 0.4 + 0.3;
  }
  update() {
    this.y += this.speedY;
    this.x += this.speedX + Math.sin(this.y / 30) * 0.5;
    this.rotation += this.rotationSpeed;
    if (this.y > this.height + 20 || this.x > this.width + 20 || this.x < -20) this.reset();
  }
  draw(ctx: CanvasRenderingContext2D) {
    ctx.save();
    ctx.translate(this.x, this.y);
    ctx.rotate((this.rotation * Math.PI) / 180);
    ctx.beginPath();
    ctx.moveTo(0, 0);
    ctx.bezierCurveTo(-this.size, -this.size / 2, -this.size / 2, -this.size * 1.5, 0, -this.size);
    ctx.bezierCurveTo(this.size / 2, -this.size * 1.5, this.size, -this.size / 2, 0, 0);
    ctx.fillStyle = `rgba(255, 183, 197, ${this.opacity})`;
    ctx.fill();
    ctx.restore();
  }
}

export default function HomeView() {
  const [activeTab, setActiveTab] = useState(TABS[0].id);
  const canvasRef = useRef<HTMLCanvasElement | null>(null);

  const ActiveComponent = useMemo(() => TABS.find((t) => t.id === activeTab)!.component, [activeTab]);

  // public/ assets must be prefixed with the site base by hand when
  // referenced as a plain string (unlike index.html's own src="...", Vite
  // doesn't rewrite string literals) — otherwise this 404s once deployed
  // under the GitHub Pages project-site subpath (SITE_BASE).
  const bannerSrc = siteBaseUrl() + "assets/mobile_fortress_banner.jpg";

  function scrollToHub() {
    document.getElementById("design-hub")?.scrollIntoView({ behavior: "smooth" });
  }

  // --- Falling petal canvas background (Ukiyo-e-influenced hero flourish) ---
  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext("2d");
    if (!ctx) return;

    let width = 0;
    let height = 0;
    let raf = 0;
    let petals: Petal[] = [];

    function resize() {
      if (!canvas) return;
      width = canvas.width = window.innerWidth;
      height = canvas.height = window.innerHeight;
    }

    function animate() {
      if (ctx) {
        ctx.clearRect(0, 0, width, height);
        petals.forEach((p) => {
          p.update();
          p.draw(ctx);
        });
      }
      raf = requestAnimationFrame(animate);
    }

    resize();
    petals = Array.from({ length: NUM_PETALS }, () => new Petal(width, height));
    window.addEventListener("resize", resize);
    animate();

    return () => {
      window.removeEventListener("resize", resize);
      if (raf) cancelAnimationFrame(raf);
    };
  }, []);

  return (
    <div className="home">
      <canvas ref={canvasRef} className="blossoms-canvas" />

      <section className="hero-section">
        <div className="hero-overlay" />
        <div className="hero-content">
          <div className="badge">DEVELOPMENT CONSOLE V3.0</div>
          <h1>Defend the Coastal Fortress</h1>
          <p className="hero-desc">
            A 1540s–1560s Wōkòu-era Cooperative Tower Defense &amp; 4X Strategy Game — an East Asian coastal power
            and its Western trading-partner allies combine traditional Ukiyo-e-influenced aesthetics with headless
            C++ core simulation, Dijkstra vector pathfinding, and machine learning difficulty adjustment to repel
            pirate raiders by land and sea.
          </p>
          <div className="hero-actions">
            <button className="btn btn-primary" onClick={scrollToHub}>
              Try Design Simulators
            </button>
            <Link to="/design/game_design_document" className="btn btn-secondary">
              Read GDD Spec
            </Link>
            <Link to="/docs" className="btn btn-secondary">
              Browse Documentation
            </Link>
          </div>
        </div>
        <div className="hero-image-container">
          <img src={bannerSrc} alt="Wōkòu Raid: Night on the China Coast" className="hero-banner-img" />
        </div>
      </section>

      <div className="container">
        <section className="hub-tabs-section" id="design-hub">
          <div className="tabs-header">
            {TABS.map((t) => (
              <button
                key={t.id}
                className={`tab-btn${activeTab === t.id ? " active" : ""}`}
                onClick={() => setActiveTab(t.id)}
              >
                <span className="icon">{t.icon}</span> {t.label}
              </button>
            ))}
          </div>
          <div className="tabs-content">
            <ActiveComponent />
          </div>
        </section>

        {/* Astro island: coastal flow-field design visualization (MFP5) */}
        <CoastalFlowFieldWrapper height="460px" />

        {/* React island: live unit roster browser (src/constants/fortress.ts) */}
        <section className="react-island-wrap panel">
          <p className="island-label">Framework island · React — live unit roster (src/constants/fortress.ts)</p>
          <UnitRosterBoard />
        </section>

        {/* Aurelia island: HQ-layout GA convergence chart (src/simulations/) */}
        <ConvergenceChartWrapper />

        {/* Apollo/GraphQL island: docs/content graph (src/graphql/schema.graphql) */}
        <ApolloLorePanel />

        <section className="roadmap-section">
          <h2 className="section-title">Mobile Fortress Roadmap</h2>
          <div className="timeline">
            {PHASES.map((phase, idx) => (
              <div className="timeline-item" key={idx}>
                <div className="timeline-badge">{idx + 1}</div>
                <div className="timeline-panel panel">
                  <h3>{phase.title}</h3>
                  <span className="timeline-date">{phase.date}</span>
                  <p>{phase.desc}</p>
                </div>
              </div>
            ))}
          </div>
        </section>
      </div>
    </div>
  );
}
