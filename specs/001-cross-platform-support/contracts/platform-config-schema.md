# Contract: platform-config.json Schema

**File**: `data/platform-config.json`
**Read by**: `HardwareProfile.gd` at startup
**Editable by**: Advanced users / operators (not required for normal play)

---

## Schema

```json
{
  "STANDARD": {
    "fps_target": 30,
    "max_concurrent_agents": 2,
    "game_memory_ceiling_gb": 4.0,
    "agent_memory_ceiling_gb": 2.0,
    "renderer_hint": "opengl3",
    "throttle_min_tick_ms": 33.0,
    "throttle_cpu_target": 0.60
  },
  "ENHANCED": {
    "fps_target": 60,
    "max_concurrent_agents": 4,
    "game_memory_ceiling_gb": 8.0,
    "agent_memory_ceiling_gb": 4.0,
    "renderer_hint": "vulkan",
    "throttle_min_tick_ms": 16.0,
    "throttle_cpu_target": 0.70
  }
}
```

---

## Field Constraints

| Field | Type | Min | Max | Notes |
|-------|------|-----|-----|-------|
| `fps_target` | int | 15 | 240 | Used to set ThrottleController `min_tick_duration_ms` |
| `max_concurrent_agents` | int | 1 | 6 | Enforced by AgentBridge queue |
| `game_memory_ceiling_gb` | float | 1.0 | 16.0 | Cannot exceed 50% of system RAM at runtime |
| `agent_memory_ceiling_gb` | float | 0.5 | 8.0 | Cannot exceed 50% of system RAM at runtime |
| `renderer_hint` | String | — | — | Must be "opengl3" or "vulkan" |
| `throttle_min_tick_ms` | float | 4.0 | 500.0 | Clipped to ThrottleController min/max bounds |
| `throttle_cpu_target` | float | 0.30 | 0.90 | PID setpoint; values > 0.85 not recommended |

---

## Validation Rules

- Both `"STANDARD"` and `"ENHANCED"` keys MUST be present. If either is missing,
  the file is treated as malformed and built-in defaults are used.
- `game_memory_ceiling_gb` + `agent_memory_ceiling_gb` MUST be ≤ 50% of detected
  system RAM. If the config exceeds this limit at runtime, the values are silently
  clamped and a warning is logged.
- `renderer_hint` values other than `"opengl3"` or `"vulkan"` are ignored; the
  platform default is used instead.

---

## Default File (shipped in repository)

```json
{
  "STANDARD": {
    "fps_target": 30,
    "max_concurrent_agents": 2,
    "game_memory_ceiling_gb": 4.0,
    "agent_memory_ceiling_gb": 2.0,
    "renderer_hint": "opengl3",
    "throttle_min_tick_ms": 33.0,
    "throttle_cpu_target": 0.60
  },
  "ENHANCED": {
    "fps_target": 60,
    "max_concurrent_agents": 4,
    "game_memory_ceiling_gb": 8.0,
    "agent_memory_ceiling_gb": 4.0,
    "renderer_hint": "vulkan",
    "throttle_min_tick_ms": 16.0,
    "throttle_cpu_target": 0.70
  }
}
```
