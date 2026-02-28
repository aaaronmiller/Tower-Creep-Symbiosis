# Contract: HardwareProfile Autoload API

**File**: `godot/autoloads/HardwareProfile.gd`
**Type**: GDScript Autoload (singleton)
**Registered as**: `HardwareProfile` (first autoload, before ThrottleController)

---

## Signals

```gdscript
## Emitted when free system memory drops below 1 GB.
## All subsystems should reduce non-critical memory usage.
signal low_memory_warning(free_bytes: int)

## Emitted when free system memory drops below 512 MB.
## AgentBridge must kill lowest-priority pending agents immediately.
signal critical_memory_warning(free_bytes: int)

## Emitted once after detection is complete. Other autoloads await this.
signal profile_ready(tier: int)  # tier: PerformanceTier enum value
```

---

## Properties (read-only after _ready)

```gdscript
## PerformanceTier enum
enum PerformanceTier { STANDARD = 0, ENHANCED = 1 }

var os_name: String               # "Windows" | "Linux" | "macOS"
var cpu_architecture: String      # "x86_64" | "arm64"
var logical_core_count: int
var total_ram_bytes: int
var gpu_name: String
var performance_tier: PerformanceTier
var game_memory_ceiling_bytes: int
var agent_memory_ceiling_bytes: int
var max_concurrent_agents: int
var renderer_hint: String         # "opengl3" | "vulkan"
```

---

## Methods

```gdscript
## Returns true if the system meets minimum requirements (≥ 16 GB RAM).
func is_supported() -> bool

## Returns current free system RAM in bytes (live reading).
func get_free_ram_bytes() -> int

## Returns normalized memory pressure [0.0, 1.0] where 1.0 = critically low.
func get_memory_pressure() -> float

## Allows user/launch-flag override of the auto-detected tier.
## Must be called before profile_ready is emitted (i.e., before _ready completes).
func override_tier(tier: PerformanceTier) -> void
```

---

## Initialization Contract

1. HardwareProfile MUST be the first autoload listed in `project.godot`.
2. All other autoloads MUST await `HardwareProfile.profile_ready` before reading
   properties, OR read properties only after `_ready()` has completed (which is
   guaranteed for autoloads registered after HardwareProfile).
3. If `is_supported()` returns false, HardwareProfile MUST call `get_tree().quit(1)`
   after showing an informative error dialog. No other autoload initializes.

---

## Error Behavior

| Condition | Behavior |
|-----------|----------|
| RAM < 8 GB | Show dialog: "Minimum 16 GB RAM required." Then quit. |
| `platform-config.json` missing | Use built-in defaults; log warning to console. |
| `platform-config.json` malformed | Use built-in defaults; log error to console. |
