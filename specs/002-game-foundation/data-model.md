# Data Model: Game Foundation — Playable Core to Self-Evolving System

**Phase 1 output for**: `specs/002-game-foundation/plan.md`
**Date**: 2026-03-10
**Sources**: PRD §5 (genome schema), §7 (entity classes), §8 (GameState)

---

## Entities

### Gene

Represents a GDScript behavior, attribute modifier, or visual effect that can be
assigned to towers or creeps. The fundamental unit of the self-evolution system.

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id` | TEXT | PRIMARY KEY, not null | Format: `{type}_{name}_{unix_timestamp}` |
| `type` | TEXT | NOT NULL, enum | `"behavior"` \| `"attribute"` \| `"effect"` |
| `name` | TEXT | NOT NULL | Human-readable gene name |
| `gdscript_path` | TEXT | nullable | `res://` or `user://` path to `.gd` file |
| `parameters` | JSON | nullable | Tunable parameters dict (validated on write) |
| `methylated` | INTEGER | DEFAULT 0 | `0` = active, `1` = dormant (soft-deleted) |
| `methylation_timestamp` | INTEGER | nullable | Unix timestamp when methylated |
| `created_at` | INTEGER | NOT NULL | Unix timestamp of registration |
| `last_executed_at` | INTEGER | nullable | Unix timestamp of most recent execution |
| `execution_count` | INTEGER | DEFAULT 0 | Total successful + failed executions |
| `error_count` | INTEGER | DEFAULT 0 | Total failed executions |
| `error_rate` | REAL | GENERATED | `error_count / execution_count` (0.0 if 0) |
| `fitness_score` | REAL | DEFAULT 0.5 | Balance contribution score [0.0, 1.0] |
| `provenance` | TEXT | nullable | `"procedural"` \| `"ai-generated"` \| `"player-authored"` \| `"macro-compiled"` |

**State transitions**:
```
registered (methylated=0)
    │
    ├── execution_count increments on each _evaluate() call
    ├── error_count increments on each failed execution
    │
    ▼ (error_rate > 0.05 OR explicit methylate_gene() call)
methylated (methylated=1, methylation_timestamp set)
    │
    ▼ (methylated for ≥ 50 balance cycles)
dormant (archived to genome.db status field, gene_pruned signal)
```

**Validation rules**:
- `id` must match pattern `^[a-z]+_[a-z_]+_[0-9]+$`
- `parameters` must be valid JSON when non-null
- `error_rate` must never be manually set (GENERATED ALWAYS)
- `methylation_timestamp` must be set atomically with `methylated = 1`

---

### GeneLineage

Tracks parent-child relationships between genes, enabling audit of how the gene pool
evolved over time.

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id` | INTEGER | PRIMARY KEY AUTOINCREMENT | |
| `child_gene_id` | TEXT | FK → genes.id, NOT NULL | The derived gene |
| `parent_gene_id` | TEXT | FK → genes.id, nullable | Source gene (null if no parent) |
| `mutation_type` | TEXT | NOT NULL | `"crossover"` \| `"mutation"` \| `"synthesis"` \| `"macro-compiled"` |
| `created_at` | INTEGER | NOT NULL | Unix timestamp |

---

### ExecutionLog

Per-frame record of each gene execution attempt. Used by GenomeRegistry to compute
`error_rate` and by code-auditor to identify candidates for methylation.

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id` | INTEGER | PRIMARY KEY AUTOINCREMENT | |
| `gene_id` | TEXT | FK → genes.id, NOT NULL | |
| `frame_number` | INTEGER | NOT NULL | `Engine.get_process_frames()` at execution time |
| `execution_time_ms` | REAL | NOT NULL | Time in milliseconds for `_evaluate()` |
| `success` | INTEGER | NOT NULL | `1` = success, `0` = error |
| `error_message` | TEXT | nullable | Error detail if `success = 0` |
| `timestamp` | INTEGER | NOT NULL | Unix timestamp |

**Retention policy**: Retain last 10,000 rows per gene; older rows deleted on insert
via trigger (prevents unbounded growth in long sessions).

---

### BalanceMetric

Snapshot of the three balance sub-metrics and their composite at a point in time.
Written by SelfOptimizer every `OPTIMIZATION_INTERVAL` ticks. Read by Dashboard
and code-auditor.

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id` | INTEGER | PRIMARY KEY AUTOINCREMENT | |
| `timestamp` | INTEGER | NOT NULL | Unix timestamp |
| `strategy_diversity` | REAL | [0.0, 1.0] | Gini coefficient of gene usage (inverted) |
| `player_retention` | REAL | [0.0, 1.0] | Session continuation rate |
| `asset_variety` | REAL | [0.0, 1.0] | Unique asset usage ratio |
| `composite_balance` | REAL | GENERATED | `0.4 × strategy_diversity + 0.4 × player_retention + 0.2 × asset_variety` |

**Constraint**: `composite_balance` must never be manually set — GENERATED ALWAYS.

---

### MutationLog

Audit trail of every parameter change applied by SelfOptimizer or balance-tuner agent.
Written BEFORE the change is applied; enables rollback.

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id` | INTEGER | PRIMARY KEY AUTOINCREMENT | |
| `gene_id` | TEXT | FK → genes.id, NOT NULL | Gene whose parameter was changed |
| `param_key` | TEXT | NOT NULL | Parameter name within gene's parameters JSON |
| `old_value` | REAL | NOT NULL | Value before mutation |
| `new_value` | REAL | NOT NULL | Value after mutation |
| `applied` | INTEGER | DEFAULT 0 | `1` = applied, `0` = pending/rolled-back |
| `rolled_back` | INTEGER | DEFAULT 0 | `1` = rolled back |
| `timestamp` | INTEGER | NOT NULL | Unix timestamp |

**Stored in**: `data/metrics.db` (separate from `genome.db` to avoid write contention
between SelfOptimizer and GenomeRegistry).

---

### PerformanceMetric

Throttle controller state snapshot for observability. Written by ThrottleController
via `log_performance_metrics()`. Read by Dashboard.

| Field | Type | Description |
|-------|------|-------------|
| `id` | INTEGER | PRIMARY KEY AUTOINCREMENT |
| `timestamp` | INTEGER | Unix timestamp |
| `tick_duration_ms` | REAL | Current simulation tick interval |
| `work_budget` | INTEGER | Max agent actions per tick |
| `frame_time_ms` | REAL | `Performance.TIME_PROCESS × 1000` |
| `memory_pressure` | REAL | `1.0 - (free / total)` [0.0, 1.0] |
| `stress` | REAL | Composite PID stress metric |

**Stored in**: `data/metrics.db`.

---

## In-Memory Entities (GDScript only, not persisted)

### AgentTask

Represents a unit of work in the AgentBridge queue. Not persisted — lives only for
the duration of a session.

| Field | Type | Description |
|-------|------|-------------|
| `id` | String | UUID-style: `"{type}_{timestamp}_{rand4}"` |
| `agent_type` | String | `"behavior-synth"` \| `"balance-tuner"` \| `"asset-gen"` \| `"code-auditor"` |
| `prompt` | String | Prompt text to send to agent |
| `priority` | int | Lower = higher priority (1=urgent, 8=low) |
| `result_path` | String | `user://agent-results/{id}.json` — polling target |
| `enqueued_at` | int | `Time.get_ticks_msec()` |

### AttributeDescriptor (MadlibsMixer output)

Generated deterministically from a seed; not stored in DB.

| Field | Type | Description |
|-------|------|-------------|
| `shape` | String | One of 6 shape vocab words |
| `color` | String | One of 6 color vocab words |
| `sound` | String | One of 6 sound vocab words |
| `effect` | String | One of 6 effect vocab words |
| `seed_value` | int | Source seed; same seed → same descriptor always |

**Computed properties**:
- `get_id() -> String`: `"{color}-{shape}-{sound}-{effect}"`
- `get_color_hex() -> String`: Maps color name to hex code (6 deterministic mappings)
- `get_sprite_path(entity_type) -> String`: `"res://data/assets/sprites/{entity_type}/{color}-{shape}.png"`

---

## Database Schema — `data/genome.db`

```sql
CREATE TABLE genes (
    id TEXT PRIMARY KEY,
    type TEXT NOT NULL CHECK(type IN ('behavior', 'attribute', 'effect')),
    name TEXT NOT NULL,
    gdscript_path TEXT,
    parameters TEXT,  -- JSON
    methylated INTEGER NOT NULL DEFAULT 0 CHECK(methylated IN (0, 1)),
    methylation_timestamp INTEGER,
    created_at INTEGER NOT NULL,
    last_executed_at INTEGER,
    execution_count INTEGER NOT NULL DEFAULT 0,
    error_count INTEGER NOT NULL DEFAULT 0,
    error_rate REAL GENERATED ALWAYS AS (
        CASE WHEN execution_count > 0
        THEN CAST(error_count AS REAL) / execution_count
        ELSE 0.0 END
    ) STORED,
    fitness_score REAL NOT NULL DEFAULT 0.5
        CHECK(fitness_score >= 0.0 AND fitness_score <= 1.0),
    provenance TEXT
);

CREATE TABLE gene_lineage (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    child_gene_id TEXT NOT NULL REFERENCES genes(id),
    parent_gene_id TEXT REFERENCES genes(id),
    mutation_type TEXT NOT NULL
        CHECK(mutation_type IN ('crossover','mutation','synthesis','macro-compiled')),
    created_at INTEGER NOT NULL
);

CREATE TABLE execution_log (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    gene_id TEXT NOT NULL REFERENCES genes(id),
    frame_number INTEGER NOT NULL,
    execution_time_ms REAL NOT NULL,
    success INTEGER NOT NULL CHECK(success IN (0, 1)),
    error_message TEXT,
    timestamp INTEGER NOT NULL
);

CREATE INDEX idx_genes_type ON genes(type);
CREATE INDEX idx_genes_methylated ON genes(methylated);
CREATE INDEX idx_genes_error_rate ON genes(error_rate);
CREATE INDEX idx_execution_log_gene ON execution_log(gene_id);
CREATE INDEX idx_execution_log_timestamp ON execution_log(timestamp);
```

---

## Database Schema — `data/metrics.db`

```sql
CREATE TABLE balance_metrics (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    timestamp INTEGER NOT NULL,
    strategy_diversity REAL NOT NULL CHECK(strategy_diversity >= 0.0 AND strategy_diversity <= 1.0),
    player_retention REAL NOT NULL CHECK(player_retention >= 0.0 AND player_retention <= 1.0),
    asset_variety REAL NOT NULL CHECK(asset_variety >= 0.0 AND asset_variety <= 1.0),
    composite_balance REAL GENERATED ALWAYS AS (
        0.4 * strategy_diversity + 0.4 * player_retention + 0.2 * asset_variety
    ) STORED
);

CREATE TABLE mutation_log (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    gene_id TEXT NOT NULL,
    param_key TEXT NOT NULL,
    old_value REAL NOT NULL,
    new_value REAL NOT NULL,
    applied INTEGER NOT NULL DEFAULT 0 CHECK(applied IN (0, 1)),
    rolled_back INTEGER NOT NULL DEFAULT 0 CHECK(rolled_back IN (0, 1)),
    timestamp INTEGER NOT NULL
);

CREATE TABLE performance_metrics (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    timestamp INTEGER NOT NULL,
    tick_duration_ms REAL NOT NULL,
    work_budget INTEGER NOT NULL,
    frame_time_ms REAL NOT NULL,
    memory_pressure REAL NOT NULL,
    stress REAL NOT NULL
);

CREATE INDEX idx_balance_timestamp ON balance_metrics(timestamp);
CREATE INDEX idx_mutation_gene ON mutation_log(gene_id);
CREATE INDEX idx_mutation_timestamp ON mutation_log(timestamp);
CREATE INDEX idx_perf_timestamp ON performance_metrics(timestamp);
```

---

## Godot Physics Layer Assignments

| Layer | Name | Used by |
|-------|------|---------|
| 1 | `world` | Static environment, Arena walls |
| 2 | `creeps` | Creep collision bodies |
| 3 | `towers` | Tower collision bodies |
| 4 | `projectiles` | Projectile Area2D |
| 5 | `tower_range` | Tower range Area2D sensor |

Tower targeting: `collision_mask = 0b00010` (layer 2 = creeps only)
Projectile hit: `collision_mask = 0b00010` (layer 2 = creeps only)
Creep nearby-tower query: `collision_mask = 0b00100` (layer 3 = towers)
