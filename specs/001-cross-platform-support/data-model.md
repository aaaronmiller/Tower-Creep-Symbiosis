# Data Model: Cross-Platform Support

**Branch**: `001-cross-platform-support` | **Date**: 2026-02-28

---

## Entities

### HardwareProfile

Detected once at game startup. Immutable for the duration of the session. Stored only
in memory (not persisted to disk).

| Field | Type | Description |
|-------|------|-------------|
| `os_name` | String | "Windows", "Linux", or "macOS" |
| `cpu_architecture` | String | "x86_64" or "arm64" |
| `logical_core_count` | int | Total logical CPU cores detected |
| `total_ram_bytes` | int | Physical RAM in bytes |
| `gpu_name` | String | GPU adapter name from rendering server |
| `performance_tier` | PerformanceTier | Assigned tier (see below) |
| `game_memory_ceiling_bytes` | int | Maximum RAM the game simulation may use |
| `agent_memory_ceiling_bytes` | int | Maximum RAM agent processes may use |
| `max_concurrent_agents` | int | Maximum agent processes that may run simultaneously |
| `renderer_hint` | String | "opengl3" or "vulkan" — default renderer for this tier |

**Validation rules**:
- `total_ram_bytes` < 8 GB → hardware is unsupported; emit warning and exit cleanly.
- `game_memory_ceiling_bytes` + `agent_memory_ceiling_bytes` MUST be ≤ 50% of
  `total_ram_bytes` (FR-006).
- `max_concurrent_agents` MUST be ≥ 1 and ≤ 6.

---

### PerformanceTier (Enum)

| Value | Trigger Condition | FPS Target | Max Agents | Game Ceiling | Agent Ceiling |
|-------|------------------|------------|------------|--------------|---------------|
| `STANDARD` | `total_ram_bytes` < 24 GB | 30 FPS | 2 | 4 GB | 2 GB |
| `ENHANCED` | `total_ram_bytes` ≥ 24 GB | 60 FPS | 4 | 8 GB | 4 GB |

Users may override via launch flag `--tier STANDARD` or `--tier ENHANCED`.
The override is applied after detection and logged to `data/metrics.db`.

---

### MemoryBudget

Derived from HardwareProfile at startup. Updated dynamically every 500 ms by the
ThrottleController sampling `OS.get_memory_info()["free"]`.

| Field | Type | Description |
|-------|------|-------------|
| `game_limit_bytes` | int | From `HardwareProfile.game_memory_ceiling_bytes` |
| `agent_limit_bytes` | int | From `HardwareProfile.agent_memory_ceiling_bytes` |
| `current_free_bytes` | int | Live reading of OS free memory |
| `low_memory_threshold_bytes` | int | 1 GB — triggers `low_memory_warning` signal |
| `critical_memory_threshold_bytes` | int | 512 MB — triggers graceful agent shutdown |

**State transitions**:

```text
Normal → LOW_MEMORY (free < 1 GB):
  - Emit HardwareProfile.low_memory_warning signal
  - Show Dashboard warning banner

LOW_MEMORY → CRITICAL (free < 512 MB):
  - Kill lowest-priority pending agents
  - Show user warning dialog with option to reduce simulation quality

CRITICAL → (game exits or memory recovers):
  - If memory > 1 GB after agent shutdown: return to LOW_MEMORY
  - If user acknowledges and memory still < 512 MB: exit gracefully
```

---

### PlatformConfig (persisted to `data/platform-config.json`)

Loaded at startup by HardwareProfile. Contains per-tier defaults that operators or
advanced users may edit without recompiling.

| Field | Type | Default (STANDARD) | Default (ENHANCED) |
|-------|------|--------------------|--------------------|
| `fps_target` | int | 30 | 60 |
| `max_concurrent_agents` | int | 2 | 4 |
| `game_memory_ceiling_gb` | float | 4.0 | 8.0 |
| `agent_memory_ceiling_gb` | float | 2.0 | 4.0 |
| `renderer_hint` | String | "opengl3" | "vulkan" |
| `throttle_min_tick_ms` | float | 33.0 (30 fps) | 16.0 (60 fps) |
| `throttle_cpu_target` | float | 0.60 | 0.70 |

File location: `data/platform-config.json` (shipped with default values; user-editable).

---

## Relationships

```text
HardwareProfile
  ├── owns → PerformanceTier (enum value)
  ├── derives → MemoryBudget (at startup, refreshed every 500ms)
  └── reads → PlatformConfig (from data/platform-config.json)

ThrottleController
  └── reads → HardwareProfile (min_tick_ms, cpu_target, game_ceiling)

AgentBridge
  └── reads → HardwareProfile.max_concurrent_agents
```
