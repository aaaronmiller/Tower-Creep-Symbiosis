# Quickstart: Game Foundation — Developer Validation Guide

**Feature**: `002-game-foundation`
**Platform**: Ubuntu 22.04 x86-64 (WSL2 primary, native Linux secondary)
**Date**: 2026-03-10

This guide validates each phase gate. Run the commands in order after each phase
is implemented. All commands assume WSL2/bash with repo at `~/code/Tower-Creep-Symbiosis`.

---

## Prerequisites

```bash
# Install Godot 4.3 (Linux x86-64)
# Download from https://godotengine.org/download/linux/
# Extract and symlink:
sudo ln -sf ~/godot/Godot_v4.3-stable_linux.x86_64 /usr/local/bin/godot4

# Install Bun
curl -fsSL https://bun.sh/install | bash
source ~/.bashrc  # or ~/.zshrc

# Install gdtoolkit 4.x (for validate-gene.sh — must pin to 4.x for GDScript 4 support)
pip3 install "gdtoolkit==4.*"

# Install Claude Code CLI
npm install -g @anthropic/claude-code
claude config set-key YOUR_ANTHROPIC_API_KEY

# Verify all tools
godot4 --version      # Expected: 4.3.stable
bun --version         # Expected: 1.x.x
gdlint --version      # Expected: gdtoolkit x.x (confirm 4.x)
claude --version      # Expected: @anthropic/claude-code x.x
```

---

## Phase 1 Gate — Project Scaffold

```bash
cd ~/code/Tower-Creep-Symbiosis

# Verify Godot project opens (window should appear, then close)
godot4 project.godot &
sleep 3 && kill %1 2>/dev/null; echo "Window test done"

# Pre-import project (required before first headless test run)
godot4 --headless --path . --import --quit

# Run GUT tests headlessly
GODOT_DISABLE_LEAK_CHECKS=1 godot4 --headless \
  --display-driver headless --audio-driver Dummy --disable-render-loop \
  -s res://addons/gut/gut_cmdln.gd -gdir=res://godot/tests -ginclude_subdirs -gexit
echo "GUT exit code: $?"  # Expected: 0
```

**Expected output**:
```
[GameState] Initialized: lives=20 gold=100 cycles=100
[GenomeRegistry] Stub initialized (SQLite deferred to Phase 3)
[ThrottleController] PID controller ready: target=60fps
[AgentBridge] Stub initialized
GUT: 3 tests passed, 0 failed
```

---

## Phase 2 Gate — Core Gameplay

```bash
# Run all entity GUT tests
godot4 --headless -s res://addons/gut/gut_cmdln.gd -gdir=res://godot/tests
echo "Exit: $?"  # Expected: 0 (now includes entity tests)

# Manual play test: open game and complete one wave
godot4 project.godot
# Expected: Arena visible, creeps spawn and walk path, towers shoot, HUD shows wave info
# Required: complete wave 1 without crash
```

**Acceptance checklist**:
- [ ] Creeps spawn at path start and follow waypoints
- [ ] Tower fires projectile when creep enters range
- [ ] Creep health reaches 0 → `died` signal → creep removed → gold awarded
- [ ] Creep reaches exit → lives decrements in HUD
- [ ] Wave 1 complete → wave counter increments or game-over shown

---

## Phase 3 Gate — Gene System

```bash
# Run genome GUT tests
godot4 --headless -s res://addons/gut/gut_cmdln.gd -gdir=res://godot/tests/unit/genome
echo "Exit: $?"  # Expected: 0

# Validate-gene.sh on example valid gene
bash scripts/validate-gene.sh godot/genes/behaviors/FlankBehavior.gd
echo "Exit: $?"  # Expected: 0

# Validate-gene.sh on a deliberately bad gene (should fail)
cat > /tmp/bad_gene.gd << 'EOF'
extends Node  # Wrong base class
func do_nothing():
    FileAccess.open("/etc/passwd", FileAccess.READ)
EOF
bash scripts/validate-gene.sh /tmp/bad_gene.gd
echo "Exit: $?"  # Expected: 1

# Run game — assign FlankBehavior to a creep manually via inspector
# Observe that FlankBehavior creep takes a different route than WalkPathBehavior
godot4 project.godot
```

**Expected validate-gene.sh stderr on bad gene**:
```
ERROR: Must extend BehaviorBase
```

---

## Phase 4 Gate — Agent Integration

```bash
# Run TypeScript tests
cd ~/code/Tower-Creep-Symbiosis
bun test agents/
echo "Exit: $?"  # Expected: 0

# Run GUT agent bridge tests
godot4 --headless -s res://addons/gut/gut_cmdln.gd -gdir=res://godot/tests/unit
echo "Exit: $?"  # Expected: 0

# Full integration test
# Terminal 1: Start orchestrator (optional — game should work without it)
bun run agents/orchestrator.ts &
ORCH_PID=$!

# Terminal 1 (or same): Launch game
godot4 project.godot

# In game: open PromptEditor, type "fast creep that targets weakest tower", press Submit
# Expected within 30s: new creep spawns with synthesized behavior

# Graceful degrade test: kill orchestrator while game is running
kill $ORCH_PID
# Expected: PromptEditor shows amber "Agent offline" message, game continues

# Verify: re-submit prompt → uses WalkPathBehavior fallback, no crash
```

**Expected log on orchestrator startup**:
```
[AgentBridge] Orchestrator started (pid: XXXX)
[AgentBridge] Harness: claude-code (available: true)
```

**Expected log on orchestrator death**:
```
[AgentBridge] Orchestrator died (exit: 143)
[AgentBridge] Graceful degrade: queued tasks will use default behavior
```

---

## Phase 5 Gate — MadLibs & Sprite Generation

```bash
# GUT test for MadlibsMixer determinism
godot4 --headless -s res://addons/gut/gut_cmdln.gd -gdir=res://godot/tests/unit
echo "Exit: $?"  # Expected: 0 (includes test_madlibs_mixer.gd)

# Generate sprite set via asset-gen agent (requires API key + orchestrator running)
bun run agents/orchestrator.ts &
bash scripts/generate-sprites.sh
echo "Exit: $?"  # Expected: 0

# Count generated sprites
ls data/assets/sprites/towers/ | wc -l   # Expected: ≥ 36
ls data/assets/sprites/creeps/ | wc -l   # Expected: ≥ 36

# Verify sprite dimensions and color count
# (validate-gene logic in sprite loader handles this at runtime)
# Run game: entities should display sprites instead of ColorRects
godot4 project.godot
# Expected: towers and creeps show pixel art sprites
```

---

## Phase 6 Gate — Self-Evolution

```bash
# Run evolution GUT tests
godot4 --headless -s res://addons/gut/gut_cmdln.gd -gdir=res://godot/tests/unit/evolution
echo "Exit: $?"  # Expected: 0

# Balance formula smoke test (verifies SC-001 and FR-011)
godot4 --headless -s scripts/evolution-smoke.gd
echo "Exit: $?"  # Expected: 0

# Verify balance_metrics table populated
sqlite3 data/metrics.db "SELECT COUNT(*), MIN(composite_balance) FROM balance_metrics"
# Expected: count ≥ 10, min ≥ 0.45
sqlite3 data/genome.db "SELECT COUNT(*) FROM gene_lineage WHERE mutation_type='macro-compiled'"
# Expected: ≥ 1
```

---

## Phase 7 Gate — Dashboard

```bash
# Run dashboard GUT tests
godot4 --headless -s res://addons/gut/gut_cmdln.gd -gdir=res://godot/tests/unit
echo "Exit: $?"  # Expected: 0

# Manual: run game, observe Dashboard
godot4 project.godot
# Expected: Dashboard visible with:
#   - FPS counter updating
#   - Memory bar showing current usage
#   - B(state) value ≥ 0.6
#   - Gene pool count > 0 (default genes registered)
```

---

## Phase 8 Gate — Full Integration (SC-001 through SC-008)

```bash
# Final full GUT suite
godot4 --headless -s res://addons/gut/gut_cmdln.gd -gdir=res://godot/tests
echo "Exit: $?"  # Expected: 0 — ALL tests pass

# Final TypeScript test suite
bun test agents/
echo "Exit: $?"  # Expected: 0

# Final evolution smoke
godot4 --headless -s scripts/evolution-smoke.gd
echo "Exit: $?"  # Expected: 0
```

**Manual acceptance checklist** (record results in `test-results-wsl2.md`):
- [ ] SC-001: GUT exits 0, all tests pass
- [ ] SC-002: `bun test` exits 0
- [ ] SC-003: 3-wave session complete in < 5 minutes, no crashes
- [ ] SC-004: NL prompt → new creep within 30s (with API key + orchestrator)
- [ ] SC-005: `MadlibsMixer.mix(42)` returns same ID on this machine as expected oracle
- [ ] SC-006: ≥ 36 tower + 36 creep sprites in `data/assets/sprites/`
- [ ] SC-007: Evolution smoke exits 0, ≥ 10 balance rows, composite_balance ≥ 0.45
- [ ] SC-008: Kill orchestrator mid-session → no crash → amber PromptEditor message

**On all items checked**: tag release and open PR.
```bash
git add -A
git commit -m "feat(002): game foundation complete — all SC-001 through SC-008 pass"
git push origin 002-game-foundation
# Open PR: 002-game-foundation → main
# After merge: Feature 001 branches from main
```
