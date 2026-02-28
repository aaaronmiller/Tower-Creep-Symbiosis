# Tower-Creep Symbiosis — Development Guidelines

Auto-generated from all feature plans. Last updated: 2026-02-28

## Active Technologies

- **Game**: GDScript 4.3 (Godot 4.3, Vulkan Forward+ / Compatibility OpenGL renderer)
- **Orchestrator**: TypeScript with Bun 1.x (`agents/orchestrator.ts`)
- **Persistence**: SQLite WAL via `bun:sqlite` (`data/genome.db`, `data/metrics.db`)
- **Config**: `data/platform-config.json` (per-tier hardware defaults)

## Project Structure

```text
godot/
├── autoloads/          # Singletons: HardwareProfile, GameState, ThrottleController,
│                       #             GenomeRegistry, AgentBridge
├── entities/           # Tower.tscn, Creep.tscn, Projectile.tscn
├── genes/              # behaviors/, attributes/, effects/
└── ui/                 # PromptEditor.tscn, Dashboard.tscn

agents/
├── arsenal/            # asset-gen/, balance-tuner/, behavior-synth/, code-auditor/
│   └── */CLAUDE.md     # Agent persona definitions
└── orchestrator.ts     # Bun-based agent scheduler (CIO pattern)

data/
├── genome.db           # SQLite: gene pool registry
├── metrics.db          # SQLite: balance + performance logs
├── platform-config.json # Per-tier hardware defaults
└── assets/             # Generated sprites and audio

scripts/
├── deploy-agent.sh     # CIO pattern launcher
└── validate-gene.sh    # Gene verification before DB insertion

specs/                  # Feature specs (speckit workflow)
docs/                   # Platform setup guides
```

## Commands

```bash
# Run game (Godot editor)
godot4 project.godot

# Run orchestrator
bun run agents/orchestrator.ts

# Validate a gene before insertion
bash scripts/validate-gene.sh <gene_id>

# Run GDScript tests (requires GUT plugin)
godot4 --headless -s addons/gut/gut_cmdln.gd
```

## Code Style

- **GDScript**: snake_case for variables/functions; PascalCase for classes and signals;
  type annotations on all public API methods
- **TypeScript**: camelCase; explicit return types; no `any`
- **Principle I (constitution)**: No single-use abstractions; dead code removed immediately
- **Principle V (constitution)**: Hardware detection in GDScript only; TypeScript for
  orchestration only

## Recent Changes

- 001-cross-platform-support: Added HardwareProfile autoload, PerformanceTier system,
  platform-config.json, per-tier memory budgets, Compatibility renderer support for Intel

<!-- MANUAL ADDITIONS START -->
<!-- MANUAL ADDITIONS END -->
