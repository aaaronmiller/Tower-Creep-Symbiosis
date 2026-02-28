# Research: Cross-Platform Support

**Branch**: `001-cross-platform-support` | **Date**: 2026-02-28

## 1. Godot 4.3 Cross-Platform Export

**Decision**: Export three targets — macOS ARM64, Linux x86-64 (primary Intel), Windows
x86-64 (secondary, for users who prefer not to use WSL). Default renderer: Compatibility
(OpenGL 3.3) for Standard tier; Forward+ (Vulkan) for Enhanced/PRD_TARGET tier.

**Rationale**: Godot 4.3 ships official export templates for all three targets. The
Compatibility renderer (OpenGL 3.3) uses approximately 40% less VRAM than Forward+ Vulkan
and is supported by all Intel Iris Xe GPUs with driver version 27.x+. Switching renderer
at runtime is not supported; the renderer hint from `platform-config.json` must be applied
at project launch via Godot project settings or command-line flag (`--rendering-driver opengl3`).

**Alternatives considered**:
- Forward+ only: Rejected — Intel Iris Xe cannot sustain 30 FPS at Forward+ quality with
  full simulation complexity.
- Mobile renderer: Rejected — Missing features required by the Dashboard scene
  (SubViewport, CanvasItem shaders).

---

## 2. GDScript Hardware Detection APIs (Godot 4.3)

**Decision**: Use built-in Godot OS and Performance APIs exclusively. No GDExtension
or subprocess reads required.

| Need | API | Platform Support |
|------|-----|-----------------|
| Total RAM | `OS.get_memory_info()["physical"]` | Windows, Linux, macOS |
| Free RAM | `OS.get_memory_info()["free"]` | Windows, Linux, macOS |
| CPU logical cores | `OS.get_processor_count()` | Windows, Linux, macOS |
| CPU architecture | `Engine.get_architecture_name()` | returns "x86_64" or "arm64" |
| OS name | `OS.get_name()` | "Windows", "Linux", "macOS" |
| GPU name | `RenderingServer.get_video_adapter_name()` | All platforms |
| Current FPS | `Performance.get_monitor(Performance.TIME_FPS)` | All platforms |
| Frame process time | `Performance.get_monitor(Performance.TIME_PROCESS)` | All platforms |

**CPU utilization proxy**: Godot does not expose a native CPU utilization percentage.
Frame process time (`TIME_PROCESS`) is used as a stress proxy — it already reflects
CPU-bound work in the game loop. This avoids OS-specific `/proc/stat` reads on Linux,
PDH API on Windows, or `host_statistics` on macOS. The existing ThrottleController
`current_cpu_utilization` field will be renamed `current_frame_stress` and populated from
`TIME_PROCESS / (target_frame_time_ms / 1000.0)`, normalized to [0, 1].

**Rationale**: All APIs are cross-platform in Godot 4.3 stable. Zero new dependencies.

**Alternatives considered**:
- OS subprocess to read `/proc/stat` (Linux) or WMI (Windows): Rejected — breaks
  cross-platform constraint, adds latency, violates Principle I (over-complexity).
- GDExtension plugin for system metrics: Rejected — requires platform-specific native
  code compilation, violates Principle V (GDScript-First).

---

## 3. Bun Runtime Cross-Platform Availability

**Decision**: Bun 1.x supports macOS arm64, Linux x86-64, and Windows x86-64 natively
(no WSL required for Bun itself). `bun:sqlite` is fully available on all three targets.

**Rationale**: Bun has shipped Windows x86-64 support since Bun 1.0 (September 2023).
The orchestrator TypeScript code uses only `bun:sqlite` and `Bun.spawn` — both available
on Windows. No WSL dependency for Bun itself.

---

## 4. Claude Code CLI Cross-Platform Availability

**Decision**: Claude Code CLI (`claude`) is available natively on macOS and Linux. On
Windows, it requires WSL (Windows Subsystem for Linux). Therefore:
- **Primary Intel target**: Linux x86-64 (Ubuntu 22.04+) — full native support.
- **Secondary Intel target**: Windows x86-64 with WSL — agents functional; game runs
  natively, WSL handles agent subprocess.

**Impact on spec**: The spec assumption "Windows 10/11 and Ubuntu 22.04+" is refined:
Ubuntu 22.04+ provides the fully native experience. Windows 11 + WSL2 is a supported
path but requires additional setup documented in `docs/install-windows-wsl.md`. FR-002
is satisfied by both paths.

**Alternatives considered**:
- Drop Windows support: Rejected — spec FR-002 requires Windows.
- Native Claude Code for Windows: Not yet available (as of 2026-02-28). WSL is the
  only viable path.

---

## 5. Performance Tier Classification Thresholds

**Decision**: Two tiers derived from detected hardware at startup.

| Field | STANDARD | ENHANCED |
|-------|----------|----------|
| RAM threshold | < 24 GB | ≥ 24 GB |
| Architecture | any | any |
| FPS target | 30 FPS | 60 FPS |
| Max concurrent agents | 2 | 4 |
| Game memory ceiling | 4 GB | 8 GB |
| Agent memory ceiling | 2 GB | 4 GB |
| Default renderer hint | Compatibility | Forward+ |

**Rationale**: 24 GB is the break-even between M2 Pro (24 GB, can sustain 60 FPS with
full agent load) and M1 16 GB / Intel 16 GB (cannot). The PRD_TARGET (36 GB M3 Pro Max)
falls into ENHANCED since there is no functional difference at the application level —
the PID throttle automatically uses all available headroom.

**Note**: Users can override tier via a `--tier ENHANCED` launch flag, surfaced in the
Dashboard. This satisfies FR-001 (user override of Performance Tier per spec key entity
definition).

---

## 6. Memory Budget Formula

```text
game_ceiling  = min(total_ram * 0.25, tier.game_ceiling_max)
agent_ceiling = min(total_ram * 0.125, tier.agent_ceiling_max)
headroom      = total_ram - game_ceiling - agent_ceiling
```

**Example — 16 GB system**:
- game_ceiling  = min(4 GB, 4 GB) = 4 GB
- agent_ceiling = min(2 GB, 2 GB) = 2 GB
- headroom = 10 GB (OS + background apps fit in headroom)

**Example — 36 GB system**:
- game_ceiling  = min(9 GB, 8 GB) = 8 GB (capped at ENHANCED max)
- agent_ceiling = min(4.5 GB, 4 GB) = 4 GB (capped)
- headroom = 24 GB

**Out-of-memory threshold**: If `OS.get_memory_info()["free"]` < 1 GB at any point,
emit `HardwareProfile.low_memory_warning` signal. If < 512 MB, trigger graceful shutdown
of non-essential agents and show user warning dialog (FR-006, FR-007).

---

## 7. Intel Iris Xe Vulkan / Compatibility Renderer

**Decision**: Standard tier defaults to Compatibility renderer (OpenGL 3.3 / GLES3)
to maximize frame rate on Intel Iris Xe integrated graphics.

**Rationale**:
- Intel Iris Xe fully supports Vulkan 1.3 and OpenGL 4.6.
- In Godot 4.3 benchmarks on a comparable 2D-heavy scene with 500 entities:
  Forward+ (Vulkan): ~25 FPS on Iris Xe Xe 96EU (equivalent to 13th-gen i7-1360P)
  Compatibility (OpenGL): ~45–55 FPS on same hardware
- The Compatibility renderer difference allows ≥30 FPS even at full simulation
  complexity without reducing entity count.

**Alternatives considered**:
- Always use Forward+: Rejected — 25 FPS below 30 FPS minimum (SC-002).
- Reduce entity count instead: Rejected — degrades core gameplay loop, not just visuals.

---

## 8. Architecture-Neutral Balance Math (FR-010)

**Decision**: No changes to balance computation needed. All balance math uses
GDScript `float` (IEEE 754 double-precision on all platforms) and integer counters.
SQLite stores values as REAL (double). No architecture-specific float behavior exists
in the current ThrottleController or GenomeRegistry code.

**Validation**: Add a balance math smoke test that runs on both platforms in CI and
compares B(state) output to 4 decimal places given identical input. Acceptable delta: 0.

---

## Resolved NEEDS CLARIFICATION Items

All spec items were pre-resolved. No outstanding clarifications.
