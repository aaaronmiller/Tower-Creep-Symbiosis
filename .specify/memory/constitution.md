<!--
SYNC IMPACT REPORT
==================
Version change: [TEMPLATE] → 1.0.0 (initial ratification)

Modified principles:
- [PRINCIPLE_1_NAME] → I. Clean Code & Efficiency (user-supplied principle)
- [PRINCIPLE_2_NAME] → II. Performance Budget
- [PRINCIPLE_3_NAME] → III. Agentic Safety
- [PRINCIPLE_4_NAME] → IV. Self-Evolution Integrity
- [PRINCIPLE_5_NAME] → V. GDScript-First

Added sections:
- Technical Constraints (replaces [SECTION_2_NAME])
- Development Workflow (replaces [SECTION_3_NAME])
- Governance (filled from template)

Removed sections: None

Templates checked:
- ✅ .specify/templates/plan-template.md — Constitution Check section present; aligns with principles
- ✅ .specify/templates/spec-template.md — Scope and requirements sections align
- ✅ .specify/templates/tasks-template.md — Task phases and parallelism align with workflow principle
- ✅ .specify/templates/agent-file-template.md — No outdated references found

Deferred TODOs: None — all placeholders resolved.
-->

# Tower-Creep Symbiosis Constitution

## Core Principles

### I. Clean Code & Efficiency

All code MUST be clean, readable, and efficient. Prefer the simplest solution that satisfies
the requirement. Complexity MUST be justified by a concrete need — not anticipated future use.

- MUST NOT introduce abstractions, helpers, or wrappers that serve only one call site
- MUST NOT add error handling, validation, or fallbacks for scenarios the system guarantees
  cannot occur
- MUST remove dead code, unused variables, and orphaned files immediately upon discovery
- SHOULD keep functions short and single-purpose; long functions are a signal to decompose
- Rationale: Self-evolving systems accumulate entropy fast. Clean baselines make agent-generated
  mutations easier to audit, prune, and reason about.

### II. Performance Budget

The game loop MUST sustain 60 FPS (≤ 16.67 ms per frame) on the target hardware
(Apple M3 Pro Max, 36 GB unified memory). Budget allocations are non-negotiable:

| Subsystem         | Budget |
|-------------------|--------|
| Physics/Simulation | ≤ 4 ms |
| Agent Execution   | ≤ 2 ms (amortized across frames) |
| Rendering         | ≤ 8 ms |
| Audio             | ≤ 1 ms |
| Headroom          | ≤ 1.67 ms |

- MUST profile before optimizing — measure first, guess never
- MUST NOT add per-frame allocations in hot paths (physics, rendering)
- Rationale: Agentic processes run alongside the game loop. Overrunning the budget degrades
  player experience and corrupts timing-sensitive balance metrics.

### III. Agentic Safety

All agent-generated mutations to the codebase or gene pool MUST be bounded, validated,
and reversible before they affect live gameplay.

- MUST NOT allow agents to modify core game logic (game loop, physics, save format)
- MUST constrain gene parameter changes to ≤ 10% per iteration
- MUST validate every generated gene against `validate-gene.sh` before insertion
  into the genome registry
- MUST enforce API budget via `cost-limiter.sh` hook; runaway agents MUST be killed
- Rationale: Unconstrained self-modification breaks reproducibility and can corrupt player
  save data. Bounded mutations preserve auditability.

### IV. Self-Evolution Integrity

The balance metric B(state) MUST remain ≥ 0.6 at all times:

> B(state) = 0.4 × strategy_diversity + 0.4 × player_retention + 0.2 × asset_variety

- Dormant genes (unused for ≥ 50 balance cycles) MUST be archived to `data/genome.db`
  with status `dormant`, not deleted
- Balance-tuner agent MUST log every parameter change as a JSON patch before applying it
- MUST roll back any mutation that causes B(state) to drop below 0.5 within 5 cycles
- Rationale: The genetic analogy is only meaningful if the gene pool stays healthy.
  Unchecked drift produces degenerate strategies that destroy player engagement.

### V. GDScript-First

Core game logic MUST be written in GDScript. TypeScript (Bun runtime) is reserved
exclusively for the agent orchestration layer.

- MUST NOT use GDExtension or native modules unless a GDScript implementation is provably
  incapable of meeting the performance budget
- MUST NOT duplicate business logic across GDScript and TypeScript layers
- Agent orchestrator (`agents/orchestrator.ts`) MUST communicate with the game only via
  the IPC bridge (`godot/autoloads/AgentBridge.gd`)
- Rationale: GDScript hot-reload enables live gene injection without recompilation.
  Crossing the language boundary unnecessarily increases surface area for bugs and breaks
  the hot-reload guarantee.

## Technical Constraints

The following constraints apply across all features and are not subject to per-feature
overrides without a constitution amendment:

- **Target runtime**: Godot 4.3 (native ARM64); no Rosetta, no emulation layers
- **Orchestration runtime**: Bun (TypeScript); Node.js MUST NOT be substituted
- **Persistence**: SQLite with WAL mode for `genome.db` and `metrics.db`; no external DB
- **Asset formats**: Sprites as PNG (32×32 or 64×64, 16-color palette, transparent BG);
  audio as OGG Vorbis (< 100 KB per file)
- **License compliance**: All dependencies MUST be MIT, Apache 2.0, or BSD licensed;
  GPL dependencies are prohibited (Godot itself is MIT)
- **Data integrity**: CRDT-based shared state MUST be the single source of truth for
  entity positions, gene pool state, and balance metrics

## Development Workflow

- Feature work MUST follow the Speckit workflow: specify → plan → tasks → implement
- Every task MUST be independently testable and deliverable as an MVP increment
- Code review MUST verify compliance with Principles I–V before merge
- Complexity violations MUST be documented in the plan's Complexity Tracking table with a
  concrete justification; undocumented violations block merge
- Agents MUST be run headless (`--headless` flag); interactive agent sessions are for
  development and debugging only
- Commits MUST be atomic: one logical change per commit; do not bundle unrelated fixes

## Governance

This constitution supersedes all other development practices. Any conflict between this
document and a feature spec, plan, or task list is resolved in favor of the constitution.

**Amendment procedure:**
1. Open a PR with the proposed change to this file
2. Describe the motivation and impact in the PR body
3. Update `CONSTITUTION_VERSION` and `LAST_AMENDED_DATE` per the versioning policy
4. All active feature specs and plans MUST be re-evaluated against the new principles
   before the amendment is merged

**Versioning policy:**
- MAJOR bump: backward-incompatible governance changes (principle removals, redefinitions)
- MINOR bump: new principle or section added, material guidance expanded
- PATCH bump: clarifications, wording fixes, non-semantic refinements

**Compliance review:**
- Every PR's "Constitution Check" section in `plan.md` MUST be completed and pass
- The balance-tuner and code-auditor agents MUST run a compliance check before any
  gene promotion to stable status

**Version**: 1.0.0 | **Ratified**: 2026-02-28 | **Last Amended**: 2026-02-28
