// --- Global App State & Event Listeners ---
document.addEventListener("DOMContentLoaded", () => {
    initTabs();
    initCherryBlossoms();
    initFlowFieldSimulator();
    initOptimizationSimulator();
    initDynamicAudioSimulator();
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
            this.y = Math.random() * height;
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

// --- Flow Field Simulator ---
const GRID_SIZE = 12;
let grid = [];
let currentTool = "wall"; 
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
    if (!gridContainer) return;
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
                type: cellType,
                cost: cellType === "swamp" ? 3.0 : (cellType === "wall" ? 99.0 : 1.0),
                distance: 9999,
                vector: {x: 0, y: 0}
            };

            const cellEl = document.createElement("div");
            cellEl.id = `cell-${r}-${c}`;
            cellEl.className = "grid-cell";
            if (isSpawn) cellEl.classList.add("cell-spawn");
            if (isKeep) cellEl.classList.add("cell-keep");

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
    const btn = document.getElementById(btnId);
    if (btn) btn.classList.add("active");
}

function handleCellClick(r, c) {
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

function recalculateFlowField() {
    for (let r = 0; r < GRID_SIZE; r++) {
        for (let c = 0; c < GRID_SIZE; c++) {
            grid[r][c].distance = 9999;
            grid[r][c].vector = {x: 0, y: 0};
        }
    }

    let queue = [];
    grid[keepPoint.x][keepPoint.y].distance = 0;
    queue.push(grid[keepPoint.x][keepPoint.y]);

    while (queue.length > 0) {
        let current = queue.shift();
        
        let neighbors = getNeighbors(current.row, current.col);
        neighbors.forEach(n => {
            if (n.type === "wall") return;

            let tentativeDist = current.distance + n.cost;
            if (tentativeDist < n.distance) {
                n.distance = tentativeDist;
                queue.push(n);
            }
        });
    }

    for (let r = 0; r < GRID_SIZE; r++) {
        for (let c = 0; c < GRID_SIZE; c++) {
            const cell = grid[r][c];
            const cellEl = document.getElementById(`cell-${r}-${c}`);
            if (!cellEl) continue;
            
            const oldArrow = cellEl.querySelector(".cell-arrow");
            if (oldArrow) oldArrow.remove();

            if (cell.type === "wall" || cell.type === "keep") {
                continue;
            }

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
                let dx = targetCell.col - c;
                let dy = targetCell.row - r;
                cell.vector = {x: dx, y: dy};

                const arrowEl = document.createElement("span");
                arrowEl.className = "cell-arrow";
                
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
    activeEnemies.forEach(e => e.el.remove());
    activeEnemies = [];
    if (simInterval) clearInterval(simInterval);

    createGrid();
    recalculateFlowField();
}

function spawnEnemies() {
    if (simInterval) clearInterval(simInterval);

    const gridContainer = document.getElementById("sim-grid");
    if (!gridContainer) return;
    const containerRect = gridContainer.getBoundingClientRect();
    const cellWidth = containerRect.width / GRID_SIZE;

    spawnPoints.forEach((spawn, idx) => {
        setTimeout(() => {
            createEnemyNode(spawn.row, spawn.col, cellWidth, gridContainer);
        }, idx * 400);

        setTimeout(() => {
            createEnemyNode(spawn.row, spawn.col, cellWidth, gridContainer);
        }, idx * 400 + 800);
    });

    simInterval = setInterval(() => {
        updateEnemies(cellWidth);
    }, 150);
}

function createEnemyNode(r, c, cellWidth, container) {
    const el = document.createElement("div");
    el.className = "enemy-dot";
    el.style.left = `${c * cellWidth + cellWidth/2}px`;
    el.style.top = `${r * cellWidth + cellWidth/2}px`;
    container.appendChild(el);

    activeEnemies.push({ r: r, c: c, el: el, active: true });
}

function updateEnemies(cellWidth) {
    if (activeEnemies.length === 0) {
        clearInterval(simInterval);
        return;
    }

    activeEnemies.forEach(enemy => {
        if (!enemy.active) return;

        if (enemy.r === keepPoint.x && enemy.c === keepPoint.y) {
            enemy.el.remove();
            enemy.active = false;
            return;
        }

        const cell = grid[enemy.r][enemy.c];
        if (cell.type === "wall") {
            enemy.active = false;
            enemy.el.remove();
            return;
        }

        let nextR = enemy.r + cell.vector.y;
        let nextC = enemy.c + cell.vector.x;

        if (nextR >= 0 && nextR < GRID_SIZE && nextC >= 0 && nextC < GRID_SIZE) {
            enemy.r = nextR;
            enemy.c = nextC;
            enemy.el.style.left = `${enemy.c * cellWidth + cellWidth/2}px`;
            enemy.el.style.top = `${enemy.r * cellWidth + cellWidth/2}px`;
        } else {
            enemy.active = false;
            enemy.el.remove();
        }
    });

    activeEnemies = activeEnemies.filter(e => e.active);
}

// --- Tab 2: Technical Blueprint - Genetic Algorithm ---
let gaGen = 0;
let gaBestFitness = 0;
let gaAvgFitness = 0;
const GA_GRID_SIZE = 8;
let gaGridData = [];

function initOptimizationSimulator() {
    createGaGrid();
    resetGa();
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

function runGaGeneration() {
    gaGen++;
    document.getElementById("ga-generation").textContent = gaGen;

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

    let noise = Math.random() * 1.5 - 0.75;
    gaBestFitness = targetBest;
    gaAvgFitness = targetAvg + noise;

    document.getElementById("ga-best-fitness").textContent = gaBestFitness;
    document.getElementById("ga-avg-fitness").textContent = gaAvgFitness.toFixed(1);

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

    let wallCoords = [];
    let pathCoords = [];

    if (gaGen < 5) {
        wallCoords = [{r: 1, c: 2}, {r: 2, c: 5}, {r: 4, c: 1}, {r: 5, c: 6}, {r: 6, c: 3}];
        pathCoords = [{r: 0, c: 1}, {r: 1, c: 1}, {r: 2, c: 1}, {r: 3, c: 1}, {r: 3, c: 2}, {r: 3, c: 3}, {r: 3, c: 4}, {r: 3, c: 5}, {r: 4, c: 5}, {r: 5, c: 5}, {r: 6, c: 5}, {r: 7, c: 5}, {r: 7, c: 6}];
    } else if (gaGen < 15) {
        wallCoords = [{r: 1, c: 2}, {r: 2, c: 2}, {r: 3, c: 2}, {r: 5, c: 5}, {r: 6, c: 5}, {r: 4, c: 5}];
        pathCoords = [{r: 0, c: 1}, {r: 0, c: 2}, {r: 0, c: 3}, {r: 1, c: 3}, {r: 2, c: 3}, {r: 3, c: 3}, {r: 4, c: 3}, {r: 4, c: 4}, {r: 4, c: 6}, {r: 5, c: 6}, {r: 6, c: 6}, {r: 7, c: 6}];
    } else if (gaGen < 30) {
        wallCoords = [
            {r: 1, c: 0}, {r: 1, c: 1}, {r: 1, c: 2}, {r: 1, c: 3}, {r: 1, c: 4}, {r: 1, c: 5},
            {r: 4, c: 2}, {r: 4, c: 3}, {r: 4, c: 4}, {r: 4, c: 5}, {r: 4, c: 6}, {r: 4, c: 7}
        ];
        pathCoords = [
            {r: 0, c: 1}, {r: 0, c: 2}, {r: 0, c: 3}, {r: 0, c: 4}, {r: 0, c: 5}, {r: 0, c: 6}, {r: 1, c: 6}, {r: 2, c: 6}, {r: 3, c: 6}, {r: 3, c: 5}, {r: 3, c: 4}, {r: 3, c: 3}, {r: 3, c: 2}, {r: 3, c: 1}, {r: 4, c: 1}, {r: 5, c: 1}, {r: 6, c: 1}, {r: 7, c: 1}, {r: 7, c: 2}, {r: 7, c: 3}, {r: 7, c: 4}, {r: 7, c: 5}, {r: 7, c: 6}
        ];
    } else {
        wallCoords = [
            {r: 1, c: 0}, {r: 1, c: 1}, {r: 1, c: 2}, {r: 1, c: 3}, {r: 1, c: 4}, {r: 1, c: 5}, {r: 1, c: 6},
            {r: 4, c: 1}, {r: 4, c: 2}, {r: 4, c: 3}, {r: 4, c: 4}, {r: 4, c: 5}, {r: 4, c: 6}, {r: 4, c: 7},
            {r: 6, c: 0}, {r: 6, c: 1}
        ];
        pathCoords = [
            {r: 0, c: 1}, {r: 0, c: 2}, {r: 0, c: 3}, {r: 0, c: 4}, {r: 0, c: 5}, {r: 0, c: 6}, {r: 0, c: 7}, {r: 1, c: 7}, {r: 2, c: 7}, {r: 3, c: 7}, {r: 3, c: 6}, {r: 3, c: 5}, {r: 3, c: 4}, {r: 3, c: 3}, {r: 3, c: 2}, {r: 3, c: 1}, {r: 3, c: 0}, {r: 4, c: 0}, {r: 5, c: 0}, {r: 5, c: 1}, {r: 5, c: 2}, {r: 5, c: 3}, {r: 5, c: 4}, {r: 5, c: 5}, {r: 5, c: 6}, {r: 6, c: 6}, {r: 7, c: 6}
        ];
    }

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

// --- Tab 3: Acoustic Design - MetaSound Excitement Waveform ---
function initDynamicAudioSimulator() {
    const waveContainer = document.getElementById("audio-wave-bar");
    if (!waveContainer) return;
    
    waveContainer.innerHTML = "";
    for (let i = 0; i < 20; i++) {
        const bar = document.createElement("div");
        bar.className = "wave-bar";
        bar.id = `wave-bar-${i}`;
        waveContainer.appendChild(bar);
    }
    updateDynamicAudioSim();
    animateWave();
}

function updateDynamicAudioSim() {
    const enemies = parseInt(document.getElementById("slider-enemies").value);
    const healthLoss = parseInt(document.getElementById("slider-healthloss").value);
    const boss = parseInt(document.getElementById("slider-boss").value);

    document.getElementById("val-enemies").textContent = `${enemies}`;
    document.getElementById("val-healthloss").textContent = `${healthLoss}%`;

    let bossText = "None";
    let bossMod = 0.0;
    if (boss === 1) {
        bossText = "Wokou Warlord";
        bossMod = 0.15;
    } else if (boss === 2) {
        bossText = "Pirate Fleet Admiral";
        bossMod = 0.4;
    }
    document.getElementById("val-boss").textContent = bossText;

    // Excitement E = enemies*0.01 + healthLoss*0.003 + bossMod
    let excitement = (enemies * 0.008) + (healthLoss * 0.003) + bossMod;
    excitement = Math.min(1.0, Math.max(0.0, excitement));

    document.getElementById("audio-excitement-val").textContent = excitement.toFixed(2);

    let state = "Day Preparation";
    let desc = "Playing ambient forest wind, rustling bamboo, and soft Shakuhachi flute loops.";
    let activeClass = "";

    if (excitement > 0.25 && excitement <= 0.6) {
        state = "Night Defense";
        desc = "Triggering light Taiko percussion tracks and dynamic Shamisen riffs.";
        activeClass = "active-gold";
    } else if (excitement > 0.6) {
        state = "Peak Siege Roar";
        desc = "Executing heavy, rapid Taiko drum rolls and sweeping battle vocal loops!";
        activeClass = "active-warn";
    }

    document.getElementById("audio-state-text").textContent = state;
    document.getElementById("audio-desc-text").textContent = desc;

    for (let i = 0; i < 20; i++) {
        const bar = document.getElementById(`wave-bar-${i}`);
        if (bar) {
            bar.className = "wave-bar";
            if (activeClass) bar.classList.add(activeClass);
        }
    }

    window.cachedExcitement = excitement;
}

function animateWave() {
    let E = window.cachedExcitement || 0.05;
    
    for (let i = 0; i < 20; i++) {
        const bar = document.getElementById(`wave-bar-${i}`);
        if (bar) {
            let base = 5 + E * 40;
            let variance = Math.random() * (10 + E * 30);
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
        title: "Sprint 1: Native Interface Parity",
        timeline: "Weeks 1-2 (Phase 1)",
        goals: [
            "Synchronize active GameLoop states across Swift and Kotlin codebases.",
            "Write JSON configuration loaders for static level layouts.",
            "Verify Canvas and SpriteKit resolution resizing operations."
        ],
        deps: "Base platform templates integration."
    },
    2: {
        title: "Sprint 2: Rust Simulation Core & ECS",
        timeline: "Weeks 5-6 (Phase 2)",
        goals: [
            "Build headless simulation engine using the Rust hecs ECS crate.",
            "Expose simulation controls through UniFFI FFI bindings.",
            "Write zero-copy binary state serializers using the rkyv format."
        ],
        deps: "Completed FFI bindings mapping schemas."
    },
    3: {
        title: "Sprint 3: Cooperative Netcode & Sockets",
        timeline: "Weeks 9-10 (Phase 3)",
        goals: [
            "Establish UDP packet delivery and delta replication buffers.",
            "Define latency-graduated matchmaking rules inside AWS GameLift FlexMatch.",
            "Build automatic fallback protocols for Spot Instance expirations."
        ],
        deps: "Completed Rust core binary serialization schemas."
    },
    4: {
        title: "Sprint 4: ML PCG Systems & Personalization",
        timeline: "Weeks 13-14 (Phase 4)",
        goals: [
            "Deploy offline PCGRL (PPO) map generators alongside WFC solvers.",
            "Integrate Imitation-Adversarial difficulty modulators.",
            "Wire Contextual Bandit (LinUCB) dynamic dynamic store pricing models."
        ],
        deps: "Replicated game telemetry databases."
    }
};

function initSprintsRoadmap() {
    showSprint(1);
}

function showSprint(id) {
    const panel = document.getElementById("sprint-info-panel");
    const data = sprintsData[id];

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

    let drift = (ping * 0.05) + (loss * 1.2) + (jitter * 0.3);
    coordinateDelta.textContent = `${drift.toFixed(1)} units`;

    let logsContent = `[SYSTEM] Profiling diagnostics...<br>`;
    
    if (ping > 120 || loss > 2.0 || jitter > 15) {
        banner.className = "alert-banner warning";
        statusText.textContent = "⚠️ REPLICATION DESYNC DETECTED";
        syncState.textContent = "Replication Drift";
        coordinateDelta.className = "highlight";
        coordinateDelta.style.color = "var(--accent-red)";
        
        logsContent += `[WARNING] Net ping: ${ping}ms exceeds substepping threshold.<br>`;
        logsContent += `[ERROR] Desync delta: ${drift.toFixed(1)} units. Snap client prediction position.<br>`;
    } else {
        banner.className = "alert-banner";
        statusText.textContent = "🟢 REPLICATION SYNCHRONIZED";
        syncState.textContent = "Perfect Parity";
        coordinateDelta.className = "highlight";
        coordinateDelta.style.color = "var(--accent-green)";
        
        logsContent += `[FFI] UniFFI byte transfer checks completed.<br>`;
        logsContent += `[SYSTEM] Delta packets: OK. Jitter: ${jitter}ms.<br>`;
    }

    logs.innerHTML = logsContent;
}
