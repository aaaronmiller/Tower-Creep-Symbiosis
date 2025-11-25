# TOWER-CREEP SYMBIOSIS

## Technical Product Requirements Document

**Document Classification:** Implementation Architecture  
**Target Hardware:** Apple M3 Pro Max (36GB Unified Memory)  
**Game Engine:** Godot 4.3 (Native ARM64)  
**Orchestration:** Claude Code Headless via CIO Pattern

---

## EXECUTIVE SUMMARY

Tower-Creep Symbiosis is a self-evolving PvPvE game where players control both defensive towers AND offensive creeps through natural language prompting. The game adapts its simulation speed to available hardware resources, progressively optimizes redundant operations, and evolves its own content through federated agentic compute.

**Core Innovation:** The game treats itself as a living codebase—non-functional behaviors become "dormant genes," successful patterns are "expressed," and the entire system optimizes toward procedural balance through measured feedback loops.

---

## 1. HARDWARE CONSTRAINTS & ENGINE SELECTION

### 1.1 Target Hardware Specification

|Component|Specification|Allocation|
|---|---|---|
|CPU|M3 Pro Max (12 cores: 6P + 6E)|4 cores game, 4 cores agents, 4 cores background|
|GPU|18-core Apple GPU|12 cores render, 6 cores compute|
|Memory|36GB Unified|~8GB game, ~4GB models, ~24GB headroom|
|ANE|16-core Neural Engine|Validation models, balance inference|
|Storage|NVMe SSD|Asset streaming, SQLite WAL|

### 1.2 Engine Selection Rationale: Godot 4.3

**Selection Criteria Analysis:**

|Engine|ARM64 Native|Metal|Scriptable|Self-Evolution|Verdict|
|---|---|---|---|---|---|
|Godot 4.3|✓ Native|✓ MoltenVK|✓ GDScript|✓ Hot-reload|**SELECTED**|
|Bevy|✓ Native|✓ wgpu|✗ Compiled|✗ Requires rebuild|Rejected|
|Unity|✓ Rosetta|✓ Metal|✓ C#|✗ License cost|Rejected|
|Unreal|✗ x86 only|✓ Metal|✗ C++|✗ Too heavy|Rejected|

**Godot 4.3 Advantages for Self-Evolution:**

1. **GDScript Hot-Reload:** Modify behavior at runtime without recompilation
2. **Scene Inheritance:** "Gene" scenes extend base scenes, enabling modular evolution
3. **Resource System:** JSON-like .tres files for serializable agent parameters
4. **Headless Mode:** `--headless` flag enables server-side simulation
5. **Native ARM64:** Ships with Apple Silicon binaries, no Rosetta overhead
6. **Open Source:** MIT license, full source access for deep integration

### 1.3 Performance Budget

```
Target Frame Time: 16.67ms (60 FPS)
├── Physics/Simulation: 4ms max
├── Agent Execution: 2ms max (amortized across frames)
├── Rendering: 8ms max
├── Audio: 1ms max
└── Headroom: 1.67ms (for GC, OS interrupts)
```

---

## 2. CORE ARCHITECTURE

### 2.1 System Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                        TOWER-CREEP SYMBIOSIS                        │
├─────────────────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐ │
│  │   GODOT 4   │  │  THROTTLE   │  │   GENOME    │  │    AGENT    │ │
│  │   RUNTIME   │◄─┤ CONTROLLER  │◄─┤   REGISTRY  │◄─┤ ORCHESTRATOR│ │
│  │ (Game Loop) │  │  (PID Loop) │  │  (SQLite)   │  │(Claude Code)│ │
│  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘ │
│         │                │                │                │        │
│         ▼                ▼                ▼                ▼        │
│  ┌─────────────────────────────────────────────────────────────────┐│
│  │                      SHARED STATE (CRDT)                        ││
│  │  • Entity Positions  • Gene Pool  • Balance Metrics  • Assets   ││
│  └─────────────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────────────┘
```

### 2.2 Directory Structure

```
tower-creep-symbiosis/
├── project.godot                 # Godot project config
├── CLAUDE.md                     # Agent persona definition
├── .claude/
│   ├── mcp.json                  # MCP tool configuration
│   └── hooks/
│       └── cost-limiter.sh       # API budget enforcement
├── godot/
│   ├── main.gd                   # Entry point
│   ├── autoloads/
│   │   ├── GameState.gd          # Global state singleton
│   │   ├── ThrottleController.gd # PID speed controller
│   │   ├── GenomeRegistry.gd     # Gene pool manager
│   │   └── AgentBridge.gd        # Claude Code IPC
│   ├── entities/
│   │   ├── Tower.tscn            # Base tower scene
│   │   ├── Creep.tscn            # Base creep scene
│   │   └── Projectile.tscn       # Base projectile scene
│   ├── genes/
│   │   ├── behaviors/            # Behavior tree genes
│   │   ├── attributes/           # Stat modifier genes
│   │   └── effects/              # Visual/audio effect genes
│   └── ui/
│       ├── PromptEditor.tscn     # Natural language input
│       └── Dashboard.tscn        # Performance metrics
├── agents/
│   ├── arsenal/
│   │   ├── asset-gen/
│   │   │   ├── CLAUDE.md         # Asset generator persona
│   │   │   └── .claude/mcp.json
│   │   ├── balance-tuner/
│   │   │   ├── CLAUDE.md         # Balance optimizer persona
│   │   │   └── .claude/mcp.json
│   │   ├── behavior-synth/
│   │   │   ├── CLAUDE.md         # Behavior tree generator
│   │   │   └── .claude/mcp.json
│   │   └── code-auditor/
│   │       ├── CLAUDE.md         # Gene pruning persona
│   │       └── .claude/mcp.json
│   └── orchestrator.ts           # Bun-based agent scheduler
├── data/
│   ├── genome.db                 # SQLite gene registry
│   ├── metrics.db                # Balance/performance logs
│   └── assets/
│       ├── sprites/              # Generated sprite atlases
│       └── audio/                # Generated sound effects
└── scripts/
    ├── deploy-agent.sh           # CIO pattern launcher
    └── validate-gene.sh          # Gene verification script
```

---

## 3. AGENTIC ORCHESTRATION (CIO PATTERN)

### 3.1 Context-Injected Orchestration Implementation

The CIO pattern separates **Capability** (static agent templates) from **Intent** (dynamic runtime prompts). Each agent "wakes up" inside a pre-configured context and executes the specific task injected via headless command.

**Agent Arsenal Structure:**

```
agents/arsenal/
├── asset-gen/
│   ├── CLAUDE.md
│   │   """
│   │   You are the Asset Generator. You create pixel art sprites
│   │   and sound effects for Tower-Creep Symbiosis.
│   │   
│   │   CONSTRAINTS:
│   │   - Output sprites as PNG, 32x32 or 64x64 only
│   │   - Output audio as OGG Vorbis, <100KB per file
│   │   - All sprites MUST have transparent backgrounds
│   │   - Use 16-color palettes for retro aesthetic
│   │   
│   │   TOOLS AVAILABLE:
│   │   - filesystem (read/write to data/assets/)
│   │   - image generation (via stable-diffusion MCP)
│   │   - audio synthesis (via tone.js MCP)
│   │   
│   │   OUTPUT FORMAT:
│   │   - Save asset to data/assets/{type}/{uuid}.{ext}
│   │   - Return JSON: {"path": "...", "metadata": {...}}
│   │   """
│   └── .claude/
│       └── mcp.json
│           {
│             "mcpServers": {
│               "filesystem": {"command": "npx", "args": ["-y", "@anthropic/mcp-filesystem"]},
│               "stable-diffusion": {"command": "python", "args": ["mcp_sd.py"]}
│             }
│           }
│
├── balance-tuner/
│   ├── CLAUDE.md
│   │   """
│   │   You are the Balance Tuner. You analyze gameplay metrics
│   │   and adjust gene parameters to optimize procedural balance.
│   │   
│   │   BALANCE OBJECTIVE:
│   │   B(state) = 0.4 * strategy_diversity + 0.4 * player_retention + 0.2 * asset_variety
│   │   
│   │   CONSTRAINTS:
│   │   - Only modify parameters in genes/attributes/
│   │   - Changes must be ≤10% per iteration
│   │   - Never modify core game logic
│   │   
│   │   OUTPUT FORMAT:
│   │   - JSON patch: {"gene_id": "...", "param": "...", "old": X, "new": Y}
│   │   """
│   └── .claude/mcp.json
│
├── behavior-synth/
│   ├── CLAUDE.md
│   │   """
│   │   You are the Behavior Synthesizer. You convert natural
│   │   language prompts into GDScript behavior trees.
│   │   
│   │   INPUT: Player prompt (e.g., "flanking scout that avoids towers")
│   │   OUTPUT: GDScript class extending BehaviorBase
│   │   
│   │   CONSTRAINTS:
│   │   - Must extend res://godot/genes/behaviors/BehaviorBase.gd
│   │   - Must implement _evaluate(entity, delta) -> Dictionary
│   │   - No infinite loops, max 100 iterations per tick
│   │   - No filesystem access, no network calls
│   │   """
│   └── .claude/mcp.json
│
└── code-auditor/
    ├── CLAUDE.md
    │   """
    │   You are the Code Auditor. You analyze gene performance
    │   and recommend methylation (dormancy) or pruning.
    │   
    │   METHYLATION CRITERIA:
    │   - Gene execution count = 0 over 1000 turns → METHYLATE
    │   - Gene error rate > 5% → METHYLATE
    │   - Gene causes >10ms execution time → METHYLATE
    │   
    │   PRUNING CRITERIA:
    │   - Methylated for >30 days → PRUNE
    │   
    │   OUTPUT FORMAT:
    │   - JSON: {"action": "methylate|prune", "gene_id": "...", "reason": "..."}
    │   """
    └── .claude/mcp.json
```

### 3.2 Orchestrator Implementation (Bun + TypeScript)

```typescript
// agents/orchestrator.ts
import { spawn } from "bun";
import { Database } from "bun:sqlite";

interface AgentTask {
  id: string;
  agentType: "asset-gen" | "balance-tuner" | "behavior-synth" | "code-auditor";
  prompt: string;
  priority: number;
  scheduledFrame: number;
}

interface AgentResult {
  taskId: string;
  success: boolean;
  output: unknown;
  executionTimeMs: number;
}

const ARSENAL_PATH = "./agents/arsenal";
const db = new Database("./data/metrics.db");

// Whirlybird scheduling: deterministic "random" based on frame hash
function computeAgentUrgency(task: AgentTask, frameHash: bigint): number {
  const baseUrgency = task.priority * 100;
  const hashOffset = Number(frameHash % 50n) - 25; // ±25 variance
  return baseUrgency + hashOffset;
}

// Deploy agent using CIO pattern
async function deployAgent(task: AgentTask): Promise<AgentResult> {
  const sessionDir = `/tmp/tcs-agent-${task.id}`;
  const arsenalDir = `${ARSENAL_PATH}/${task.agentType}`;
  
  // 1. Isolate: Create ephemeral session directory
  await Bun.spawn(["mkdir", "-p", sessionDir]).exited;
  
  // 2. Inject: Copy agent template into session
  await Bun.spawn(["cp", "-r", `${arsenalDir}/.`, sessionDir]).exited;
  
  // 3. Execute: Run Claude Code headless with injected prompt
  const startTime = performance.now();
  const proc = spawn({
    cmd: [
      "claude",
      "-p", task.prompt,
      "--output-format", "stream-json",
      "--max-tokens", "4096"
    ],
    cwd: sessionDir,
    stdout: "pipe",
    stderr: "pipe"
  });
  
  // 4. Monitor: Collect output
  const stdout = await new Response(proc.stdout).text();
  const exitCode = await proc.exited;
  const executionTimeMs = performance.now() - startTime;
  
  // 5. Cleanup
  await Bun.spawn(["rm", "-rf", sessionDir]).exited;
  
  // Parse JSON output
  let output: unknown = null;
  try {
    // Extract final JSON from stream
    const lines = stdout.split("\n").filter(l => l.trim());
    const lastJson = lines[lines.length - 1];
    output = JSON.parse(lastJson);
  } catch {
    output = { raw: stdout };
  }
  
  return {
    taskId: task.id,
    success: exitCode === 0,
    output,
    executionTimeMs
  };
}

// Main scheduler loop
export async function runOrchestrator(taskQueue: AgentTask[], frameNumber: bigint) {
  // Compute frame hash for deterministic scheduling
  const frameHash = BigInt(`0x${Bun.hash(frameNumber.toString()).toString(16)}`);
  
  // Sort by urgency (deterministic "whirlybird" scheduling)
  const sortedTasks = [...taskQueue].sort((a, b) => 
    computeAgentUrgency(b, frameHash) - computeAgentUrgency(a, frameHash)
  );
  
  // Execute top-priority task (one per frame to avoid blocking)
  if (sortedTasks.length > 0) {
    const task = sortedTasks[0];
    const result = await deployAgent(task);
    
    // Log to metrics DB
    db.run(
      `INSERT INTO agent_executions (task_id, agent_type, success, execution_ms, frame)
       VALUES (?, ?, ?, ?, ?)`,
      [result.taskId, task.agentType, result.success ? 1 : 0, result.executionTimeMs, Number(frameNumber)]
    );
    
    return result;
  }
  
  return null;
}
```

### 3.3 Godot-Agent Bridge (GDScript)

```gdscript
# godot/autoloads/AgentBridge.gd
extends Node

signal agent_result_received(task_id: String, result: Dictionary)

var _orchestrator_process: int = -1
var _task_queue: Array[Dictionary] = []
var _pending_tasks: Dictionary = {}

func _ready() -> void:
    # Start Bun orchestrator as child process
    var args := ["bun", "run", "agents/orchestrator.ts"]
    _orchestrator_process = OS.execute("bun", ["run", "agents/orchestrator.ts"], [], true)

func queue_task(agent_type: String, prompt: String, priority: int = 5) -> String:
    var task_id := str(Time.get_unix_time_from_system()) + "_" + str(randi())
    var task := {
        "id": task_id,
        "agentType": agent_type,
        "prompt": prompt,
        "priority": priority,
        "scheduledFrame": Engine.get_process_frames()
    }
    _task_queue.append(task)
    _pending_tasks[task_id] = task
    return task_id

func _process(_delta: float) -> void:
    # Check for completed tasks via IPC (simplified: file-based)
    var result_file := "data/agent_results.json"
    if FileAccess.file_exists(result_file):
        var file := FileAccess.open(result_file, FileAccess.READ)
        var json := JSON.parse_string(file.get_as_text())
        file.close()
        DirAccess.remove_absolute(result_file)
        
        if json and json.has("taskId"):
            emit_signal("agent_result_received", json["taskId"], json)
            _pending_tasks.erase(json["taskId"])

# Convenience methods for common agent tasks
func generate_asset(description: String) -> String:
    return queue_task("asset-gen", "Generate: " + description, 3)

func synthesize_behavior(player_prompt: String) -> String:
    return queue_task("behavior-synth", player_prompt, 8)

func request_balance_tuning() -> String:
    var metrics := _get_current_metrics()
    return queue_task("balance-tuner", "Optimize balance given: " + JSON.stringify(metrics), 2)

func request_code_audit() -> String:
    return queue_task("code-auditor", "Audit genes for methylation/pruning", 1)

func _get_current_metrics() -> Dictionary:
    return {
        "strategy_diversity": GenomeRegistry.get_strategy_diversity(),
        "player_retention": GameState.get_player_retention(),
        "asset_variety": GenomeRegistry.get_asset_variety(),
        "error_rates": GenomeRegistry.get_gene_error_rates()
    }
```

---

## 4. ADAPTIVE SPEED THROTTLING

### 4.1 PID Controller for Simulation Speed

The game runs "as fast as it can" until stress is detected, then backs off. This creates the "steam locomotive throttle" effect—maximum speed within safe operating parameters.

```gdscript
# godot/autoloads/ThrottleController.gd
extends Node

# PID controller gains (tuned for stability)
const KP := 0.5   # Proportional gain
const KI := 0.1   # Integral gain
const KD := 0.05  # Derivative gain

# Target setpoints
const TARGET_CPU_UTILIZATION := 0.70  # 70% CPU target
const TARGET_FRAME_TIME_MS := 14.0    # Leave 2.67ms headroom from 16.67ms
const TARGET_MEMORY_PRESSURE := 0.60  # 60% memory target

# Control variables
var tick_duration_ms := 100.0         # Start slow (100ms ticks)
var min_tick_duration_ms := 16.0      # Fastest: 60 ticks/sec
var max_tick_duration_ms := 500.0     # Slowest: 2 ticks/sec
var work_budget_per_tick := 10        # Max agent actions per tick

# PID state
var _integral_error := 0.0
var _previous_error := 0.0
var _last_adjustment_time := 0.0

# Metrics (updated externally)
var current_cpu_utilization := 0.0
var current_frame_time_ms := 0.0
var current_memory_pressure := 0.0
var current_error_rate := 0.0

signal tick_duration_changed(new_duration_ms: float)
signal work_budget_changed(new_budget: int)

func _ready() -> void:
    # Start performance monitoring timer
    var timer := Timer.new()
    timer.wait_time = 0.5  # Adjust every 500ms
    timer.timeout.connect(_adjust_throttle)
    add_child(timer)
    timer.start()

func _adjust_throttle() -> void:
    # Compute composite stress metric (0.0 = no stress, 1.0 = max stress)
    var stress := _compute_stress()
    
    # PID control
    var error := TARGET_CPU_UTILIZATION - stress  # Positive = can go faster
    _integral_error = clampf(_integral_error + error * 0.5, -1.0, 1.0)
    var derivative := (error - _previous_error) / 0.5
    _previous_error = error
    
    var adjustment := KP * error + KI * _integral_error + KD * derivative
    
    # Apply adjustment to tick duration (negative adjustment = slower)
    tick_duration_ms = clampf(
        tick_duration_ms * (1.0 - adjustment * 0.2),
        min_tick_duration_ms,
        max_tick_duration_ms
    )
    
    # Scale work budget with speed
    var speed_ratio := (max_tick_duration_ms - tick_duration_ms) / (max_tick_duration_ms - min_tick_duration_ms)
    work_budget_per_tick = int(lerp(5, 50, speed_ratio))
    
    emit_signal("tick_duration_changed", tick_duration_ms)
    emit_signal("work_budget_changed", work_budget_per_tick)
    
    # Log metrics
    _log_throttle_state()

func _compute_stress() -> float:
    # Weighted stress computation
    var cpu_stress := current_cpu_utilization / TARGET_CPU_UTILIZATION
    var frame_stress := current_frame_time_ms / TARGET_FRAME_TIME_MS
    var memory_stress := current_memory_pressure / TARGET_MEMORY_PRESSURE
    var error_stress := current_error_rate * 5.0  # Penalize errors heavily
    
    return clampf(
        0.4 * cpu_stress + 0.3 * frame_stress + 0.2 * memory_stress + 0.1 * error_stress,
        0.0, 2.0
    )

func _log_throttle_state() -> void:
    var metrics := {
        "tick_duration_ms": tick_duration_ms,
        "work_budget": work_budget_per_tick,
        "cpu_utilization": current_cpu_utilization,
        "frame_time_ms": current_frame_time_ms,
        "memory_pressure": current_memory_pressure,
        "stress": _compute_stress()
    }
    GenomeRegistry.log_performance_metrics(metrics)

# Called by main loop to get current tick timing
func get_tick_interval() -> float:
    return tick_duration_ms / 1000.0

func get_work_budget() -> int:
    return work_budget_per_tick
```

### 4.2 Resource Monitoring (macOS-Specific)

```gdscript
# godot/autoloads/ResourceMonitor.gd
extends Node

var _last_cpu_sample := 0.0
var _last_memory_sample := 0

func _ready() -> void:
    var timer := Timer.new()
    timer.wait_time = 0.25  # Sample every 250ms
    timer.timeout.connect(_sample_resources)
    add_child(timer)
    timer.start()

func _sample_resources() -> void:
    # CPU utilization via sysctl (macOS)
    var output := []
    OS.execute("sysctl", ["-n", "vm.loadavg"], output, true)
    if output.size() > 0:
        # Parse "{ 1.50 1.25 1.00 }" format
        var parts := (output[0] as String).strip_edges().trim_prefix("{ ").trim_suffix(" }").split(" ")
        if parts.size() >= 1:
            var load_1min := float(parts[0])
            # Normalize to 0-1 based on core count (12 cores)
            ThrottleController.current_cpu_utilization = load_1min / 12.0
    
    # Memory pressure via vm_stat (macOS)
    output.clear()
    OS.execute("vm_stat", [], output, true)
    if output.size() > 0:
        var vm_stat := output[0] as String
        # Parse "Pages free: 12345" etc.
        var free_pages := _parse_vm_stat(vm_stat, "Pages free")
        var total_pages := _parse_vm_stat(vm_stat, "Pages wired down") + \
                          _parse_vm_stat(vm_stat, "Pages active") + \
                          _parse_vm_stat(vm_stat, "Pages inactive") + \
                          free_pages
        if total_pages > 0:
            ThrottleController.current_memory_pressure = 1.0 - (float(free_pages) / float(total_pages))
    
    # Frame time from engine
    ThrottleController.current_frame_time_ms = Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0

func _parse_vm_stat(output: String, key: String) -> int:
    var regex := RegEx.new()
    regex.compile(key + ":\\s+(\\d+)")
    var result := regex.search(output)
    if result:
        return int(result.get_string(1))
    return 0
```

---

## 5. GENOME REGISTRY & DNA MODEL

### 5.1 Gene Schema (SQLite)

```sql
-- data/genome.db

CREATE TABLE genes (
    id TEXT PRIMARY KEY,
    type TEXT NOT NULL,                    -- 'behavior', 'attribute', 'effect'
    name TEXT NOT NULL,
    gdscript_path TEXT,                    -- Path to .gd file
    parameters JSON,                       -- Tunable parameters
    methylated INTEGER DEFAULT 0,          -- 0=active, 1=dormant
    methylation_timestamp INTEGER,         -- When methylated
    created_at INTEGER NOT NULL,
    last_executed_at INTEGER,
    execution_count INTEGER DEFAULT 0,
    error_count INTEGER DEFAULT 0,
    error_rate REAL GENERATED ALWAYS AS (
        CASE WHEN execution_count > 0 
        THEN CAST(error_count AS REAL) / execution_count 
        ELSE 0 END
    ) STORED,
    fitness_score REAL DEFAULT 0.5,        -- 0.0-1.0 balance contribution
    provenance TEXT                        -- 'procedural', 'ai-generated', 'player-authored'
);

CREATE TABLE gene_lineage (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    child_gene_id TEXT REFERENCES genes(id),
    parent_gene_id TEXT REFERENCES genes(id),
    mutation_type TEXT,                    -- 'crossover', 'mutation', 'synthesis'
    created_at INTEGER NOT NULL
);

CREATE TABLE execution_log (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    gene_id TEXT REFERENCES genes(id),
    frame_number INTEGER,
    execution_time_ms REAL,
    success INTEGER,
    error_message TEXT,
    timestamp INTEGER NOT NULL
);

CREATE TABLE balance_metrics (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    timestamp INTEGER NOT NULL,
    strategy_diversity REAL,               -- Gini coefficient of strategy usage
    player_retention REAL,                 -- Session continuation rate
    asset_variety REAL,                    -- Unique asset usage ratio
    composite_balance REAL GENERATED ALWAYS AS (
        0.4 * strategy_diversity + 0.4 * player_retention + 0.2 * asset_variety
    ) STORED
);

CREATE INDEX idx_genes_type ON genes(type);
CREATE INDEX idx_genes_methylated ON genes(methylated);
CREATE INDEX idx_execution_log_gene ON execution_log(gene_id);
CREATE INDEX idx_balance_metrics_time ON balance_metrics(timestamp);
```

### 5.2 Gene Registry Manager (GDScript)

```gdscript
# godot/autoloads/GenomeRegistry.gd
extends Node

const DB_PATH := "user://genome.db"

var _db: SQLite = null
var _loaded_genes: Dictionary = {}  # gene_id -> GDScript instance
var _methylated_cache: Dictionary = {}  # gene_id -> true

signal gene_activated(gene_id: String)
signal gene_methylated(gene_id: String, reason: String)
signal gene_pruned(gene_id: String)

func _ready() -> void:
    _db = SQLite.new()
    _db.path = DB_PATH
    _db.open_db()
    _initialize_schema()
    _load_active_genes()

func _initialize_schema() -> void:
    # Schema creation (see SQL above)
    var schema_sql := FileAccess.get_file_as_string("res://data/schema.sql")
    for statement in schema_sql.split(";"):
        if statement.strip_edges().length() > 0:
            _db.query(statement)

func _load_active_genes() -> void:
    var result := _db.select_rows("genes", "methylated = 0", ["id", "gdscript_path", "parameters"])
    for row in result:
        _load_gene(row["id"], row["gdscript_path"], row["parameters"])

func _load_gene(gene_id: String, gdscript_path: String, parameters: String) -> bool:
    if not FileAccess.file_exists(gdscript_path):
        push_warning("Gene script not found: %s" % gdscript_path)
        return false
    
    var script := load(gdscript_path) as GDScript
    if script == null:
        _record_error(gene_id, "Failed to load script")
        return false
    
    var instance = script.new()
    if instance.has_method("initialize"):
        var params := JSON.parse_string(parameters) if parameters else {}
        instance.initialize(params)
    
    _loaded_genes[gene_id] = instance
    emit_signal("gene_activated", gene_id)
    return true

func execute_gene(gene_id: String, context: Dictionary) -> Variant:
    if gene_id in _methylated_cache:
        return null  # Dormant gene, skip execution
    
    if not gene_id in _loaded_genes:
        push_warning("Gene not loaded: %s" % gene_id)
        return null
    
    var instance = _loaded_genes[gene_id]
    var start_time := Time.get_ticks_usec()
    var result = null
    var success := true
    var error_msg := ""
    
    # Sandboxed execution with timeout
    if instance.has_method("execute"):
        # Note: GDScript doesn't have true timeout, we rely on cooperative multitasking
        result = instance.execute(context)
    else:
        error_msg = "Gene missing execute() method"
        success = false
    
    var execution_time_ms := (Time.get_ticks_usec() - start_time) / 1000.0
    
    # Log execution
    _db.insert_row("execution_log", {
        "gene_id": gene_id,
        "frame_number": Engine.get_process_frames(),
        "execution_time_ms": execution_time_ms,
        "success": 1 if success else 0,
        "error_message": error_msg,
        "timestamp": Time.get_unix_time_from_system()
    })
    
    # Update gene stats
    _db.query("UPDATE genes SET execution_count = execution_count + 1, last_executed_at = %d WHERE id = '%s'" % [
        Time.get_unix_time_from_system(), gene_id
    ])
    
    if not success:
        _record_error(gene_id, error_msg)
    
    return result

func _record_error(gene_id: String, message: String) -> void:
    _db.query("UPDATE genes SET error_count = error_count + 1 WHERE id = '%s'" % gene_id)
    
    # Check for automatic methylation threshold
    var result := _db.select_rows("genes", "id = '%s'" % gene_id, ["error_rate"])
    if result.size() > 0 and result[0]["error_rate"] > 0.05:
        methylate_gene(gene_id, "Error rate exceeded 5%")

func methylate_gene(gene_id: String, reason: String) -> void:
    _db.query("UPDATE genes SET methylated = 1, methylation_timestamp = %d WHERE id = '%s'" % [
        Time.get_unix_time_from_system(), gene_id
    ])
    
    # Unload from memory
    if gene_id in _loaded_genes:
        _loaded_genes.erase(gene_id)
    _methylated_cache[gene_id] = true
    
    emit_signal("gene_methylated", gene_id, reason)
    print("[GenomeRegistry] Methylated gene %s: %s" % [gene_id, reason])

func prune_gene(gene_id: String) -> void:
    # Archive before deletion
    var gene_data := _db.select_rows("genes", "id = '%s'" % gene_id, ["*"])
    if gene_data.size() > 0:
        var archive_path := "user://archived_genes/%s.json" % gene_id
        DirAccess.make_dir_recursive_absolute(archive_path.get_base_dir())
        var file := FileAccess.open(archive_path, FileAccess.WRITE)
        file.store_string(JSON.stringify(gene_data[0]))
        file.close()
    
    # Delete from registry
    _db.delete_rows("genes", "id = '%s'" % gene_id)
    _methylated_cache.erase(gene_id)
    
    emit_signal("gene_pruned", gene_id)
    print("[GenomeRegistry] Pruned gene %s" % gene_id)

func register_gene(type: String, name: String, gdscript_path: String, parameters: Dictionary, provenance: String) -> String:
    var gene_id := "%s_%s_%d" % [type, name.to_lower().replace(" ", "_"), Time.get_unix_time_from_system()]
    
    _db.insert_row("genes", {
        "id": gene_id,
        "type": type,
        "name": name,
        "gdscript_path": gdscript_path,
        "parameters": JSON.stringify(parameters),
        "provenance": provenance,
        "created_at": Time.get_unix_time_from_system()
    })
    
    _load_gene(gene_id, gdscript_path, JSON.stringify(parameters))
    return gene_id

# Balance metrics accessors
func get_strategy_diversity() -> float:
    var result := _db.query("SELECT strategy_diversity FROM balance_metrics ORDER BY timestamp DESC LIMIT 1")
    return result[0]["strategy_diversity"] if result.size() > 0 else 0.5

func get_player_retention() -> float:
    var result := _db.query("SELECT player_retention FROM balance_metrics ORDER BY timestamp DESC LIMIT 1")
    return result[0]["player_retention"] if result.size() > 0 else 0.5

func get_asset_variety() -> float:
    var result := _db.query("SELECT asset_variety FROM balance_metrics ORDER BY timestamp DESC LIMIT 1")
    return result[0]["asset_variety"] if result.size() > 0 else 0.5

func get_gene_error_rates() -> Dictionary:
    var result := _db.select_rows("genes", "methylated = 0", ["id", "error_rate"])
    var rates := {}
    for row in result:
        rates[row["id"]] = row["error_rate"]
    return rates

func log_performance_metrics(metrics: Dictionary) -> void:
    # Called by ThrottleController
    pass  # Stored in metrics.db, not genome.db
```

---

## 6. SELF-EVOLUTION MECHANICS

### 6.1 Macro Compilation (Action Sequence Optimization)

The game identifies repeated action sequences and compiles them into macro "genes" that execute faster.

```gdscript
# godot/autoloads/MacroCompiler.gd
extends Node

const MIN_SEQUENCE_LENGTH := 3
const MIN_OCCURRENCE_COUNT := 10
const PATTERN_WINDOW := 100  # Frames to analyze

var _action_history: Array[Dictionary] = []
var _discovered_macros: Dictionary = {}  # hash -> {actions, count, macro_gene_id}

func record_action(entity_id: String, action: Dictionary) -> void:
    _action_history.append({
        "entity": entity_id,
        "action": action,
        "frame": Engine.get_process_frames()
    })
    
    # Trim old history
    while _action_history.size() > PATTERN_WINDOW * 10:
        _action_history.pop_front()

func analyze_patterns() -> void:
    # Sliding window pattern detection
    for window_size in range(MIN_SEQUENCE_LENGTH, 10):
        var sequences := _extract_sequences(window_size)
        for seq_hash in sequences:
            var seq_data: Dictionary = sequences[seq_hash]
            if seq_data["count"] >= MIN_OCCURRENCE_COUNT:
                _promote_to_macro(seq_hash, seq_data)

func _extract_sequences(length: int) -> Dictionary:
    var sequences := {}
    
    for i in range(_action_history.size() - length):
        var seq := _action_history.slice(i, i + length)
        var seq_hash := _hash_sequence(seq)
        
        if seq_hash in sequences:
            sequences[seq_hash]["count"] += 1
        else:
            sequences[seq_hash] = {"actions": seq, "count": 1}
    
    return sequences

func _hash_sequence(seq: Array) -> String:
    var hash_input := ""
    for item in seq:
        hash_input += JSON.stringify(item["action"])
    return hash_input.sha256_text().substr(0, 16)

func _promote_to_macro(seq_hash: String, seq_data: Dictionary) -> void:
    if seq_hash in _discovered_macros:
        return  # Already promoted
    
    # Generate macro gene
    var macro_name := "macro_%s" % seq_hash.substr(0, 8)
    var gdscript := _generate_macro_script(seq_data["actions"])
    
    # Save script
    var script_path := "user://genes/macros/%s.gd" % macro_name
    DirAccess.make_dir_recursive_absolute(script_path.get_base_dir())
    var file := FileAccess.open(script_path, FileAccess.WRITE)
    file.store_string(gdscript)
    file.close()
    
    # Register as gene
    var gene_id := GenomeRegistry.register_gene(
        "behavior",
        macro_name,
        script_path,
        {"sequence_hash": seq_hash, "action_count": seq_data["actions"].size()},
        "macro-compiled"
    )
    
    _discovered_macros[seq_hash] = {
        "actions": seq_data["actions"],
        "count": seq_data["count"],
        "macro_gene_id": gene_id
    }
    
    print("[MacroCompiler] Promoted sequence %s to macro gene %s (count: %d)" % [
        seq_hash, gene_id, seq_data["count"]
    ])

func _generate_macro_script(actions: Array) -> String:
    var script := """extends "res://godot/genes/behaviors/BehaviorBase.gd"

# Auto-generated macro from observed action sequence
# DO NOT EDIT - regenerate if modifications needed

var _sequence := %s

func execute(context: Dictionary) -> Dictionary:
    var results := []
    for action in _sequence:
        results.append(_execute_action(context, action))
    return {"macro_results": results}

func _execute_action(context: Dictionary, action: Dictionary) -> Variant:
    # Delegate to entity's action system
    var entity = context.get("entity")
    if entity and entity.has_method("perform_action"):
        return entity.perform_action(action["action"])
    return null
""" % JSON.stringify(actions)
    return script
```

### 6.2 Self-Optimization Feedback Loop

```gdscript
# godot/autoloads/SelfOptimizer.gd
extends Node

const OPTIMIZATION_INTERVAL := 100  # Every 100 ticks
const GRADIENT_STEP := 0.02         # Maximum parameter change per iteration

var _tick_counter := 0
var _balance_history: Array[float] = []

func _process(delta: float) -> void:
    _tick_counter += 1
    
    if _tick_counter % OPTIMIZATION_INTERVAL == 0:
        _run_optimization_cycle()

func _run_optimization_cycle() -> void:
    # 1. Collect current balance metric
    var current_balance := _compute_balance()
    _balance_history.append(current_balance)
    
    # Trim history
    while _balance_history.size() > 100:
        _balance_history.pop_front()
    
    # 2. Compute gradient direction
    var gradient := _estimate_gradient()
    
    # 3. Apply small parameter adjustments to active genes
    var active_genes := GenomeRegistry.get_active_genes_with_params()
    for gene_id in active_genes:
        var params: Dictionary = active_genes[gene_id]
        _nudge_parameters(gene_id, params, gradient)
    
    # 4. Log balance metrics
    GenomeRegistry._db.insert_row("balance_metrics", {
        "timestamp": Time.get_unix_time_from_system(),
        "strategy_diversity": _compute_strategy_diversity(),
        "player_retention": _compute_player_retention(),
        "asset_variety": _compute_asset_variety()
    })
    
    # 5. Occasionally trigger agent-based optimization
    if _tick_counter % (OPTIMIZATION_INTERVAL * 10) == 0:
        AgentBridge.request_balance_tuning()

func _compute_balance() -> float:
    return 0.4 * _compute_strategy_diversity() + \
           0.4 * _compute_player_retention() + \
           0.2 * _compute_asset_variety()

func _estimate_gradient() -> float:
    if _balance_history.size() < 3:
        return 0.0
    
    # Simple finite difference
    var recent := _balance_history.slice(-3)
    var trend := (recent[2] - recent[0]) / 2.0
    return trend

func _nudge_parameters(gene_id: String, params: Dictionary, gradient: float) -> void:
    # Only adjust numeric parameters
    var modified := false
    for key in params:
        if params[key] is float or params[key] is int:
            var adjustment := gradient * GRADIENT_STEP * randf_range(-1.0, 1.0)
            params[key] = params[key] + adjustment
            modified = true
    
    if modified:
        GenomeRegistry.update_gene_parameters(gene_id, params)

func _compute_strategy_diversity() -> float:
    # Gini coefficient of gene usage
    var usage := GenomeRegistry.get_gene_usage_counts()
    if usage.size() == 0:
        return 0.5
    
    var values := usage.values()
    values.sort()
    var n := values.size()
    var sum_i_times_y := 0.0
    var sum_y := 0.0
    
    for i in range(n):
        sum_i_times_y += (i + 1) * values[i]
        sum_y += values[i]
    
    if sum_y == 0:
        return 0.5
    
    var gini := (2.0 * sum_i_times_y) / (n * sum_y) - (n + 1.0) / n
    return 1.0 - gini  # Invert so higher = more diverse

func _compute_player_retention() -> float:
    # Ratio of sessions continued vs abandoned
    return GameState.get_session_continuation_rate()

func _compute_asset_variety() -> float:
    # Ratio of unique assets used in last 1000 ticks
    return GenomeRegistry.get_unique_asset_ratio()
```

---

## 7. GAMEPLAY SYSTEMS

### 7.1 Natural Language Prompt Interface

```gdscript
# godot/ui/PromptEditor.gd
extends Control

@onready var _input: TextEdit = $TextEdit
@onready var _preview: RichTextLabel = $Preview
@onready var _cost_label: Label = $CostLabel
@onready var _submit_button: Button = $SubmitButton

var _pending_parse_task: String = ""

func _ready() -> void:
    _input.text_changed.connect(_on_text_changed)
    _submit_button.pressed.connect(_on_submit)
    AgentBridge.agent_result_received.connect(_on_agent_result)

func _on_text_changed() -> void:
    var prompt := _input.text.strip_edges()
    
    # Estimate CPU cost (simple heuristic: 1 cycle per 10 chars)
    var estimated_cost := ceili(prompt.length() / 10.0)
    _cost_label.text = "Cost: %d cycles" % estimated_cost
    
    # Debounced preview generation
    _request_preview_debounced(prompt)

var _debounce_timer: Timer = null
func _request_preview_debounced(prompt: String) -> void:
    if _debounce_timer == null:
        _debounce_timer = Timer.new()
        _debounce_timer.one_shot = true
        _debounce_timer.timeout.connect(_generate_preview)
        add_child(_debounce_timer)
    
    _debounce_timer.stop()
    _debounce_timer.start(0.5)

func _generate_preview() -> void:
    var prompt := _input.text.strip_edges()
    if prompt.length() < 5:
        _preview.text = "[i]Enter a behavior description...[/i]"
        return
    
    # Local regex parsing for instant preview
    var preview_text := _local_parse(prompt)
    _preview.text = preview_text

func _local_parse(prompt: String) -> String:
    # Simple keyword-based parsing for instant feedback
    var behaviors := []
    
    if "flank" in prompt.to_lower():
        behaviors.append("→ Prefers indirect paths")
    if "avoid" in prompt.to_lower():
        behaviors.append("→ Avoids specified targets")
    if "target" in prompt.to_lower():
        behaviors.append("→ Prioritizes specified objectives")
    if "defend" in prompt.to_lower():
        behaviors.append("→ Defensive positioning")
    if "attack" in prompt.to_lower():
        behaviors.append("→ Aggressive engagement")
    if "resource" in prompt.to_lower():
        behaviors.append("→ Resource-focused")
    
    if behaviors.size() == 0:
        return "[i]Parsing behavior...[/i]"
    
    return "[b]Detected Behaviors:[/b]\n" + "\n".join(behaviors)

func _on_submit() -> void:
    var prompt := _input.text.strip_edges()
    if prompt.length() < 5:
        return
    
    # Check player has enough cycles
    var cost := ceili(prompt.length() / 10.0)
    if GameState.player_cycles < cost:
        _show_error("Not enough CPU cycles!")
        return
    
    # Deduct cycles
    GameState.player_cycles -= cost
    
    # Queue behavior synthesis
    _pending_parse_task = AgentBridge.synthesize_behavior(prompt)
    _submit_button.disabled = true
    _submit_button.text = "Synthesizing..."

func _on_agent_result(task_id: String, result: Dictionary) -> void:
    if task_id != _pending_parse_task:
        return
    
    _submit_button.disabled = false
    _submit_button.text = "Submit"
    
    if result.get("success", false):
        var gene_id: String = result.get("gene_id", "")
        _preview.text = "[color=green]✓ Behavior created: %s[/color]" % gene_id
        _input.text = ""
        
        # Spawn creep with new behavior
        GameState.spawn_creep_with_behavior(gene_id)
    else:
        _show_error("Failed to synthesize behavior: %s" % result.get("error", "Unknown error"))

func _show_error(message: String) -> void:
    _preview.text = "[color=red]✗ %s[/color]" % message
```

### 7.2 Madlibs Attribute System

```gdscript
# godot/systems/MadlibsMixer.gd
extends RefCounted

const SHAPES := ["orb", "shard", "spike", "wave", "burst", "beam"]
const COLORS := ["crimson", "void", "amber", "azure", "moss", "ember"]
const SOUNDS := ["hum", "screech", "pulse", "thrum", "crackle", "whisper"]
const EFFECTS := ["freeze", "bleed", "chain", "poison", "stun", "drain"]

class AttributeDescriptor:
    var shape: String
    var color: String
    var sound: String
    var effect: String
    var seed_value: int
    
    func get_id() -> String:
        return "%s-%s-%s-%s" % [color, shape, sound, effect]
    
    func get_color_hex() -> String:
        match color:
            "crimson": return "DC143C"
            "void": return "1A1A2E"
            "amber": return "FFBF00"
            "azure": return "007FFF"
            "moss": return "8A9A5B"
            "ember": return "FF4500"
            _: return "FFFFFF"

static func mix(seed_value: int) -> AttributeDescriptor:
    var rng := RandomNumberGenerator.new()
    rng.seed = seed_value
    
    var desc := AttributeDescriptor.new()
    desc.shape = SHAPES[rng.randi() % SHAPES.size()]
    desc.color = COLORS[rng.randi() % COLORS.size()]
    desc.sound = SOUNDS[rng.randi() % SOUNDS.size()]
    desc.effect = EFFECTS[rng.randi() % EFFECTS.size()]
    desc.seed_value = seed_value
    
    return desc

static func generate_sprite_prompt(desc: AttributeDescriptor) -> String:
    return "%s %s projectile, pixel art, game asset, transparent background, %s glow" % [
        desc.color, desc.shape, desc.color
    ]

static func get_effect_script_path(effect: String) -> String:
    return "res://godot/genes/effects/%s_effect.gd" % effect
```

### 7.3 Entity Base Classes

```gdscript
# godot/entities/Creep.gd
extends CharacterBody2D
class_name Creep

@export var max_health := 100.0
@export var move_speed := 100.0
@export var behavior_gene_id := ""

var health: float
var _behavior_instance = null

signal died(creep: Creep)

func _ready() -> void:
    health = max_health
    _load_behavior()

func _load_behavior() -> void:
    if behavior_gene_id.is_empty():
        return
    
    _behavior_instance = GenomeRegistry.get_gene_instance(behavior_gene_id)

func _physics_process(delta: float) -> void:
    if _behavior_instance == null:
        return
    
    # Execute behavior gene
    var context := {
        "entity": self,
        "delta": delta,
        "position": global_position,
        "health": health,
        "nearby_enemies": _get_nearby_enemies(),
        "nearby_towers": _get_nearby_towers(),
        "resource_nodes": _get_resource_nodes()
    }
    
    var result: Dictionary = GenomeRegistry.execute_gene(behavior_gene_id, context)
    
    if result.has("move_direction"):
        var dir: Vector2 = result["move_direction"]
        velocity = dir.normalized() * move_speed
        move_and_slide()
    
    if result.has("target"):
        _attack_target(result["target"])

func take_damage(amount: float, source: Node = null) -> void:
    health -= amount
    if health <= 0:
        emit_signal("died", self)
        queue_free()

func _get_nearby_enemies() -> Array[Node2D]:
    # Use physics query for efficiency
    var space := get_world_2d().direct_space_state
    var query := PhysicsShapeQueryParameters2D.new()
    query.shape = CircleShape2D.new()
    query.shape.radius = 200.0
    query.transform = Transform2D(0, global_position)
    query.collision_mask = 2  # Enemy layer
    
    var results := space.intersect_shape(query)
    var enemies: Array[Node2D] = []
    for r in results:
        if r.collider != self:
            enemies.append(r.collider)
    return enemies

func _get_nearby_towers() -> Array[Node2D]:
    return get_tree().get_nodes_in_group("towers").filter(
        func(t): return global_position.distance_to(t.global_position) < 300.0
    )

func _get_resource_nodes() -> Array[Node2D]:
    return get_tree().get_nodes_in_group("resources")

func _attack_target(target: Node2D) -> void:
    if target.has_method("take_damage"):
        target.take_damage(10.0, self)
```

```gdscript
# godot/entities/Tower.gd
extends StaticBody2D
class_name Tower

@export var attributes: Resource  # MadlibsAttributes resource
@export var damage := 25.0
@export var fire_rate := 1.0
@export var range_radius := 200.0

var _fire_cooldown := 0.0
var _target: Node2D = null

func _ready() -> void:
    $RangeArea/CollisionShape2D.shape.radius = range_radius

func _process(delta: float) -> void:
    _fire_cooldown -= delta
    
    if _target == null or not is_instance_valid(_target):
        _target = _find_target()
    
    if _target and _fire_cooldown <= 0:
        _fire_at_target()
        _fire_cooldown = 1.0 / fire_rate

func _find_target() -> Node2D:
    var bodies := $RangeArea.get_overlapping_bodies()
    var creeps := bodies.filter(func(b): return b is Creep)
    
    if creeps.size() == 0:
        return null
    
    # Target closest
    creeps.sort_custom(func(a, b):
        return global_position.distance_to(a.global_position) < \
               global_position.distance_to(b.global_position)
    )
    return creeps[0]

func _fire_at_target() -> void:
    var projectile: Projectile = preload("res://godot/entities/Projectile.tscn").instantiate()
    projectile.global_position = global_position
    projectile.target = _target
    projectile.damage = damage
    projectile.attributes = attributes
    get_parent().add_child(projectile)
```

---

## 8. MULTIPLAYER & STATE SYNC

### 8.1 CRDT-Based State (Simplified)

```gdscript
# godot/autoloads/GameState.gd
extends Node

# LWW-Register for simple values
var player_cycles := 100
var territory_control: Dictionary = {}  # tile_id -> player_id
var entity_positions: Dictionary = {}   # entity_id -> Vector2

# G-Counter for monotonic values
var total_kills := 0
var total_assets_generated := 0

# Session metrics
var session_start_time: int
var session_continuation_rate := 0.5

signal state_changed(key: String, value: Variant)

func _ready() -> void:
    session_start_time = Time.get_unix_time_from_system()

func get_session_continuation_rate() -> float:
    # Simplified: ratio of active players to total players
    return session_continuation_rate

func spawn_creep_with_behavior(behavior_gene_id: String) -> void:
    var creep: Creep = preload("res://godot/entities/Creep.tscn").instantiate()
    creep.behavior_gene_id = behavior_gene_id
    creep.global_position = _get_spawn_point()
    get_tree().current_scene.add_child(creep)

func _get_spawn_point() -> Vector2:
    # Find player's spawn zone
    var spawn_zones := get_tree().get_nodes_in_group("player_spawn")
    if spawn_zones.size() > 0:
        return spawn_zones[0].global_position + Vector2(randf_range(-50, 50), randf_range(-50, 50))
    return Vector2(100, 100)

func claim_territory(tile_id: String, player_id: String) -> void:
    territory_control[tile_id] = player_id
    emit_signal("state_changed", "territory", territory_control)

func get_player_territory_count(player_id: String) -> int:
    return territory_control.values().count(player_id)
```

---

## 9. BUILD & DEPLOYMENT

### 9.1 Project Configuration

```ini
; project.godot
[application]
config/name="Tower-Creep Symbiosis"
run/main_scene="res://godot/main.tscn"
config/features=PackedStringArray("4.3", "Forward Plus")

[autoload]
GameState="*res://godot/autoloads/GameState.gd"
GenomeRegistry="*res://godot/autoloads/GenomeRegistry.gd"
ThrottleController="*res://godot/autoloads/ThrottleController.gd"
AgentBridge="*res://godot/autoloads/AgentBridge.gd"
ResourceMonitor="*res://godot/autoloads/ResourceMonitor.gd"
MacroCompiler="*res://godot/autoloads/MacroCompiler.gd"
SelfOptimizer="*res://godot/autoloads/SelfOptimizer.gd"

[rendering]
renderer/rendering_method="forward_plus"
renderer/rendering_method.mobile="forward_plus"

[physics]
common/physics_ticks_per_second=60

[display]
window/size/viewport_width=1920
window/size/viewport_height=1080
window/size/resizable=true
```

### 9.2 Build Script (macOS ARM64)

```bash
#!/bin/bash
# scripts/build-macos.sh

set -e

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$PROJECT_DIR/build/macos"
GODOT_PATH="/Applications/Godot.app/Contents/MacOS/Godot"

# Ensure Godot 4.3 ARM64 is available
if [[ ! -f "$GODOT_PATH" ]]; then
    echo "Error: Godot not found at $GODOT_PATH"
    echo "Install Godot 4.3 from https://godotengine.org/download"
    exit 1
fi

# Clean and create build directory
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# Export for macOS
echo "Building Tower-Creep Symbiosis for macOS ARM64..."
$GODOT_PATH --headless --export-release "macOS" "$BUILD_DIR/TowerCreepSymbiosis.app"

# Sign the app (requires Apple Developer ID)
if [[ -n "$APPLE_TEAM_ID" ]]; then
    codesign --deep --force --sign "Developer ID Application: $APPLE_TEAM_ID" \
        "$BUILD_DIR/TowerCreepSymbiosis.app"
fi

# Create DMG
hdiutil create -volname "Tower-Creep Symbiosis" \
    -srcfolder "$BUILD_DIR/TowerCreepSymbiosis.app" \
    -ov -format UDZO \
    "$BUILD_DIR/TowerCreepSymbiosis.dmg"

echo "Build complete: $BUILD_DIR/TowerCreepSymbiosis.dmg"
```

### 9.3 Agent Deployment Script

```bash
#!/bin/bash
# scripts/deploy-agent.sh
# CIO Pattern implementation

set -e

TEMPLATE_NAME="$1"
USER_PROMPT="$2"
ARSENAL_PATH="./agents/arsenal"
SESSION_ID="$(date +%s)-$(openssl rand -hex 4)"
SESSION_DIR="/tmp/tcs-agent-$SESSION_ID"

if [[ -z "$TEMPLATE_NAME" ]] || [[ -z "$USER_PROMPT" ]]; then
    echo "Usage: deploy-agent.sh <template-name> <prompt>"
    echo "Templates: asset-gen, balance-tuner, behavior-synth, code-auditor"
    exit 1
fi

# Validate template exists
if [[ ! -d "$ARSENAL_PATH/$TEMPLATE_NAME" ]]; then
    echo "Error: Template '$TEMPLATE_NAME' not found in $ARSENAL_PATH"
    exit 1
fi

# 1. Isolate: Create ephemeral session directory
mkdir -p "$SESSION_DIR"

# 2. Inject: Copy agent template
cp -r "$ARSENAL_PATH/$TEMPLATE_NAME/." "$SESSION_DIR/"

# 3. Execute: Run Claude Code headless
cd "$SESSION_DIR"
claude -p "$USER_PROMPT" --output-format stream-json 2>&1 | tee "/tmp/tcs-agent-$SESSION_ID.log"

# 4. Capture result
EXIT_CODE=$?

# 5. Cleanup (optional: keep for debugging)
# rm -rf "$SESSION_DIR"

exit $EXIT_CODE
```

---

## 10. IMPLEMENTATION ROADMAP

### Phase 1: Foundation (Week 1-2)

|Task|Description|Owner|
|---|---|---|
|P1.1|Godot 4.3 project scaffold|Dev|
|P1.2|SQLite genome registry schema|Dev|
|P1.3|Basic Tower/Creep entities|Dev|
|P1.4|ThrottleController PID loop|Dev|
|P1.5|ResourceMonitor (macOS sysctl)|Dev|

**Deliverable:** Playable prototype with static behaviors, adaptive frame rate

### Phase 2: Agent Integration (Week 3-4)

|Task|Description|Owner|
|---|---|---|
|P2.1|AgentBridge IPC implementation|Dev|
|P2.2|Bun orchestrator with CIO pattern|Dev|
|P2.3|behavior-synth agent template|Dev|
|P2.4|Natural language prompt UI|Dev|
|P2.5|Gene loading/execution pipeline|Dev|

**Deliverable:** Players can create creeps via natural language prompts

### Phase 3: Self-Evolution (Week 5-6)

|Task|Description|Owner|
|---|---|---|
|P3.1|MacroCompiler pattern detection|Dev|
|P3.2|SelfOptimizer feedback loop|Dev|
|P3.3|code-auditor agent template|Dev|
|P3.4|Methylation/pruning system|Dev|
|P3.5|Balance metrics computation|Dev|

**Deliverable:** Game optimizes its own behavior patterns over time

### Phase 4: Content Generation (Week 7-8)

|Task|Description|Owner|
|---|---|---|
|P4.1|asset-gen agent template|Dev|
|P4.2|MadlibsMixer attribute system|Dev|
|P4.3|balance-tuner agent template|Dev|
|P4.4|Verified module pool|Dev|
|P4.5|Cross-session asset persistence|Dev|

**Deliverable:** Game generates and curates its own assets

### Phase 5: Polish & Launch (Week 9-10)

|Task|Description|Owner|
|---|---|---|
|P5.1|Performance profiling|Dev|
|P5.2|Memory optimization|Dev|
|P5.3|UI/UX refinement|Dev|
|P5.4|macOS notarization|Dev|
|P5.5|Documentation|Dev|

**Deliverable:** Production-ready release for M3 Pro Max

---

## 11. TECHNICAL VALIDATION

### 11.1 Performance Targets

|Metric|Target|Measurement|
|---|---|---|
|Frame Time|<16.67ms|Performance.TIME_PROCESS|
|Memory Usage|<8GB|Activity Monitor|
|Agent Latency|<2s per task|Orchestrator logs|
|Gene Execution|<1ms per gene|GenomeRegistry logs|
|Tick Duration|16-500ms adaptive|ThrottleController|

### 11.2 Correctness Invariants

1. **Cycle Conservation:** `Σ(player_cycles) + Σ(spent_cycles) = initial_total`
2. **Gene Determinism:** Same seed → same behavior output
3. **Methylation Irreversibility:** Methylated genes never auto-activate
4. **State Convergence:** All clients reach same state within 10 ticks

### 11.3 Failure Modes & Mitigations

|Failure|Detection|Mitigation|
|---|---|---|
|Gene infinite loop|>10ms execution|Terminate + methylate|
|Agent timeout|>30s response|Skip task, log warning|
|Memory pressure >80%|ResourceMonitor|Reduce work_budget|
|SQLite lock contention|Write timeout|WAL mode, retry|
|Claude Code unavailable|Process exit|Fallback to local regex parser|

---

## 12. CONCLUSION

Tower-Creep Symbiosis is technically feasible on M3 Pro Max with Godot 4.3 as the game engine. The architecture achieves self-evolution through:

1. **CIO Pattern:** Isolated agent execution with predefined capabilities
2. **DNA Model:** Genes as modular GDScript files with methylation control
3. **Adaptive Speed:** PID-controlled tick duration based on resource utilization
4. **Macro Compilation:** Automatic optimization of repeated action sequences
5. **Balance Feedback:** Continuous metric-driven parameter tuning

The game will start slow with redundant operations, progressively compile efficient macros, and evolve complexity as hardware headroom permits—creating unique gameplay experiences across different hardware configurations.

**Next Action:** Initialize Godot 4.3 project and implement Phase 1 foundation tasks.

---

_Document generated by The Astute Sliither for Ice-ninja_ _Classification: Technical PRD - Implementation Ready_