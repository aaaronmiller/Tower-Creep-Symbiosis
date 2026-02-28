# Quickstart: Cross-Platform Support Validation

**Branch**: `001-cross-platform-support` | **Date**: 2026-02-28

Use this guide to verify the cross-platform feature works end-to-end on each target
platform after implementation.

---

## Prerequisites (All Platforms)

- Godot 4.3 stable installed (or the project exported as a binary)
- Bun 1.x installed (`bun --version` should print 1.x)
- Claude Code CLI installed (`claude --version` should work)
- Repository cloned and on branch `001-cross-platform-support`

---

## Linux (Ubuntu 22.04+ x86-64) — Primary Intel Path

```bash
# 1. Verify hardware meets minimum spec
free -h   # confirm ≥ 16 GB RAM shown

# 2. Run platform detection smoke test (prints detected tier to stdout)
bun run agents/orchestrator.ts --detect-platform

# 3. Launch game headless and verify startup
./tower-creep-symbiosis.x86_64 --headless --quit-after 5
# Expected: prints "HardwareProfile: STANDARD tier detected" and exits 0

# 4. Launch game with display
./tower-creep-symbiosis.x86_64
# Expected: Dashboard shows tier label (STANDARD or ENHANCED), memory bar visible

# 5. Trigger behavior synthesis (verifies agents work)
# In-game: open prompt editor, type "fast flanking scout", submit
# Expected: behavior-synth agent completes within 30 seconds, new behavior active

# 6. Check memory usage stays within budget
# Dashboard memory bar should stay below the red line throughout a 10-minute session
```

---

## Windows (x86-64 via WSL2) — Secondary Intel Path

```powershell
# In PowerShell (Admin): ensure WSL2 is installed
wsl --status
```

```bash
# Inside WSL2 Ubuntu shell:

# 1. Clone repo (if not already done inside WSL filesystem)
git clone <repo-url> && cd Tower-Creep-Symbiosis

# 2. Install Bun
curl -fsSL https://bun.sh/install | bash

# 3. Install Claude Code CLI
npm install -g @anthropic/claude-code

# 4. Launch the Windows game binary from WSL (game runs natively on Windows,
#    agents run in WSL)
# Open a separate PowerShell window and launch:
#   tower-creep-symbiosis.exe
# Then in WSL:
bun run agents/orchestrator.ts

# 5. Verify agent IPC: submit a prompt in-game and confirm completion
```

**Note**: The game executable runs natively on Windows (Godot x86-64 export). The
agent orchestrator runs in WSL. The IPC bridge communicates via `data/agent_results.json`
on a shared filesystem path. Ensure the repository is cloned inside the WSL filesystem
(not `/mnt/c/...`) for reliable file I/O performance.

---

## macOS (ARM64, M1 or later) — Full Native Path

```bash
# 1. Verify hardware
system_profiler SPHardwareDataType | grep -E "Memory|Chip"
# Expected: "Chip: Apple M1" (or M2/M3) and "Memory: 16 GB" (or more)

# 2. Install Bun (if not already)
curl -fsSL https://bun.sh/install | bash

# 3. Launch game
open tower-creep-symbiosis.app
# Or from terminal:
./tower-creep-symbiosis.arm64

# 4. Verify tier
# Dashboard should show "STANDARD" for 16 GB M1, "ENHANCED" for 24 GB M2 Pro or above

# 5. Full agent cycle test (10-minute session)
# Play normally; confirm all four agent types complete at least one task
# (Dashboard agent log shows completions)
```

---

## Acceptance Scenario Verification

Run through these checks after completing platform-specific setup:

| Check | Command / Action | Pass Condition |
|-------|-----------------|----------------|
| Game starts | Launch binary | Main scene visible in < 2 min |
| Tier detected | Check Dashboard | "STANDARD" or "ENHANCED" label visible |
| Memory within budget | 10-min session | Memory bar never exceeds ceiling (red line) |
| Agents functional | Submit behavior prompt | Behavior active in < 30 s |
| Throttle responds | Open 10 browser tabs (simulate load) | FPS recovers within 5 s after closing them |
| Low memory warning | `--simulate-low-memory` flag | Warning banner appears; no crash |

---

## Troubleshooting

**"Minimum 16 GB RAM required" dialog on startup**
→ The game detected < 16 GB free or total. Close background applications and retry.
If total RAM is < 16 GB, this hardware is out of scope.

**Agents never complete on Linux/Windows**
→ Verify Claude Code CLI is installed and authenticated: `claude --version` and
`claude config` should not error. Check `data/metrics.db` for agent execution logs.

**Low FPS on Intel iGPU (< 30 FPS)**
→ Edit `data/platform-config.json`: set `STANDARD.renderer_hint` to `"opengl3"` if
it was manually changed to `"vulkan"`. Restart the game.

**Dashboard memory bar shows incorrect values**
→ Verify `data/platform-config.json` exists and is valid JSON. Delete it to restore
built-in defaults.
