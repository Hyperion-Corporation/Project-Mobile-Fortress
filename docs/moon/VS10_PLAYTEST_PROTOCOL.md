# VS10 — Collaborator Playtest Protocol & "Shows Promise" Record

**Status:** 📋 Ready — awaiting sessions  
**Gate:** Slice-0 Phase 1a exit (see [`roadmaps/vertical_slice.md`](roadmaps/vertical_slice.md) VS10)  
**Owner:** Owner / collaborators (3 humans)  
**Session target:** ≥ 2 independent collaborator playtests, both reaching the decision "shows promise"  
**Decision doc:** this file, filled in below §Session Log

---

## How to run a session

### 1 — Environment setup (5 min)

```bash
# Build the native sim extension (if not already built)
cd game && cmake -B build -DCMAKE_BUILD_TYPE=Release && cmake --build build -j$(nproc)
cp build/libmobile_fortress_core.so bin/libmobile_fortress_core.linux.template_debug.x86_64.so

# Open the project in Godot 4.7+
godot --path game/
# Press Play (F5) — default scene: scenes/main_menu.tscn
```

> iOS testers: see `docs/moon/roadmaps/ios.md` — requires a macOS host or CI build.  
> Android testers: install the debug APK from `game/exports/android/MobileFortress-debug.apk`
> (run `bash game/scripts/export_mobile_smoke.sh --export-android` to rebuild if stale).

### 2 — Mandatory acceptance checks (VS-A1 – VS-A11)

Complete this table during or immediately after your session. All **Hard** criteria must be ✅ before recording a "shows promise" verdict.

| ID | Criterion | Hard/Scope | Result | Notes |
| --- | --- | --- | --- | --- |
| VS-A1 | One complete session with **both land AND sea** fronts active | Hard | ☐ ✅ / ☐ ❌ | |
| VS-A2 | Ming + Portuguese as the only playable civ pair | Hard | ☐ ✅ / ☐ ❌ | |
| VS-A3 | Isometric 2.5D presentation; **ukiyo-e-readable art** (not pure greyboxes) | Hard | ☐ ✅ / ☐ ❌ | See art checklist §3 |
| VS-A4 | Build/position/upgrade phase + combat/resource phase functional | Hard | ☐ ✅ / ☐ ❌ | |
| VS-A5 | HQ primary lose condition; outpost loss is **economic only** | Hard | ☐ ✅ / ☐ ❌ | |
| VS-A6 | ≥1 hero (grid place, aura, active CD, reposition travel) | Hard | ☐ ✅ / ☐ ❌ | Qi + E pulse |
| VS-A7 | ≥1 cross-front support unit with a meaningful trade-off | Hard | ☐ ✅ / ☐ ❌ | Signal Battery |
| VS-A8 | 10–40 simultaneous units at **30+ FPS** on target device | Hard | ☐ ✅ / ☐ ❌ | See perf notes |
| VS-A9 | Offline play + local campaign state persistence (run history) | Hard | ☐ ✅ / ☐ ❌ | |
| VS-A10 | Single player controlling both fronts; shared camera/perspective | Hard | ☐ ✅ / ☐ ❌ | |
| VS-A11 | No networked co-op, PvP, live services, or gameplay gacha required | Scope | ☐ ✅ / ☐ N/A | Out-of-scope check |

### 3 — Art & UX acceptance checklist (VS-A3 detail)

**Ukiyo-e-readable** means: colour palette is legible at a glance, unit silhouettes read clearly on the isometric tile grid, and the aesthetic is coherent (not pure programmer art). This is a qualitative gate, not a pixel count.

| Check | Result | Notes |
| --- | --- | --- |
| Main menu colour palette (paper/indigo/cinnabar bands) is readable and era-appropriate | ☐ ✅ / ☐ ❌ | |
| Wōkòu subtitle and "Defend the Coast" label are legible at default resolution | ☐ ✅ / ☐ ❌ | |
| Isometric tile grid is visually distinct between land front and sea front | ☐ ✅ / ☐ ❌ | |
| Defender units (towers / gunners) are distinguishable from raider units at a glance | ☐ ✅ / ☐ ❌ | |
| HQ and Outpost structures read clearly as key targets (size / colour treatment) | ☐ ✅ / ☐ ❌ | |
| HUD strip (HQ HP bar, Resource/Trading OP HP, dual currency, wave/phase) is legible mid-combat | ☐ ✅ / ☐ ❌ | |
| Pause overlay (Resume / Save / Menu) is readable and does not obscure critical state | ☐ ✅ / ☐ ❌ | |
| Hero commander (Commander Qi) is visually distinct from generic defenders | ☐ ✅ / ☐ ❌ | |
| Cross-front support unit (Signal Battery) is visually distinct from land defenders | ☐ ✅ / ☐ ❌ | |
| Overall impression: era-coherent; not pure greybox; playtest-presentable | ☐ ✅ / ☐ ❌ | |

**Art/UX issues to log** (flag here; fix in post-VS10 G2 polish, not a blocker unless VS-A3 fails outright):

| Issue | Severity (cosmetic / functional) | Suggested fix |
| --- | --- | --- |
| | | |

### 4 — Qualitative feedback prompts

Answer briefly; one sentence per item is fine.

1. **Core loop clarity:** Could you intuitively tell what to build and where without instructions?
2. **Dual-front tension:** Did managing both land and sea feel interesting, or overwhelming?
3. **Hero impact:** Did Commander Qi's aura and pulse feel meaningful?
4. **Economy legibility:** Could you tell which outpost funded which front?
5. **Moment of failure:** When the HQ was hit or destroyed, did the cause feel fair and readable?
6. **Memorable moment:** Was there any moment that felt genuinely fun or surprising?
7. **Overall verdict:** Does this prototype "show promise" as a cooperative tower-defense concept? (Yes / Needs work / No)

### 5 — Performance notes

Record device + FPS if possible. Target: **30+ FPS with ≥10 units on screen**.

| Device | OS | FPS (est) | Unit count at worst frame | Notes |
| --- | --- | --- | --- | --- |
| | | | | |

---

## §Session Log

Fill in one block per playtest session. Minimum 2 sessions (owner + ≥1 collaborator) required for the gate.

### Session 1

- **Date:** ___________
- **Tester:** ___________
- **Device/platform:** ___________
- **Build:** commit ___________
- **VS-A checks:** all Hard ✅ / failures: ___________
- **Art/UX checks:** all ✅ / failures: ___________
- **Qualitative answers:** (attach or paste below)
- **Overall verdict:** Shows promise ☐ / Needs work ☐ / No ☐

---

### Session 2

- **Date:** ___________
- **Tester:** ___________
- **Device/platform:** ___________
- **Build:** commit ___________
- **VS-A checks:** all Hard ✅ / failures: ___________
- **Art/UX checks:** all ✅ / failures: ___________
- **Qualitative answers:** (attach or paste below)
- **Overall verdict:** Shows promise ☐ / Needs work ☐ / No ☐

---

## §Gate decision

| | |
| --- | --- |
| **Sessions completed:** | __ / 2 |
| **All Hard VS-A criteria met:** | ☐ Yes / ☐ No (list failures) |
| **All Art/UX checks met:** | ☐ Yes / ☐ No (list failures) |
| **Both testers verdict:** | ☐ "Shows promise" / ☐ one or more "Needs work" |
| **Decision:** | ✅ **PHASE 1a COMPLETE — proceed to G3+ polish** / ☐ More work needed — see issues below |
| **Signed by owner:** | ___________ |
| **Date:** | ___________ |

---

## §Post-gate board hygiene (to complete when decision = ✅)

Close or update these issues once VS10 decision is recorded:

| Issue | Action |
| --- | --- |
| #9 G2 dual-front loop | Close with link to this decision record |
| #128 Slice-0 epic | Re-open or create #134 for Phase 1 polish track |
| #129 Godot+C++ epic | Update status comment — S0–S5 done, G3 flow field next |
| GitHub project board | Move VS0–VS10 cards to Done; open G3/S2/U3/U8 cards as Phase 1 work |

---

## §Known polish items for Phase 1 (do not fix before VS10; log for after)

These are **not blockers** for the gate — document them here so the post-gate sprint has a clear backlog:

| Item | Roadmap ref | Priority |
| --- | --- | --- |
| Flow Field depth (BFS lanes → real flow field) | G3 / S2 | High |
| G8 score/progression wiring (`Progression.record_run` in `GameSession.end_run`) | G8 / T17 | High (T17 in progress) |
| Settings screen (audio, controls, telemetry consent) | U3 | Medium |
| Accessibility pass (large touch targets, screen reader) | U8 | Medium |
| Hero expand: additional heroes, commander pool | G4+ | Low |
| Coastal territory meta-map skeleton | G9 | Deferred |
