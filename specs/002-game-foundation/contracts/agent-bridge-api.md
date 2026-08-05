# Contract: AgentBridge IPC Interface

**Version**: 1.0.0
**File**: `res://godot/autoloads/AgentBridge.gd`
**Counterpart**: `agents/orchestrator.ts` (Bun process)

---

## Overview

AgentBridge is the sole IPC boundary between the Godot game process and the Bun
orchestrator. It owns three responsibilities:

1. **Enqueue** agent tasks (with priority and type)
2. **Spawn** the Bun orchestrator subprocess on first task (lazy start)
3. **Poll** for results via filesystem (`user://agent-results/<task_id>.json`)

---

## Signals (emitted by AgentBridge, consumed by UI)

| Signal | Parameters | When emitted |
|--------|------------|--------------|
| `agent_result_received` | `task_id: String, result: Dictionary` | Result file detected and parsed |
| `orchestrator_started` | — | Bun process successfully spawned |
| `orchestrator_died` | `exit_code: int` | Bun process exited unexpectedly |
| `queue_full` | `attempted_type: String` | Task rejected — queue at max capacity |

---

## Public Methods

### `queue_task(agent_type: String, prompt: String, priority: int) -> String`

Enqueues a task for the agent orchestrator.

**Parameters**:
- `agent_type`: one of `"behavior-synth"`, `"balance-tuner"`, `"asset-gen"`, `"code-auditor"`
- `prompt`: the prompt string for the agent (max 4000 chars)
- `priority`: integer 1–8 (1 = highest priority)

**Returns**: `task_id` (non-empty String) on success; `""` on rejection (queue full or
orchestrator unavailable after graceful degrade).

**Side effects**: Spawns orchestrator subprocess if not running. Writes task spec to
`user://agent-tasks/<task_id>.json` for orchestrator pickup.

**Errors**: Does NOT push_error or crash. Returns `""` silently; emits `queue_full`
signal when applicable.

---

### `synthesize_behavior(prompt: String) -> String`

Convenience wrapper: calls `queue_task("behavior-synth", prompt, 8)`.
Returns `task_id` or `""`.

---

### `request_balance_tuning() -> String`

Convenience wrapper: calls `queue_task("balance-tuner", "Optimize balance given: " + metrics_json, 2)`.
Returns `task_id` or `""`.

---

### `request_code_audit() -> String`

Convenience wrapper: calls `queue_task("code-auditor", "Audit genes for methylation/pruning", 1)`.
Returns `task_id` or `""`.

---

### `is_available() -> bool`

Returns true if the orchestrator subprocess is running and responsive.
Does NOT launch the subprocess — use `queue_task()` for that.

---

## Task File Format (`user://agent-tasks/<task_id>.json`)

Written by AgentBridge, read by orchestrator:

```json
{
  "id": "behavior-synth_1741600000_a3f2",
  "agentType": "behavior-synth",
  "prompt": "flanking scout that avoids cannon towers",
  "priority": 8,
  "enqueuedAt": 1741600000000
}
```

---

## Result File Format (`user://agent-results/<task_id>.json`)

Written by orchestrator, read by AgentBridge (polled every 250ms):

```json
{
  "taskId": "behavior-synth_1741600000_a3f2",
  "success": true,
  "output": "extends BehaviorBase\n\nfunc _evaluate(context)...",
  "error": null,
  "completedAt": 1741600030000
}
```

On `success: true` for behavior-synth: `output` is the raw GDScript string.
AgentBridge passes it through `validate-gene.sh` before registering.
On `success: false`: `error` contains a human-readable reason; AgentBridge emits
`agent_result_received` with `{"success": false, "error": "..."}`.

---

## Queue Constraints

| Parameter | Default | Modified by |
|-----------|---------|-------------|
| `_max_queue_size` | 4 | Feature 001 (`HardwareProfile.max_concurrent_agents`) |
| Poll interval | 250ms | Fixed |
| Task timeout | 60s | After 60s without result, task is marked failed |

---

## Graceful Degrade Protocol

If `_orchestrator_available = false` (process not started or died):
1. `queue_task()` returns `""` without attempting to spawn
2. Callers (PromptEditor) detect `""` and show amber "Agent offline" message
3. Gameplay continues unaffected — no crash, no error dialog
4. `is_available()` returns `false`

AgentBridge sets `_orchestrator_available = false` when:
- `Bun.spawn` exits with non-zero before emitting first result
- 3 consecutive task timeouts (60s each)
- Explicit SIGTERM sent to orchestrator process
