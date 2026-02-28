# Tasks: Cross-Platform Support (Intel x86-64 + Mac M-Series)

**Input**: Design documents from `/specs/001-cross-platform-support/`
**Prerequisites**: plan.md ✅ spec.md ✅ research.md ✅ data-model.md ✅ contracts/ ✅ quickstart.md ✅

**Tests**: Not requested in spec — no test tasks generated.

**Organization**: Tasks grouped by user story for independent implementation and delivery.

## Format: `[ID] [P?] [Story?] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3)
- Exact file paths included in every task description

## Path Conventions

- Game logic: `godot/autoloads/`, `godot/ui/`, `godot/` (GDScript)
- Orchestrator: `agents/orchestrator.ts`, `agents/harness/` (TypeScript / Bun)
- Config: `data/` (JSON files)
- Docs: `docs/` (Markdown)

---

## Phase 1: Setup

**Purpose**: Create config files and register the new autoload before any implementation begins.

- [ ] T001 Create `data/platform-config.json` with STANDARD and ENHANCED tier defaults per `specs/001-cross-platform-support/contracts/platform-config-schema.md` (fps_target, max_concurrent_agents, game_memory_ceiling_gb, agent_memory_ceiling_gb, renderer_hint, throttle_min_tick_ms, throttle_cpu_target for each tier)
- [ ] T002 [P] Create `data/agent-harness.json` with content `{"harness": "claude-code", "config": {}}` — this is the default harness selection file read by the orchestrator at startup
- [ ] T003 Update `godot/project.godot` autoloads section — add `HardwareProfile="*res://godot/autoloads/HardwareProfile.gd"` as the first entry, before ThrottleController, GameState, GenomeRegistry, and AgentBridge

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Implement `HardwareProfile.gd` — every user story depends on it.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [ ] T004 Create `godot/autoloads/HardwareProfile.gd` — define `PerformanceTier` enum (`STANDARD = 0`, `ENHANCED = 1`); declare all read-only exported properties: `os_name: String`, `cpu_architecture: String`, `logical_core_count: int`, `total_ram_bytes: int`, `gpu_name: String`, `performance_tier: PerformanceTier`, `game_memory_ceiling_bytes: int`, `agent_memory_ceiling_bytes: int`, `max_concurrent_agents: int`, `renderer_hint: String`; declare signals `low_memory_warning(free_bytes: int)`, `critical_memory_warning(free_bytes: int)`, `profile_ready(tier: int)`
- [ ] T005 Implement `HardwareProfile._ready()` in `godot/autoloads/HardwareProfile.gd` — populate properties by calling `OS.get_name()`, `Engine.get_architecture_name()`, `OS.get_processor_count()`, `OS.get_memory_info()["physical"]`, `RenderingServer.get_video_adapter_name()`; load `data/platform-config.json` via `FileAccess`; assign `STANDARD` tier if `total_ram_bytes < 24 * 1073741824` else `ENHANCED`; compute `game_memory_ceiling_bytes = min(int(total_ram_bytes * 0.25), int(tier_config.game_memory_ceiling_gb * 1073741824))`; compute `agent_memory_ceiling_bytes = min(int(total_ram_bytes * 0.125), int(tier_config.agent_memory_ceiling_gb * 1073741824))`; set `max_concurrent_agents` and `renderer_hint` from tier config; emit `profile_ready(performance_tier)` at end of `_ready()`
- [ ] T006 Implement `HardwareProfile.is_supported()` in `godot/autoloads/HardwareProfile.gd` — return `total_ram_bytes >= 16 * 1073741824`; call at top of `_ready()` before any other logic; if unsupported, call `OS.alert("Tower-Creep Symbiosis requires at least 16 GB of RAM.\n\nDetected: %d GB" % [total_ram_bytes / 1073741824], "Unsupported Hardware")` then `get_tree().quit(1)`
- [ ] T007 [P] Implement `HardwareProfile` utility methods in `godot/autoloads/HardwareProfile.gd` — `get_free_ram_bytes() -> int` returns `OS.get_memory_info()["free"]`; `get_memory_pressure() -> float` returns `clampf(1.0 - float(get_free_ram_bytes()) / float(total_ram_bytes), 0.0, 1.0)`; `override_tier(tier: PerformanceTier) -> void` sets `performance_tier = tier` and reloads tier-specific fields from the already-loaded platform config (must be safe to call before `profile_ready` emit)
- [ ] T008 Implement memory pressure polling in `godot/autoloads/HardwareProfile.gd` — in `_ready()`, add a `Timer` node with `wait_time = 0.5`; connect its `timeout` signal to `_on_memory_check()`; in `_on_memory_check()`, read `get_free_ram_bytes()`; emit `low_memory_warning(free)` if `free < 1073741824` (1 GB); emit `critical_memory_warning(free)` if `free < 536870912` (512 MB); print renderer hint guidance: `"[HardwareProfile] Tier: %s | Renderer hint: --rendering-driver %s"` to console

**Checkpoint**: `HardwareProfile` fully functional — all user stories can now begin in parallel.

---

## Phase 3: User Story 1 — Run Game on Intel 16GB (Priority: P1) 🎯 MVP

**Goal**: Game launches successfully on any ≥16 GB x86-64 system; agent concurrency
respects hardware limits; install is documented; harness is pluggable.

**Independent Test**: On an Ubuntu 22.04 x86-64 system with 16 GB RAM, run
`./tower-creep-symbiosis.x86_64 --headless --quit-after 5` — must exit 0 with
"HardwareProfile: Tier: STANDARD" printed. Then submit one behavior prompt in-game
and confirm agent completes within 30 s.

- [ ] T009 [P] [US1] Create `agents/harness/harness-interface.ts` — define and export TypeScript interface `AgentHarness` with methods `deploy(task: AgentTask): Promise<AgentResult>` and `isAvailable(): Promise<boolean>`; re-export `AgentTask` and `AgentResult` types from `agents/orchestrator.ts` (move type definitions here)
- [ ] T010 [P] [US1] Create `agents/harness/claude-code-harness.ts` — implement `AgentHarness` interface; move the `deployAgent()` function from `agents/orchestrator.ts` into this file as the `deploy()` method; implement `isAvailable()` by running `claude --version` via `Bun.spawn` and returning `exitCode === 0`
- [ ] T011 [US1] Update `agents/orchestrator.ts` — import `AgentHarness` from `agents/harness/harness-interface.ts`; add `loadHarness(): AgentHarness` function that reads `data/agent-harness.json`, checks `Bun.argv` for `--harness <name>` override, and returns the appropriate implementation (currently only `ClaudeCodeHarness`); call `isAvailable()` at startup and `console.warn` if false; replace direct `deployAgent()` call with `harness.deploy(task)` (depends on T009, T010)
- [ ] T012 [US1] Modify `godot/autoloads/AgentBridge.gd` — in `queue_task()`, replace any hardcoded concurrent agent limit with `HardwareProfile.max_concurrent_agents`; add guard: `if _pending_tasks.size() >= HardwareProfile.max_concurrent_agents: push_warning("Agent queue full for tier " + str(HardwareProfile.performance_tier)); return ""`; ensure `AgentBridge._ready()` awaits `HardwareProfile.profile_ready` signal before starting orchestrator process
- [ ] T013 [P] [US1] Create `docs/install-linux.md` — Ubuntu 22.04 setup guide: prerequisites (Godot 4.3 download from godotengine.org, Bun install via `curl -fsSL https://bun.sh/install | bash`, Claude Code CLI install via `npm install -g @anthropic/claude-code`, API key setup via `claude config`); game launch command; paste-ready verification commands from `specs/001-cross-platform-support/quickstart.md` Linux section
- [ ] T014 [P] [US1] Create `docs/install-windows-wsl.md` — Windows 11 + WSL2 setup guide: enable WSL2 (`wsl --install`), install Ubuntu 22.04 from Microsoft Store, clone repo inside WSL filesystem (not `/mnt/c/`), install Bun and Claude Code CLI inside WSL, download Godot Windows export and run natively, start WSL orchestrator separately; include troubleshooting from `specs/001-cross-platform-support/quickstart.md` Windows section

**Checkpoint**: US1 complete — game launches on 16 GB x86-64, respects concurrency limits, harness is swappable, install is documented for Linux and Windows/WSL2.

---

## Phase 4: User Story 2 — Acceptable Performance on Intel 16GB (Priority: P1)

**Goal**: Adaptive throttle reads platform-tier targets instead of M3 Pro Max constants;
responds to memory pressure signals within 2 seconds.

**Independent Test**: On a 16 GB Intel system under normal load, open a 10-minute gameplay
session; confirm average FPS ≥ 30 and Dashboard shows memory bar below ceiling throughout.

- [ ] T015 [US2] Modify `godot/autoloads/ThrottleController.gd` — remove hardcoded `TARGET_CPU_UTILIZATION := 0.70`, `TARGET_FRAME_TIME_MS := 14.0`, and `min_tick_duration_ms := 16.0` constants; replace with variables populated in `_ready()` after awaiting `HardwareProfile.profile_ready`: read `throttle_cpu_target` and `throttle_min_tick_ms` from the HardwareProfile's loaded platform config values (access via `HardwareProfile.performance_tier` to index into the same JSON loaded by HardwareProfile)
- [ ] T016 [US2] Replace `current_cpu_utilization` with `current_frame_stress` in `godot/autoloads/ThrottleController.gd` — rename the field; in `_adjust_throttle()`, set `current_frame_stress = Performance.get_monitor(Performance.TIME_PROCESS) / (target_frame_time_ms / 1000.0)` where `target_frame_time_ms = 1000.0 / HardwareProfile performance tier fps_target`; update `_compute_stress()` to use `current_frame_stress` in place of `current_cpu_utilization`; remove `current_memory_pressure` field (now sourced from `HardwareProfile.get_memory_pressure()`)
- [ ] T017 [US2] Subscribe `ThrottleController` to `HardwareProfile` memory signals in `godot/autoloads/ThrottleController.gd` — in `_ready()`, connect `HardwareProfile.low_memory_warning` to `_on_low_memory(free_bytes: int)`: set `work_budget_per_tick = max(5, work_budget_per_tick / 2)`; connect `HardwareProfile.critical_memory_warning` to `_on_critical_memory(free_bytes: int)`: set `work_budget_per_tick = 1` and emit `work_budget_changed(1)`

**Checkpoint**: US2 complete — throttle tier-aware, responds to memory pressure, no M3 Pro Max assumptions remain in ThrottleController.

---

## Phase 5: User Story 3 — Full Experience on Mac M-Series 16GB (Priority: P2)

**Goal**: Dashboard shows tier + live memory bar; all four agent CLAUDE.md files
confirmed architecture-neutral; renderer hint guidance visible at launch.

**Independent Test**: Launch on Mac M1 16 GB; Dashboard shows "ENHANCED" tier label
and memory bar; submit prompts for all four agent types; confirm all complete within session.

- [ ] T018 [P] [US3] Modify `godot/ui/Dashboard.tscn` — add a `Label` node named `TierLabel` (position: top-right HUD corner) with text populated from `"Tier: " + ("STANDARD" if HardwareProfile.performance_tier == HardwareProfile.PerformanceTier.STANDARD else "ENHANCED")`; add a `ProgressBar` node named `MemoryBar` with `max_value = HardwareProfile.game_memory_ceiling_bytes`; update value every 0.5 s using `OS.get_memory_info()["physical"] - OS.get_memory_info()["free"]` clamped to ceiling; add red tint when `HardwareProfile.get_memory_pressure() > 0.8`
- [ ] T019 [US3] Add renderer hint guidance print to `godot/autoloads/HardwareProfile.gd` `_ready()` — after computing `renderer_hint`, print: `"[HardwareProfile] Performance tier: %s | For best results on this hardware, launch with: --rendering-driver %s" % [PerformanceTier.keys()[performance_tier], renderer_hint]`; this guides players to apply the correct renderer without any in-game UI
- [ ] T020 [P] [US3] Audit all `agents/arsenal/*/CLAUDE.md` files (asset-gen, balance-tuner, behavior-synth, code-auditor) — remove any reference to Apple Neural Engine (ANE), MoltenVK, Metal, or Apple-specific hardware; replace model inference assumptions with "inference via Anthropic API (platform-agnostic, no local hardware dependency)"

**Checkpoint**: US3 complete — Dashboard shows tier and memory; all agents confirmed platform-neutral; Mac M1 16 GB fully supported.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Verification, cleanup, and balance math parity confirmation.

- [ ] T021 Run `specs/001-cross-platform-support/quickstart.md` acceptance checks on Ubuntu 22.04 — execute every verification command in the Linux section; confirm all pass criteria are met; record pass/fail results in `specs/001-cross-platform-support/test-results-linux.md`
- [ ] T022 [P] Run `specs/001-cross-platform-support/quickstart.md` acceptance checks on Mac M1 16 GB — verify SC-005 (≥60 FPS), SC-003 (≤8 GB), SC-006 (throttle response ≤2 s); record results in `specs/001-cross-platform-support/test-results-mac.md`
- [ ] T023 Create `scripts/balance-smoke.gd` — minimal headless GDScript that instantiates a mock `GameState` with fixed strategy_diversity=0.7, player_retention=0.6, asset_variety=0.5 inputs and prints `B(state) = 0.4 * 0.7 + 0.4 * 0.6 + 0.2 * 0.5`; run as `godot4 --headless -s scripts/balance-smoke.gd`; expected output: `B(state) = 0.62` — used for FR-010 cross-platform parity check
- [ ] T024 [P] Remove all hardcoded 36 GB / M3 Pro Max assumptions from `godot/autoloads/ThrottleController.gd` and `godot/autoloads/GenomeRegistry.gd` — search for numeric literals `36`, `0.60` (memory pressure target), and any comment referencing "M3" or "36GB"; replace with `HardwareProfile`-derived values or remove if now redundant

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately
- **Foundational (Phase 2)**: Depends on Phase 1 (T003 must register HardwareProfile before implementation)
- **US1 (Phase 3)**: Depends on Phase 2 completion — HardwareProfile.max_concurrent_agents must exist for T012
- **US2 (Phase 4)**: Depends on Phase 2 completion — ThrottleController reads HardwareProfile values
- **US3 (Phase 5)**: Depends on Phase 2 completion — Dashboard reads HardwareProfile; T019 extends HardwareProfile._ready()
- **Polish (Phase 6)**: Depends on all user story phases

### User Story Dependencies

- **US1 (P1)**: After Phase 2 only — independent of US2 and US3
- **US2 (P1)**: After Phase 2 only — T017 requires T008 (memory signals); T015/T016 require T005
- **US3 (P2)**: After Phase 2 only — T018 requires T004 (properties); T019 requires T005 (_ready exists)

### Within Each Phase

- T009, T010 must complete before T011 (harness interface before orchestrator update)
- T015 must complete before T016 (constants removed before frame_stress added — same file)
- T016 must complete before T017 (ThrottleController refactored before signals wired)
- T004 must complete before T005, T006, T007, T008 (properties must exist before methods)
- T005 must complete before T006 (is_supported called inside _ready)

### Parallel Opportunities

Within Phase 1: T002, T003 can run in parallel after T001.
Within Phase 2: T006 and T007 can run in parallel after T004; T008 after T005.
Within Phase 3: T009, T010, T013, T014 are fully parallel; T011 after T009+T010; T012 after T005.
Within Phase 5: T018, T020 are fully parallel; T019 requires T005.
Within Phase 6: T021 and T022 are parallel; T023 and T024 are parallel.

---

## Parallel Execution Examples

### Phase 3 (US1) — Maximum Parallelism

```bash
# Launch all parallel US1 tasks together:
Task: "Create agents/harness/harness-interface.ts [T009]"
Task: "Create agents/harness/claude-code-harness.ts [T010]"
Task: "Create docs/install-linux.md [T013]"
Task: "Create docs/install-windows-wsl.md [T014]"

# Then sequentially:
Task: "Update agents/orchestrator.ts [T011]"   # depends on T009, T010
Task: "Modify godot/autoloads/AgentBridge.gd [T012]"  # depends on T005
```

### Phase 4 (US2) — Sequential

```bash
# Must be sequential (same file):
Task: "Modify ThrottleController — replace constants [T015]"
Task: "Modify ThrottleController — replace cpu_utilization with frame_stress [T016]"
Task: "Modify ThrottleController — wire memory signals [T017]"
```

### Phase 5 (US3) — Parallel then Sequential

```bash
# Parallel:
Task: "Modify Dashboard.tscn — tier label + memory bar [T018]"
Task: "Audit agents/arsenal/*/CLAUDE.md [T020]"

# Sequential (adds to HardwareProfile._ready):
Task: "Add renderer hint print to HardwareProfile.gd [T019]"
```

---

## Implementation Strategy

### MVP (US1 Only — Phases 1–3)

1. Complete Phase 1: Setup (T001–T003)
2. Complete Phase 2: HardwareProfile (T004–T008)
3. Complete Phase 3: US1 (T009–T014)
4. **STOP and VALIDATE**: Run `docs/install-linux.md` from scratch on an Intel x86-64 system
5. Confirm: game launches, tier printed, agent completes one behavior prompt

### Incremental Delivery

1. Phases 1–2 → Foundation ready (no user-visible change yet)
2. Phase 3 (US1) → Game launches on Intel; harness pluggable; install documented
3. Phase 4 (US2) → Throttle tier-aware; ≥30 FPS on 16 GB Intel
4. Phase 5 (US3) → Dashboard shows tier; Mac M1 16 GB confirmed
5. Phase 6 → All platforms validated; balance parity confirmed; cleanup done

### Parallel Team Strategy

With two people:
- Person A: Phases 1–2 (foundational HardwareProfile)
- Once Phase 2 complete:
  - Person A: Phase 4 (ThrottleController) + Phase 6 cleanup
  - Person B: Phase 3 (harness abstraction + install docs) + Phase 5 (Dashboard + audit)

---

## Notes

- `[P]` tasks write to different files — safe to run in parallel
- `[Story]` label maps each task to its user story for traceability
- No test tasks generated — none requested in spec
- Stretch goal (FR-012: alternative harness implementations) is NOT in scope for this task list; a separate feature branch should be created for each harness (pydantic-harness, openai-harness, etc.)
- T011's `loadHarness()` function is intentionally minimal — it returns `ClaudeCodeHarness` only; the switch statement for future harnesses goes in when FR-012 is implemented
- Commit after each phase checkpoint to keep history clean
