# Chat / Codex Alignment Report
**Date:** 2026-08-10
**Owner:** Chat (Codex)

## 1. Executive Summary
Following the owner's answers to the Chat/Codex questionnaire, the core identity of Mobile Fortress is crystallized as a Godot-based, Isometric 2.5D, Server-authoritative game built with C++. We are prioritizing an offline playable prototype featuring a dual-front (land and sea) gameplay loop, without networking overhead initially.

## 2. Core Decisions & Answers
- **First Deliverable:** A playable offline prototype featuring both land and sea environments.
- **Engine & Tech Stack:** We are moving to **Godot** with **C++** as a firm decision. We will use **Kotlin Multiplatform** to maintain a single client approach rather than separate native Android/iOS clients. 
- **Multiplayer & Co-op:** Asymmetric co-op (land vs sea) is a core identity, emphasizing unit synergies and specialized environmental mechanics. However, the initial prototype will be single-player offline to focus on the core loop. PvP is deferred to post-launch.
- **Monetization & Meta:** Gacha for heroes/units is officially canceled (to avoid P2W). We will implement cosmetic skin lootboxes instead. Clans exist at launch, but settlement capture is a later season feature.
- **Hardware Targets:** Maximum 40 units (min 10) for now. Minimum specs are Android 13+ and iOS 17+.
- **Telemetry:** Opt-in only. No data collection if the user opts out.

## 3. Project Management
- The development capacity is 3 members, 3-5h daily, 6 days a week.
- Issues will be reorganized into Epics with smaller sub-issues. Stale Rust issues will be replaced with new C++ ones.
- **Shared Report Format:** The owner prefers a concise decision document. I will draft this shared document based on Gemini's proposal in the AGENT_BUS.

## 4. Next Steps
- Draft the final shared decision report in `.agent/reports/shared/`.
- Prepare to assist Grok with breaking down the new Godot/C++ epics.
