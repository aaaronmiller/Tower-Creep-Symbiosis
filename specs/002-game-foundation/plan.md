# Implementation Plan: Game Foundation — Playable Core to Self-Evolving System

**Branch**: `002-game-foundation` | **Date**: 2026-03-10 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/002-game-foundation/spec.md`
**PRD Reference**: All code architecture is per `prd.md` §3–9. When a method signature
or constant appears in both this plan and the PRD, the PRD is authoritative.
**Prerequisite for**: Feature 001 (`001-cross-platform-support`) — do not start 001 until
Phases 1–3 here are merged.

---

## Summary

Build Tower-Creep Symbiosis from zero to a self-evolving, agent-powered tower defense game
across eight phases. Each phase ships a runnable increment validated by GUT/bun tests
before moving to the next. Primitive Godot shapes (ColorRect, polygon) stand in for sprites
until Phase 5 (asset generation), keeping visual polish separate from gameplay validation.

The implementation follows the PRD architecture exactly — no new systems are invented here.
Code samples in the PRD (§7.1–7.3, §5–6) are the canonical reference for every method
signature; they are not suggestions.

---

## Technical Context

**Language/Version**: GDScript 4.3 (game logic, tests), TypeScript with Bun 1.x (agent orchestration)
**Primary Dependencies**: Godot 4.3 engine (Forward+ renderer, Compatibility fallback);
Bun 1.x runtime; SQLite via `bun:sqlite`; GUT (Godot Unit Testing) plugin v9.x;
Claude Code CLI (agent harness default)
**Storage**: `data/genome.db` (SQLite WAL — gene pool); `data/metrics.db` (SQLite WAL —
balance + performance logs); `data/schema.sql` (schema source of truth, read at startup)
**Testing**: GUT (all GDScript logic, headless); `bun test` (all TypeScript orchestration);
manual integration smoke tests per acceptance scenario; headless evolution smoke script
**Target Platform**: Linux x86-64 (Ubuntu 22.04+ via WSL2 or native) — primary dev target.
macOS ARM64 supported implicitly; full cross-platform validation is Feature 001's scope.
**Project Type**: Desktop game with headless agentic sub-processes (CIO pattern)
**Performance Goals**: 60 FPS game loop on M-series; 30 FPS minimum on Intel 16 GB
(enforced by Feature 001's ThrottleController modifications, not this feature)
**Constraints**: All gene mutations ≤ 10% per iteration; B(state) ≥ 0.6 enforced;
no agent writes to core game logic files; SQLite WAL for concurrent read/write
**Scale/Scope**: Single-player local game; 2–4 concurrent agent processes during peak synthesis

---

## Constitution Check

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Clean Code & Efficiency | ✅ PASS | Each file has one responsibility. No helper wrappers introduced for one-time use. GUT tests enforce cleanliness at every phase gate. Dead code removed before phase commit. |
| II. Performance Budget | ✅ PASS | PID ThrottleController from PRD §4.1 enforces 60 FPS budget. Gene execution sandboxed to avoid frame overruns. MacroCompiler runs at a configurable interval (not per-frame). |
| III. Agentic Safety | ✅ PASS | validate-gene.sh gates every agent-generated gene before registry insertion. Agents cannot write to `godot/` source files — only to `user://genes/` runtime directory. cost-limiter.sh hook constrains API spend per session. |
| IV. Self-Evolution Integrity | ✅ PASS | B(state) ≥ 0.6 enforced. Rollback triggers at < 0.5 within 5 cycles. Every parameter mutation logged as JSON patch before application. Dormant genes archived not deleted. |
| V. GDScript-First | ✅ PASS | All game logic in GDScript. TypeScript only in `agents/`. AgentBridge is the sole IPC boundary. No GDExtension introduced. |

**Post-design re-check**: PASS — Phase 1 design (data-model.md, contracts) introduced no
additional violations. SQLite dual-access complexity is documented in Complexity Tracking.

---

## Project Structure

### Documentation (this feature)

```text
specs/002-game-foundation/
├── spec.md              # Requirements (/speckit.specify output)
├── plan.md              # This file (/speckit.plan output)
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/
│   ├── behavior-base-api.md       # BehaviorBase GDScript interface contract
│   ├── agent-bridge-api.md        # AgentBridge IPC contract
│   └── gene-validate-contract.md  # validate-gene.sh input/output contract
├── checklists/
│   └── requirements.md            # Quality checklist (all PASS)
└── tasks.md             # Phase 2 output (/speckit.tasks command)
```

### Source Code — Full File Manifest by Phase

```text
# Phase 1: Project Scaffold
project.godot                        ← NEW: Godot project config, autoload registrations
addons/gut/                          ← NEW: GUT plugin (vendored, MIT)
godot/
├── main.tscn                        ← NEW: Entry scene → loads Arena.tscn
├── main.gd                          ← NEW: Scene switcher, startup sequence
├── autoloads/
│   ├── GameState.gd                 ← NEW: Lives, gold, wave counter, session metrics, CRDT state
│   ├── GenomeRegistry.gd            ← NEW: Stub (in-memory dict only; SQLite added Phase 3)
│   ├── ThrottleController.gd        ← NEW: Full PID controller (PRD §4.1)
│   └── AgentBridge.gd               ← NEW: Stub (no IPC yet; returns empty task IDs)
├── tests/
│   └── unit/
│       └── test_gamestate.gd        ← NEW: GUT tests for GameState (lives, gold, cycles)
data/
└── schema.sql                       ← NEW: SQLite schema for genome.db + metrics.db

# Phase 2: Core Gameplay
godot/
├── scenes/
│   └── Arena.tscn                   ← NEW: Map with Path2D, tower slots (Markers), spawn/exit
├── entities/
│   ├── Creep.tscn                   ← NEW: CharacterBody2D + ColorRect + CollisionShape2D
│   ├── Creep.gd                     ← NEW: Path following, health, gene exec hook (PRD §7.3)
│   ├── Tower.tscn                   ← NEW: StaticBody2D + ColorRect + Area2D range sensor
│   ├── Tower.gd                     ← NEW: Target acquisition, fire rate, projectile spawning (PRD §7.3)
│   ├── Projectile.tscn              ← NEW: Area2D + ColorRect
│   └── Projectile.gd                ← NEW: Homing, collision, damage application
├── systems/
│   ├── WaveManager.gd               ← NEW: Wave config, spawn sequencing, wave-complete detection
│   └── PathFollower.gd              ← NEW: Waypoint traversal logic extracted from Creep
├── ui/
│   └── HUD.tscn + HUD.gd           ← NEW: Lives, gold, wave counter display
└── tests/
    └── unit/
        ├── test_creep.gd            ← NEW: Path follow, health, death signal
        ├── test_tower.gd            ← NEW: Target find, fire cooldown, projectile spawn
        ├── test_projectile.gd       ← NEW: Travel, collision, damage call
        └── test_wave_manager.gd     ← NEW: Spawn count, wave complete signal

# Phase 3: Gene System
godot/
├── genes/
│   ├── behaviors/
│   │   ├── BehaviorBase.gd          ← NEW: Abstract base class; _evaluate() contract
│   │   ├── WalkPathBehavior.gd      ← NEW: Default path-following behavior gene
│   │   └── FlankBehavior.gd         ← NEW: Example: avoids tower range zones
│   └── effects/
│       ├── FreezeEffect.gd          ← NEW: Slows tower fire rate on contact
│       ├── BleedEffect.gd           ← NEW: Applies DoT to towers
│       ├── ChainEffect.gd           ← NEW: Damage chains to adjacent towers
│       ├── PoisonEffect.gd          ← NEW: Progressive tower damage
│       ├── StunEffect.gd            ← NEW: Disables tower briefly
│       └── DrainEffect.gd           ← NEW: Converts tower damage to creep HP
├── autoloads/
│   └── GenomeRegistry.gd            ← REPLACE STUB: Full SQLite WAL implementation (PRD §5.2)
└── tests/
    └── unit/
        └── genome/
            ├── test_genome_registry.gd  ← NEW: register, execute, methylation, pruning
            ├── test_behavior_base.gd    ← NEW: BehaviorBase interface compliance
            └── test_effects.gd          ← NEW: Each effect gene applies correct modifier
scripts/
└── validate-gene.sh                 ← NEW: Syntax check + BehaviorBase compliance + static analysis

# Phase 4: Agent Integration
agents/
├── orchestrator.ts                  ← NEW: Bun CIO scheduler (PRD §3.2)
├── harness/
│   ├── harness-interface.ts         ← NEW: AgentHarness interface + AgentTask/AgentResult types
│   └── claude-code-harness.ts       ← NEW: Claude Code CLI implementation
├── arsenal/
│   ├── behavior-synth/
│   │   ├── CLAUDE.md                ← NEW: Behavior synthesizer persona (PRD §3.1)
│   │   └── .claude/mcp.json         ← NEW: MCP tool config (filesystem only)
│   ├── balance-tuner/
│   │   ├── CLAUDE.md                ← NEW: Balance optimizer persona
│   │   └── .claude/mcp.json
│   ├── code-auditor/
│   │   ├── CLAUDE.md                ← NEW: Gene pruning persona
│   │   └── .claude/mcp.json
│   └── asset-gen/
│       ├── CLAUDE.md                ← NEW: Asset generator persona (stub; full in Phase 5)
│       └── .claude/mcp.json         ← NEW: Stable-diffusion MCP config (Phase 5 activates it)
godot/
├── autoloads/
│   └── AgentBridge.gd               ← REPLACE STUB: Full IPC via stdout/stdin + file polling (PRD §3.x)
├── ui/
│   ├── PromptEditor.tscn            ← NEW: TextEdit + Preview + CostLabel + SubmitButton
│   ├── PromptEditor.gd              ← NEW: Debounced preview, cycle check, synthesis request (PRD §7.1)
│   └── Dashboard.tscn + Dashboard.gd ← NEW: Performance metrics display (throttle, FPS, memory stub)
└── tests/
    └── unit/
        └── test_agent_bridge.gd     ← NEW: Queue size limit, graceful degrade, task ID format
scripts/
└── deploy-agent.sh                  ← NEW: CIO pattern launcher (PRD §9.3)
data/
└── agent-harness.json               ← NEW: {"harness": "claude-code", "config": {}}
tests/
└── agents/
    ├── orchestrator.test.ts         ← NEW: bun test — task queuing, harness mock, shutdown
    └── harness.test.ts              ← NEW: bun test — ClaudeCodeHarness.isAvailable(), mock deploy

# Phase 5: MadLibs & Sprite Generation
godot/
├── systems/
│   └── MadlibsMixer.gd              ← NEW: Deterministic attribute generation (PRD §7.2)
├── entities/
│   ├── Creep.gd                     ← MODIFY: integrate MadlibsMixer on _ready(); sprite swap logic
│   └── Tower.gd                     ← MODIFY: integrate MadlibsMixer on _ready(); sprite swap logic
└── tests/
    └── unit/
        └── test_madlibs_mixer.gd    ← NEW: Determinism test (seed=42 → known descriptor);
                                     #      cross-platform parity assertion
agents/
└── arsenal/
    └── asset-gen/
        ├── CLAUDE.md                ← UPDATE: Activate stable-diffusion MCP, full sprite pipeline
        └── .claude/mcp.json         ← UPDATE: Enable stable-diffusion + filesystem MCPs
data/
└── assets/
    ├── sprites/
    │   ├── towers/                  ← GENERATED: 36+ PNG files by asset-gen agent
    │   └── creeps/                  ← GENERATED: 36+ PNG files by asset-gen agent
    └── invalid/                     ← NEW: Quarantine dir for rejected sprites
scripts/
└── generate-sprites.sh              ← NEW: Invokes asset-gen agent for full starter set

# Phase 6: Self-Evolution
godot/
├── autoloads/
│   ├── MacroCompiler.gd             ← NEW: Action sequence detection + macro promotion (PRD §6.1)
│   ├── SelfOptimizer.gd             ← NEW: B(state) measurement, gradient nudge, rollback (PRD §6.2)
│   └── ResourceMonitor.gd           ← NEW: Platform-agnostic CPU/memory sampling
├── tests/
│   └── unit/
│       └── evolution/
│           ├── test_macro_compiler.gd   ← NEW: Pattern detect at MIN_OCCURRENCE threshold
│           ├── test_self_optimizer.gd   ← NEW: Balance formula, gradient, rollback trigger
│           └── test_balance_metric.gd   ← NEW: Numeric formula with hardcoded fixture
└── project.godot                    ← MODIFY: Register MacroCompiler, SelfOptimizer, ResourceMonitor
scripts/
└── evolution-smoke.gd               ← NEW: Headless 20-min simulation; asserts ≥10 balance rows

# Phase 7: Dashboard & Observability
godot/
├── ui/
│   ├── Dashboard.tscn               ← UPDATE: Full metrics — FPS counter, memory bar (stub values),
│   │                                #          B(state) live display, gene pool size, wave info
│   └── Dashboard.gd                 ← UPDATE: Poll ThrottleController, GenomeRegistry, SelfOptimizer
└── tests/
    └── unit/
        └── test_dashboard.gd        ← NEW: Dashboard updates on signal, shows correct values

# Phase 8: Integration & Polish
specs/002-game-foundation/
└── test-results-wsl2.md             ← NEW: Manual acceptance test results (all SC-00x)
```

**Structure Decision**: Godot-native layout under `godot/`, TypeScript agent layer under
`agents/`, shared data under `data/`. No monorepo tooling — directories are separated by
runtime (Godot process vs Bun process), not by package boundaries.

---

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|--------------------------------------|
| SQLite accessed from both GDScript (GenomeRegistry) and TypeScript (orchestrator metrics) | Balance metrics written by orchestrator; gene data read by game | A single-process design would require the game to run Bun inside Godot (impossible without GDExtension). Shared SQLite WAL is the minimum viable IPC for structured data. |
| GUT plugin vendored into repo | Headless CI testing requires GUT; not installable via package manager without editor | Alternative (manual test scripts) produces far less coverage with far more maintenance burden. GUT is MIT licensed. |

---

## Phase-by-Phase Implementation Plan

### Phase 1 — Project Scaffold

**Goal**: `godot4 project.godot` opens without errors. All autoloads initialize.
GUT runs headlessly with the scaffolding test.

**Files created**: `project.godot`, `godot/main.tscn`, `godot/main.gd`,
`godot/autoloads/GameState.gd`, `godot/autoloads/GenomeRegistry.gd` (stub),
`godot/autoloads/ThrottleController.gd`, `godot/autoloads/AgentBridge.gd` (stub),
`data/schema.sql`, `addons/gut/` (vendored), `godot/tests/unit/test_gamestate.gd`

**Autoload registration order** in `project.godot`:
```
GameState="*res://godot/autoloads/GameState.gd"
GenomeRegistry="*res://godot/autoloads/GenomeRegistry.gd"
ThrottleController="*res://godot/autoloads/ThrottleController.gd"
AgentBridge="*res://godot/autoloads/AgentBridge.gd"
```

**ThrottleController**: Implement full PID loop from PRD §4.1 verbatim.
`TARGET_CPU_UTILIZATION`, `TARGET_FRAME_TIME_MS`, `TARGET_MEMORY_PRESSURE` as named
constants. `tick_duration_changed` and `work_budget_changed` signals.

**GameState stub** must provide: `player_cycles: int`, `lives: int`, `gold: int`,
`wave_number: int`, `state_changed` signal, `spawn_creep_with_behavior(gene_id)`.

**GUT tests** for GameState: starting lives == config value; `player_cycles` decrements
on deduct; `state_changed` fires on territory claim.

**Checkpoint**: `godot4 --headless -s addons/gut/gut_cmdln.gd` exits 0. Game window
opens to a grey screen (no arena yet). Console shows all autoload init messages.

---

### Phase 2 — Core Gameplay

**Goal**: Complete playable wave: creeps walk path → towers shoot → creeps die or
drain lives → wave-complete or game-over. All entity GUT tests pass.

**Arena.tscn** layout:
- `Path2D` with at least 5 `PathPoint` children defining the creep route
- 3 `Marker2D` nodes in group `"tower_slots"` — player places towers here
- `Marker2D` in group `"player_spawn"` at path start
- `Marker2D` in group `"path_exit"` at path end; triggers life loss on creep arrival

**Creep.gd** key behaviors:
- `_ready()`: set `health = max_health`, call `_load_behavior()` (no-op if gene_id empty)
- `_physics_process()`: call `PathFollower.advance(self, delta)` for movement
- `take_damage(amount, source)`: decrement health; if ≤ 0 emit `died`, award gold, queue_free()
- When creep's PathFollower signals `path_completed`: call `GameState.lives -= 1`, queue_free()

**Tower.gd** key behaviors:
- `_process(delta)`: decrement `_fire_cooldown`; call `_find_target()` if current target gone
- `_find_target()`: `$RangeArea.get_overlapping_bodies()` filtered to Creep; sorted by distance
- `_fire_at_target()`: instantiate Projectile.tscn; set `target`, `damage`, `attributes`; add to parent

**Projectile.gd**: Moves toward `target.global_position` each physics frame at `speed`.
On `body_entered` (Area2D): call `target.take_damage(damage, self)`, queue_free().

**WaveManager.gd**:
- `wave_config: Array[Dictionary]` — each entry: `{count, health, speed, gene_id, gold_reward, spawn_interval}`
- `start_wave(wave_number)`: spawn `count` creeps with `spawn_interval` delay via Timer
- Listens to all Creep `died` and life-loss signals; emits `wave_complete` when all creeps gone

**GUT test strategy** (each test is independent, uses a minimal scene):
- `test_creep.gd`: Assert `take_damage(50)` on a 100HP creep results in health=50.
  Assert `take_damage(100)` emits `died` and `queue_free()` is called.
- `test_tower.gd`: Spawn a mock Creep inside Tower's range Area2D. Assert `_find_target()`
  returns it. Assert `_fire_at_target()` adds a Projectile child to parent scene.
- `test_projectile.gd`: Mock a Creep target. Assert Projectile calls `take_damage` on
  `body_entered`.
- `test_wave_manager.gd`: Configure a wave with count=3. Assert 3 Creeps are spawned.
  Kill all 3. Assert `wave_complete` signal fires.

**Checkpoint**: Manual play — complete one wave, reach wave complete or game over.
All Phase 2 GUT tests pass headlessly.

---

### Phase 3 — Gene System

**Goal**: GenomeRegistry fully operational with SQLite WAL. BehaviorBase interface
enforced. Default and example behavior genes registered and executing. GUT tests
cover registry CRUD, execution, methylation.

**BehaviorBase.gd** contract:
```gdscript
class_name BehaviorBase
extends Resource

func _evaluate(context: Dictionary) -> Dictionary:
    push_error("BehaviorBase._evaluate() not implemented")
    return {}

func initialize(params: Dictionary) -> void:
    pass  # Override to read params
```

**WalkPathBehavior.gd**: Returns `{"move_direction": PathFollower.get_next_direction(entity)}`
**FlankBehavior.gd**: Returns move_direction biased away from nearest tower's range zone

**GenomeRegistry.gd** replaces stub:
- Opens `user://genome.db` in WAL mode; reads schema from `res://data/schema.sql`
- `register_gene()`, `execute_gene()`, `methylate_gene()`, `prune_gene()` per PRD §5.2
- `_on_memory_check()` — error rate auto-methylation after 20 failures
- `get_strategy_diversity()`, `get_gene_error_rates()` — balance metric accessors

**validate-gene.sh** checks (bash):
1. GDScript syntax + lint via `gdlint` (gdtoolkit 4.x — `pip3 install "gdtoolkit==4.*"`)
2. `extends BehaviorBase` present (exact string match)
3. `func _evaluate(context` present (method signature)
4. Forbidden keywords absent: `FileAccess`, `HTTPRequest`, `OS.execute`, `while true:`
5. For-loop iteration heuristic: flag if loop bounds exceed 100 (static warning)

**GUT tests** (using an in-memory Dictionary test double injected into GenomeRegistry):
- `test_genome_registry.gd`: register → gene in _loaded_genes; execute → _evaluate() called;
  20 errors → auto-methylate.
- `test_behavior_base.gd`: WalkPathBehavior and FlankBehavior both return dict with
  `"move_direction"` key.
- `test_effects.gd`: Each effect gene modifies the correct Tower stat when applied.

**Checkpoint**: All Phase 3 GUT tests pass. `FlankBehavior` assigned to a creep in a
running game observes different path than `WalkPathBehavior`.

---

### Phase 4 — Agent Integration

**Goal**: PromptEditor submits a prompt, orchestrator synthesizes a gene, creep spawns
with it. Graceful degrade when orchestrator is offline. All bun tests pass.

**agents/harness/harness-interface.ts**:
```typescript
export interface AgentHarness {
  deploy(task: AgentTask): Promise<AgentResult>;
  isAvailable(): Promise<boolean>;
}
export interface AgentTask { id: string; agentType: AgentType; prompt: string; priority: number; }
export interface AgentResult { taskId: string; success: boolean; output: string; error?: string; }
export type AgentType = "asset-gen" | "balance-tuner" | "behavior-synth" | "code-auditor";
```

**agents/orchestrator.ts**: Priority queue. Reads `data/agent-harness.json` to select
harness. Polls AgentBridge result file path for task acknowledgement. Max concurrency: 4.
Graceful shutdown on SIGTERM.

**AgentBridge.gd** (full IPC):
- Manages a `_task_queue: Array[Dictionary]` with max size 4
- `queue_task(type, prompt, priority) -> String`: returns task_id or "" if queue full
- Spawns `bun run agents/orchestrator.ts` as subprocess on first task
- Polls `user://agent-results/<task_id>.json` every 250ms via Timer
- On result: parses JSON, emits `agent_result_received(task_id, result)`

**behavior-synth CLAUDE.md** output constraint: agent outputs ONLY a GDScript code block
extending BehaviorBase, no prose. Harness extracts code block and pipes to validate-gene.sh.

**bun tests**:
- `orchestrator.test.ts`: mock harness resolves immediately; assert priority ordering.
- `harness.test.ts`: mock `Bun.spawn` exit 0 for `isAvailable()`; assert deploy() passes prompt.

**GUT tests**:
- `test_agent_bridge.gd`: 5th task rejected when max=4; `_orchestrator_available=false`
  causes `synthesize_behavior()` to return "" without spawning subprocess.

**Checkpoint**: `bun test` exits 0. Submit "fast creep" in-game; new creep spawns within 30s.
Kill orchestrator; game continues; PromptEditor shows amber message.

---

### Phase 5 — MadLibs & Sprite Generation

**Goal**: Every entity has a deterministic visual/mechanical identity. asset-gen agent
produces a complete sprite set. Game swaps ColorRects for sprites when files exist.

**MadlibsMixer.gd** vocabulary (exact from PRD §7.2):
- `SHAPES = ["orb","shard","spike","wave","burst","beam"]`
- `COLORS = ["crimson","void","amber","azure","moss","ember"]`
- `SOUNDS = ["hum","screech","pulse","thrum","crackle","whisper"]`
- `EFFECTS = ["freeze","bleed","chain","poison","stun","drain"]`

RNG: `RandomNumberGenerator.new(); rng.seed = seed_value` for determinism.
`static func mix(seed_value: int) -> AttributeDescriptor` — no instance state.

**Sprite validation** in loader utility:
- Reject if not 32×32 px
- Reject if > 16 unique colors (sampled)
- Reject if file size > 50 KB
- Move rejected files to `data/assets/invalid/`; use ColorRect fallback silently

**GUT test** `test_madlibs_mixer.gd`:
- `mix(42).get_id()` == hardcoded oracle string (captured once, committed)
- `mix(42) == mix(42)` (determinism)
- `mix(1) != mix(2)` (seed variation)

**Checkpoint**: `generate-sprites.sh` produces ≥ 36 tower + ≥ 36 creep PNGs in
`data/assets/sprites/`. Run game — entities show sprites. GUT tests pass.

---

### Phase 6 — Self-Evolution

**Goal**: MacroCompiler promotes repeated sequences. SelfOptimizer measures and nudges.
Rollback triggers below 0.5. All evolution GUT tests pass.

**MacroCompiler.gd** key parameters (PRD §6.1):
- `MIN_SEQUENCE_LENGTH = 3`; `MIN_OCCURRENCE_COUNT = 10`; `PATTERN_WINDOW = 100`
- Promoted macros use provenance `"macro-compiled"`

**SelfOptimizer.gd** key behaviors (PRD §6.2):
- Every parameter nudge: write JSON patch to `metrics.db.mutation_log` BEFORE applying
- Rollback if last 5 `_balance_history` entries all < 0.5

**ResourceMonitor.gd**: Platform-agnostic sampling via `Performance.get_monitor()` and
`OS.get_memory_info()` only. No OS-specific calls (those come in Feature 001).

**Register in project.godot**:
```
MacroCompiler="*res://godot/autoloads/MacroCompiler.gd"
SelfOptimizer="*res://godot/autoloads/SelfOptimizer.gd"
ResourceMonitor="*res://godot/autoloads/ResourceMonitor.gd"
```

**GUT tests**:
- `test_balance_metric.gd`: `_compute_balance(0.7, 0.6, 0.5)` → `is_equal_approx(0.62, 0.001)`
- `test_macro_compiler.gd`: 12 identical actions → `analyze_patterns()` → 1 macro in registry
- `test_self_optimizer.gd`: inject 5× balance=0.45 history → assert rollback called (spy)

**scripts/evolution-smoke.gd**: Headless 20-min sim; asserts ≥10 `balance_metrics` rows;
`composite_balance` ≥ 0.45 throughout; ≥1 `gene_lineage` row (macro promoted). Exits 0 or 1.

**Checkpoint**: `godot4 --headless -s scripts/evolution-smoke.gd` exits 0. All Phase 6 GUT pass.

---

### Phase 7 — Dashboard & Observability

**Goal**: Dashboard shows live FPS, memory bar, B(state), gene pool size, wave number.

**Dashboard.tscn** nodes:
- `FPSLabel` — polled each 0.5s from `Engine.get_frames_per_second()`
- `MemoryBar` (ProgressBar) — max=physical RAM; current=physical-free; red tint if >80% pressure
- `BalanceLabel` — text=`"B: %.2f" % SelfOptimizer.last_balance`; updated on `balance_updated` signal
- `GenePoolLabel` — `"Genes: %d" % GenomeRegistry.get_active_gene_count()`
- `WaveLabel` — `"Wave: %d" % GameState.wave_number`

**GUT test**: Mock signals; assert label text updates within one frame of signal emission.

---

### Phase 8 — Integration & Polish

**Goal**: All SC-001 through SC-008 verified. Gate for Feature 001 merge.

Manual checklist produces `test-results-wsl2.md`. All 8 success criteria signed off.
Tag `v0.1.0-game-foundation`. Open PR to merge to `main`.
Feature 001 branches from `main` after merge.

---

## Parallelism Opportunities

- **Phase 2**: Arena.tscn layout + WaveManager independent of Projectile.gd
- **Phase 3**: Effect genes (6 files) all independent of each other and of GenomeRegistry SQLite
- **Phase 4**: harness TypeScript files independent of PromptEditor UI; bun tests writable alongside GDScript IPC
- **Phase 5**: Sprite generation (agent invocation) runs while MadlibsMixer GDScript is coded
- **Phases 6+7**: Must be sequential (Dashboard consumes SelfOptimizer signals)

---

## Testing Strategy Summary

| Layer | Tool | Gate | Scope |
|-------|------|------|-------|
| GDScript unit | GUT headless | Each phase | GameState, entities, genome, mixer, evolution, dashboard |
| GDScript integration | GUT headless | Phase 4 | AgentBridge degrade, end-to-end spawn |
| TypeScript unit | bun test | Phase 4 | Orchestrator, harness contract, mock deploy |
| Headless evolution | evolution-smoke.gd | Phase 6 | B(state) stability, macro promotion |
| Manual acceptance | Spec SC-00x | Phase 8 | Full session, NL synthesis, sprite display |

**TDD order within each phase**: GUT test skeleton written → implement to pass → refactor
if needed → commit. No GUT test file is left failing at a phase checkpoint.
