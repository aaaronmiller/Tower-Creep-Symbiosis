# Implementation Plan: Cross-Platform Support (Intel x86-64 + Mac M-Series)

**Branch**: `001-cross-platform-support` | **Date**: 2026-02-28 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/001-cross-platform-support/spec.md`

## Summary

Extend Tower-Creep Symbiosis to run on 16 GB Intel 13th-gen systems (Linux primary,
Windows via WSL secondary) and on Mac M-series chips with 16 GB unified memory, in
addition to the existing 36 GB M3 Pro Max target. The approach introduces a
HardwareProfile autoload that detects available resources at startup, classifies hardware
into a PerformanceTier, and propagates per-tier memory budgets and concurrency limits to
the ThrottleController and AgentBridge. No new runtime dependencies are required; all
cross-platform APIs are already available in Godot 4.3 and Bun 1.x.

## Technical Context

**Language/Version**: GDScript 4.3 (game logic), TypeScript with Bun 1.x (agent orchestrator)
**Primary Dependencies**: Godot 4.3 engine (Vulkan Forward+ and Compatibility/OpenGL renderer),
Bun 1.x runtime, SQLite via bun:sqlite, Claude Code CLI
**Storage**: SQLite WAL (`data/genome.db`, `data/metrics.db`); `data/platform-config.json`
for per-tier defaults
**Testing**: Godot GUT (GDScript Unit Testing) framework; `bun test` for orchestrator;
manual integration smoke tests per platform per spec acceptance scenarios
**Target Platform**: Linux x86-64 (Ubuntu 22.04+ primary), Windows x86-64 via WSL
(secondary), macOS ARM64 (M1+)
**Project Type**: Desktop game with headless agentic sub-processes
**Performance Goals**: ≥60 FPS on M-series 16 GB; ≥30 FPS on Intel 16 GB 13th-gen
**Constraints**: Total memory ≤50% of system RAM; adaptive throttle reacts within 2 s;
no OS-specific GPU driver code in game logic
**Scale/Scope**: Single-player local game; 2–4 concurrent agent processes on Standard tier,
4–6 on Enhanced tier

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-checked after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Clean Code & Efficiency | ✅ PASS | HardwareProfile is one new autoload. No speculative abstractions. Tier dispatch is a simple match statement. |
| II. Performance Budget | ✅ PASS (with note) | 60 FPS target preserved for M-series. Intel 16 GB runs at a documented lower bound of 30 FPS minimum — this is an extended hardware tier, not a violation of the primary target. Noted in Complexity Tracking. |
| III. Agentic Safety | ✅ PASS | No changes to agent safety constraints. Concurrency is reduced on Standard tier; safety bounds remain unchanged. |
| IV. Self-Evolution Integrity | ✅ PASS | B(state) ≥ 0.6 enforced on all platforms. FR-010 explicitly prohibits architecture-specific numeric divergence in balance math. |
| V. GDScript-First | ✅ PASS | Hardware detection lives in GDScript. No new FFI or GDExtension introduced. Orchestrator TypeScript unchanged in language. |

## Project Structure

### Documentation (this feature)

```text
specs/001-cross-platform-support/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/
│   ├── hardware-profile-api.md   # HardwareProfile GDScript interface
│   └── platform-config-schema.md # JSON config contract
└── tasks.md             # Phase 2 output (/speckit.tasks command)
```

### Source Code (repository root)

```text
godot/
├── autoloads/
│   ├── HardwareProfile.gd        ← NEW: hardware detection, tier assignment, memory budgets
│   ├── ThrottleController.gd     ← MODIFY: read budgets from HardwareProfile; use
│   │                                        platform-agnostic frame-time stress proxy
│   └── AgentBridge.gd            ← MODIFY: cap concurrent agents from HardwareProfile.max_agents
├── ui/
│   └── Dashboard.tscn            ← MODIFY: display tier label + live memory bar
└── project.godot                 ← MODIFY: register HardwareProfile as first autoload

agents/
└── orchestrator.ts               ← MODIFY: read agent memory ceiling from platform-config.json

data/
└── platform-config.json          ← NEW: per-tier defaults (agent ceilings, renderer hint)

docs/
├── install-linux.md              ← NEW: Ubuntu 22.04 setup guide
└── install-windows-wsl.md        ← NEW: Windows WSL setup guide
```

**Structure Decision**: Existing single-project layout retained. All changes are additions
or modifications within the existing `godot/autoloads/`, `agents/`, `data/`, and `docs/`
directories. No new top-level directories introduced.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| 30 FPS minimum on Intel deviates from 60 FPS constitution target | Intel 16 GB iGPU cannot sustain 60 FPS at full simulation complexity | Requiring 60 FPS would exclude all Intel iGPU hardware from the supported platform list, defeating the feature goal |
