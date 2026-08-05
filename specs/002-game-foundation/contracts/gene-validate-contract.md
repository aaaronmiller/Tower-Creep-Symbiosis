# Contract: validate-gene.sh Input/Output

**Version**: 1.0.0
**File**: `scripts/validate-gene.sh`
**Called by**: AgentBridge.gd (after behavior-synth result), deploy-agent.sh pipeline

---

## Invocation

```bash
bash scripts/validate-gene.sh <path-to-gene.gd>
```

**Input**: Absolute or relative path to a `.gd` file (agent-generated or manually written).
**Working directory**: Repository root.

---

## Exit Codes

| Code | Meaning |
|------|---------|
| `0` | Gene is valid — safe to register in GenomeRegistry |
| `1` | Gene is invalid — reason printed to stderr; do NOT register |

---

## Validation Steps (in order; stop at first failure)

### Step 1 — File exists and is readable
```bash
[ -f "$GENE" ] || { echo "ERROR: File not found: $GENE" >&2; exit 1; }
[ -r "$GENE" ] || { echo "ERROR: File not readable: $GENE" >&2; exit 1; }
```

### Step 2 — File size limit
```bash
[ $(wc -c < "$GENE") -le 51200 ] || { echo "ERROR: File exceeds 50KB" >&2; exit 1; }
```

### Step 3 — GDScript syntax and lint
```bash
gdlint "$GENE" >/dev/null 2>&1 || { echo "ERROR: GDScript syntax/lint error" >&2; gdlint "$GENE" >&2; exit 1; }
```
Requires `gdtoolkit` installed (`pip3 install "gdtoolkit==4.*"` — must pin to 4.x).

### Step 4 — Base class
```bash
grep -q 'extends BehaviorBase' "$GENE" || { echo "ERROR: Must extend BehaviorBase" >&2; exit 1; }
```

### Step 5 — Required method signature
```bash
grep -q 'func _evaluate(context' "$GENE" || { echo "ERROR: Must implement func _evaluate(context" >&2; exit 1; }
```

### Step 6 — Forbidden patterns (security/safety)
```bash
if grep -qE 'FileAccess|HTTPRequest|OS\.execute|TCPServer|StreamPeer|while\s+true:' "$GENE"; then
    echo "ERROR: Forbidden API usage detected" >&2
    grep -nE 'FileAccess|HTTPRequest|OS\.execute|TCPServer|StreamPeer|while\s+true:' "$GENE" >&2
    exit 1
fi
```

### Step 7 — Loop bounds heuristic (warning only, does not fail)
```bash
# Count for-loops with literal bounds; warn if any bound literal > 100
# This is a heuristic — static analysis cannot catch all cases
if awk '/for .* in range\(([0-9]+)/' "$GENE" | awk -F'[()]' '{n=$2; if(n>100) exit 1}'; then
    echo "WARNING: Possible loop count > 100 — review manually" >&2
    # NOT exit 1 — warning only
fi
```

---

## stderr Output Format

All error messages begin with `ERROR:` or `WARNING:`. Tools parsing stderr should
check the prefix to distinguish failures from warnings.

```
ERROR: GDScript syntax error (see gdparse output)
  --> line 14: unexpected token 'func'
ERROR: Must extend BehaviorBase
ERROR: Forbidden API usage detected
  line 7: OS.execute("rm", ["-rf", "/"])
WARNING: Possible loop count > 100 — review manually
```

---

## Integration with AgentBridge

After a `behavior-synth` agent result arrives:

1. Write `output` string to a temp file: `user://agent-results/<task_id>_gene.gd`
2. Call: `OS.execute("bash", ["scripts/validate-gene.sh", temp_path], output, true)`
3. Check exit code:
   - `0` → register gene, spawn creep, show green status
   - `1` → log error, refund player cycles, show red status, delete temp file
4. Delete temp file after processing

**Important**: AgentBridge NEVER registers a gene without calling validate-gene.sh first,
regardless of whether the gene was AI-generated or player-authored.
