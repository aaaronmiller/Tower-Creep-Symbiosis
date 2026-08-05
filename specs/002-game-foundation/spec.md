# Feature Specification: Game Foundation — Playable Core to Self-Evolving System

**Feature Branch**: `002-game-foundation`
**Created**: 2026-03-10
**Status**: Draft
**Supersedes**: PRD.md §10 Implementation Roadmap (Phases 1–4); replaces the implicit
assumption in feature 001 that game code already exists.
**Feeds Into**: Feature 001 (`001-cross-platform-support`) — that feature modifies autoloads
created here; 001 MUST NOT be implemented before 002 Phases 1–3 are merged.

---

## Why This Feature Exists

The project has a complete specification (PRD, constitution, contracts) and a
cross-platform feature spec (001), but **zero executable code**. The `godot/` directory,
`project.godot`, all autoloads, all entities, all agent code — none of it exists.
Feature 001 assumes these files exist and modifies them; it cannot be implemented first.

This feature builds everything from scratch in the correct order:
scaffold → playable loop → gene system → NL behavior synthesis →
procedural sprite generation → self-evolution.

Each user story is independently testable and produces a runnable artifact.
GUT tests (GDScript) and `bun test` (TypeScript) are written before or alongside
each implementation task — no story is complete until its tests pass headlessly.

---

## User Scenarios & Testing

### User Story 1 — Playable Core Loop (Priority: P1)

A developer on WSL2/Linux can open the Godot project, press Play, and experience a
complete wave-based tower defense match: creeps spawn and follow a path, towers shoot
projectiles that damage and kill them, lives decrease when a creep reaches the end,
and the game displays a win/lose state after a configurable number of waves.
All game entities use Godot primitive shapes (ColorRect / polygon) — no sprite assets
are required for this story. All core logic is covered by GUT tests that pass headlessly.

**Why this priority**: Without a running game loop, nothing else can be tested.
Every subsequent story assumes this foundation exists. It is the mandatory prerequisite
for gameplay validation.

**Independent Test**: Run `godot4 --headless -s addons/gut/gut_cmdln.gd` — all Phase 1
GUT tests pass. Then run `godot4 project.godot` and complete one full wave without error.

**Acceptance Scenarios**:

1. **Given** a freshly cloned repo on Ubuntu 22.04 with Godot 4.3 installed,
   **When** the developer runs `godot4 project.godot`,
   **Then** the game opens showing an arena with at least one tower slot, a creep path,
   and a HUD displaying lives, gold, and wave number.

2. **Given** a running game session,
   **When** a wave starts,
   **Then** creeps spawn at the defined entry point, follow path waypoints in order,
   and reach the exit after traversing all waypoints without teleporting or clipping.

3. **Given** a creep within a tower's range radius,
   **When** the tower's fire cooldown expires,
   **Then** a projectile is spawned at the tower's position targeting that creep,
   travels toward it, and calls `take_damage()` on contact, reducing the creep's health.

4. **Given** a creep's health reaching ≤ 0,
   **When** `take_damage()` is called with a lethal amount,
   **Then** the creep emits `died`, awards the player gold equal to its configured
   `gold_reward`, and is removed from the scene tree within the same frame.

5. **Given** a creep that reaches the path exit node,
   **When** it arrives at the final waypoint,
   **Then** `GameState.lives` decrements by 1, the creep is removed, and if lives
   reach 0, a "Game Over" overlay appears and simulation stops.

6. **Given** all GUT test files in `godot/tests/`,
   **When** running `godot4 --headless -s addons/gut/gut_cmdln.gd`,
   **Then** all tests pass with exit code 0 and zero failing assertions.

---

### User Story 2 — Gene Behavior System (Priority: P1)

A developer can write a GDScript class extending `BehaviorBase`, register it in
GenomeRegistry, assign its `gene_id` to a Creep, and observe that creep executing
the custom behavior in-game. The genome database (SQLite WAL) stores the gene's
metadata, tracks execution counts, and automatically methylates genes whose error
rate exceeds 5%. GUT tests cover registration, execution, and methylation.

**Why this priority**: The gene system is the primary technical differentiator.
Without it, Tower-Creep Symbiosis is a standard tower defense. All higher stories
(NL synthesis, self-evolution) depend on this layer.

**Independent Test**: Run `godot4 --headless -s addons/gut/gut_cmdln.gd --gut-dir
godot/tests/unit/genome` — all genome registry tests pass. Then in a running game,
manually assign a `FlankBehavior` gene to a creep and observe it pathfinding around
tower range zones.

**Acceptance Scenarios**:

1. **Given** a GDScript file at `godot/genes/behaviors/FlankBehavior.gd` extending
   `BehaviorBase` and implementing `_evaluate(context) -> Dictionary`,
   **When** a developer calls `GenomeRegistry.register_gene("behavior",
   "FlankBehavior", path, {}, "manual")`,
   **Then** a row is inserted into `genome.db` genes table with `methylated = 0`,
   a valid UUID-style `gene_id` is returned, and the gene instance is loaded in memory.

2. **Given** a Creep node with `behavior_gene_id` set to a registered gene,
   **When** `_physics_process(delta)` executes,
   **Then** `GenomeRegistry.execute_gene(behavior_gene_id, context)` is called once
   per frame, the gene's `execution_count` in the DB increments, and the creep's
   velocity is set from the returned `move_direction`.

3. **Given** a gene that throws a GDScript error on `execute()`,
   **When** `GenomeRegistry.execute_gene()` catches it 20 consecutive times,
   **Then** `error_rate` for that gene exceeds 0.05, `methylate_gene()` is called
   automatically, the gene is removed from `_loaded_genes`, and `gene_methylated`
   signal is emitted.

4. **Given** a methylated gene that has been dormant for ≥ 50 balance cycles (defined
   as 50 × `OPTIMIZATION_INTERVAL` ticks),
   **When** the code-auditor check runs,
   **Then** the gene row in `genome.db` is archived to `data/genome.db` as status
   `dormant` (not deleted), and `gene_pruned` signal fires.

5. **Given** all genome GUT tests,
   **When** running headlessly,
   **Then** all pass with zero failures, including tests that mock the SQLite layer.

---

### User Story 3 — Natural Language Behavior Synthesis (Priority: P2)

A player types a behavior description (e.g., "flanking scout that avoids cannon towers")
into the PromptEditor UI, presses Submit, and within 30 seconds a new creep spawns in
the game with that AI-synthesized behavior active. The behavior-synth agent (Claude Code
headless) generates a `BehaviorBase` subclass, it is validated by `validate-gene.sh`,
registered in GenomeRegistry, and the creep is spawned. If the agent is unavailable,
the game degrades gracefully: PromptEditor shows an informative message, and the
default `WalkPathBehavior` is used instead.

**Why this priority**: This is the central player-facing differentiator — the "symbiosis"
mechanic. Without it, the gene system is only developer-accessible. It transforms the
game from a programmable sandbox into a natural-language strategy game.

**Independent Test**: With `bun run agents/orchestrator.ts` running and a valid
Anthropic API key configured, submit the prompt "fast creep that targets the weakest
tower" via PromptEditor. Within 30 s a new creep spawns and its behavior script exists
at `user://genes/behaviors/<id>.gd`. Then kill the orchestrator and verify the game
still starts and plays without crashing.

**Acceptance Scenarios**:

1. **Given** the orchestrator running and an API key configured,
   **When** the player submits a behavior prompt of ≥ 5 characters,
   **Then** `AgentBridge.queue_task()` enqueues the task, the PromptEditor shows
   "Synthesizing...", and the Submit button is disabled until the task resolves.

2. **Given** a successfully completed behavior-synth task,
   **When** the agent returns a valid GDScript string,
   **Then** `validate-gene.sh` runs on it, the gene is registered, a new Creep is
   spawned at the player spawn point with that gene assigned, and PromptEditor shows
   a green "✓ Behavior created" message with the gene ID.

3. **Given** the orchestrator is not running when the player submits a prompt,
   **When** `AgentBridge.isAvailable()` returns false,
   **Then** PromptEditor shows "Agent offline — using default behavior" in amber,
   a creep is still spawned using `WalkPathBehavior`, and no error dialog appears.

4. **Given** a behavior prompt costing more CPU cycles than `GameState.player_cycles`,
   **When** the player presses Submit,
   **Then** the submit is rejected with "Not enough CPU cycles" and no agent task
   is queued, leaving `player_cycles` unchanged.

5. **Given** an agent that returns syntactically invalid GDScript,
   **When** `validate-gene.sh` exits with non-zero,
   **Then** the gene is NOT registered, PromptEditor shows "Synthesis failed — invalid
   behavior", the player's cycles are refunded, and no creep is spawned.

---

### User Story 4 — MadLibs Procedural Sprites & Asset Generation (Priority: P2)

The game uses a procedural naming system (MadlibsMixer: shape × color × sound × effect)
to generate visual and mechanical identities for towers and creeps. Each entity gets a
unique descriptor (e.g., "crimson-orb-hum-freeze") that drives both its visual style
and its mechanical effect gene. The asset-gen agent is triggered once to produce a
starter set of 32×32 PNG sprites (16-color palette, transparent background) for every
combination needed, stored in `data/assets/sprites/`. After this phase the game can be
reskinned by replacing ColorRect primitives with the generated sprites. GUT tests
verify the MadlibsMixer logic deterministically.

**Why this priority**: This phase transforms the game from a developer prototype into
a game that looks and feels like a finished product. The procedural naming also unlocks
the mechanical diversity of the gene system (different visual descriptors → different
effect genes). Sprite generation is a one-time agent invocation, not per-session work.

**Independent Test**: Call `MadlibsMixer.mix(seed=42)` and verify it always returns
`crimson-orb-hum-freeze` (deterministic). Trigger the asset-gen agent via
`bash scripts/deploy-agent.sh asset-gen "Generate starter sprite set"` and verify
sprites appear in `data/assets/sprites/` matching the naming convention.

**Acceptance Scenarios**:

1. **Given** `MadlibsMixer.mix(seed_value: int)` called with the same seed twice,
   **When** comparing both returned `AttributeDescriptor` instances,
   **Then** both have identical `shape`, `color`, `sound`, `effect` values (deterministic).

2. **Given** a Tower or Creep node instantiated with a non-zero `attribute_seed`,
   **When** the scene is ready,
   **Then** `MadlibsMixer.mix(attribute_seed)` is called, the entity's visual body
   (ColorRect) is tinted with `AttributeDescriptor.get_color_hex()`, and the matching
   effect gene (if registered) is applied to its behavior.

3. **Given** the asset-gen agent invoked with `"Generate starter sprite set"`,
   **When** the agent completes,
   **Then** PNG files exist in `data/assets/sprites/towers/` and `data/assets/sprites/creeps/`
   for at least the 6 colors × 6 shapes = 36 tower variants and 36 creep variants,
   each file is 32×32 px, has transparent background, uses ≤ 16 colors, and is < 50 KB.

4. **Given** PNG sprites exist for all active MadLibs combinations,
   **When** a Tower or Creep with a matching descriptor loads,
   **Then** its visual body is replaced with a `Sprite2D` using the matching PNG,
   the ColorRect fallback is hidden, and the sprite renders without visual corruption.

5. **Given** a PNG sprite file is missing for a given descriptor,
   **When** the entity loads,
   **Then** it falls back silently to the ColorRect tinted with `get_color_hex()`,
   with no error dialog and a single `push_warning()` in the Godot output.

---

### User Story 5 — Self-Evolution & Balance Loop (Priority: P3)

The game autonomously analyzes its own gameplay patterns over time. MacroCompiler
detects repeated action sequences and promotes them to macro genes. SelfOptimizer
measures B(state) every 100 ticks, nudges gene parameters toward higher balance,
and rolls back any mutation that drops B(state) below 0.5 within 5 cycles.
The balance-tuner and code-auditor agents run on a schedule, applying larger
structural optimizations and pruning stale genes. All mutations are logged as
JSON patches before application; the audit trail persists in `data/metrics.db`.
GUT tests verify the balance formula and the rollback trigger.

**Why this priority**: Self-evolution is the deepest differentiator — no other tower
defense game adapts its own mechanics. However, it requires a healthy gene pool
(US2) and measurable gameplay (US1) before it can operate meaningfully. P3 is
correct: impressive if present, but US1–3 deliver the core value.

**Independent Test**: Run a 20-minute headless simulation (`godot4 --headless -s
scripts/evolution-smoke.gd`). Verify that `balance_metrics` table in `metrics.db`
has ≥ 10 rows, that `composite_balance` never drops below 0.45, and that at least
one gene lineage row exists in `gene_lineage` table (macro was promoted).

**Acceptance Scenarios**:

1. **Given** `SelfOptimizer._compute_balance()` called with mocked GameState returning
   `strategy_diversity=0.7, player_retention=0.6, asset_variety=0.5`,
   **When** the formula executes,
   **Then** the return value is exactly `0.62` (= 0.4×0.7 + 0.4×0.6 + 0.2×0.5).

2. **Given** a sequence of 10+ identical action tuples recorded by `MacroCompiler`,
   **When** `analyze_patterns()` runs after 100 frames of history,
   **Then** the sequence is promoted to a macro gene registered in GenomeRegistry,
   a row appears in `gene_lineage` with `mutation_type = "macro-compiled"`, and
   subsequent executions use the compiled macro path.

3. **Given** `SelfOptimizer` applies a parameter nudge that causes B(state) to drop
   from 0.65 to 0.48 over 5 cycles,
   **When** the 5th cycle's balance measurement is recorded,
   **Then** the parameter change is reverted by reloading the pre-mutation snapshot,
   a rollback event is logged to `metrics.db`, and B(state) recovers to ≥ 0.5
   within the next 5 cycles.

4. **Given** the balance-tuner agent invoked after B(state) falls below 0.6,
   **When** the agent returns a JSON patch changing a gene parameter by ≤ 10%,
   **Then** the patch is applied to `genome.db`, the old value is logged before
   the change, and `GenomeRegistry.gene_updated` signal fires.

5. **Given** a gene with `methylated = 1` and `methylation_timestamp` > 50 balance
   cycles ago,
   **When** the code-auditor agent runs,
   **Then** the gene is archived (status `dormant` in `genome.db`) with its full
   parameters preserved, and `gene_pruned` signal fires.

---

### Edge Cases

- What happens if `genome.db` is corrupted or missing at startup?
  GenomeRegistry MUST recreate the schema, log a warning, and start with an empty
  gene pool. The game MUST still be playable (fallback to `WalkPathBehavior`).

- What happens if a generated behavior gene script imports an unavailable class
  or calls a method that doesn't exist?
  `validate-gene.sh` MUST catch this before registration. If it passes validation
  but fails at runtime, the error rate threshold catches it and methylates within
  20 frames.

- What happens if the Bun orchestrator process exits mid-game?
  AgentBridge MUST detect the dead process on the next `queue_task()` call,
  mark `_orchestrator_available = false`, and degrade gracefully for the session.

- What happens if the player submits two prompts simultaneously before the first
  resolves?
  The second submit MUST be rejected with "Already synthesizing — please wait"
  while the first task is pending. No duplicate agent processes.

- What happens if the asset-gen agent produces a PNG larger than 50 KB or not
  32×32 px?
  The sprite loader MUST reject it, log a push_warning, and fall back to the
  ColorRect tint. The invalid file MUST be moved to `data/assets/invalid/` for
  developer review, not silently deleted.

- What happens if B(state) cannot recover above 0.5 after 20 rollback attempts?
  The game MUST pause the self-optimizer, emit a `balance_critical` signal logged
  to `metrics.db`, and display a Dashboard warning. Gameplay continues unaffected.

---

## Requirements

### Functional Requirements

- **FR-001**: The game MUST run via `godot4 project.godot` on Ubuntu 22.04 (WSL2 or
  native) with no additional manual setup steps beyond the documented install procedure.

- **FR-002**: A complete wave must be playable — creeps spawn, follow a path, take
  damage from towers, and either die or reduce player lives — using only Godot
  primitive shapes (no external sprite files required for core gameplay).

- **FR-003**: All GDScript game logic MUST be covered by GUT unit tests that run
  headlessly (`godot4 --headless -s addons/gut/gut_cmdln.gd`) with exit code 0.
  Test coverage MUST include: path following, tower targeting, projectile damage,
  gene registration, gene methylation, balance metric formula, and macro promotion.

- **FR-004**: The genome registry MUST use SQLite WAL mode for `genome.db` and MUST
  recreate the schema from `data/schema.sql` if the file is missing or empty.

- **FR-005**: Every gene MUST be validated by `scripts/validate-gene.sh` before
  insertion. Validation MUST check: valid GDScript syntax, correct base class
  (`BehaviorBase`), presence of `_evaluate(context) -> Dictionary` method, absence
  of filesystem/network calls, and max 100 iterations per tick (static analysis).

- **FR-006**: The behavior-synth agent MUST produce GDScript conforming to the
  `BehaviorBase` contract. The validate-gene script MUST reject any submission that
  fails this contract, with a specific error message indicating the violation.

- **FR-007**: `MadlibsMixer.mix(seed)` MUST be deterministic: identical seeds MUST
  always produce identical `AttributeDescriptor` values across sessions and platforms.

- **FR-008**: Generated PNG sprites MUST conform to the asset constraint (32×32 px,
  ≤ 16 colors, transparent background, < 50 KB). The sprite loader MUST enforce these
  constraints at load time and reject non-conforming files with a push_warning.

- **FR-009**: The PromptEditor MUST degrade gracefully when the agent orchestrator is
  unavailable: the Submit button remains visible and functional, spawning a creep with
  the default `WalkPathBehavior` instead of a synthesized one. An amber status message
  MUST explain the degradation.

- **FR-010**: The Bun orchestrator (`agents/orchestrator.ts`) MUST be independently
  startable and testable with `bun test` covering: task queuing, harness interface
  contract, and graceful shutdown.

- **FR-011**: `SelfOptimizer._compute_balance()` MUST implement exactly:
  `B = 0.4 × strategy_diversity + 0.4 × player_retention + 0.2 × asset_variety`
  and MUST produce identical floating-point results on all supported CPU architectures
  (x86-64 and ARM64). GUT test with fixed inputs MUST verify the formula numerically.

- **FR-012**: Any mutation applied by SelfOptimizer or the balance-tuner agent MUST
  be logged as a JSON patch to `metrics.db` before application, enabling full rollback.
  The rollback mechanism MUST restore the pre-patch value if B(state) < 0.5 within
  5 measurement cycles.

- **FR-013**: The game MUST function without agents running. Core gameplay (waves,
  towers, creeps, HUD) MUST be fully playable with zero agent processes active.
  Agentic features degrade gracefully; they MUST NOT block the game loop.

- **FR-014**: All autoloads MUST initialize in the correct dependency order:
  `GameState` → `GenomeRegistry` → `ThrottleController` → `AgentBridge`.
  Each autoload MUST emit a `ready` signal after initialization completes.
  Downstream autoloads MUST await upstream signals before referencing their APIs.

### Key Entities

- **Gene**: A versioned GDScript class extending `BehaviorBase`, registered in
  `genome.db` with metadata (type, name, path, parameters, execution stats, fitness
  score, provenance). Genes have lifecycle states: active → methylated → dormant.

- **AttributeDescriptor**: A deterministically generated combination of shape, color,
  sound, and effect vocabulary terms derived from a seed value via MadlibsMixer.
  Drives both visual identity (sprite selection / ColorRect tint) and mechanical
  effect gene assignment for any entity.

- **Wave**: A configured batch of Creep spawns with defined health, speed, and
  behavior gene assignments. WaveManager owns wave sequencing; GameState owns
  the wave counter and knows when all waves are complete.

- **Balance Metric**: A composite score B(state) ∈ [0.0, 1.0] computed from three
  sub-metrics (strategy_diversity via Gini coefficient, player_retention via session
  continuation rate, asset_variety via unique asset usage ratio). Stored per-tick
  in `metrics.db`. Drives rollback and agent-based optimization triggers.

- **MacroGene**: A behavior gene auto-generated by MacroCompiler from a detected
  repeated action sequence. Provenance = "macro-compiled". Identical in schema to
  hand-written genes; distinguished only by provenance field and lineage entry.

- **AgentTask**: A unit of work dispatched to the orchestrator with type
  (`behavior-synth` | `balance-tuner` | `asset-gen` | `code-auditor`), a prompt
  string, a priority integer, and a task ID. Results are returned via IPC to
  AgentBridge and dispatched as signals to the requesting UI component.

---

## Success Criteria

### Measurable Outcomes

- **SC-001**: `godot4 --headless -s addons/gut/gut_cmdln.gd` exits 0 with all GUT
  tests passing (0 failures) on Ubuntu 22.04 WSL2 on completion of each phase.

- **SC-002**: `bun test` in the `agents/` directory exits 0 with all TypeScript
  tests passing on completion of Phase 4.

- **SC-003**: A human tester can complete a 3-wave session (game open → play →
  win/lose state) in under 5 minutes on Ubuntu 22.04 WSL2 with no crashes,
  error dialogs, or manual interventions required.

- **SC-004**: A behavior prompt submitted to PromptEditor produces a new gene
  and spawns a live creep within 30 seconds on the target hardware (WSL2, Intel,
  16 GB RAM) with the Anthropic API key configured.

- **SC-005**: `MadlibsMixer.mix(42)` returns the same `AttributeDescriptor` on
  both x86-64 (Linux) and ARM64 (macOS M-series) — verified by GUT test with
  hardcoded expected output.

- **SC-006**: The asset-gen agent produces ≥ 36 tower sprites and ≥ 36 creep sprites
  in `data/assets/sprites/`, all conforming to the size/color/format constraints.

- **SC-007**: A 20-minute headless evolution smoke test (`scripts/evolution-smoke.gd`)
  produces ≥ 10 rows in `metrics.db:balance_metrics` with `composite_balance` ≥ 0.45
  throughout, and ≥ 1 row in `gene_lineage` (proving macro promotion ran).

- **SC-008**: Killing the Bun orchestrator mid-session causes no crash, error dialog,
  or gameplay interruption — only an amber status message in PromptEditor.

---

## Relationship to Feature 001

Feature 001 (`001-cross-platform-support`) adds `HardwareProfile.gd` as an autoload
and modifies `ThrottleController.gd`, `AgentBridge.gd`, and `Dashboard.tscn` — all
files created by this feature. Feature 001 is a pure additive modification layer.

**Merge order**: `002-game-foundation` fully merged → then `001-cross-platform-support`
branches from that merged state and modifies the newly created files.

Feature 001 tasks T003 (register HardwareProfile in `project.godot`) and T012
(add concurrency guard in `AgentBridge.gd`) are only meaningful after this feature
creates those files.
