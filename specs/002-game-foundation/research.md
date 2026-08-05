# Research: Game Foundation — Playable Core to Self-Evolving System

**Phase 0 output for**: `specs/002-game-foundation/plan.md`
**Date**: 2026-03-10
**Status**: Complete — all unknowns resolved

---

## 1. GUT (Godot Unit Testing) Plugin — Headless Testing

**Decision**: Use GUT v9.x, vendored directly into `addons/gut/` from the
[GitHub release](https://github.com/bitwes/Gut). Do NOT rely on Godot AssetLibrary
download at test-time — vendor the plugin for reproducible headless runs.

**Headless command** (confirmed for Godot 4.3 Linux x86-64):
```bash
# Step 1: pre-import project (required on first run, creates .godot/ cache)
godot4 --headless --path . --import --quit

# Step 2: run tests
GODOT_DISABLE_LEAK_CHECKS=1 godot4 --headless \
  --display-driver headless \
  --audio-driver Dummy \
  --disable-render-loop \
  -s res://addons/gut/gut_cmdln.gd \
  -gdir=res://godot/tests \
  -ginclude_subdirs \
  -gexit
```
The `-gdir` + `-ginclude_subdirs` flags scan the directory recursively for test scripts.
`-gexit` ensures non-zero exit on failures (required for CI). `GODOT_DISABLE_LEAK_CHECKS=1`
prevents false-positive leak warnings from dummy renderer storage.

**Rationale**: GUT v9.x is the only maintained unit test framework for GDScript 4.x.
It provides mock/spy patterns (`double()`, `stub()`, `assert_called()`), signal testing
(`watch_signals()`), and headless-compatible test runner. All of these are needed for
testing GenomeRegistry (mock SQLite), AgentBridge (mock subprocess), and SelfOptimizer
(spy on rollback calls).

**Known issues** (Godot 4.3 + Linux x86-64):
- GUT v9.4.x had a signal watcher bug on Godot 4.3; use v9.6+ which targets 4.3+.
- Without pre-import (`--import --quit`), headless launch may hang waiting for `.godot/` cache.
- Test files MUST be named `test_*.gd` or `*_test.gd` for auto-discovery.
- "Parameter 'm' is null" errors in CI are a known dummy renderer artifact — suppressed by
  `GODOT_DISABLE_LEAK_CHECKS=1` and `--disable-render-loop`.

**Alternatives considered**:
- Manual test scripts (ad-hoc `assert` statements): rejected — no mocking, no signal
  testing, no structured reporting. Would require 10× more boilerplate.
- gdUnit4: actively maintained alternative; rejected in favor of GUT because GUT has
  longer Godot 4.x track record and the PRD already references it.

---

## 2. SQLite WAL Mode — Concurrent GDScript + Bun Access

**Decision**: Enable WAL mode with `busy_timeout = 5000` on both connections.
`genome.db` is written by GDScript (gene registration, methylation) and read by
the Bun orchestrator (balance metrics read). `metrics.db` is written by the
orchestrator and read by GDScript (Dashboard). WAL mode makes this safe.

**Required pragmas** (set immediately after opening each DB connection):
```sql
PRAGMA journal_mode = WAL;
PRAGMA busy_timeout = 5000;
PRAGMA synchronous = NORMAL;
```

**bun:sqlite configuration**:
```typescript
const db = new Database("data/genome.db");
db.run("PRAGMA journal_mode = WAL");
db.run("PRAGMA busy_timeout = 5000");
db.run("PRAGMA synchronous = NORMAL");
```

**Rationale**: SQLite WAL allows one writer + many simultaneous readers without
blocking. `busy_timeout = 5000` (5 seconds) absorbs brief contention windows when
the orchestrator writes metrics while GDScript reads balance values. `synchronous =
NORMAL` is safe with WAL and avoids unnecessary fsync overhead.

**IPC for agent task results**: Use filesystem JSON polling (`user://agent-results/<id>.json`),
NOT shared SQLite. Agent task results are ephemeral and write-once — SQLite table
locking for ephemeral results adds unnecessary contention. File polling is simpler,
and GDScript's `FileAccess` + a 250ms Timer is sufficient throughput for 2–4
concurrent agents.

**Alternatives considered**:
- Full SQLite for agent results: rejected — adds schema complexity and write contention
  for ephemeral records that don't need to survive past a session.
- TCP socket IPC: rejected — requires GDExtension or OS-specific socket code; violates
  constitution Principle V (no GDExtension unless provably necessary).
- Named pipes: rejected — not reliably available in Godot 4.3's process abstraction
  on all supported platforms.

---

## 3. gdtoolkit — GDScript 4.x Static Analysis for validate-gene.sh

**Decision**: Use `gdtoolkit` (pip install gdtoolkit) for GDScript 4.x syntax
validation. The `gdparse` command parses and validates syntax; `gdlint` checks style.

**Install and usage**:
```bash
pip3 install "gdtoolkit==4.*"   # Must pin to 4.x for GDScript 4.x support
gdlint path/to/gene.gd && echo "LINT OK" || echo "LINT ERROR"
```

**gdtoolkit 4.x status**: gdtoolkit 4.3.3+ explicitly supports GDScript 4.x syntax
(latest: 4.5.0). `gdlint` performs two-phase validation: syntax parsing + configurable
linting rules. Exits non-zero on errors. `gdparse` is the lower-level parser;
`gdlint` is the preferred validation tool as it catches more issues.

**Limitation**: `gdlint` does NOT natively detect forbidden patterns (`FileAccess`,
`while true:`, inheritance violations). These require grep supplement.

**validate-gene.sh strategy** (combining gdtoolkit + grep):
1. `gdlint "$GENE"` — syntax + lint validation (exits 1 on error)
2. `grep -q 'extends BehaviorBase' "$GENE"` — class inheritance check
3. `grep -q 'func _evaluate(context' "$GENE"` — method signature check
4. `grep -qE 'FileAccess|HTTPRequest|OS\.execute|while\s+true' "$GENE"` — forbidden patterns (exit 1 if found)
5. Loop bounds heuristic: `awk` scan for `for` loops; warn (not error) if static
   bound exceeds 100

**Alternatives considered**:
- `godot4 --check-only`: requires a full Godot project context to type-check; too heavy
  and would require a separate headless launch per gene validation.
- Pure grep: syntax errors wouldn't be caught. gdparse catches malformed GDScript that
  grep would miss (unclosed strings, bad indentation, etc.).
- gdUnit4 validator: not designed for gene validation; overkill.

---

## 4. Claude Code CLI — Headless CIO Pattern Invocation

**Decision**: Use `claude -p "<prompt>" --output-format stream-json` for headless
non-interactive agent invocation. The `-p` flag passes a prompt directly, suppressing
interactive mode. `--output-format stream-json` produces newline-delimited JSON events
on stdout.

**Confirmed invocation** (validated against claude CLI docs):
```bash
# Structured JSON output (recommended for orchestrator parsing)
claude -p "$USER_PROMPT" --output-format json --no-user-prompt 2>&1

# Streaming JSON (for long-running tasks with progress events)
claude -p "$USER_PROMPT" --output-format stream-json --no-user-prompt 2>&1 | tee "/tmp/tcs-agent-$ID.log"
```

`--no-user-prompt` is critical — without it, Claude Code may block waiting for
interactive confirmation on ambiguous operations.

**Bun subprocess integration** (confirmed pattern):
```typescript
const proc = Bun.spawn(
  ["claude", "-p", task.prompt, "--output-format", "json", "--no-user-prompt"],
  { cwd: sessionDir, stdio: ["pipe", "pipe", "pipe"] }
);
const output = await Bun.readableStreamToText(proc.stdout);
const result = JSON.parse(output);
// result.result contains the agent's text output
// result.type === "result", result.subtype === "success" | "error"
```

**JSON output structure**:
```json
{
  "type": "result",
  "subtype": "success",
  "result": "extends BehaviorBase\n...",
  "session_id": "...",
  "duration_ms": 12345,
  "total_cost_usd": 0.01
}
```

**Rationale**: `-p` flag is the correct non-interactive invocation. `--output-format json`
is simpler to parse than `stream-json` for the orchestrator's task result extraction.
Use `stream-json` only if real-time progress detection is needed for timeout logic.

**Availability check**: `claude --version` exit code 0 confirms availability.
`ClaudeCodeHarness.isAvailable()` runs this check at orchestrator startup.

**Alternatives considered**:
- `claude --print`: alias for `-p`, works identically. Chose `-p` for consistency
  with PRD §9.3 which uses it explicitly.
- Anthropic API SDK directly from TypeScript: would bypass the CIO pattern and the
  agent persona CLAUDE.md injection. The CIO pattern's value is the pre-configured
  agent context; direct API calls lose this.

---

## 5. Godot 4.3 — SQLite Plugin for GDScript

**Decision**: Use the `gdsqlite` GDExtension plugin (MIT license) for SQLite access
from GDScript. This is the only viable path — GDScript has no built-in SQLite.

**Plugin**: [godot-sqlite](https://github.com/2shady4u/godot-sqlite) — pre-built
binaries available for Linux x86-64, Windows, macOS ARM64. Vendored into `addons/gdsqlite/`.

**WAL pragma** — set in `GenomeRegistry._ready()`:
```gdscript
_db.query("PRAGMA journal_mode = WAL")
_db.query("PRAGMA busy_timeout = 5000")
_db.query("PRAGMA synchronous = NORMAL")
```

**Rationale**: godot-sqlite is the de-facto standard for SQLite in Godot 4.x projects.
It wraps the SQLite C library and exposes a GDScript-friendly API matching the PRD's
`_db.select_rows()`, `_db.insert_row()`, `_db.query()` calls exactly. MIT licensed,
active maintenance, pre-built for all our target platforms.

**Constitution note**: This IS a GDExtension — the only one permitted by the
constitution ("unless GDScript is provably incapable of meeting the performance budget").
SQLite access is categorically impossible in pure GDScript; this exception is justified.
Documented in plan.md Complexity Tracking.

**Alternatives considered**:
- Flat JSON files for gene storage: rejected — no query capability, no atomic writes,
  no foreign-key relationships for gene_lineage. The balance metric query patterns
  (Gini coefficient, aggregation) require SQL.
- Custom TCP server with an external SQLite process: rejected — excessive complexity
  for single-player local storage.

---

## Summary — All Unknowns Resolved

| Unknown | Resolution |
|---------|------------|
| GUT version and headless command | GUT v9.6+; `godot4 --headless -s res://addons/gut/gut_cmdln.gd -gdir=res://godot/tests` |
| SQLite WAL concurrent safety | Safe with WAL + busy_timeout=5000; file polling for agent results |
| gdtoolkit GDScript 4.x support | Supported (pin `gdtoolkit==4.*`); `gdlint` + grep is the validate-gene.sh strategy |
| Claude CLI headless invocation | `claude -p "<prompt>" --output-format stream-json` |
| GDScript SQLite access | godot-sqlite GDExtension (MIT); only justified GDExtension in project |
