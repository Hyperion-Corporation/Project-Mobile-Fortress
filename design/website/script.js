// --- Global App State & Event Listeners ---
document.addEventListener("DOMContentLoaded", () => {
    initTabs();
    initGrassConfettiBackground();
    initSoccerPitch();
    initBehaviorTree();
    initAudioSimulator();
    initSprintsRoadmap();
    initQaSuite();
});

// --- Tab System ---
function initTabs() {
    const tabButtons = document.querySelectorAll(".tab-btn");
    const tabPanes = document.querySelectorAll(".tab-pane");

    tabButtons.forEach(btn => {
        btn.addEventListener("click", () => {
            tabButtons.forEach(b => b.classList.remove("active"));
            tabPanes.forEach(p => p.classList.remove("active"));

            btn.classList.add("active");
            const target = btn.getAttribute("data-target");
            document.getElementById(target).classList.add("active");
        });
    });

    const navLinks = document.querySelectorAll(".nav-links a");
    navLinks.forEach(link => {
        link.addEventListener("click", (e) => {
            const href = link.getAttribute("href");
            if (href.startsWith("#") && href !== "#") {
                e.preventDefault();
                navLinks.forEach(l => l.classList.remove("active"));
                link.classList.add("active");

                let tabTarget = "tab-design";
                if (href === "#tech") tabTarget = "tab-tech";
                if (href === "#audio") tabTarget = "tab-audio";
                if (href === "#production") tabTarget = "tab-production";
                if (href === "#qa") tabTarget = "tab-qa";

                const targetBtn = document.querySelector(`.tab-btn[data-target="${tabTarget}"]`);
                if (targetBtn) targetBtn.click();

                document.querySelector(".gdd-tabs-section").scrollIntoView({ behavior: "smooth" });
            }
        });
    });
}

// --- Dynamic Grass Particles Background ---
function initGrassConfettiBackground() {
    const canvas = document.getElementById("blossoms-canvas");
    const ctx = canvas.getContext("2d");

    let width = canvas.width = window.innerWidth;
    let height = canvas.height = window.innerHeight;

    window.addEventListener("resize", () => {
        width = canvas.width = window.innerWidth;
        height = canvas.height = window.innerHeight;
    });

    const numParticles = 30;
    const particles = [];

    class GrassFlake {
        constructor() {
            this.reset();
            this.y = Math.random() * height;
        }

        reset() {
            this.x = Math.random() * width;
            this.y = -20;
            this.width = Math.random() * 3 + 2;
            this.length = Math.random() * 12 + 6;
            this.speedY = Math.random() * 1.2 + 0.6;
            this.speedX = Math.random() * 1.0 - 0.5;
            this.angle = Math.random() * Math.PI * 2;
            this.spinSpeed = Math.random() * 0.05 - 0.025;
            this.opacity = Math.random() * 0.2 + 0.1;
        }

        update() {
            this.y += this.speedY;
            this.x += this.speedX + Math.sin(this.y / 40) * 0.3;
            this.angle += this.spinSpeed;

            if (this.y > height + 20 || this.x > width + 20 || this.x < -20) {
                this.reset();
            }
        }

        draw() {
            ctx.save();
            ctx.translate(this.x, this.y);
            ctx.rotate(this.angle);
            ctx.beginPath();
            
            // Draw a grass blade / confetti strand
            ctx.rect(-this.width/2, -this.length/2, this.width, this.length);
            
            ctx.fillStyle = `rgba(56, 176, 0, ${this.opacity})`;
            ctx.fill();
            ctx.restore();
        }
    }

    for (let i = 0; i < numParticles; i++) {
        particles.push(new GrassFlake());
    }

    function animate() {
        ctx.clearRect(0, 0, width, height);
        particles.forEach(p => {
            p.update();
            p.draw();
        });
        requestAnimationFrame(animate);
    }

    animate();
}

// --- Interactive Soccer Pitch Simulator ---
const PITCH_ROWS = 8;
const PITCH_COLS = 12;
let pitchGrid = [];
let currentSoccerTool = "defender"; // "defender", "attacker", "ball"
let ballPos = { r: 3, c: 3 };

function initSoccerPitch() {
    createSoccerPitch();
    recalculatePassLanes();
}

function createSoccerPitch() {
    const pitchGridEl = document.getElementById("pitch-grid");
    if (!pitchGridEl) return;
    pitchGridEl.innerHTML = "";
    pitchGrid = [];

    // Pre-populated actors
    const initialActors = [
        { r: 3, c: 3, type: "ball" },
        { r: 2, c: 1, type: "defender" },
        { r: 5, c: 2, type: "defender" },
        { r: 5, c: 5, type: "attacker" },
        { r: 1, c: 6, type: "attacker" }
    ];

    for (let r = 0; r < PITCH_ROWS; r++) {
        pitchGrid[r] = [];
        for (let c = 0; c < PITCH_COLS; c++) {
            let initial = initialActors.find(a => a.r === r && a.c === c);
            let actorType = initial ? initial.type : "clear";
            
            pitchGrid[r][c] = { row: r, col: c, type: actorType };

            const cellEl = document.createElement("div");
            cellEl.id = `pitch-cell-${r}-${c}`;
            cellEl.className = "pitch-cell";

            if (actorType === "defender") {
                cellEl.classList.add("cell-defender");
                cellEl.textContent = "🏃🔴";
            } else if (actorType === "attacker") {
                cellEl.classList.add("cell-attacker");
                cellEl.textContent = "🏃🔵";
            } else if (actorType === "ball") {
                cellEl.classList.add("cell-ball");
                cellEl.textContent = "⚽";
                ballPos = { r: r, c: c };
            }

            cellEl.addEventListener("click", () => handlePitchCellClick(r, c));
            pitchGridEl.appendChild(cellEl);
        }
    }
}

function setSoccerTool(toolName) {
    currentSoccerTool = toolName;
    document.querySelectorAll(".btn-tool").forEach(btn => btn.classList.remove("active"));
    
    let btnId = "tool-defender";
    if (toolName === "attacker") btnId = "tool-attacker";
    if (toolName === "ball") btnId = "tool-ball";
    document.getElementById(btnId).classList.add("active");
}

function handlePitchCellClick(r, c) {
    const cellEl = document.getElementById(`pitch-cell-${r}-${c}`);
    const previousType = pitchGrid[r][c].type;

    // Reset current element
    if (previousType === "ball") {
        // Can't delete ball, must move it
        if (currentSoccerTool !== "ball") return;
    }

    // Apply tool changes
    if (currentSoccerTool === "defender") {
        if (previousType === "defender") {
            pitchGrid[r][c].type = "clear";
            cellEl.classList.remove("cell-defender");
            cellEl.textContent = "";
        } else {
            clearCell(r, c);
            pitchGrid[r][c].type = "defender";
            cellEl.classList.add("cell-defender");
            cellEl.textContent = "🏃🔴";
        }
    } else if (currentSoccerTool === "attacker") {
        if (previousType === "attacker") {
            pitchGrid[r][c].type = "clear";
            cellEl.classList.remove("cell-attacker");
            cellEl.textContent = "";
        } else {
            clearCell(r, c);
            pitchGrid[r][c].type = "attacker";
            cellEl.classList.add("cell-attacker");
            cellEl.textContent = "🏃🔵";
        }
    } else if (currentSoccerTool === "ball") {
        // Remove previous ball representation
        const prevBallEl = document.getElementById(`pitch-cell-${ballPos.r}-${ballPos.c}`);
        if (prevBallEl) {
            prevBallEl.classList.remove("cell-ball");
            prevBallEl.textContent = "";
            pitchGrid[ballPos.r][ballPos.c].type = "clear";
        }

        clearCell(r, c);
        ballPos = { r: r, c: c };
        pitchGrid[r][c].type = "ball";
        cellEl.classList.add("cell-ball");
        cellEl.textContent = "⚽";
    }

    recalculatePassLanes();
}

function clearCell(r, c) {
    const el = document.getElementById(`pitch-cell-${r}-${c}`);
    el.className = "pitch-cell";
    el.textContent = "";
    pitchGrid[r][c].type = "clear";
}

function resetSoccerPitch() {
    createSoccerPitch();
    recalculatePassLanes();
}

// Clears dynamic vector line visualizers and draws updated passing options
function recalculatePassLanes() {
    // Clear old lines
    document.querySelectorAll(".pass-viability-line").forEach(l => l.remove());

    const pitchContainer = document.getElementById("pitch-grid");
    if (!pitchContainer) return;
    const rect = pitchContainer.getBoundingClientRect();
    const cellW = rect.width / PITCH_COLS;
    const cellH = rect.height / PITCH_ROWS;

    // Center of ball coordinate
    const ballX = ballPos.c * cellW + cellW/2;
    const ballY = ballPos.r * cellH + cellH/2;

    // Scan for attackers
    for (let r = 0; r < PITCH_ROWS; r++) {
        for (let c = 0; c < PITCH_COLS; c++) {
            if (pitchGrid[r][c].type === "attacker") {
                const targetX = c * cellW + cellW/2;
                const targetY = r * cellH + cellH/2;

                // Verify if any defender intersects the direct pass vector line
                let passesBlock = checkPassBlocked(ballPos, {r: r, c: c});

                // Calculate distance and angles for drawing line
                let dist = Math.hypot(targetX - ballX, targetY - ballY);
                let angle = Math.atan2(targetY - ballY, targetX - ballX) * 180 / Math.PI;

                const line = document.createElement("div");
                line.className = "pass-viability-line";
                line.style.width = `${dist}px`;
                line.style.left = `${ballX}px`;
                line.style.top = `${ballY}px`;
                line.style.transform = `rotate(${angle}deg)`;

                if (passesBlock) {
                    // Blocked pass: draw red line
                    line.style.background = "linear-gradient(90deg, var(--accent-red) 0%, rgba(217,4,41,0.2) 100%)";
                    line.style.boxShadow = "0 0 5px var(--accent-red-glow)";
                }

                pitchContainer.appendChild(line);
            }
        }
    }
}

// Verifies if a defender intersects the path line using simple ray-to-box checks
function checkPassBlocked(start, end) {
    let blocked = false;
    
    // Look for any defender cell
    for (let r = 0; r < PITCH_ROWS; r++) {
        for (let c = 0; c < PITCH_COLS; c++) {
            if (pitchGrid[r][c].type === "defender") {
                // Approximate line-intersection by checks along vector segments
                let steps = 15;
                for (let i = 1; i < steps; i++) {
                    let t = i / steps;
                    let checkR = Math.round(start.r + (end.r - start.r) * t);
                    let checkC = Math.round(start.c + (end.c - start.c) * t);

                    if (checkR === r && checkC === c) {
                        blocked = true;
                        break;
                    }
                }
            }
        }
        if (blocked) break;
    }
    return blocked;
}

// Simple dynamic movement of ball to first open teammate
function simulatePassingPlay() {
    let targetAttacker = null;

    // Search for first unblocked attacker
    for (let r = 0; r < PITCH_ROWS; r++) {
        for (let c = 0; c < PITCH_COLS; c++) {
            if (pitchGrid[r][c].type === "attacker") {
                if (!checkPassBlocked(ballPos, {r: r, c: c})) {
                    targetAttacker = {r: r, c: c};
                    break;
                }
            }
        }
        if (targetAttacker) break;
    }

    if (!targetAttacker) {
        alert("All passing lanes are currently blocked by opponent defenders! Adjust player positions.");
        return;
    }

    // Move ball visually
    const cellW = document.getElementById("pitch-grid").getBoundingClientRect().width / PITCH_COLS;
    const cellH = document.getElementById("pitch-grid").getBoundingClientRect().height / PITCH_ROWS;

    // Transition ball element
    const prevBallEl = document.getElementById(`pitch-cell-${ballPos.r}-${ballPos.c}`);
    const nextBallEl = document.getElementById(`pitch-cell-${targetAttacker.r}-${targetAttacker.c}`);

    if (prevBallEl && nextBallEl) {
        prevBallEl.classList.remove("cell-ball");
        prevBallEl.textContent = "";
        pitchGrid[ballPos.r][ballPos.c].type = "clear";

        ballPos = { r: targetAttacker.r, c: targetAttacker.c };
        pitchGrid[ballPos.r][ballPos.c].type = "ball";
        nextBallEl.classList.add("cell-ball");
        nextBallEl.textContent = "⚽";
        
        recalculatePassLanes();
    }
}

// --- Tab 2: Tech - Behavior Tree Visualizer ---
function initBehaviorTree() {
    updateBehaviorTree();
}

function updateBehaviorTree() {
    const hasBall = document.getElementById("toggle-has-ball").value === "1";
    const inRange = document.getElementById("toggle-in-range").value === "1";
    const teammateOpen = document.getElementById("toggle-teammate-open").value === "1";

    document.getElementById("val-has-ball").textContent = hasBall ? "Yes" : "No";
    document.getElementById("val-in-range").textContent = inRange ? "Yes" : "No";
    document.getElementById("val-teammate-open").textContent = teammateOpen ? "Yes" : "No";

    // Reset node colors
    const nodes = ["node-root", "node-selector", "node-possession", "node-shoot", "node-pass", "node-dribble", "node-loose", "node-intercept", "node-defensive", "node-mark"];
    nodes.forEach(n => {
        const el = document.getElementById(n);
        if (el) el.classList.remove("active");
    });

    // Traverse Behavior Tree decisions based on inputs
    document.getElementById("node-root").classList.add("active");
    document.getElementById("node-selector").classList.add("active");

    if (hasBall) {
        document.getElementById("node-possession").classList.add("active");
        if (inRange) {
            document.getElementById("node-shoot").classList.add("active");
        } else if (teammateOpen) {
            document.getElementById("node-pass").classList.add("active");
        } else {
            document.getElementById("node-dribble").classList.add("active");
        }
    } else {
        // If opponent has ball (simulated default off-possession state)
        // If teammate open acts as ball loose flag in this simulator interface
        if (teammateOpen) {
            document.getElementById("node-loose").classList.add("active");
            document.getElementById("node-intercept").classList.add("active");
        } else {
            document.getElementById("node-defensive").classList.add("active");
            document.getElementById("node-mark").classList.add("active");
        }
    }
}

// --- Tab 3: Audio - MetaSound Excitement Waveform ---
function initAudioSimulator() {
    const waveContainer = document.getElementById("audio-wave-bar");
    if (!waveContainer) return;
    
    waveContainer.innerHTML = "";
    // Create 20 visual audio frequency bars
    for (let i = 0; i < 20; i++) {
        const bar = document.createElement("div");
        bar.className = "wave-bar";
        bar.id = `wave-bar-${i}`;
        waveContainer.appendChild(bar);
    }
    updateAudioSim();
    animateWave();
}

let waveHeights = Array(20).fill(10);

function updateAudioSim() {
    const prox = parseInt(document.getElementById("slider-proximity").value);
    const tension = parseInt(document.getElementById("slider-tension").value);
    const bigPlay = parseInt(document.getElementById("slider-bigplay").value);

    document.getElementById("val-proximity").textContent = `${prox}m`;
    
    let tensionText = "Low";
    if (tension > 40 && tension <= 75) tensionText = "Moderate";
    if (tension > 75) tensionText = "Critical Match Point";
    document.getElementById("val-tension").textContent = tensionText;

    let bigPlayText = "None";
    let playModifier = 0.0;
    if (bigPlay === 1) {
        bigPlayText = "Tactical Tackle";
        playModifier = 0.2;
    } else if (bigPlay === 2) {
        bigPlayText = "GOAL INBOUND!";
        playModifier = 0.5;
    }
    document.getElementById("val-bigplay").textContent = bigPlayText;

    // Excitement E = w1*(100-prox)/100 + w2*tension/100 + w3*playModifier
    let goalProxVal = (100 - prox) / 100;
    let tensionVal = tension / 100;
    let excitement = (goalProxVal * 0.4) + (tensionVal * 0.2) + playModifier;
    excitement = Math.min(1.0, Math.max(0.0, excitement));

    document.getElementById("audio-excitement-val").textContent = excitement.toFixed(2);

    let state = "Idle Murmur";
    let desc = "Synthesizing ambient murmurs and distant chatter.";
    let activeClass = "";

    if (excitement > 0.35 && excitement <= 0.7) {
        state = "Anticipation";
        desc = "Stitching mid-level crowd cheers and rhythmic clapping updates.";
        activeClass = "active-gold";
    } else if (excitement > 0.7) {
        state = "Peak Roar";
        desc = "Triggering MetaSound stadium roar sample stitches and dynamic whistle peaks!";
        activeClass = "active-warn";
    }

    document.getElementById("audio-state-text").textContent = state;
    document.getElementById("audio-desc-text").textContent = desc;

    // Apply color indicators to wave bars
    for (let i = 0; i < 20; i++) {
        const bar = document.getElementById(`wave-bar-${i}`);
        if (bar) {
            bar.className = "wave-bar";
            if (activeClass) bar.classList.add(activeClass);
        }
    }

    // Cache excitement scale for animator
    window.cachedExcitement = excitement;
}

function animateWave() {
    let E = window.cachedExcitement || 0.24;
    
    for (let i = 0; i < 20; i++) {
        const bar = document.getElementById(`wave-bar-${i}`);
        if (bar) {
            // Frequency calculation based on excitement index
            let base = 5 + E * 40;
            let variance = Math.random() * (15 + E * 35);
            let height = base + variance;
            bar.style.height = `${Math.min(75, height)}px`;
        }
    }

    setTimeout(() => {
        requestAnimationFrame(animateWave);
    }, 120);
}

// --- Tab 4: Production - Sprints Roadmap ---
const sprintsData = {
    1: {
        title: "Sprint 1: Base Physics & Setup",
        timeline: "Weeks 1-2 (Phase 1)",
        goals: [
            "Initialize custom Actor hierarchy extending GameModeBase and GameStateBase.",
            "Integrate Chaos substepping config files with 200Hz evaluation loops.",
            "Verify ball collision boundaries in stadium meshes."
        ],
        deps: "Unreal Engine 5 physics subsystem init."
    },
    2: {
        title: "Sprint 2: AI Systems & NavMesh",
        timeline: "Weeks 5-6 (Phase 2)",
        goals: [
            "Scaffold NavMesh volume constraints across the pitch parameters.",
            "Write C++ threat checking systems inside UAISensorComponent.",
            "Deploy spatial hash grid coordinates bucket systems for O(1) query lookups."
        ],
        deps: "Completed character models and default mesh constraints."
    },
    3: {
        title: "Sprint 3: GUI Overlays & Controls",
        timeline: "Weeks 9-10 (Phase 3)",
        goals: [
            "Write match HUD scoreboards and managers consoles.",
            "Bind team strategy posture sliders directly to tactical directives.",
            "Replicate GameState variables for match clocks and scores."
        ],
        deps: "Replicated C++ base variables in AAISoccerGameState."
    },
    4: {
        title: "Sprint 4: Lumen Profiles & Audio Attenuation",
        timeline: "Weeks 13-14 (Phase 4)",
        goals: [
            "Configure Lumen global reflections profiles for night match lights.",
            "Design MetaSound stadium excitation chains and low-pass curves.",
            "Integrate net impact velocity sound triggers."
        ],
        deps: "Dynamic mesh assets and physics net bounds."
    },
    5: {
        title: "Sprint 5: CPU Profiling & Launch Prep",
        timeline: "Weeks 17-18 (Phase 5)",
        goals: [
            "Throttle Behavior Tree ticks to prevent CPU frame spikes.",
            "Run automated headless Stress Test routines to check AI logic bounds.",
            "Review memory allocations using Unreal Insights."
        ],
        deps: "Completed match play systems and simulation triggers."
    }
};

function initSprintsRoadmap() {
    showSprint(1); // Show default sprint
}

function showSprint(id) {
    const panel = document.getElementById("sprint-info-panel");
    const data = sprintsData[id];

    // Set buttons active
    document.querySelectorAll(".sprint-nav-btn").forEach((btn, idx) => {
        if (idx === id - 1) btn.classList.add("active");
        else btn.classList.remove("active");
    });

    panel.style.opacity = 0;
    setTimeout(() => {
        let goalsList = data.goals.map(g => `<li>${g}</li>`).join("");
        panel.innerHTML = `
            <h4 style="color: var(--accent-gold); margin-bottom: 0.3rem;">${data.title}</h4>
            <span style="font-size: 0.8rem; color: var(--accent-green); font-weight: bold; display: block; margin-bottom: 0.8rem;">${data.timeline}</span>
            <strong style="font-size: 0.85rem; color: var(--text-primary);">Sprint Deliverables Checklist:</strong>
            <ul class="roadmap-list">
                ${goalsList}
            </ul>
            <div style="margin-top: 1rem; border-top: 1px solid var(--border-color); padding-top: 0.8rem; font-size: 0.8rem; color: var(--text-muted);">
                <strong>Technical Dependencies:</strong> ${data.deps}
            </div>
        `;
        panel.style.opacity = 1;
    }, 120);
}

// --- Tab 5: QA - Net Sync Diagnostics ---
function initQaSuite() {
    updateQaSim();
}

function updateQaSim() {
    const ping = parseInt(document.getElementById("slider-ping").value);
    const loss = parseInt(document.getElementById("slider-loss").value);
    const jitter = parseInt(document.getElementById("slider-jitter").value);

    document.getElementById("val-ping").textContent = `${ping}ms`;
    document.getElementById("val-loss").textContent = `${loss.toFixed(1)}%`;
    document.getElementById("val-jitter").textContent = `${jitter}ms`;

    const banner = document.getElementById("qa-alert-banner");
    const statusText = document.getElementById("qa-alert-status");
    const syncState = document.getElementById("qa-sync-state");
    const coordinateDelta = document.getElementById("qa-coordinate-delta");
    const logs = document.getElementById("qa-logs");

    // Recalculate drift: drift coordinate delta = ping * 0.1 + loss * 2.0 + jitter * 0.5
    let drift = (ping * 0.08) + (loss * 1.5) + (jitter * 0.4);
    coordinateDelta.textContent = `${drift.toFixed(1)} units`;

    let logsContent = `[SYSTEM] Profiling diagnostics...<br>`;
    
    if (ping > 120 || loss > 2.0 || jitter > 15) {
        banner.className = "alert-banner warning";
        statusText.textContent = "⚠️ REPLICATION DESYNC DETECTED";
        syncState.textContent = "Simulation Drift";
        coordinateDelta.className = "highlight";
        coordinateDelta.style.color = "var(--accent-red)";
        
        logsContent += `[WARNING] Ping: ${ping}ms exceeds substepping threshold.<br>`;
        logsContent += `[ERROR] Desync delta: ${drift.toFixed(1)} units. Triggering position interpolation snap.<br>`;
    } else {
        banner.className = "alert-banner";
        statusText.textContent = "🟢 SYSTEM SYNCHRONIZED";
        syncState.textContent = "Perfect Parity";
        coordinateDelta.className = "highlight";
        coordinateDelta.style.color = "var(--accent-green)";
        
        logsContent += `[CLIENT] Connection stable. Replicating AAISoccerGameState variables.<br>`;
        logsContent += `[SYSTEM] Thread parity: OK. Chaos Substeps: 0.005s.<br>`;
    }

    logs.innerHTML = logsContent;
}
