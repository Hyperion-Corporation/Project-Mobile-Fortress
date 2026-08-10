# core/ — Mobile Fortress (Godot 4 Slice-0)

Playable **offline dual-front** prototype for Mobile Fortress.

| Path | Role |
| --- | --- |
| **`main.tscn` + `main.gd`** | **Primary playable** — isometric dual land/sea loop |
| `scenes/`, `scripts/` | Modular scene/script split (menu + battle) for next iteration |
| `assets/levels/` | Level JSON |
| `src/` | Historical shared-spec docs (pre-Godot) |

## Run

1. Install [Godot 4.3+](https://godotengine.org/download).
2. **Import / open this `core/` folder** as the project.
3. Press **F5** (main scene is `main.tscn`).

```text
Godot → Import → select core/project.godot → Run
```

## Controls

| Input | Action |
| --- | --- |
| **1–4** or top unit buttons | Garrison / Arquebus / Support / Commander |
| **Click** a diamond cell on **land or sea** | Place unit (build phase) |
| **Space** or START COMBAT | Begin raid |
| **E** | Hero active ability (cooldown) |
| **S** / **L** | Offline save / load (`user://mobile_fortress_slice0.json`) |

## Loop (Slice-0)

1. **Build** — place Ming/Portuguese units on both fronts.
2. **Combat** — raiders approach each front; hold **HQ**.
3. Outpost loss is **economic only** (income drops).
4. Survive ~45s with field clear → victory. Results also go to `user://last_run_results.json`.

## Next engineering steps

- Polish VS1 feel (waves from `assets/levels/slice0_dual_front.json`).
- Promote modular `scenes/battle` when structure helps.
- S0 spike: godot-cpp / C++ modules for sim (`docs/moon/roadmaps/shared_core.md`).
