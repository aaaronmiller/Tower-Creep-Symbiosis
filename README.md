# Tower-Creep Symbiosis

A self-evolving PvPvE tower defense game where players control both towers and creeps
through natural language. The game adapts its simulation speed to available hardware and
evolves its own content through federated agentic compute.

---

## Implementation Agent — Start Here

> **You are an implementation agent beginning the cross-platform support feature.**
> Everything below is your orientation. Read it fully before writing a single line of code.

### Your Entry Point

The task list is your source of truth:

```
specs/001-cross-platform-support/tasks.md
```

Work through it **in phase order**, marking tasks complete as you go. Each task has an
exact file path and enough context to execute without additional research.

To begin, run:

```
/speckit.implement
```

Or execute tasks manually starting at **T001** in Phase 1.

---

### What Has Been Done (Do Not Redo)

| Artifact | Location | Status |
|----------|----------|--------|
| Feature spec | `specs/001-cross-platform-support/spec.md` | ✅ Clarified |
| Implementation plan | `specs/001-cross-platform-support/plan.md` | ✅ Complete |
| Research decisions | `specs/001-cross-platform-support/research.md` | ✅ Complete |
| Data model | `specs/001-cross-platform-support/data-model.md` | ✅ Complete |
| API contracts | `specs/001-cross-platform-support/contracts/` | ✅ Complete |
| Quickstart guide | `specs/001-cross-platform-support/quickstart.md` | ✅ Complete |
| Task list | `specs/001-cross-platform-support/tasks.md` | ✅ Ready |
| Project constitution | `.specify/memory/constitution.md` | ✅ v1.0.0 |

---

### Feature Goal (001-cross-platform-support)

Extend the game to run on **any system with ≥ 16 GB RAM**:
- Linux x86-64 (Ubuntu 22.04+) — primary Intel path
- Windows 10/11 via WSL2 — first-class Windows path
- macOS ARM64 (M1+) — existing primary target, extended to 16 GB configs
- Any ARM64 ≥ 16 GB — stretch goal

**Three user stories in priority order:**
1. **US1 (P1)**: Game launches and installs successfully on 16 GB x86-64
2. **US2 (P1)**: Game maintains ≥ 30 FPS with adaptive throttle on 16 GB x86-64
3. **US3 (P2)**: Full 60 FPS experience on Mac M-series 16 GB

---

### Key Decisions Already Made (Do Not Re-Research)

Read `specs/001-cross-platform-support/research.md` for full rationale. Summary:

| Decision | Choice | Why |
|----------|--------|-----|
| CPU stress metric | Godot frame-time proxy | No OS-specific calls needed |
| Default renderer on Standard tier | Compatibility (OpenGL 3.3) | ~2× FPS vs Forward+ on Intel iGPU |
| Windows agent support | WSL2 | Claude Code CLI not natively on Windows |
| Harness abstraction | `agents/harness/` interface | Enables future Pydantic/OpenAI swap |
| Tier threshold | < 24 GB → STANDARD, ≥ 24 GB → ENHANCED | M2 Pro 24 GB break-even |
| Harness selection | `data/agent-harness.json` + `--harness` flag | No Dashboard UI clutter |

---

### Constitution Constraints (Non-Negotiable)

Read `.specify/memory/constitution.md` for full text. Critical rules:

- **Principle I**: No single-use abstractions. No speculative code. Dead code removed immediately.
- **Principle II**: 60 FPS on M-series. 30 FPS minimum on Standard tier Intel (documented exception).
- **Principle III**: Agents cannot touch core game logic. Gene mutations ≤ ±10%.
- **Principle IV**: B(state) ≥ 0.6 at all times.
- **Principle V**: Hardware detection in GDScript only. TypeScript for orchestration only.

---

### Project Structure

```
godot/
├── autoloads/          # HardwareProfile (NEW), ThrottleController (MODIFY),
│                       # AgentBridge (MODIFY), GameState, GenomeRegistry
├── entities/           # Tower.tscn, Creep.tscn, Projectile.tscn
├── genes/              # behaviors/, attributes/, effects/
└── ui/                 # Dashboard.tscn (MODIFY), PromptEditor.tscn

agents/
├── harness/            # NEW: AgentHarness interface + ClaudeCodeHarness impl
├── arsenal/            # asset-gen/, balance-tuner/, behavior-synth/, code-auditor/
└── orchestrator.ts     # MODIFY: use harness interface

data/
├── platform-config.json  # NEW: per-tier hardware defaults
├── agent-harness.json    # NEW: default harness selection (gitignored after first run)
├── genome.db             # runtime only (gitignored)
└── metrics.db            # runtime only (gitignored)

docs/
├── install-linux.md      # NEW: Ubuntu 22.04 setup guide
└── install-windows-wsl.md # NEW: Windows + WSL2 setup guide

specs/001-cross-platform-support/
├── tasks.md              # YOUR TASK LIST — start here
├── plan.md               # Architecture decisions
├── research.md           # Technology decisions
├── data-model.md         # Entity definitions and contracts
├── contracts/            # HardwareProfile API + platform-config schema
└── quickstart.md         # End-to-end validation guide
```

---

### Running the Project

```bash
# Launch game (Godot editor)
godot4 project.godot

# Launch game headless (smoke test)
godot4 --headless --quit-after 5

# Launch with renderer override (Standard tier)
godot4 --rendering-driver opengl3 project.godot

# Run agent orchestrator
bun run agents/orchestrator.ts

# Run with alternative harness (stretch goal, once implemented)
bun run agents/orchestrator.ts --harness pydantic

# Validate a gene before DB insertion
bash scripts/validate-gene.sh <gene_id>

# Balance math smoke test (FR-010 cross-platform parity)
godot4 --headless -s scripts/balance-smoke.gd
```

---

### MVP Scope

**Implement Phases 1–3 (T001–T014) first**, validate US1, then continue to US2 and US3.

US1 validation: `godot4 --headless --quit-after 5` must exit 0 with
`[HardwareProfile] Tier: STANDARD` printed. Then submit one behavior prompt in-game
and confirm completion within 30 seconds.

---

### Stretch Goals (Out of Scope for This Branch)

The following are **not** in `tasks.md` and require their own feature branches:

- Alternative harness implementations: Pydantic AI, OpenAI SDK, Anthropic ADK,
  OpenClaw, LettaBot (FR-012)
- Windows on ARM / Snapdragon X native Godot export
- Linux ARM64 support
