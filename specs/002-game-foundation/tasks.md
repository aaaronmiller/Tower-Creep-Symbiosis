# Tasks: Game Foundation — Playable Core to Self-Evolving System

**Input**: Design documents from `/specs/002-game-foundation/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/
**Tests**: INCLUDED — spec mandates TDD (GUT tests written before/alongside implementation; `bun test` for TypeScript)
**Organization**: Tasks grouped by user story for independent implementation and testing

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1–US5)
- All file paths are relative to repository root

---

## Phase 1: Setup (Project Scaffold)

**Purpose**: `godot4 project.godot` opens without errors. All autoloads initialize. GUT runs headlessly.

- [ ] T001 Create `project.godot` with Godot 4.3 config, autoload registrations (GameState, GenomeRegistry, ThrottleController, AgentBridge), physics layer assignments (world=1, creeps=2, towers=3, projectiles=4, tower_range=5), and main scene set to `res://godot/main.tscn`
- [ ] T002 [P] Create `godot/main.tscn` (entry scene with Node2D root) and `godot/main.gd` (scene switcher, startup sequence, loads Arena.tscn)
- [ ] T003 [P] Vendor GUT v9.6+ plugin into `addons/gut/` from GitHub release (MIT license)
- [ ] T004 [P] Vendor godot-sqlite (gdsqlite) GDExtension plugin into `addons/gdsqlite/` with Linux x86-64 binary (MIT license)
- [ ] T005 [P] Create `data/schema.sql` with full SQLite schema for `genome.db` (genes, gene_lineage, execution_log tables with indexes) and `metrics.db` (balance_metrics, mutation_log, performance_metrics tables with indexes) per data-model.md
- [ ] T006 Create `godot/autoloads/GameState.gd` — singleton with `player_cycles: int`, `lives: int`, `gold: int`, `wave_number: int`, `state_changed` signal, `spawn_creep_with_behavior(gene_id)` stub, default values from PRD
- [ ] T007 [P] Create `godot/autoloads/GenomeRegistry.gd` — STUB with in-memory `_loaded_genes: Dictionary`, `register_gene()`, `execute_gene()`, `methylate_gene()` returning placeholder values (SQLite deferred to US2)
- [ ] T008 [P] Create `godot/autoloads/ThrottleController.gd` — full PID controller per PRD §4.1 with `TARGET_CPU_UTILIZATION`, `TARGET_FRAME_TIME_MS`, `TARGET_MEMORY_PRESSURE` constants, `tick_duration_changed` and `work_budget_changed` signals
- [ ] T009 [P] Create `godot/autoloads/AgentBridge.gd` — STUB with `queue_task()` returning `""`, `is_available()` returning `false`, `synthesize_behavior()` returning `""`, signals declared but never emitted
- [ ] T010 Create `godot/tests/unit/test_gamestate.gd` — GUT tests: starting lives == config value, `player_cycles` decrements on deduct, `state_changed` fires on territory claim, gold increments correctly

**Checkpoint**: `godot4 --headless --path . --import --quit` succeeds. `GODOT_DISABLE_LEAK_CHECKS=1 godot4 --headless --display-driver headless --audio-driver Dummy --disable-render-loop -s res://addons/gut/gut_cmdln.gd -gdir=res://godot/tests -ginclude_subdirs -gexit` exits 0. Game window opens to grey screen.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Directory structure, base classes, and path system that ALL user stories depend on

**CRITICAL**: No user story work can begin until this phase is complete

- [ ] T011 Create directory structure: `godot/entities/`, `godot/scenes/`, `godot/systems/`, `godot/ui/`, `godot/genes/behaviors/`, `godot/genes/effects/`, `godot/tests/unit/genome/`, `godot/tests/unit/evolution/`, `agents/harness/`, `agents/arsenal/behavior-synth/`, `agents/arsenal/balance-tuner/`, `agents/arsenal/code-auditor/`, `agents/arsenal/asset-gen/`, `data/assets/sprites/towers/`, `data/assets/sprites/creeps/`, `data/assets/invalid/`, `scripts/`, `tests/agents/`
- [ ] T012 Create `godot/systems/PathFollower.gd` — waypoint traversal logic: `advance(entity: Node2D, delta: float)`, `get_next_direction(entity: Node2D) -> Vector2`, `path_completed` signal; operates on Path2D children

**Checkpoint**: Foundation ready — all directories exist, PathFollower available for entity use

---

## Phase 3: User Story 1 — Playable Core Loop (Priority: P1) MVP

**Goal**: Complete wave-based tower defense: creeps spawn → follow path → towers shoot → creeps die or drain lives → wave-complete/game-over. All primitive shapes (ColorRect/polygon).

**Independent Test**: `godot4 --headless -s addons/gut/gut_cmdln.gd` — all GUT tests pass. Then `godot4 project.godot` and complete one full wave.

### Tests for User Story 1

- [ ] T013 [P] [US1] Create `godot/tests/unit/test_creep.gd` — GUT tests: `take_damage(50)` on 100HP creep → health=50; `take_damage(100)` emits `died` and calls `queue_free()`; path completion decrements `GameState.lives`
- [ ] T014 [P] [US1] Create `godot/tests/unit/test_tower.gd` — GUT tests: `_find_target()` returns Creep in range Area2D; `_fire_at_target()` adds Projectile child to parent scene; fire cooldown prevents rapid fire
- [ ] T015 [P] [US1] Create `godot/tests/unit/test_projectile.gd` — GUT tests: Projectile moves toward target; calls `take_damage()` on `body_entered`; `queue_free()` after hit
- [ ] T016 [P] [US1] Create `godot/tests/unit/test_wave_manager.gd` — GUT tests: wave config with count=3 spawns 3 Creeps; killing all 3 emits `wave_complete`; spawn interval timing

### Implementation for User Story 1

- [ ] T017 [US1] Create `godot/scenes/Arena.tscn` — 2D scene with Path2D (5+ PathPoint children for creep route), 3 Marker2D nodes in group `"tower_slots"`, Marker2D in group `"player_spawn"` at path start, Marker2D in group `"path_exit"` at path end
- [ ] T018 [P] [US1] Create `godot/entities/Creep.tscn` and `godot/entities/Creep.gd` — CharacterBody2D + ColorRect + CollisionShape2D (layer 2); `_ready()` sets `health = max_health` and calls `_load_behavior()`; `_physics_process()` calls `PathFollower.advance(self, delta)`; `take_damage(amount, source)` decrements health, emits `died` on ≤0, awards gold, `queue_free()`; path completion → `GameState.lives -= 1`, `queue_free()`
- [ ] T019 [P] [US1] Create `godot/entities/Tower.tscn` and `godot/entities/Tower.gd` — StaticBody2D + ColorRect + Area2D range sensor (layer 5, mask=creeps layer 2); `_process(delta)` decrements `_fire_cooldown`, calls `_find_target()` via `$RangeArea.get_overlapping_bodies()` sorted by distance; `_fire_at_target()` instantiates Projectile.tscn with `target`, `damage`, `attributes`
- [ ] T020 [P] [US1] Create `godot/entities/Projectile.tscn` and `godot/entities/Projectile.gd` — Area2D + ColorRect (layer 4, mask=creeps layer 2); moves toward `target.global_position` at `speed` each physics frame; on `body_entered` calls `target.take_damage(damage, self)`, `queue_free()`
- [ ] T021 [US1] Create `godot/systems/WaveManager.gd` — `wave_config: Array[Dictionary]` with entries `{count, health, speed, gene_id, gold_reward, spawn_interval}`; `start_wave(wave_number)` spawns creeps with Timer delay; listens to Creep `died` and life-loss signals; emits `wave_complete` when all creeps gone
- [ ] T022 [US1] Create `godot/ui/HUD.tscn` and `godot/ui/HUD.gd` — CanvasLayer with Labels for lives, gold, wave number; game-over overlay when lives reach 0; updates on `GameState.state_changed`
- [ ] T023 [US1] Wire Arena.tscn into `godot/main.gd` — main scene loads Arena, instantiates WaveManager, connects HUD, starts wave 1 on scene ready

**Checkpoint**: Manual play — complete one wave, reach wave complete or game over. All Phase 3 GUT tests pass headlessly.

---

## Phase 4: User Story 2 — Gene Behavior System (Priority: P1)

**Goal**: GenomeRegistry fully operational with SQLite WAL. BehaviorBase interface enforced. Default + example behavior genes registered and executing. Effect genes apply modifiers.

**Independent Test**: `godot4 --headless -s addons/gut/gut_cmdln.gd --gut-dir godot/tests/unit/genome` — all genome tests pass. In running game, FlankBehavior creep takes different route than WalkPathBehavior.

### Tests for User Story 2

- [ ] T024 [P] [US2] Create `godot/tests/unit/genome/test_genome_registry.gd` — GUT tests: register → gene in `_loaded_genes`; execute → `_evaluate()` called; 20 errors → auto-methylate; methylated gene not in loaded; gene pruning after 50 cycles; SQLite schema recreation on missing DB
- [ ] T025 [P] [US2] Create `godot/tests/unit/genome/test_behavior_base.gd` — GUT tests: WalkPathBehavior and FlankBehavior both return dict with `"move_direction"` key; BehaviorBase._evaluate() pushes error; initialize() is idempotent
- [ ] T026 [P] [US2] Create `godot/tests/unit/genome/test_effects.gd` — GUT tests: each effect gene (Freeze, Bleed, Chain, Poison, Stun, Drain) modifies correct Tower stat when applied

### Implementation for User Story 2

- [ ] T027 [US2] Create `godot/genes/behaviors/BehaviorBase.gd` — `class_name BehaviorBase extends Resource`; `_evaluate(context: Dictionary) -> Dictionary` with push_error stub; `initialize(params: Dictionary) -> void` no-op; `get_display_name() -> String`; `get_description() -> String` per behavior-base-api.md contract
- [ ] T028 [P] [US2] Create `godot/genes/behaviors/WalkPathBehavior.gd` — extends BehaviorBase; `_evaluate()` returns `{"move_direction": PathFollower.get_next_direction(entity)}`
- [ ] T029 [P] [US2] Create `godot/genes/behaviors/FlankBehavior.gd` — extends BehaviorBase; `_evaluate()` returns move_direction biased away from nearest tower's range zone
- [ ] T030 [P] [US2] Create `godot/genes/effects/FreezeEffect.gd` — extends BehaviorBase; slows tower fire rate on contact
- [ ] T031 [P] [US2] Create `godot/genes/effects/BleedEffect.gd` — extends BehaviorBase; applies DoT to towers
- [ ] T032 [P] [US2] Create `godot/genes/effects/ChainEffect.gd` — extends BehaviorBase; damage chains to adjacent towers
- [ ] T033 [P] [US2] Create `godot/genes/effects/PoisonEffect.gd` — extends BehaviorBase; progressive tower damage
- [ ] T034 [P] [US2] Create `godot/genes/effects/StunEffect.gd` — extends BehaviorBase; disables tower briefly
- [ ] T035 [P] [US2] Create `godot/genes/effects/DrainEffect.gd` — extends BehaviorBase; converts tower damage to creep HP
- [ ] T036 [US2] Replace `godot/autoloads/GenomeRegistry.gd` stub with full SQLite WAL implementation per PRD §5.2 — opens `user://genome.db` in WAL mode; reads schema from `res://data/schema.sql`; `register_gene()`, `execute_gene()`, `methylate_gene()`, `prune_gene()`; `_on_memory_check()` auto-methylation after 20 failures; `get_strategy_diversity()`, `get_gene_error_rates()` balance metric accessors; recreates schema if DB missing/corrupt
- [ ] T037 [US2] Create `scripts/validate-gene.sh` — per gene-validate-contract.md: file exists check, size ≤ 50KB, `gdlint` syntax/lint, `extends BehaviorBase` check, `func _evaluate(context` check, forbidden patterns (FileAccess, HTTPRequest, OS.execute, TCPServer, StreamPeer, while true:), loop bounds heuristic warning; exit 0=valid, 1=invalid with ERROR/WARNING to stderr
- [ ] T038 [US2] Modify `godot/entities/Creep.gd` — integrate gene execution: `_load_behavior()` loads BehaviorBase from GenomeRegistry by `behavior_gene_id`; `_physics_process()` calls `GenomeRegistry.execute_gene(behavior_gene_id, context)` and applies returned `move_direction`

**Checkpoint**: All Phase 4 GUT tests pass. `bash scripts/validate-gene.sh godot/genes/behaviors/FlankBehavior.gd` exits 0. FlankBehavior creep takes different route in-game.

---

## Phase 5: User Story 3 — Natural Language Behavior Synthesis (Priority: P2)

**Goal**: Player types behavior description in PromptEditor → orchestrator synthesizes gene → validate-gene.sh gates it → creep spawns with behavior. Graceful degrade when offline.

**Independent Test**: With `bun run agents/orchestrator.ts` running + API key, submit "fast creep that targets weakest tower" → new creep spawns within 30s. Kill orchestrator → game continues, amber message shown.

### Tests for User Story 3

- [ ] T039 [P] [US3] Create `tests/agents/orchestrator.test.ts` — bun tests: mock harness resolves immediately; assert priority ordering; graceful shutdown on SIGTERM; max concurrency 4
- [ ] T040 [P] [US3] Create `tests/agents/harness.test.ts` — bun tests: mock `Bun.spawn` exit 0 for `isAvailable()`; assert `deploy()` passes prompt to claude CLI with `-p` flag
- [ ] T041 [P] [US3] Create `godot/tests/unit/test_agent_bridge.gd` — GUT tests: 5th task rejected when max=4; `_orchestrator_available=false` causes `synthesize_behavior()` to return `""` without spawning subprocess; task timeout after 60s

### Implementation for User Story 3

- [ ] T042 [P] [US3] Create `agents/harness/harness-interface.ts` — `AgentHarness` interface with `deploy(task: AgentTask): Promise<AgentResult>` and `isAvailable(): Promise<boolean>`; `AgentTask`, `AgentResult`, `AgentType` type exports per plan.md
- [ ] T043 [US3] Create `agents/harness/claude-code-harness.ts` — implements `AgentHarness`; `isAvailable()` runs `claude --version`; `deploy()` spawns `claude -p "$prompt" --output-format json --no-user-prompt` via `Bun.spawn`, parses JSON result
- [ ] T044 [US3] Create `agents/orchestrator.ts` — Bun CIO scheduler per PRD §3.2; priority queue; reads `data/agent-harness.json`; polls AgentBridge result file for task acknowledgement; max concurrency 4; graceful shutdown on SIGTERM
- [ ] T045 [P] [US3] Create `data/agent-harness.json` — `{"harness": "claude-code", "config": {}}`
- [ ] T046 [P] [US3] Create `agents/arsenal/behavior-synth/CLAUDE.md` — behavior synthesizer persona per PRD §3.1; output constraint: ONLY GDScript code block extending BehaviorBase, no prose
- [ ] T047 [P] [US3] Create `agents/arsenal/behavior-synth/.claude/mcp.json` — MCP tool config (filesystem only)
- [ ] T048 [P] [US3] Create `agents/arsenal/balance-tuner/CLAUDE.md` and `agents/arsenal/balance-tuner/.claude/mcp.json` — balance optimizer persona
- [ ] T049 [P] [US3] Create `agents/arsenal/code-auditor/CLAUDE.md` and `agents/arsenal/code-auditor/.claude/mcp.json` — gene pruning persona
- [ ] T050 [P] [US3] Create `agents/arsenal/asset-gen/CLAUDE.md` and `agents/arsenal/asset-gen/.claude/mcp.json` — asset generator persona stub (full activation in US4)
- [ ] T051 [US3] Replace `godot/autoloads/AgentBridge.gd` stub with full IPC implementation per agent-bridge-api.md — `_task_queue: Array[Dictionary]` max size 4; `queue_task(type, prompt, priority) -> String` returns task_id or ""; lazy-spawns `bun run agents/orchestrator.ts`; polls `user://agent-results/<task_id>.json` every 250ms; emits `agent_result_received`, `orchestrator_started`, `orchestrator_died`, `queue_full` signals; graceful degrade protocol; 60s task timeout
- [ ] T052 [US3] Create `godot/ui/PromptEditor.tscn` and `godot/ui/PromptEditor.gd` — TextEdit + Preview + CostLabel + SubmitButton; debounced preview; cycle cost check against `GameState.player_cycles`; calls `AgentBridge.synthesize_behavior()`; shows "Synthesizing..." while pending; green message on success; amber "Agent offline" on degrade; red "Synthesis failed" on validation failure; rejects second submit while first pending; refunds cycles on failure
- [ ] T053 [US3] Create `scripts/deploy-agent.sh` — CIO pattern launcher per PRD §9.3; accepts agent type and prompt; invokes `claude -p` with persona CLAUDE.md injected
- [ ] T054 [US3] Create `godot/ui/Dashboard.tscn` and `godot/ui/Dashboard.gd` — STUB: basic layout with FPSLabel, MemoryBar (ProgressBar), BalanceLabel, GenePoolLabel, WaveLabel; placeholder values (full wiring in Phase 8)

**Checkpoint**: `bun test` exits 0. Submit "fast creep" in-game → new creep spawns within 30s (with API key). Kill orchestrator → game continues, amber PromptEditor message. All Phase 5 GUT tests pass.

---

## Phase 6: User Story 4 — MadLibs & Procedural Sprites (Priority: P2)

**Goal**: Every entity has a deterministic visual/mechanical identity via MadlibsMixer. asset-gen agent produces starter sprite set. Game swaps ColorRects for sprites when files exist.

**Independent Test**: `MadlibsMixer.mix(42)` always returns same AttributeDescriptor. `bash scripts/generate-sprites.sh` produces ≥36 tower + ≥36 creep PNGs in `data/assets/sprites/`.

### Tests for User Story 4

- [ ] T055 [P] [US4] Create `godot/tests/unit/test_madlibs_mixer.gd` — GUT tests: `mix(42).get_id()` equals hardcoded oracle string; `mix(42) == mix(42)` (determinism); `mix(1) != mix(2)` (seed variation); all 6 shapes, colors, sounds, effects reachable

### Implementation for User Story 4

- [ ] T056 [US4] Create `godot/systems/MadlibsMixer.gd` — static class; vocabulary arrays `SHAPES`, `COLORS`, `SOUNDS`, `EFFECTS` per PRD §7.2; `static func mix(seed_value: int) -> AttributeDescriptor` using `RandomNumberGenerator.new()` with `rng.seed = seed_value`; no instance state
- [ ] T057 [US4] Create `godot/systems/AttributeDescriptor.gd` — Resource class with `shape`, `color`, `sound`, `effect`, `seed_value` properties; `get_id() -> String` returns `"{color}-{shape}-{sound}-{effect}"`; `get_color_hex() -> String` maps color name to hex; `get_sprite_path(entity_type: String) -> String` returns `"res://data/assets/sprites/{entity_type}/{color}-{shape}.png"`
- [ ] T058 [US4] Create `godot/systems/SpriteLoader.gd` — utility to load and validate PNG sprites: reject if not 32x32 px, reject if >16 unique colors (sampled), reject if >50KB; move rejected to `data/assets/invalid/`; return ColorRect fallback silently with `push_warning()`
- [ ] T059 [US4] Modify `godot/entities/Creep.gd` — integrate MadlibsMixer on `_ready()`: call `MadlibsMixer.mix(attribute_seed)`, tint ColorRect with `get_color_hex()`, attempt sprite swap via SpriteLoader, apply matching effect gene if registered
- [ ] T060 [US4] Modify `godot/entities/Tower.gd` — integrate MadlibsMixer on `_ready()`: call `MadlibsMixer.mix(attribute_seed)`, tint ColorRect with `get_color_hex()`, attempt sprite swap via SpriteLoader
- [ ] T061 [US4] Update `agents/arsenal/asset-gen/CLAUDE.md` — activate full sprite pipeline: stable-diffusion MCP, 32x32 px constraint, 16-color palette, transparent background, naming convention `{color}-{shape}.png`
- [ ] T062 [US4] Update `agents/arsenal/asset-gen/.claude/mcp.json` — enable stable-diffusion + filesystem MCPs
- [ ] T063 [US4] Create `scripts/generate-sprites.sh` — invokes asset-gen agent for full starter set (6 colors x 6 shapes = 36 tower + 36 creep variants); validates output dimensions and file sizes

**Checkpoint**: GUT tests pass (determinism verified). `generate-sprites.sh` produces ≥36+36 PNGs. Game entities show sprites or tinted ColorRect fallback.

---

## Phase 7: User Story 5 — Self-Evolution & Balance Loop (Priority: P3)

**Goal**: MacroCompiler promotes repeated sequences. SelfOptimizer measures B(state) and nudges. Rollback triggers below 0.5 within 5 cycles. All mutations logged as JSON patches.

**Independent Test**: `godot4 --headless -s scripts/evolution-smoke.gd` exits 0 — ≥10 balance_metrics rows, composite_balance ≥ 0.45, ≥1 gene_lineage row.

### Tests for User Story 5

- [ ] T064 [P] [US5] Create `godot/tests/unit/evolution/test_balance_metric.gd` — GUT test: `_compute_balance(0.7, 0.6, 0.5)` → `is_equal_approx(0.62, 0.001)` per formula `B = 0.4*sd + 0.4*pr + 0.2*av`
- [ ] T065 [P] [US5] Create `godot/tests/unit/evolution/test_macro_compiler.gd` — GUT test: 12 identical action tuples → `analyze_patterns()` → 1 macro registered in GenomeRegistry with provenance `"macro-compiled"`
- [ ] T066 [P] [US5] Create `godot/tests/unit/evolution/test_self_optimizer.gd` — GUT test: inject 5x balance=0.45 history → assert rollback called (spy); parameter nudge logged as JSON patch before application

### Implementation for User Story 5

- [ ] T067 [US5] Create `godot/autoloads/MacroCompiler.gd` — per PRD §6.1: `MIN_SEQUENCE_LENGTH = 3`, `MIN_OCCURRENCE_COUNT = 10`, `PATTERN_WINDOW = 100`; `analyze_patterns()` detects repeated action sequences; promotes macros with provenance `"macro-compiled"`; registers in GenomeRegistry; writes gene_lineage row
- [ ] T068 [US5] Create `godot/autoloads/SelfOptimizer.gd` — per PRD §6.2: `_compute_balance()` with formula `B = 0.4*strategy_diversity + 0.4*player_retention + 0.2*asset_variety`; measures every `OPTIMIZATION_INTERVAL` ticks; writes JSON patch to `metrics.db.mutation_log` BEFORE applying; rollback if last 5 `_balance_history` entries all < 0.5; `balance_updated` and `balance_critical` signals; pauses optimizer after 20 failed rollback attempts
- [ ] T069 [US5] Create `godot/autoloads/ResourceMonitor.gd` — platform-agnostic CPU/memory sampling via `Performance.get_monitor()` and `OS.get_memory_info()` only; no OS-specific calls
- [ ] T070 [US5] Modify `project.godot` — register new autoloads: `MacroCompiler="*res://godot/autoloads/MacroCompiler.gd"`, `SelfOptimizer="*res://godot/autoloads/SelfOptimizer.gd"`, `ResourceMonitor="*res://godot/autoloads/ResourceMonitor.gd"`
- [ ] T071 [US5] Create `scripts/evolution-smoke.gd` — headless 20-min simulation; asserts ≥10 `balance_metrics` rows in metrics.db; `composite_balance` ≥ 0.45 throughout; ≥1 `gene_lineage` row with `mutation_type = "macro-compiled"`; exits 0 on pass, 1 on fail

**Checkpoint**: All Phase 7 GUT tests pass. `evolution-smoke.gd` exits 0. Balance formula numerically verified.

---

## Phase 8: Dashboard & Observability

**Purpose**: Wire Dashboard to live data from all autoloads

- [ ] T072 [P] Create `godot/tests/unit/test_dashboard.gd` — GUT test: mock signals from ThrottleController, GenomeRegistry, SelfOptimizer; assert label text updates within one frame of signal emission
- [ ] T073 Update `godot/ui/Dashboard.tscn` and `godot/ui/Dashboard.gd` — full metrics wiring: FPSLabel polls `Engine.get_frames_per_second()` every 0.5s; MemoryBar shows `OS.get_memory_info()` with red tint >80% pressure; BalanceLabel shows `SelfOptimizer.last_balance` on `balance_updated` signal; GenePoolLabel shows `GenomeRegistry.get_active_gene_count()`; WaveLabel shows `GameState.wave_number`

**Checkpoint**: Dashboard shows live FPS, memory, B(state), gene pool size, wave number. GUT test passes.

---

## Phase 9: Polish & Integration

**Purpose**: Final validation of all SC-001 through SC-008, tagging, PR preparation

- [ ] T074 Run full GUT test suite headlessly — verify all tests across all phases pass with exit code 0 (SC-001)
- [ ] T075 Run `bun test agents/` — verify all TypeScript tests pass (SC-002)
- [ ] T076 Manual 3-wave playtest on WSL2 — verify no crashes, error dialogs, or manual interventions (SC-003)
- [ ] T077 NL synthesis test — submit behavior prompt with API key + orchestrator → new creep within 30s (SC-004)
- [ ] T078 MadlibsMixer cross-platform determinism — verify `mix(42)` returns same ID (SC-005)
- [ ] T079 Sprite count verification — verify ≥36 tower + ≥36 creep sprites in `data/assets/sprites/` (SC-006)
- [ ] T080 Evolution smoke test — `godot4 --headless -s scripts/evolution-smoke.gd` exits 0 (SC-007)
- [ ] T081 Graceful degrade test — kill orchestrator mid-session → no crash, amber PromptEditor message (SC-008)
- [ ] T082 Create `specs/002-game-foundation/test-results-wsl2.md` — manual acceptance test results documenting all SC-001 through SC-008
- [ ] T083 Run `quickstart.md` validation end-to-end per Phase 1–8 gate commands
- [ ] T084 Tag `v0.1.0-game-foundation` and prepare PR: `002-game-foundation` → `main`

**Checkpoint**: All 8 success criteria pass. Tagged and ready for merge. Feature 001 can branch from main after merge.

---

## Dependencies & Execution Order

### Phase Dependencies

```
Phase 1 (Setup) ──────────────► Phase 2 (Foundational) ──┬──► Phase 3 (US1: Core Loop) P1
                                                          │
                                                          └──► [BLOCKED until US1 complete]
                                                                    │
                                                          ┌─────────┤
                                                          ▼         ▼
                                                   Phase 4       Phase 4
                                                   (US2: Genes)  (US2 needs US1 entities)
                                                          │
                                                   ┌──────┴──────┐
                                                   ▼             ▼
                                            Phase 5          Phase 6
                                            (US3: NL Synth)  (US4: MadLibs)
                                            [needs US2]      [needs US1+US2]
                                                   │             │
                                                   └──────┬──────┘
                                                          ▼
                                                   Phase 7 (US5: Self-Evolution)
                                                   [needs US1+US2]
                                                          │
                                                          ▼
                                                   Phase 8 (Dashboard)
                                                   [needs US5 signals]
                                                          │
                                                          ▼
                                                   Phase 9 (Polish)
```

### User Story Dependencies

- **US1 (P1)**: Can start after Foundational (Phase 2) — no dependencies on other stories
- **US2 (P1)**: Depends on US1 (entities must exist for gene execution integration)
- **US3 (P2)**: Depends on US2 (GenomeRegistry, BehaviorBase, validate-gene.sh must exist)
- **US4 (P2)**: Depends on US1 (entities to modify) and US2 (effect genes)
- **US5 (P3)**: Depends on US1 (gameplay data) and US2 (gene pool to evolve)

### Within Each User Story

- Tests written FIRST, ensure they FAIL before implementation
- Base classes before implementations
- Core logic before integration with other systems
- Story complete before moving to next priority

### Parallel Opportunities

**Within Phase 1 (Setup)**:
- T002, T003, T004, T005 all independent — run in parallel
- T007, T008, T009 all independent autoload stubs — run in parallel

**Within Phase 3 (US1)**:
- T013, T014, T015, T016 — all test files independent, run in parallel
- T018, T019, T020 — entity scenes use different files, run in parallel

**Within Phase 4 (US2)**:
- T024, T025, T026 — all test files independent, run in parallel
- T028, T029 — both behavior genes independent of each other
- T030–T035 — all 6 effect genes independent, run in parallel

**Within Phase 5 (US3)**:
- T039, T040, T041 — all test files independent (different runtimes even)
- T042, T045, T046–T050 — type definitions, config files, and persona files all independent

**Within Phase 7 (US5)**:
- T064, T065, T066 — all test files independent, run in parallel

---

## Parallel Example: User Story 2 (Gene System)

```bash
# Round 1 — Tests (all parallel, all should FAIL initially):
Task T024: "GUT tests for GenomeRegistry in godot/tests/unit/genome/test_genome_registry.gd"
Task T025: "GUT tests for BehaviorBase in godot/tests/unit/genome/test_behavior_base.gd"
Task T026: "GUT tests for effects in godot/tests/unit/genome/test_effects.gd"

# Round 2 — Base class (sequential, blocks implementations):
Task T027: "BehaviorBase contract in godot/genes/behaviors/BehaviorBase.gd"

# Round 3 — Behaviors + Effects (all parallel):
Task T028: "WalkPathBehavior in godot/genes/behaviors/WalkPathBehavior.gd"
Task T029: "FlankBehavior in godot/genes/behaviors/FlankBehavior.gd"
Task T030: "FreezeEffect in godot/genes/effects/FreezeEffect.gd"
Task T031: "BleedEffect in godot/genes/effects/BleedEffect.gd"
Task T032: "ChainEffect in godot/genes/effects/ChainEffect.gd"
Task T033: "PoisonEffect in godot/genes/effects/PoisonEffect.gd"
Task T034: "StunEffect in godot/genes/effects/StunEffect.gd"
Task T035: "DrainEffect in godot/genes/effects/DrainEffect.gd"

# Round 4 — Core systems (sequential, depends on Round 3):
Task T036: "Full GenomeRegistry SQLite implementation"
Task T037: "validate-gene.sh script"

# Round 5 — Integration (depends on Round 4):
Task T038: "Creep.gd gene execution integration"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001–T010)
2. Complete Phase 2: Foundational (T011–T012)
3. Complete Phase 3: User Story 1 (T013–T023)
4. **STOP and VALIDATE**: `godot4 --headless -s addons/gut/gut_cmdln.gd` exits 0; play one full wave manually
5. This delivers a playable tower defense game with primitive shapes

### Incremental Delivery

1. Setup + Foundational → Project scaffold operational
2. Add US1 (Core Loop) → Playable game (MVP!)
3. Add US2 (Genes) → Self-modifying creep behaviors
4. Add US3 (NL Synthesis) → Player-facing AI integration
5. Add US4 (MadLibs/Sprites) → Visual identity + sprite assets
6. Add US5 (Self-Evolution) → Autonomous game adaptation
7. Dashboard + Polish → Observability and release gate

### Single Developer Strategy

Execute phases sequentially in priority order. Within each phase, maximize parallelism on [P] tasks by working on independent files. Commit after each task or logical group.

---

## Notes

- [P] tasks = different files, no dependencies on incomplete tasks
- [Story] label maps task to specific user story for traceability
- All GDScript tests use GUT (headless); all TypeScript tests use `bun test`
- `godot-sqlite` GDExtension is the only GDExtension — justified per constitution (GDScript has no native SQLite)
- Spec requires tests: TDD approach within each phase (tests first, then implementation)
- Feature 001 branches from `main` AFTER this feature merges — do not start 001 early
- No Friday deploys (superstition, but also good practice)
