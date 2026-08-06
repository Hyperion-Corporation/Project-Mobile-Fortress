// --- Global App State & Event Listeners ---
document.addEventListener("DOMContentLoaded", () => {
    initTabs();
    initCherryBlossoms();
    initUnitCards();
    initFlowFieldSimulator();
    initDdaSimulator();
    initBanditSimulator();
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
