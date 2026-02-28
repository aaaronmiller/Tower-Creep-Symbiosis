# Feature Specification: Cross-Platform Support (Intel x86-64 + Mac M-Series)

**Feature Branch**: `001-cross-platform-support`
**Created**: 2026-02-28
**Status**: Draft
**Input**: User description: "make sure project can be run on 16gb 13th gen intel cpus as well as mac m series chips"

## Clarifications

### Session 2026-02-28

- Q: Windows support depth → A: WSL2 first-class supported path (not secondary); agentic
  layer refactored to a pluggable harness interface with Claude Code as default; additional
  harness implementations (Pydantic AI, OpenAI SDK, Anthropic ADK, OpenClaw, LettaBot)
  as stretch-goal options, allowing users to select their preferred LLM framework.
- Q: Harness selection mechanism → A: Config file (`data/agent-harness.json`) sets
  default harness; `--harness <name>` launch flag overrides at runtime. No in-game UI —
  Dashboard stays focused on gameplay; settings clutter is explicitly avoided.
- Q: CPU generation scope → A: Broadest possible — any CPU architecture ≥ 16 GB RAM
  (x86-64, ARM64 including Windows on ARM/Snapdragon); 13th-gen Intel is the reference
  test machine. Narrow to x86-64-only if Godot export limitations arise; AMD and 12th-gen
  Intel are implicitly supported alongside the Intel 13th-gen reference.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Run Game on Intel 16GB (Priority: P1)

A developer or player on a Windows or Linux machine equipped with a 13th-gen Intel CPU
and 16 GB of RAM can install and launch Tower-Creep Symbiosis and play a full session,
including natural language prompting, gene evolution, and balance tuning, without
platform-specific errors or manual workarounds.

**Why this priority**: Expanding the supported hardware base is the primary goal of this
feature. Intel/x86-64 on Windows and Linux represents the largest available hardware pool
outside the Apple ecosystem. Without this working, the feature delivers no value.

**Independent Test**: Launch the game on a clean 16 GB Intel 13th-gen system (Windows 11
or Ubuntu 22.04), play for 10 minutes including one full behavior synthesis prompt, and
verify the session ends without crash, error dialog, or out-of-memory termination.

**Acceptance Scenarios**:

1. **Given** a clean Windows 11 install on a 16 GB Intel 13th-gen machine,
   **When** the user runs the game launcher,
   **Then** the game starts in under 2 minutes and the main gameplay scene is visible.

2. **Given** a running gameplay session on the above system,
   **When** the user submits a natural language creep behavior prompt,
   **Then** the behavior-synth agent completes the request and the new behavior is active
   in game within 30 seconds.

3. **Given** the game running for 10 minutes on a 16 GB system,
   **When** the adaptive throttle monitors resource pressure,
   **Then** total memory usage stays at or below 8 GB throughout the session.

---

### User Story 2 - Acceptable Performance on Intel 16GB (Priority: P1)

On a 16 GB Intel 13th-gen system, the game maintains smooth, playable frame rates during
normal gameplay. When the system is under pressure, the adaptive throttle reduces
simulation complexity rather than dropping frames or crashing.

**Why this priority**: A game that launches but runs unplayably is not viable. This pairs
with US1 to form the minimum viable cross-platform experience.

**Independent Test**: Run a 15-minute gameplay session on a 16 GB Intel system under
normal background load (browser + OS services). Measure frame rate throughout. Verify the
throttle activates within 2 seconds of any sustained resource spike.

**Acceptance Scenarios**:

1. **Given** normal gameplay (no extra background load),
   **When** measuring frame rate over a 10-minute session on a 16 GB Intel system,
   **Then** average FPS is ≥ 30 and the game never drops below 20 FPS for more than
   3 consecutive seconds.

2. **Given** the system experiencing high memory pressure (> 75% utilization),
   **When** the adaptive throttle detects this condition,
   **Then** agent execution frequency and simulation tick rate are reduced within 2 seconds,
   and the frame rate recovers above 20 FPS within 5 seconds.

3. **Given** the throttle has reduced simulation speed due to resource pressure,
   **When** system pressure drops back below 60% utilization,
   **Then** simulation speed increases back toward target over the next 10 seconds.

---

### User Story 3 - Full Experience on Mac M-Series (Priority: P2)

A Mac user with an M1, M2, or M3 chip and at least 16 GB of RAM can play Tower-Creep
Symbiosis at target performance (60 FPS), including all agentic features, without any
additional configuration.

**Why this priority**: Mac M-series is the existing primary target, but the PRD assumed
36 GB. This story validates the game works across M-series chips at the lower 16 GB
configuration that many users actually own.

**Independent Test**: Launch the game on a Mac with an M1 chip and 16 GB RAM. Play for
10 minutes including all four agent types. Verify 60 FPS is maintained and memory stays
under 8 GB.

**Acceptance Scenarios**:

1. **Given** a Mac with M1 (16 GB) or later,
   **When** the user launches the game,
   **Then** the game starts in under 90 seconds and runs at ≥ 60 FPS under normal load.

2. **Given** a Mac with M-series chip,
   **When** all four agent types (asset-gen, balance-tuner, behavior-synth, code-auditor)
   are triggered during a gameplay session,
   **Then** all four complete at least one task successfully within the session.

---

### Edge Cases

- What happens when available RAM drops below the required game memory budget mid-session
  (e.g., another application opens)? The game MUST warn the user without crashing and
  reduce its memory footprint if possible.
- What happens on a system with only an integrated Intel GPU (no discrete GPU)?
  The game MUST still render and run at reduced quality; it MUST NOT refuse to start.
- What happens if the agent orchestrator cannot be launched (e.g., Bun is not installed)?
  The base game MUST still start and be playable; agentic features MUST degrade gracefully
  with an informative error shown in the dashboard.
- What is the behavior on M1 with only 8 GB of RAM? This configuration is explicitly
  out of scope; the game may show an unsupported hardware warning and exit cleanly.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The game MUST detect available system memory and CPU core count at startup
  and configure memory budgets and agent concurrency limits accordingly.
- **FR-002**: The game MUST run on any x86-64 system with ≥ 16 GB RAM on Ubuntu 22.04+
  (native) and Windows 10/11 (via WSL2); both are first-class supported paths. Intel
  13th-gen is the reference test hardware. AMD Ryzen, 12th-gen Intel, and other x86-64
  CPUs are implicitly supported. Windows on ARM (Snapdragon X) via WSL2 is a stretch-goal
  target; narrow to x86-64-only if Godot export limitations arise.
- **FR-003**: The game MUST run on any ARM64 system with ≥ 16 GB RAM, including Mac
  M1 or later and, as a stretch goal, other ARM64 platforms (e.g., Linux on ARM64).
- **FR-004**: The adaptive simulation throttle MUST use real-time resource signals —
  frame processing time as a CPU stress proxy, and live free-memory readings — available
  natively from the game engine on all supported platforms. No platform-specific OS calls
  are permitted; no hardcoded hardware assumptions.
- **FR-005**: All four agent types MUST be schedulable and executable on any x86-64
  system running Ubuntu natively or Windows via WSL2.
- **FR-006**: Total game memory usage MUST remain at or below 50% of total system RAM
  on any supported platform under normal gameplay.
- **FR-007**: The game MUST display a clear, non-crashing error to the user when
  available memory falls below a safe operating threshold, and MUST attempt to free
  non-critical resources before terminating.
- **FR-008**: Installation MUST succeed on all supported platforms by following a single
  documented setup procedure per platform, with no undocumented manual steps.
- **FR-009**: The game MUST function without requiring a dedicated GPU; integrated
  graphics MUST be sufficient to run at reduced visual quality settings.
- **FR-010**: The balance metric B(state) and the self-evolution genome loop MUST
  produce correct results on all supported CPU architectures (no architecture-specific
  numeric divergence).
- **FR-011**: The agent orchestration layer MUST be implemented as a pluggable harness
  interface; Claude Code CLI MUST be the default implementation. Harness selection MUST
  be controlled via `data/agent-harness.json` (persistent default) or the `--harness`
  launch flag (session override). No in-game UI for harness selection.
- **FR-012** *(stretch goal)*: The system MUST support alternative harness implementations
  — Pydantic AI, OpenAI SDK, Anthropic ADK, OpenClaw, and LettaBot — each satisfying the
  same four agent-type contracts (asset-gen, balance-tuner, behavior-synth, code-auditor).
  Switching harnesses MUST require only a config or flag change, with no code modification.

### Key Entities

- **Hardware Profile**: Detected at startup; captures CPU architecture, physical core
  count, total RAM, available RAM, and GPU capability tier. Drives memory budget
  initialization and default throttle parameters. Persisted for the session only.
- **Memory Budget**: Per-subsystem RAM allocation (game simulation, agent processes,
  headroom) derived from the Hardware Profile. Enforced throughout the session;
  adjusted dynamically if pressure exceeds thresholds.
- **Performance Tier**: A classification (Standard or Enhanced) assigned from the
  Hardware Profile at startup. Determines default simulation quality, maximum concurrent
  agents, and throttle aggressiveness. Users MUST be able to override the tier manually.
- **Agent Harness**: The pluggable interface that wraps LLM orchestration for all four
  agent types. Defines a common contract (inputs, outputs, error protocol) that any
  harness implementation must satisfy. Default: Claude Code CLI. Stretch-goal
  implementations: Pydantic AI, OpenAI SDK, Anthropic ADK, OpenClaw, LettaBot.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Game starts successfully on any x86-64 system with 16 GB RAM (reference:
  Intel 13th-gen, Windows 11 via WSL2 or Ubuntu 22.04) in under 2 minutes from launch.
- **SC-002**: Game maintains average ≥ 30 FPS during a 10-minute normal gameplay session
  on any x86-64 or ARM64 system with 16 GB RAM (reference test: Intel 13th-gen).
- **SC-003**: Game memory usage peaks at ≤ 8 GB on any 16 GB system during a normal
  10-minute gameplay session.
- **SC-004**: All four agentic features complete at least one full task cycle without
  error during a test session on x86-64 hardware (Ubuntu native or Windows via WSL2).
- **SC-005**: Game starts and maintains ≥ 60 FPS on any ARM64 system with 16 GB RAM
  (reference: Mac M1 16 GB) under normal gameplay.
- **SC-006**: The adaptive throttle responds to sustained resource pressure within
  2 seconds on all supported platforms.
- **SC-007**: Game produces a user-visible informative message (not a crash or silent
  hang) when started on explicitly unsupported hardware (< 16 GB RAM).

## Assumptions

- **Reference test hardware**: Intel 13th-gen x86-64 with 16 GB RAM (Ubuntu 22.04 and
  Windows 11 via WSL2). AMD Ryzen, 12th-gen Intel, and other x86-64 CPUs are implicitly
  supported. Windows on ARM (Snapdragon X) is a stretch-goal target.
- **Minimum configuration**: Any CPU architecture with ≥ 16 GB RAM. Systems with < 16 GB
  are explicitly out of scope; the game shows an unsupported hardware message and exits.
- **GPU**: At least an integrated GPU capable of OpenGL 3.3 or Vulkan 1.0; discrete GPU
  not required. Intel Iris Xe, AMD Radeon 680M, and Apple GPU all qualify.
- **Agent harness default**: Claude Code CLI; runs inside WSL2 on Windows. Harness is
  swappable via `data/agent-harness.json` or `--harness` flag. Alternative harnesses
  (Pydantic AI, OpenAI SDK, Anthropic ADK, OpenClaw, LettaBot) are stretch-goal targets.
- **LLM inference**: All agents use the Anthropic API (or equivalent remote API for
  alternative harnesses); no local model inference required. ANE absence on non-Mac
  hardware is irrelevant.
- **Free memory at launch**: Any supported 16 GB system is assumed to have ≥ 10 GB free
  at game launch (OS + background services ≤ 6 GB).
- **Godot export scope**: If Godot 4.3 export template limitations prevent Windows on ARM
  or other non-reference platforms, scope narrows to x86-64 + Apple ARM64 only (Option B
  fallback) without spec amendment.
