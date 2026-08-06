// --- Global App State & Event Listeners ---
document.addEventListener("DOMContentLoaded", () => {
    initTabs();
    initCherryBlossoms();
    initUnitCards();
    initFlowFieldSimulator();
    initDdaSimulator();
    initBanditSimulator();
    initOptimizationSimulator();
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

    // Wires up the main navbar links to activate the corresponding tabs
    const navLinks = document.querySelectorAll(".nav-links a");
    navLinks.forEach(link => {
        link.addEventListener("click", (e) => {
            const href = link.getAttribute("href");
            if (href.startsWith("#") && href !== "#") {
                e.preventDefault();
                navLinks.forEach(l => l.classList.remove("active"));
                link.classList.add("active");

                // Map navigation link targets to tabs
                let tabTarget = "tab-vision";
                if (href === "#gameplay") tabTarget = "tab-flowfield";
                if (href === "#netcode") tabTarget = "tab-flowfield"; // Netcode tab uses the grid simulation
                if (href === "#ai-ml") tabTarget = "tab-dda";

                const targetBtn = document.querySelector(`.tab-btn[data-target="${tabTarget}"]`);
                if (targetBtn) targetBtn.click();

                // Smooth scroll to tabs section
                document.querySelector(".gdd-tabs-section").scrollIntoView({ behavior: "smooth" });
            }
        });
    });
}

// --- Falling Cherry Blossoms Particles ---
function initCherryBlossoms() {
    const canvas = document.getElementById("blossoms-canvas");
    const ctx = canvas.getContext("2d");

    let width = canvas.width = window.innerWidth;
    let height = canvas.height = window.innerHeight;

    window.addEventListener("resize", () => {
        width = canvas.width = window.innerWidth;
        height = canvas.height = window.innerHeight;
    });

    const numPetals = 40;
    const petals = [];

    class Petal {
        constructor() {
            this.reset();
            this.y = Math.random() * height; // Distribute initial petals vertically
        }

        reset() {
            this.x = Math.random() * width;
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

            if (this.y > height + 20 || this.x > width + 20 || this.x < -20) {
                this.reset();
            }
        }

        draw() {
            ctx.save();
            ctx.translate(this.x, this.y);
            ctx.rotate((this.rotation * Math.PI) / 180);
            ctx.beginPath();
            
            // Draw a cute cherry blossom shape
            ctx.moveTo(0, 0);
            ctx.bezierCurveTo(-this.size, -this.size / 2, -this.size / 2, -this.size * 1.5, 0, -this.size);
            ctx.bezierCurveTo(this.size / 2, -this.size * 1.5, this.size, -this.size / 2, 0, 0);
            
            ctx.fillStyle = `rgba(255, 183, 197, ${this.opacity})`;
            ctx.fill();
            ctx.restore();
        }
    }

    for (let i = 0; i < numPetals; i++) {
        petals.push(new Petal());
    }

    function animate() {
        ctx.clearRect(0, 0, width, height);
        petals.forEach(p => {
            p.update();
            p.draw();
        });
        requestAnimationFrame(animate);
    }

    animate();
}

// --- Unit Showcase Panel ---
const unitData = {
    ashigaru: {
        title: "Ashigaru Spearmen",
        role: "Melee Blocker & Crowd Controller",
        stats: "Health: 7/10 | Damage: 3/10 | Placement Cost: 25 Gold",
        desc: "Equipped with long Yari spears, these conscripts are deployed directly onto paths. While their damage output is low, their spatial blockage alters flow field coordinates, directing incoming hordes into Matchlock gun lanes."
    },
    matchlock: {
        title: "Matchlock Gunners",
        role: "High-Caliber Piercing Ranged",
        stats: "Health: 4/10 | Damage: 9/10 | Placement Cost: 75 Gold",
        desc: "Introduced by Portuguese traders, Matchlocks deal critical piercing damage in a straight vector line. Requires placement along straight paths and corridors where enemies line up in the vector flow field."
    },
    samurai: {
        title: "Samurai Hero",
        role: "Mobile Champion",
        stats: "Health: 9/10 | Damage: 8/10 | Placement Cost: 150 Gold",
        desc: "Dynamic combat super-units. Samurai are not static towers; they can be commanded to run to any location on the map. Possess large sweeping melee attacks and a cooling ultimate cleave that cleanses defiled ground."
    },
    shaman: {
        title: "Shaman Priestess",
        role: "Purifier / Support",
        stats: "Health: 5/10 | Damage: 4/10 | Placement Cost: 60 Gold",
        desc: "Shamans purify surrounding tiles, reducing local corruption. Enemies traveling over purified tiles experience a 40% speed reduction and take holy damage over time, stabilizing defensive choke points."
    }
};

function initUnitCards() {
    showUnitDetails("ashigaru"); // Set default unit display
}

function showUnitDetails(unitId) {
    const box = document.getElementById("unit-detail-box");
    const data = unitData[unitId];

    // Fade effect during update
    box.style.opacity = 0;
    setTimeout(() => {
        box.innerHTML = `
            <h4 style="color: var(--accent-pink); margin-bottom: 0.3rem;">${data.title}</h4>
            <strong style="font-size: 0.8rem; text-transform: uppercase; color: var(--accent-gold); display: block; margin-bottom: 0.5rem;">${data.role}</strong>
            <p style="font-size: 0.85rem; color: var(--text-muted); margin-bottom: 0.5rem;">${data.stats}</p>
            <p style="font-size: 0.9rem; line-height: 1.5; color: var(--text-secondary);">${data.desc}</p>
        `;
        box.style.opacity = 1;
    }, 150);
}

// --- Interactive Flow Field Simulator ---
const GRID_SIZE = 12;
let grid = [];
let currentTool = "wall"; // "wall", "swamp", "clear"
const spawnPoints = [{x: 0, y: 0}, {x: 0, y: 11}, {x: 11, y: 0}];
const keepPoint = {x: 5, y: 5};
let activeEnemies = [];
let simInterval = null;

function initFlowFieldSimulator() {
    createGrid();
    recalculateFlowField();
}

function createGrid() {
    const gridContainer = document.getElementById("sim-grid");
    gridContainer.innerHTML = "";
    grid = [];

    for (let r = 0; r < GRID_SIZE; r++) {
        grid[r] = [];
        for (let c = 0; c < GRID_SIZE; c++) {
            let isSpawn = spawnPoints.some(pt => pt.x === r && pt.y === c);
            let isKeep = keepPoint.x === r && keepPoint.y === c;
            
            let cellType = "clear";
            if (isKeep) cellType = "keep";
            else if (isSpawn) cellType = "spawn";

            grid[r][c] = {
                row: r,
                col: c,
                type: cellType, // "clear", "wall", "swamp", "keep", "spawn"
                cost: cellType === "swamp" ? 3.0 : (cellType === "wall" ? 99.0 : 1.0),
                distance: 9999,
                vector: {x: 0, y: 0}
            };

            const cellEl = document.createElement("div");
            cellEl.id = `cell-${r}-${c}`;
            cellEl.className = "grid-cell";
            if (isSpawn) cellEl.classList.add("cell-spawn");
            if (isKeep) cellEl.classList.add("cell-keep");

            // Event listener for user interaction
            cellEl.addEventListener("mousedown", () => handleCellClick(r, c));
            gridContainer.appendChild(cellEl);
        }
    }
}

function setTool(toolName) {
    currentTool = toolName;
    document.querySelectorAll(".btn-tool").forEach(btn => btn.classList.remove("active"));
    
    let btnId = "tool-wall";
    if (toolName === "swamp") btnId = "tool-swamp";
    if (toolName === "clear") btnId = "tool-clear";
    document.getElementById(btnId).classList.add("active");
}

function handleCellClick(r, c) {
    // Avoid overriding Keep or Spawns
    if (grid[r][c].type === "keep" || grid[r][c].type === "spawn") return;

    const cellEl = document.getElementById(`cell-${r}-${c}`);
    
    if (currentTool === "wall") {
        if (grid[r][c].type === "wall") {
            grid[r][c].type = "clear";
            grid[r][c].cost = 1.0;
            cellEl.classList.remove("cell-wall");
        } else {
            grid[r][c].type = "wall";
            grid[r][c].cost = 99.0;
            cellEl.classList.remove("cell-swamp");
            cellEl.classList.add("cell-wall");
        }
    } else if (currentTool === "swamp") {
        if (grid[r][c].type === "swamp") {
            grid[r][c].type = "clear";
            grid[r][c].cost = 1.0;
            cellEl.classList.remove("cell-swamp");
        } else {
            grid[r][c].type = "swamp";
            grid[r][c].cost = 3.0;
            cellEl.classList.remove("cell-wall");
            cellEl.classList.add("cell-swamp");
        }
    } else if (currentTool === "clear") {
        grid[r][c].type = "clear";
        grid[r][c].cost = 1.0;
        cellEl.classList.remove("cell-wall", "cell-swamp");
    }

    recalculateFlowField();
}

// Recalculates the Dijkstra distance fields and updates the vector arrows
function recalculateFlowField() {
    // 1. Reset distances
    for (let r = 0; r < GRID_SIZE; r++) {
        for (let c = 0; c < GRID_SIZE; c++) {
            grid[r][c].distance = 9999;
            grid[r][c].vector = {x: 0, y: 0};
        }
    }

    // 2. Dijkstra Map evaluation using a simple queue BFS
    let queue = [];
    grid[keepPoint.x][keepPoint.y].distance = 0;
    queue.push(grid[keepPoint.x][keepPoint.y]);

    while (queue.length > 0) {
        let current = queue.shift();
        
        let neighbors = getNeighbors(current.row, current.col);
        neighbors.forEach(n => {
            if (n.type === "wall") return; // Barriers block path

            let tentativeDist = current.distance + n.cost;
            if (tentativeDist < n.distance) {
                n.distance = tentativeDist;
                queue.push(n);
            }
        });
    }

    // 3. Compute Negative Gradient Vector Field
    for (let r = 0; r < GRID_SIZE; r++) {
        for (let c = 0; c < GRID_SIZE; c++) {
            const cell = grid[r][c];
            const cellEl = document.getElementById(`cell-${r}-${c}`);
            
            // Remove previous arrows
            const oldArrow = cellEl.querySelector(".cell-arrow");
            if (oldArrow) oldArrow.remove();

            if (cell.type === "wall" || cell.type === "keep") {
                continue;
            }

            // Find neighboring cell with smallest distance
            let neighbors = getNeighbors(r, c);
            let minDistance = cell.distance;
            let targetCell = null;

            neighbors.forEach(n => {
                if (n.type !== "wall" && n.distance < minDistance) {
                    minDistance = n.distance;
                    targetCell = n;
                }
            });

            if (targetCell) {
                // Calculate directional vector pointing to that node
                let dx = targetCell.col - c;
                let dy = targetCell.row - r;
                cell.vector = {x: dx, y: dy};

                // Add arrow element to UI for visualization
                const arrowEl = document.createElement("span");
                arrowEl.className = "cell-arrow";
                
                // Determine arrow symbol and angle
                let arrowChar = "→";
                if (dx === 0 && dy === -1) arrowChar = "↑";
                else if (dx === 0 && dy === 1) arrowChar = "↓";
                else if (dx === -1 && dy === 0) arrowChar = "←";
                else if (dx === -1 && dy === -1) arrowChar = "↖";
                else if (dx === 1 && dy === -1) arrowChar = "↗";
                else if (dx === -1 && dy === 1) arrowChar = "↙";
                else if (dx === 1 && dy === 1) arrowChar = "↘";

                arrowEl.textContent = arrowChar;
                cellEl.appendChild(arrowEl);
            }
        }
    }
}

function getNeighbors(r, c) {
    let neighbors = [];
    const dirs = [
        {dr: -1, dc: 0},  {dr: 1, dc: 0},
        {dr: 0, dc: -1},  {dr: 0, dc: 1},
        {dr: -1, dc: -1}, {dr: -1, dc: 1},
        {dr: 1, dc: -1},  {dr: 1, dc: 1}
    ];

    dirs.forEach(d => {
        let nr = r + d.dr;
        let nc = c + d.dc;
        if (nr >= 0 && nr < GRID_SIZE && nc >= 0 && nc < GRID_SIZE) {
            neighbors.push(grid[nr][nc]);
        }
    });

    return neighbors;
}

function clearSimMap() {
    // Clear active animations
    activeEnemies.forEach(e => e.el.remove());
    activeEnemies = [];
    if (simInterval) clearInterval(simInterval);

    createGrid();
    recalculateFlowField();
}

// Animated Wave Spawning using computed vectors
function spawnEnemies() {
    if (simInterval) clearInterval(simInterval);

    const gridContainer = document.getElementById("sim-grid");
    const containerRect = gridContainer.getBoundingClientRect();
    const cellWidth = containerRect.width / GRID_SIZE;

    // Spawn 3 waves from each active spawn gate
    spawnPoints.forEach((spawn, idx) => {
        setTimeout(() => {
            createEnemyNode(spawn.row, spawn.col, cellWidth, gridContainer);
        }, idx * 400);

        setTimeout(() => {
            createEnemyNode(spawn.row, spawn.col, cellWidth, gridContainer);
        }, idx * 400 + 800);
    });

    // Run ticks simulation
    simInterval = setInterval(() => {
        updateEnemies(cellWidth);
    }, 150);
}

function createEnemyNode(r, c, cellWidth, container) {
    const el = document.createElement("div");
    el.className = "enemy-dot";
    
    // Position relatively
    el.style.left = `${c * cellWidth + cellWidth/2}px`;
    el.style.top = `${r * cellWidth + cellWidth/2}px`;
    
    container.appendChild(el);

    activeEnemies.push({
        r: r,
        c: c,
        el: el,
        active: true
    });
}

function updateEnemies(cellWidth) {
    if (activeEnemies.length === 0) {
        clearInterval(simInterval);
        return;
    }

    activeEnemies.forEach(enemy => {
        if (!enemy.active) return;

        // Reach Goal
        if (enemy.r === keepPoint.x && enemy.c === keepPoint.y) {
            enemy.el.remove();
            enemy.active = false;
            return;
        }

        const cell = grid[enemy.r][enemy.c];
        
        // Blocked case: recalculate if blocked
        if (cell.type === "wall") {
            enemy.active = false;
            enemy.el.remove();
            return;
        }

        // Apply vector changes
        let nextR = enemy.r + cell.vector.y;
        let nextC = enemy.c + cell.vector.x;

        if (nextR >= 0 && nextR < GRID_SIZE && nextC >= 0 && nextC < GRID_SIZE) {
            enemy.r = nextR;
            enemy.c = nextC;

            // Move animated node
            enemy.el.style.left = `${enemy.c * cellWidth + cellWidth/2}px`;
            enemy.el.style.top = `${enemy.r * cellWidth + cellWidth/2}px`;
        } else {
            enemy.active = false;
            enemy.el.remove();
        }
    });

    // Clean up inactive enemies
    activeEnemies = activeEnemies.filter(e => e.active);
}

// --- Adversarial DDA Simulator ---
function initDdaSimulator() {
    updateDda();
}

function updateDda() {
    const reactionVal = parseInt(document.getElementById("slider-reaction").value);
    const hoardingVal = parseInt(document.getElementById("slider-hoarding").value);
    const shortrangeVal = parseInt(document.getElementById("slider-shortrange").value);

    // Update labels
    document.getElementById("val-reaction").textContent = `${reactionVal}ms`;
    document.getElementById("val-hoarding").textContent = `${hoardingVal}%`;
    document.getElementById("val-shortrange").textContent = `${shortrangeVal}%`;

    // Compute metrics
    // Clone fit is higher when playstyle is extreme (very fast or very slow reaction, high hoard)
    let cloneFit = Math.min(98, Math.round(50 + (hoardingVal/2) + (shortrangeVal/4)));
    
    // Threat intensity adjusts to challenge user
    // High hoarding or fast reaction increases threat to keep tension active
    let threatVal = Math.round(30 + (1500 - reactionVal)/30 + (hoardingVal/3) + (shortrangeVal/5));
    threatVal = Math.min(99, Math.max(10, threatVal));

    document.getElementById("bar-clone").style.width = `${cloneFit}%`;
    document.getElementById("bar-clone").textContent = `${cloneFit}%`;
    
    document.getElementById("bar-threat").style.width = `${threatVal}%`;
    document.getElementById("bar-threat").textContent = `${threatVal}%`;

    // Dynamic response text based on settings
    let responseText = "Observing user. Standard waves deployed.";
    if (reactionVal > 900) {
        responseText = "User reaction times are sluggish. Deploying fast-moving Tengu Yokai waves and sudden spatial flanking raids to challenge lateral coverage.";
    } else if (hoardingVal > 60) {
        responseText = "User is hoarding gold coins rather than upgrading defenses. Deploying early armor-plated Gashadokuro siege boss to force combat spending.";
    } else if (shortrangeVal > 80) {
        responseText = "User places mostly short-range melee Ashigaru spearmen. Modulating waves to spawn long-range Oni archers and flying spirits that bypass path blockages.";
    } else if (reactionVal < 300 && shortrangeVal < 40) {
        responseText = "User has hyper-active reaction speeds and spreads range coverage effectively. Competition Agent is executing a heavy split-lane siege containing high-HP minibosses.";
    } else {
        responseText = "Optimizing threat boundaries to maintain Flow State. Balanced distribution of standard melee and ranged Yokai groups deployed.";
    }

    document.getElementById("dda-tactical-response").textContent = responseText;
}

// --- Monetization (CMAB) Simulator ---
const offers = [
    {
        title: "Samurai Warlord Starter Package",
        price: "$4.99",
        desc: "Equip your Samurai Hero with legendary armor and visual particle effects, providing early damage increases during tactical loops.",
        baseVal: 0.6
    },
    {
        title: "Matchlock Marksman Special Offer",
        price: "$2.99",
        desc: "Instant resources package containing 500 gold coins and a rare Matchlock Blueprint to quickly counter linear lanes.",
        baseVal: 0.4
    },
    {
        title: "Shaman Purification Blessing",
        price: "$0.99",
        desc: "Cozy progress booster that speeds up Shaman healing rates by 25% for 3 days. Includes an exclusive blossom cherry cosmetic.",
        baseVal: 0.3
    },
    {
        title: "Daimyo's Golden Castle Skin",
        price: "$9.99",
        desc: "Transform your central Keep into a glowing gold monument with custom historical audio themes. Pure premium aesthetic skin.",
        baseVal: 0.2
    }
];

function initBanditSimulator() {
    updateBandit();
}

function updateBandit() {
    const retentionVal = parseInt(document.getElementById("slider-retention").value);
    const deficitVal = parseInt(document.getElementById("slider-deficit").value);
    const favVal = parseInt(document.getElementById("slider-fav").value);

    // Update labels
    let phase = "D1 Onboarding";
    if (retentionVal > 3 && retentionVal <= 14) phase = `D${retentionVal} Retained`;
    if (retentionVal > 14) phase = `D${retentionVal} Core Veteran`;
    document.getElementById("val-retention").textContent = phase;

    let deficit = "Low Deficit";
    if (deficitVal === 1) deficit = "Medium Deficit";
    if (deficitVal === 2) deficit = "Severe Gold Deficit";
    document.getElementById("val-deficit").textContent = deficit;

    let favClass = "Samurai Champion";
    if (favVal === 1) favClass = "Matchlock Gunners";
    if (favVal === 2) favClass = "Shaman Priestess";
    if (favVal === 3) favClass = "Cosmetics/Decorative";
    document.getElementById("val-fav").textContent = favClass;

    // Simulate LinUCB calculations for each offer
    // context vector: x = [retention_phase, gold_deficit, favorite_class_usage]
    let maxScore = -1;
    let selectedOffer = null;
    let selectedDetails = {};

    offers.forEach((offer, idx) => {
        let expectedPayout = offer.baseVal;
        
        // Context rules logic matching vectors
        if (idx === 0) { // Samurai Warlord
            expectedPayout += (retentionVal < 5) ? 0.3 : 0.05;
            expectedPayout += (favVal === 0) ? 0.4 : 0.0;
        } else if (idx === 1) { // Matchlock Special
            expectedPayout += (deficitVal === 2) ? 0.5 : 0.1;
            expectedPayout += (favVal === 1) ? 0.3 : 0.0;
        } else if (idx === 2) { // Shaman Blessing
            expectedPayout += (retentionVal > 14) ? 0.4 : 0.1;
            expectedPayout += (favVal === 2) ? 0.4 : 0.0;
        } else if (idx === 3) { // Castle Skin
            expectedPayout += (retentionVal > 10) ? 0.6 : -0.2;
            expectedPayout += (favVal === 3) ? 0.5 : 0.0;
        }

        // Add simulated pseudo-random exploration bonus (alpha * sqrt(var))
        let explorationBonus = 0.1 + Math.sin(idx * 45 + retentionVal) * 0.1;
        explorationBonus = Math.max(0.05, Math.min(0.3, explorationBonus));
        
        let score = expectedPayout + explorationBonus;

        if (score > maxScore) {
            maxScore = score;
            selectedOffer = offer;
            selectedDetails = {
                payout: expectedPayout.toFixed(2),
                bonus: explorationBonus.toFixed(2),
                total: score.toFixed(2)
            };
        }
    });

    // Update UI elements
    document.getElementById("offer-title").textContent = selectedOffer.title;
    document.getElementById("offer-price").textContent = selectedOffer.price;
    document.getElementById("offer-desc").textContent = selectedOffer.desc;
    
    document.getElementById("math-payout").textContent = selectedDetails.payout;
    document.getElementById("math-bonus").textContent = selectedDetails.bonus;
    document.getElementById("math-total").textContent = selectedDetails.total;
}

// --- Tab 5: Mathematical Optimization (GA & ACO) ---
let gaGen = 0;
let gaBestFitness = 0;
let gaAvgFitness = 0;
const GA_GRID_SIZE = 8;
let gaGridData = [];

function initOptimizationSimulator() {
    createGaGrid();
    resetGa();
    initAcoGraph();
}

function createGaGrid() {
    const gaGridEl = document.getElementById("ga-grid");
    if (!gaGridEl) return;
    gaGridEl.innerHTML = "";
    gaGridData = [];

    for (let r = 0; r < GA_GRID_SIZE; r++) {
        gaGridData[r] = [];
        for (let c = 0; c < GA_GRID_SIZE; c++) {
            let type = "clear";
            if (r === 0 && c === 0) type = "spawn";
            else if (r === GA_GRID_SIZE - 1 && c === GA_GRID_SIZE - 1) type = "keep";

            gaGridData[r][c] = { row: r, col: c, type: type };

            const cellEl = document.createElement("div");
            cellEl.id = `ga-cell-${r}-${c}`;
            cellEl.className = "ga-cell";
            if (type === "spawn") {
                cellEl.classList.add("ga-spawn");
                cellEl.textContent = "⛩️";
            } else if (type === "keep") {
                cellEl.classList.add("ga-keep");
                cellEl.textContent = "🏰";
            }
            gaGridEl.appendChild(cellEl);
        }
    }
}

function resetGa() {
    gaGen = 0;
    gaBestFitness = 0;
    gaAvgFitness = 0.0;
    
    document.getElementById("ga-generation").textContent = gaGen;
    document.getElementById("ga-best-fitness").textContent = gaBestFitness;
    document.getElementById("ga-avg-fitness").textContent = gaAvgFitness.toFixed(1);

    // Clear grid styles except spawn/keep
    for (let r = 0; r < GA_GRID_SIZE; r++) {
        for (let c = 0; c < GA_GRID_SIZE; c++) {
            const cell = gaGridData[r][c];
            if (cell.type !== "spawn" && cell.type !== "keep") {
                cell.type = "clear";
                const cellEl = document.getElementById(`ga-cell-${r}-${c}`);
                if (cellEl) {
                    cellEl.className = "ga-cell";
                    cellEl.textContent = "";
                }
            }
        }
    }
}

// Simulated GA optimization steps showing structural convergence
function runGaGeneration() {
    gaGen++;
    document.getElementById("ga-generation").textContent = gaGen;

    // Simulate progress: as gen increases, best fitness converges to optimal winding path
    let targetBest = 14;
    let targetAvg = 10.5;

    if (gaGen >= 1 && gaGen < 5) {
        targetBest = 16;
        targetAvg = 12.2;
    } else if (gaGen >= 5 && gaGen < 15) {
        targetBest = 20;
        targetAvg = 15.6;
    } else if (gaGen >= 15 && gaGen < 30) {
        targetBest = 24;
        targetAvg = 19.8;
    } else {
        targetBest = 28;
        targetAvg = 23.4;
    }

    // Slightly fluctuate values to look like active genetic diversity
    let noise = Math.random() * 1.5 - 0.75;
    gaBestFitness = targetBest;
    gaAvgFitness = targetAvg + noise;

    document.getElementById("ga-best-fitness").textContent = gaBestFitness;
    document.getElementById("ga-avg-fitness").textContent = gaAvgFitness.toFixed(1);

    // Draw the evolved walls and optimal path based on generation stage
    // Clean old cells first
    for (let r = 0; r < GA_GRID_SIZE; r++) {
        for (let c = 0; c < GA_GRID_SIZE; c++) {
            const cell = gaGridData[r][c];
            if (cell.type !== "spawn" && cell.type !== "keep") {
                cell.type = "clear";
                const cellEl = document.getElementById(`ga-cell-${r}-${c}`);
                if (cellEl) {
                    cellEl.className = "ga-cell";
                    cellEl.textContent = "";
                }
            }
        }
    }

    // Coordinates of walls for different generation tiers (pre-coded to show convergence)
    let wallCoords = [];
    let pathCoords = [];

    if (gaGen < 5) {
        // Gen 1-4: Random scattered walls
        wallCoords = [{r: 1, c: 2}, {r: 2, c: 5}, {r: 4, c: 1}, {r: 5, c: 6}, {r: 6, c: 3}];
        pathCoords = [{r: 0, c: 1}, {r: 1, c: 1}, {r: 2, c: 1}, {r: 3, c: 1}, {r: 3, c: 2}, {r: 3, c: 3}, {r: 3, c: 4}, {r: 3, c: 5}, {r: 4, c: 5}, {r: 5, c: 5}, {r: 6, c: 5}, {r: 7, c: 5}, {r: 7, c: 6}];
    } else if (gaGen < 15) {
        // Gen 5-14: Structural blockages forming
        wallCoords = [{r: 1, c: 2}, {r: 2, c: 2}, {r: 3, c: 2}, {r: 5, c: 5}, {r: 6, c: 5}, {r: 4, c: 5}];
        pathCoords = [{r: 0, c: 1}, {r: 0, c: 2}, {r: 0, c: 3}, {r: 1, c: 3}, {r: 2, c: 3}, {r: 3, c: 3}, {r: 4, c: 3}, {r: 4, c: 4}, {r: 4, c: 6}, {r: 5, c: 6}, {r: 6, c: 6}, {r: 7, c: 6}];
    } else if (gaGen < 30) {
        // Gen 15-29: Double winding paths
        wallCoords = [
            {r: 1, c: 0}, {r: 1, c: 1}, {r: 1, c: 2}, {r: 1, c: 3}, {r: 1, c: 4}, {r: 1, c: 5},
            {r: 4, c: 2}, {r: 4, c: 3}, {r: 4, c: 4}, {r: 4, c: 5}, {r: 4, c: 6}, {r: 4, c: 7}
        ];
        pathCoords = [
            {r: 0, c: 1}, {r: 0, c: 2}, {r: 0, c: 3}, {r: 0, c: 4}, {r: 0, c: 5}, {r: 0, c: 6}, {r: 1, c: 6}, {r: 2, c: 6}, {r: 3, c: 6}, {r: 3, c: 5}, {r: 3, c: 4}, {r: 3, c: 3}, {r: 3, c: 2}, {r: 3, c: 1}, {r: 4, c: 1}, {r: 5, c: 1}, {r: 6, c: 1}, {r: 7, c: 1}, {r: 7, c: 2}, {r: 7, c: 3}, {r: 7, c: 4}, {r: 7, c: 5}, {r: 7, c: 6}
        ];
    } else {
        // Gen 30+: Maximum maze winding within budget (16 walls)
        wallCoords = [
            {r: 1, c: 0}, {r: 1, c: 1}, {r: 1, c: 2}, {r: 1, c: 3}, {r: 1, c: 4}, {r: 1, c: 5}, {r: 1, c: 6},
            {r: 4, c: 1}, {r: 4, c: 2}, {r: 4, c: 3}, {r: 4, c: 4}, {r: 4, c: 5}, {r: 4, c: 6}, {r: 4, c: 7},
            {r: 6, c: 0}, {r: 6, c: 1}
        ];
        pathCoords = [
            {r: 0, c: 1}, {r: 0, c: 2}, {r: 0, c: 3}, {r: 0, c: 4}, {r: 0, c: 5}, {r: 0, c: 6}, {r: 0, c: 7}, {r: 1, c: 7}, {r: 2, c: 7}, {r: 3, c: 7}, {r: 3, c: 6}, {r: 3, c: 5}, {r: 3, c: 4}, {r: 3, c: 3}, {r: 3, c: 2}, {r: 3, c: 1}, {r: 3, c: 0}, {r: 4, c: 0}, {r: 5, c: 0}, {r: 5, c: 1}, {r: 5, c: 2}, {r: 5, c: 3}, {r: 5, c: 4}, {r: 5, c: 5}, {r: 5, c: 6}, {r: 6, c: 6}, {r: 7, c: 6}
        ];
    }

    // Apply classes to UI cells
    wallCoords.forEach(w => {
        gridCellTypeSet(w.r, w.c, "wall", "ga-cell ga-wall");
    });

    pathCoords.forEach(p => {
        gridCellTypeSet(p.r, p.c, "path", "ga-cell ga-path");
        const cellEl = document.getElementById(`ga-cell-${p.r}-${p.c}`);
        if (cellEl) cellEl.textContent = "🔸";
    });
}

function gridCellTypeSet(r, c, type, className) {
    if (r >= 0 && r < GA_GRID_SIZE && c >= 0 && c < GA_GRID_SIZE) {
        gaGridData[r][c].type = type;
        const cellEl = document.getElementById(`ga-cell-${r}-${c}`);
        if (cellEl) cellEl.className = className;
    }
}

// Ant Colony Optimization Graph Setup
const acoNodes = {
    Kyoto: { name: "Kyoto", x: 40, y: 100, type: "start", role: "Kyoto (Base)" },
    Mino: { name: "Mino", x: 130, y: 50, type: "prov", role: "Mino" },
    Owari: { name: "Owari", x: 130, y: 150, type: "prov", role: "Owari" },
    Kaga: { name: "Kaga", x: 230, y: 50, type: "prov", role: "Kaga" },
    Mikawa: { name: "Mikawa", x: 230, y: 150, type: "prov", role: "Mikawa" },
    Echigo: { name: "Echigo", x: 320, y: 100, type: "goal", role: "Echigo (Keep)" }
};

const acoEdges = [
    { from: "Kyoto", to: "Mino", dist: 4 },
    { from: "Kyoto", to: "Owari", dist: 5 },
    { from: "Mino", to: "Kaga", dist: 4 },
    { from: "Owari", to: "Mikawa", dist: 5 },
    { from: "Kaga", to: "Echigo", dist: 4 },
    { from: "Mikawa", to: "Echigo", dist: 5 },
    { from: "Mino", to: "Echigo", dist: 14 } // Direct high cost shortcut
];

let provThreats = {
    Mino: false,
    Mikawa: false,
    Owari: false
};

function initAcoGraph() {
    renderAcoNodes();
    drawAcoEdges();
    calculateAcoBestPath();
}

function renderAcoNodes() {
    const container = document.getElementById("aco-nodes-container");
    if (!container) return;
    container.innerHTML = "";

    Object.keys(acoNodes).forEach(key => {
        const node = acoNodes[key];
        const nodeEl = document.createElement("div");
        nodeEl.className = `aco-node node-${key.toLowerCase()}`;
        nodeEl.style.left = `${node.x}px`;
        nodeEl.style.top = `${node.y}px`;
        nodeEl.textContent = key;
        nodeEl.title = node.role;
        container.appendChild(nodeEl);
    });
}

function drawAcoEdges() {
    const svg = document.getElementById("aco-svg");
    if (!svg) return;
    svg.innerHTML = "";

    acoEdges.forEach((edge, idx) => {
        const nFrom = acoNodes[edge.from];
        const nTo = acoNodes[edge.to];
        
        const line = document.createElementNS("http://www.w3.org/2000/svg", "line");
        line.setAttribute("x1", nFrom.x);
        line.setAttribute("y1", nFrom.y);
        line.setAttribute("x2", nTo.x);
        line.setAttribute("y2", nTo.y);
        line.setAttribute("stroke", "rgba(255,255,255,0.15)");
        line.setAttribute("stroke-width", "2");
        line.id = `aco-edge-${idx}`;
        svg.appendChild(line);
    });
}

function toggleProvince(provName) {
    provThreats[provName] = !provThreats[provName];
    
    // Update button states
    const btn = document.getElementById(`prov-${provName.toLowerCase()}`);
    const nodeEl = document.querySelector(`.node-${provName.toLowerCase()}`);
    
    if (provThreats[provName]) {
        if (btn) {
            btn.classList.add("active");
            btn.textContent = `${provName}: THREAT`;
        }
        if (nodeEl) nodeEl.classList.add("node-threat");
    } else {
        if (btn) {
            btn.classList.remove("active");
            btn.textContent = `${provName}: Safe`;
        }
        if (nodeEl) nodeEl.classList.remove("node-threat");
    }

    calculateAcoBestPath();
}

function calculateAcoBestPath() {
    // Determine edge weights: weight = dist * threat
    // Threat defaults to 1.0, increases to 10.0 if province is set to High Threat
    let edgeWeights = acoEdges.map(edge => {
        let threat = 1.0;
        if (provThreats[edge.from] || provThreats[edge.to]) {
            threat = 10.0;
        }
        return edge.dist * threat;
    });

    // 3 main pathways from Kyoto to Echigo
    // Route 0: Kyoto -> Mino -> Kaga -> Echigo
    let cost0 = edgeWeights[0] + edgeWeights[2] + edgeWeights[4]; // Kyoto->Mino + Mino->Kaga + Kaga->Echigo
    // Route 1: Kyoto -> Owari -> Mikawa -> Echigo
    let cost1 = edgeWeights[1] + edgeWeights[3] + edgeWeights[5]; // Kyoto->Owari + Owari->Mikawa + Mikawa->Echigo
    // Route 2: Kyoto -> Mino -> Echigo (direct shortcut)
    let cost2 = edgeWeights[0] + edgeWeights[6]; // Kyoto->Mino + Mino->Echigo

    let pathText = "";
    let activeEdges = [];

    if (cost0 <= cost1 && cost0 <= cost2) {
        pathText = "Kyoto ➔ Mino ➔ Kaga ➔ Echigo";
        activeEdges = [0, 2, 4];
    } else if (cost1 <= cost0 && cost1 <= cost2) {
        pathText = "Kyoto ➔ Owari ➔ Mikawa ➔ Echigo";
        activeEdges = [1, 3, 5];
    } else {
        pathText = "Kyoto ➔ Mino ➔ Echigo (Direct)";
        activeEdges = [0, 6];
    }

    const displayEl = document.getElementById("aco-path-display");
    if (displayEl) displayEl.textContent = pathText;

    // Highlights path in SVG edges
    acoEdges.forEach((edge, idx) => {
        const line = document.getElementById(`aco-edge-${idx}`);
        if (line) {
            if (activeEdges.includes(idx)) {
                line.setAttribute("stroke", "var(--accent-gold)");
                line.setAttribute("stroke-width", "4");
                line.setAttribute("style", "filter: drop-shadow(0 0 5px var(--accent-gold-glow));");
            } else {
                line.setAttribute("stroke", "rgba(255,255,255,0.15)");
                line.setAttribute("stroke-width", "2");
                line.removeAttribute("style");
            }
        }
    });

    return activeEdges;
}

// Particle simulation representing ants routing
function launchAcoConvoys() {
    const activeEdges = calculateAcoBestPath();
    const container = document.querySelector(".graph-viewport");
    if (!container) return;
    
    // Spawn ants along the chosen path sequentially
    let pathNodes = [];
    if (activeEdges.includes(2)) {
        pathNodes = ["Kyoto", "Mino", "Kaga", "Echigo"];
    } else if (activeEdges.includes(3)) {
        pathNodes = ["Kyoto", "Owari", "Mikawa", "Echigo"];
    } else {
        pathNodes = ["Kyoto", "Mino", "Echigo"];
    }

    for (let i = 0; i < 5; i++) {
        setTimeout(() => {
            spawnAntParticle(pathNodes, container);
        }, i * 300);
    }
}

function spawnAntParticle(nodes, container) {
    const ant = document.createElement("div");
    ant.className = "aco-ant-particle";
    
    let startNode = acoNodes[nodes[0]];
    ant.style.left = `${startNode.x}px`;
    ant.style.top = `${startNode.y}px`;
    container.appendChild(ant);

    let currentStep = 0;
    
    function moveNext() {
        if (currentStep >= nodes.length - 1) {
            // Reached goal
            setTimeout(() => ant.remove(), 200);
            return;
        }

        let fromNode = acoNodes[nodes[currentStep]];
        let toNode = acoNodes[nodes[currentStep + 1]];
        
        let startX = fromNode.x;
        let startY = fromNode.y;
        let endX = toNode.x;
        let endY = toNode.y;

        let startTime = null;
        let duration = 600; // ms

        function step(timestamp) {
            if (!startTime) startTime = timestamp;
            let progress = (timestamp - startTime) / duration;
            if (progress > 1.0) progress = 1.0;

            let curX = startX + (endX - startX) * progress;
            let curY = startY + (endY - startY) * progress;

            ant.style.left = `${curX}px`;
            ant.style.top = `${curY}px`;

            if (progress < 1.0) {
                requestAnimationFrame(step);
            } else {
                currentStep++;
                moveNext();
            }
        }

        requestAnimationFrame(step);
    }

    moveNext();
}
