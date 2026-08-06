// Mobile Fortress — combined interactive design-hub + documentation site.
// Plain Vue 3 (no build step): component templates live in index.html as
// <script type="text/x-template"> blocks, referenced here by selector.

const { createApp, reactive, ref, computed, onMounted, onUnmounted, nextTick, watch } = Vue;
const { createRouter, createWebHashHistory, useRoute, useRouter } = VueRouter;

const REPO = "https://github.com/ACFHarbinger/Project-Mobile-Fortress";

// ---------------------------------------------------------------------
// Documentation content map — mirrors docs/{index.md,ARCHITECTURE.md,...}
// one-to-one. `docs/website`'s build step copies those markdown sources
// into content/<slug>.md (see .github/workflows/docs.yml) so this app can
// fetch them at runtime.
// ---------------------------------------------------------------------
const docSections = [
    {
        title: "Getting Started",
        items: [
            { slug: "index", title: "Overview" },
            { slug: "ARCHITECTURE", title: "Architecture" },
            { slug: "DEVELOPMENT", title: "Development" },
            { slug: "TESTING", title: "Testing" },
            { slug: "GLOSSARY", title: "Glossary" },
        ],
    },
    {
        title: "Architecture Decisions",
        items: [
            { slug: "adr/0001-record-architecture-decisions", title: "0001 — Record Architecture Decisions" },
            { slug: "adr/0002-rendering-approach", title: "0002 — Rendering Approach (Android)" },
            { slug: "adr/0003-ios-rendering-approach", title: "0003 — Rendering Approach (iOS)" },
        ],
    },
    {
        title: "Roadmap",
        items: [
            { slug: "moon/ROADMAP", title: "Roadmap Overview" },
            { slug: "moon/CHANGELOG", title: "Changelog" },
            { slug: "moon/roadmaps/gameplay", title: "Gameplay" },
            { slug: "moon/roadmaps/ui_ux", title: "UI / UX" },
            { slug: "moon/roadmaps/performance", title: "Performance" },
            { slug: "moon/roadmaps/monetization", title: "Monetization" },
            { slug: "moon/roadmaps/backend", title: "Backend" },
            { slug: "moon/roadmaps/ai_systems", title: "AI Systems" },
            { slug: "moon/roadmaps/qa_testing", title: "QA & Testing" },
            { slug: "moon/roadmaps/ios", title: "iOS" },
            { slug: "moon/roadmaps/shared_core", title: "Shared Core" },
        ],
    },
    {
        title: "Design",
        items: [
            { slug: "design/game_design_document", title: "Game Design Document" },
            { slug: "design/art_bible", title: "Art Bible" },
            { slug: "design/audio_design_document", title: "Audio Design" },
            { slug: "design/pitch_deck", title: "Pitch Deck" },
            { slug: "design/production_roadmap", title: "Production Roadmap" },
            { slug: "design/qa_test_plan", title: "QA Test Plan" },
            { slug: "design/technical_design_document", title: "Technical Design Document" },
        ],
    },
];

const flatDocs = docSections.flatMap((section) =>
    section.items.map((item) => ({ ...item, section: section.title }))
);
const knownSlugs = new Set(flatDocs.map((d) => d.slug));

function findDoc(slug) {
    return flatDocs.find((d) => d.slug === slug) || null;
}

function slugify(text) {
    return String(text)
        .toLowerCase()
        .trim()
        .replace(/[^a-z0-9]+/g, "-")
        .replace(/(^-|-$)/g, "");
}

// Resolves a markdown-authored relative link against the *source* doc's
// repo path (docs/<slug>.md) using the URL parser for correct ../ handling.
// Internal links (into our known doc set) route via Vue Router; everything
// else outside docs/ (reports/, research/, android/, .agent/, ...) opens as
// a GitHub blob link instead of 404ing on the static site.
function resolveHref(href, currentSlug) {
    const base = "https://x.invalid/docs/" + currentSlug + ".md";
    let target;
    try {
        target = new URL(href, base);
    } catch (e) {
        return { type: "external" };
    }
    const pathname = decodeURIComponent(target.pathname).replace(/^\//, "");
    const hash = target.hash || "";
    if (pathname.startsWith("docs/")) {
        const candidateSlug = pathname.slice(5).replace(/\.md$/, "");
        if (knownSlugs.has(candidateSlug)) {
            return { type: "internal", slug: candidateSlug, hash };
        }
    }
    return { type: "blob", path: pathname };
}

// ---------------------------------------------------------------------
// Shared Home-view state (which design-hub tab is active) — a module-level
// reactive object so both <nav-bar> and <home-view> can read/drive it.
// ---------------------------------------------------------------------
const TABS = [
    { id: "design", nav: "Design", icon: "🏮", label: "Design Hub" },
    { id: "tech", nav: "Tech", icon: "⚙️", label: "Technical Blueprint" },
    { id: "audio", nav: "Audio", icon: "🔊", label: "Acoustic Design" },
    { id: "production", nav: "Production", icon: "📅", label: "Production Roadmap" },
    { id: "qa", nav: "QA", icon: "🔬", label: "QA Test Suite" },
];
const homeState = reactive({ tab: "design" });

function scrollToDesignHub() {
    nextTick(() => {
        document.getElementById("design-hub")?.scrollIntoView({ behavior: "smooth" });
    });
}

// ---------------------------------------------------------------------
// Components
// ---------------------------------------------------------------------

const BlossomsCanvas = {
    template: "#tpl-blossoms-canvas",
    setup() {
        const canvas = ref(null);
        let ctx, width, height, raf;
        const petals = [];
        const NUM_PETALS = 40;

        function resize() {
            width = canvas.value.width = window.innerWidth;
            height = canvas.value.height = window.innerHeight;
        }

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
                if (this.y > height + 20 || this.x > width + 20 || this.x < -20) this.reset();
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

        function animate() {
            ctx.clearRect(0, 0, width, height);
            petals.forEach((p) => {
                p.update();
                p.draw();
            });
            raf = requestAnimationFrame(animate);
        }

        onMounted(() => {
            ctx = canvas.value.getContext("2d");
            resize();
            for (let i = 0; i < NUM_PETALS; i++) petals.push(new Petal());
            window.addEventListener("resize", resize);
            animate();
        });
        onUnmounted(() => {
            window.removeEventListener("resize", resize);
            if (raf) cancelAnimationFrame(raf);
        });

        return { canvas };
    },
};

const NavBar = {
    template: "#tpl-nav-bar",
    setup() {
        const route = useRoute();
        const router = useRouter();
        const isDocsActive = computed(() => route.path.startsWith("/docs"));
        function isHomeTabActive(id) {
            return route.path === "/" && homeState.tab === id;
        }
        function goToTab(id) {
            homeState.tab = id;
            if (route.path !== "/") {
                router.push("/").then(scrollToDesignHub);
            } else {
                scrollToDesignHub();
            }
        }
        return { tabs: TABS, homeState, isHomeTabActive, isDocsActive, goToTab };
    },
};

const SiteFooter = { template: "#tpl-site-footer" };

const DesignPanel = {
    template: "#tpl-design-panel",
    setup() {
        const GRID_SIZE = 12;
        const spawnPoints = [
            { row: 0, col: 0 },
            { row: 0, col: 11 },
            { row: 11, col: 0 },
        ];
        const keepPoint = { row: 5, col: 5 };
        const grid = reactive([]);
        const enemies = reactive([]);
        const tool = ref("wall");
        const gridEl = ref(null);
        const cellWidth = ref(36);
        let enemyId = 0;
        let simInterval = null;

        function isSpawn(r, c) {
            return spawnPoints.some((p) => p.row === r && p.col === c);
        }
        function isKeepCell(r, c) {
            return keepPoint.row === r && keepPoint.col === c;
        }
        function cellAt(r, c) {
            return grid[r * GRID_SIZE + c];
        }
        function neighbors(r, c) {
            const dirs = [
                [-1, 0], [1, 0], [0, -1], [0, 1],
                [-1, -1], [-1, 1], [1, -1], [1, 1],
            ];
            const res = [];
            dirs.forEach(([dr, dc]) => {
                const nr = r + dr, nc = c + dc;
                if (nr >= 0 && nr < GRID_SIZE && nc >= 0 && nc < GRID_SIZE) res.push(cellAt(nr, nc));
            });
            return res;
        }

        function buildGrid() {
            grid.length = 0;
            for (let r = 0; r < GRID_SIZE; r++) {
                for (let c = 0; c < GRID_SIZE; c++) {
                    let type = "clear";
                    if (isKeepCell(r, c)) type = "keep";
                    else if (isSpawn(r, c)) type = "spawn";
                    grid.push({
                        row: r, col: c, type,
                        cost: type === "wall" ? 99 : type === "swamp" ? 3 : 1,
                        distance: Infinity,
                        vector: { x: 0, y: 0 },
                        arrow: "",
                    });
                }
            }
        }

        function recalc() {
            grid.forEach((cell) => {
                cell.distance = Infinity;
                cell.vector = { x: 0, y: 0 };
                cell.arrow = "";
            });
            const start = cellAt(keepPoint.row, keepPoint.col);
            start.distance = 0;
            const queue = [start];
            while (queue.length) {
                const current = queue.shift();
                neighbors(current.row, current.col).forEach((n) => {
                    if (n.type === "wall") return;
                    const tentative = current.distance + n.cost;
                    if (tentative < n.distance) {
                        n.distance = tentative;
                        queue.push(n);
                    }
                });
            }
            const arrows = {
                "1,0": "→", "0,-1": "↑", "0,1": "↓", "-1,0": "←",
                "-1,-1": "↖", "1,-1": "↗", "-1,1": "↙", "1,1": "↘",
            };
            grid.forEach((cell) => {
                if (cell.type === "wall" || cell.type === "keep") return;
                let minDist = cell.distance, target = null;
                neighbors(cell.row, cell.col).forEach((n) => {
                    if (n.type !== "wall" && n.distance < minDist) {
                        minDist = n.distance;
                        target = n;
                    }
                });
                if (target) {
                    const dx = target.col - cell.col, dy = target.row - cell.row;
                    cell.vector = { x: dx, y: dy };
                    cell.arrow = arrows[dx + "," + dy] || "→";
                }
            });
        }

        function handleCellClick(cell) {
            if (cell.type === "keep" || cell.type === "spawn") return;
            if (tool.value === "wall") {
                cell.type = cell.type === "wall" ? "clear" : "wall";
                cell.cost = cell.type === "wall" ? 99 : 1;
            } else if (tool.value === "swamp") {
                cell.type = cell.type === "swamp" ? "clear" : "swamp";
                cell.cost = cell.type === "swamp" ? 3 : 1;
            } else {
                cell.type = "clear";
                cell.cost = 1;
            }
            recalc();
        }

        function cellClass(cell) {
            return {
                "cell-spawn": cell.type === "spawn",
                "cell-keep": cell.type === "keep",
                "cell-wall": cell.type === "wall",
                "cell-swamp": cell.type === "swamp",
            };
        }

        function resetGrid() {
            enemies.length = 0;
            if (simInterval) clearInterval(simInterval);
            buildGrid();
            recalc();
        }

        function tick() {
            if (!enemies.length) {
                clearInterval(simInterval);
                return;
            }
            for (let i = enemies.length - 1; i >= 0; i--) {
                const e = enemies[i];
                if (e.r === keepPoint.row && e.c === keepPoint.col) {
                    enemies.splice(i, 1);
                    continue;
                }
                const cell = cellAt(e.r, e.c);
                if (!cell || cell.type === "wall") {
                    enemies.splice(i, 1);
                    continue;
                }
                const nr = e.r + cell.vector.y, nc = e.c + cell.vector.x;
                if (nr >= 0 && nr < GRID_SIZE && nc >= 0 && nc < GRID_SIZE) {
                    e.r = nr;
                    e.c = nc;
                } else {
                    enemies.splice(i, 1);
                }
            }
        }

        function spawnEnemies() {
            if (simInterval) clearInterval(simInterval);
            spawnPoints.forEach((sp, idx) => {
                setTimeout(() => enemies.push({ id: enemyId++, r: sp.row, c: sp.col }), idx * 400);
                setTimeout(() => enemies.push({ id: enemyId++, r: sp.row, c: sp.col }), idx * 400 + 800);
            });
            simInterval = setInterval(tick, 150);
        }

        function updateCellWidth() {
            if (gridEl.value) cellWidth.value = gridEl.value.clientWidth / GRID_SIZE;
        }

        onMounted(() => {
            buildGrid();
            recalc();
            nextTick(updateCellWidth);
            window.addEventListener("resize", updateCellWidth);
        });
        onUnmounted(() => {
            if (simInterval) clearInterval(simInterval);
            window.removeEventListener("resize", updateCellWidth);
        });

        return { grid, enemies, tool, gridEl, cellWidth, handleCellClick, cellClass, spawnEnemies, resetGrid };
    },
};

const TechPanel = {
    template: "#tpl-tech-panel",
    setup() {
        const GA_SIZE = 8;
        const grid = reactive([]);
        const gen = ref(0);
        const bestFitness = ref(0);
        const avgFitness = ref(0);

        function cellAt(r, c) {
            return grid[r * GA_SIZE + c];
        }

        function buildGrid() {
            grid.length = 0;
            for (let r = 0; r < GA_SIZE; r++) {
                for (let c = 0; c < GA_SIZE; c++) {
                    let type = "clear";
                    if (r === 0 && c === 0) type = "spawn";
                    else if (r === GA_SIZE - 1 && c === GA_SIZE - 1) type = "keep";
                    grid.push({ row: r, col: c, type });
                }
            }
        }

        function reset() {
            gen.value = 0;
            bestFitness.value = 0;
            avgFitness.value = 0;
            grid.forEach((cell) => {
                if (cell.type !== "spawn" && cell.type !== "keep") cell.type = "clear";
            });
        }

        function setCells(coords, type) {
            coords.forEach(({ r, c }) => {
                const cell = cellAt(r, c);
                if (cell) cell.type = type;
            });
        }

        function runGeneration() {
            gen.value++;
            let targetBest, targetAvg;
            if (gen.value < 5) {
                targetBest = 16; targetAvg = 12.2;
            } else if (gen.value < 15) {
                targetBest = 20; targetAvg = 15.6;
            } else if (gen.value < 30) {
                targetBest = 24; targetAvg = 19.8;
            } else {
                targetBest = 28; targetAvg = 23.4;
            }
            bestFitness.value = targetBest;
            avgFitness.value = targetAvg + (Math.random() * 1.5 - 0.75);

            grid.forEach((cell) => {
                if (cell.type !== "spawn" && cell.type !== "keep") cell.type = "clear";
            });

            let wallCoords = [], pathCoords = [];
            if (gen.value < 5) {
                wallCoords = [{ r: 1, c: 2 }, { r: 2, c: 5 }, { r: 4, c: 1 }, { r: 5, c: 6 }, { r: 6, c: 3 }];
                pathCoords = [{ r: 0, c: 1 }, { r: 1, c: 1 }, { r: 2, c: 1 }, { r: 3, c: 1 }, { r: 3, c: 2 }, { r: 3, c: 3 }, { r: 3, c: 4 }, { r: 3, c: 5 }, { r: 4, c: 5 }, { r: 5, c: 5 }, { r: 6, c: 5 }, { r: 7, c: 5 }, { r: 7, c: 6 }];
            } else if (gen.value < 15) {
                wallCoords = [{ r: 1, c: 2 }, { r: 2, c: 2 }, { r: 3, c: 2 }, { r: 5, c: 5 }, { r: 6, c: 5 }, { r: 4, c: 5 }];
                pathCoords = [{ r: 0, c: 1 }, { r: 0, c: 2 }, { r: 0, c: 3 }, { r: 1, c: 3 }, { r: 2, c: 3 }, { r: 3, c: 3 }, { r: 4, c: 3 }, { r: 4, c: 4 }, { r: 4, c: 6 }, { r: 5, c: 6 }, { r: 6, c: 6 }, { r: 7, c: 6 }];
            } else if (gen.value < 30) {
                wallCoords = [{ r: 1, c: 0 }, { r: 1, c: 1 }, { r: 1, c: 2 }, { r: 1, c: 3 }, { r: 1, c: 4 }, { r: 1, c: 5 }, { r: 4, c: 2 }, { r: 4, c: 3 }, { r: 4, c: 4 }, { r: 4, c: 5 }, { r: 4, c: 6 }, { r: 4, c: 7 }];
                pathCoords = [{ r: 0, c: 1 }, { r: 0, c: 2 }, { r: 0, c: 3 }, { r: 0, c: 4 }, { r: 0, c: 5 }, { r: 0, c: 6 }, { r: 1, c: 6 }, { r: 2, c: 6 }, { r: 3, c: 6 }, { r: 3, c: 5 }, { r: 3, c: 4 }, { r: 3, c: 3 }, { r: 3, c: 2 }, { r: 3, c: 1 }, { r: 4, c: 1 }, { r: 5, c: 1 }, { r: 6, c: 1 }, { r: 7, c: 1 }, { r: 7, c: 2 }, { r: 7, c: 3 }, { r: 7, c: 4 }, { r: 7, c: 5 }, { r: 7, c: 6 }];
            } else {
                wallCoords = [{ r: 1, c: 0 }, { r: 1, c: 1 }, { r: 1, c: 2 }, { r: 1, c: 3 }, { r: 1, c: 4 }, { r: 1, c: 5 }, { r: 1, c: 6 }, { r: 4, c: 1 }, { r: 4, c: 2 }, { r: 4, c: 3 }, { r: 4, c: 4 }, { r: 4, c: 5 }, { r: 4, c: 6 }, { r: 4, c: 7 }, { r: 6, c: 0 }, { r: 6, c: 1 }];
                pathCoords = [{ r: 0, c: 1 }, { r: 0, c: 2 }, { r: 0, c: 3 }, { r: 0, c: 4 }, { r: 0, c: 5 }, { r: 0, c: 6 }, { r: 0, c: 7 }, { r: 1, c: 7 }, { r: 2, c: 7 }, { r: 3, c: 7 }, { r: 3, c: 6 }, { r: 3, c: 5 }, { r: 3, c: 4 }, { r: 3, c: 3 }, { r: 3, c: 2 }, { r: 3, c: 1 }, { r: 3, c: 0 }, { r: 4, c: 0 }, { r: 5, c: 0 }, { r: 5, c: 1 }, { r: 5, c: 2 }, { r: 5, c: 3 }, { r: 5, c: 4 }, { r: 5, c: 5 }, { r: 5, c: 6 }, { r: 6, c: 6 }, { r: 7, c: 6 }];
            }
            setCells(wallCoords, "wall");
            setCells(pathCoords, "path");
        }

        function gaCellClass(cell) {
            return {
                "ga-spawn": cell.type === "spawn",
                "ga-keep": cell.type === "keep",
                "ga-wall": cell.type === "wall",
                "ga-path": cell.type === "path",
            };
        }
        function gaCellIcon(cell) {
            if (cell.type === "spawn") return "⛩️";
            if (cell.type === "keep") return "🏰";
            if (cell.type === "path") return "🔸";
            return "";
        }

        onMounted(buildGrid);

        return { grid, gen, bestFitness, avgFitness, runGeneration, reset, gaCellClass, gaCellIcon };
    },
};

const AudioPanel = {
    template: "#tpl-audio-panel",
    setup() {
        const enemyCount = ref(2);
        const healthLoss = ref(0);
        const boss = ref(0);
        const waveHeights = reactive(Array.from({ length: 20 }, () => 8));
        let timeoutId = null, raf = null;

        const bossText = computed(() => (boss.value === 1 ? "Wokou Warlord" : boss.value === 2 ? "Pirate Fleet Admiral" : "None"));
        const bossMod = computed(() => (boss.value === 1 ? 0.15 : boss.value === 2 ? 0.4 : 0));
        const excitement = computed(() =>
            Math.min(1, Math.max(0, enemyCount.value * 0.008 + healthLoss.value * 0.003 + bossMod.value))
        );
        const state = computed(() =>
            excitement.value > 0.6 ? "Peak Siege Roar" : excitement.value > 0.25 ? "Night Defense" : "Day Preparation"
        );
        const desc = computed(() => {
            if (excitement.value > 0.6) return "Executing heavy, rapid Taiko drum rolls and sweeping battle vocal loops!";
            if (excitement.value > 0.25) return "Triggering light Taiko percussion tracks and dynamic Shamisen riffs.";
            return "Playing ambient forest wind, rustling bamboo, and soft Shakuhachi flute loops.";
        });
        const activeClass = computed(() => (excitement.value > 0.6 ? "active-warn" : excitement.value > 0.25 ? "active-gold" : ""));

        function animate() {
            const E = excitement.value;
            for (let i = 0; i < 20; i++) {
                const base = 5 + E * 40;
                const variance = Math.random() * (10 + E * 30);
                waveHeights[i] = Math.min(75, base + variance);
            }
            timeoutId = setTimeout(() => {
                raf = requestAnimationFrame(animate);
            }, 120);
        }

        onMounted(animate);
        onUnmounted(() => {
            if (raf) cancelAnimationFrame(raf);
            if (timeoutId) clearTimeout(timeoutId);
        });

        return { enemyCount, healthLoss, boss, bossText, excitement, state, desc, activeClass, waveHeights };
    },
};

const ProductionPanel = {
    template: "#tpl-production-panel",
    setup() {
        const sprints = {
            1: {
                title: "Sprint 1: Native Interface Parity",
                timeline: "Weeks 1-2 (Phase 1)",
                goals: [
                    "Synchronize active GameLoop states across Swift and Kotlin codebases.",
                    "Write JSON configuration loaders for static level layouts.",
                    "Verify Canvas and SpriteKit resolution resizing operations.",
                ],
                deps: "Base platform templates integration.",
            },
            2: {
                title: "Sprint 2: Rust Simulation Core & ECS",
                timeline: "Weeks 5-6 (Phase 2)",
                goals: [
                    "Build headless simulation engine using the Rust hecs ECS crate.",
                    "Expose simulation controls through UniFFI FFI bindings.",
                    "Write zero-copy binary state serializers using the rkyv format.",
                ],
                deps: "Completed FFI bindings mapping schemas.",
            },
            3: {
                title: "Sprint 3: Cooperative Netcode & Sockets",
                timeline: "Weeks 9-10 (Phase 3)",
                goals: [
                    "Establish UDP packet delivery and delta replication buffers.",
                    "Define latency-graduated matchmaking rules inside AWS GameLift FlexMatch.",
                    "Build automatic fallback protocols for Spot Instance expirations.",
                ],
                deps: "Completed Rust core binary serialization schemas.",
            },
            4: {
                title: "Sprint 4: ML PCG Systems & Personalization",
                timeline: "Weeks 13-14 (Phase 4)",
                goals: [
                    "Deploy offline PCGRL (PPO) map generators alongside WFC solvers.",
                    "Integrate Imitation-Adversarial difficulty modulators.",
                    "Wire Contextual Bandit (LinUCB) dynamic store pricing models.",
                ],
                deps: "Replicated game telemetry databases.",
            },
        };
        const selected = ref(1);
        const current = computed(() => sprints[selected.value]);
        return { sprints, selected, current };
    },
};

const QaPanel = {
    template: "#tpl-qa-panel",
    setup() {
        const ping = ref(50), loss = ref(0), jitter = ref(5);
        const drift = computed(() => ping.value * 0.05 + loss.value * 1.2 + jitter.value * 0.3);
        const desynced = computed(() => ping.value > 120 || loss.value > 2.0 || jitter.value > 15);
        const logs = computed(() =>
            desynced.value
                ? [
                      "[SYSTEM] Profiling diagnostics...",
                      `[WARNING] Net ping: ${ping.value}ms exceeds substepping threshold.`,
                      `[ERROR] Desync delta: ${drift.value.toFixed(1)} units. Snap client prediction position.`,
                  ]
                : [
                      "[SYSTEM] Profiling diagnostics...",
                      "[FFI] UniFFI byte transfer checks completed.",
                      `[SYSTEM] Delta packets: OK. Jitter: ${jitter.value}ms.`,
                  ]
        );
        return { ping, loss, jitter, drift, desynced, logs };
    },
};

const HomeView = {
    template: "#tpl-home-view",
    components: { DesignPanel, TechPanel, AudioPanel, ProductionPanel, QaPanel },
    setup() {
        const activePanel = computed(
            () =>
                ({
                    design: "DesignPanel",
                    tech: "TechPanel",
                    audio: "AudioPanel",
                    production: "ProductionPanel",
                    qa: "QaPanel",
                }[homeState.tab])
        );
        function goToTab(id) {
            homeState.tab = id;
            scrollToDesignHub();
        }
        const phases = [
            { title: "Phase 1: Native Parity & Setup", date: "Weeks 1-4", desc: "Synchronize game state kinds across Kotlin Android client and Swift iOS client. Integrate shared levels asset JSON reading schemas." },
            { title: "Phase 2: Rust Core Simulation Engine", date: "Weeks 5-8", desc: "Scaffold headless core simulation using hecs ECS. Establish UniFFI bindings and rkyv zero-copy serialization buffers." },
            { title: "Phase 3: Cooperative Netcode & AWS", date: "Weeks 9-12", desc: "Write UDP sockets replication channels. Establish latency-graduated matchmaking queues on AWS GameLift FlexMatch." },
            { title: "Phase 4: ML & Mathematical Optimizations", date: "Weeks 13-16", desc: "Deploy Genetic Algorithms for dynamic HQ layout generation, WFC PCG, and Contextual Bandits for storefront optimization." },
        ];
        return { tabs: TABS, homeState, activePanel, goToTab, phases };
    },
};

const DocsView = {
    template: "#tpl-docs-view",
    setup() {
        const route = useRoute();
        const router = useRouter();

        const slug = computed(() => {
            const s = route.params.slug;
            if (!s || (Array.isArray(s) && !s.length)) return "index";
            return Array.isArray(s) ? s.join("/") : s;
        });

        const content = ref("");
        const loading = ref(true);
        const error = ref(false);
        const headings = reactive([]);
        const query = ref("");
        const sidebarOpen = ref(false);
        const contentEl = ref(null);

        const filteredSections = computed(() => {
            if (!query.value.trim()) return docSections;
            const q = query.value.trim().toLowerCase();
            return docSections
                .map((section) => ({
                    title: section.title,
                    items: section.items.filter((i) => i.title.toLowerCase().includes(q)),
                }))
                .filter((section) => section.items.length);
        });

        const currentDoc = computed(() => findDoc(slug.value));
        const breadcrumb = computed(() =>
            currentDoc.value ? `${currentDoc.value.section} / ${currentDoc.value.title}` : slug.value
        );
        const editUrl = computed(() => `${REPO}/edit/main/docs/${slug.value}.md`);

        const docIndex = computed(() => flatDocs.findIndex((d) => d.slug === slug.value));
        const prevDoc = computed(() => (docIndex.value > 0 ? flatDocs[docIndex.value - 1] : null));
        const nextDoc = computed(() =>
            docIndex.value >= 0 && docIndex.value < flatDocs.length - 1 ? flatDocs[docIndex.value + 1] : null
        );

        function scrollToHeading(id) {
            document.getElementById(id)?.scrollIntoView({ behavior: "smooth", block: "start" });
        }

        async function enhanceContent() {
            const el = contentEl.value;
            if (!el) return;

            // Mermaid diagrams: marked emits <pre><code class="language-mermaid">;
            // mermaid.run() expects <pre class="mermaid"> (or .mermaid) nodes.
            const mermaidBlocks = el.querySelectorAll("pre > code.language-mermaid");
            mermaidBlocks.forEach((codeEl) => {
                const div = document.createElement("div");
                div.className = "mermaid";
                div.textContent = codeEl.textContent;
                codeEl.parentElement.replaceWith(div);
            });
            if (mermaidBlocks.length && window.mermaid) {
                try {
                    window.mermaid.initialize({ startOnLoad: false, theme: "dark" });
                    await window.mermaid.run({ querySelector: ".docs-content .mermaid" });
                } catch (e) {
                    console.error("mermaid render failed", e);
                }
            }

            // Heading anchors + "on this page" TOC (h2/h3 only).
            const used = new Set();
            const list = [];
            el.querySelectorAll("h2, h3").forEach((h) => {
                let id = slugify(h.textContent);
                const base = id || "section";
                let n = 1;
                while (used.has(id) || !id) id = `${base}-${n++}`;
                used.add(id);
                h.id = id;
                list.push({ id, text: h.textContent, level: h.tagName === "H2" ? 2 : 3 });
            });
            headings.splice(0, headings.length, ...list);

            // Math ($...$ / $$...$$) via KaTeX auto-render.
            if (window.renderMathInElement) {
                window.renderMathInElement(el, {
                    delimiters: [
                        { left: "$$", right: "$$", display: true },
                        { left: "$", right: "$", display: false },
                    ],
                    throwOnError: false,
                });
            }

            // Copy-to-clipboard on remaining code blocks.
            el.querySelectorAll("pre > code:not(.language-mermaid)").forEach((codeEl) => {
                const pre = codeEl.parentElement;
                if (pre.querySelector(".copy-btn")) return;
                pre.style.position = "relative";
                const btn = document.createElement("button");
                btn.type = "button";
                btn.className = "copy-btn";
                btn.textContent = "Copy";
                btn.addEventListener("click", () => {
                    navigator.clipboard.writeText(codeEl.textContent).then(() => {
                        btn.textContent = "Copied!";
                        setTimeout(() => (btn.textContent = "Copy"), 1500);
                    });
                });
                pre.appendChild(btn);
            });
        }

        async function load(newSlug) {
            loading.value = true;
            error.value = false;
            content.value = "";
            headings.splice(0, headings.length);
            try {
                const res = await fetch(`content/${newSlug}.md`);
                if (!res.ok) throw new Error("not found");
                const raw = await res.text();
                const html = marked.parse(raw, { mangle: false, headerIds: false });
                content.value = DOMPurify.sanitize(html, { ADD_ATTR: ["target"] });
            } catch (e) {
                error.value = true;
            } finally {
                loading.value = false;
            }
            // contentEl only exists once `loading` is false (it's behind
            // v-else) — enhancement has to wait for that DOM flip first.
            if (!error.value) {
                await nextTick();
                await enhanceContent();
            }
        }

        function onContentClick(e) {
            const a = e.target.closest("a");
            if (!a) return;
            const href = a.getAttribute("href");
            if (!href) return;

            if (href.startsWith("#")) {
                e.preventDefault();
                scrollToHeading(href.slice(1));
                return;
            }
            if (/^([a-z]+:)?\/\//i.test(href) || href.startsWith("mailto:")) return;

            const resolved = resolveHref(href, slug.value);
            if (resolved.type === "internal") {
                e.preventDefault();
                router.push("/docs/" + resolved.slug + (resolved.hash || ""));
            } else if (resolved.type === "blob") {
                e.preventDefault();
                window.open(`${REPO}/blob/main/${resolved.path}`, "_blank", "noopener");
            }
        }

        watch(slug, load, { immediate: true });

        return {
            slug, content, loading, error, headings, query, sidebarOpen, contentEl,
            filteredSections, breadcrumb, editUrl, prevDoc, nextDoc,
            scrollToHeading, onContentClick,
        };
    },
};

const NotFound = { template: "#tpl-not-found" };

const App = {
    template: "#tpl-app",
    components: { BlossomsCanvas, NavBar, SiteFooter },
};

// ---------------------------------------------------------------------
// Router + mount
// ---------------------------------------------------------------------
const router = createRouter({
    history: createWebHashHistory(),
    scrollBehavior(to, from) {
        if (to.path !== from.path) return { top: 0 };
    },
    routes: [
        { path: "/", name: "home", component: HomeView },
        { path: "/docs", redirect: "/docs/index" },
        { path: "/docs/:slug*", name: "docs", component: DocsView },
        { path: "/:pathMatch(.*)*", name: "not-found", component: NotFound },
    ],
});

createApp(App).use(router).mount("#app");
