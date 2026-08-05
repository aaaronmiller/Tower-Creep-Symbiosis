# Contract: BehaviorBase GDScript Interface

**Version**: 1.0.0
**File**: `res://godot/genes/behaviors/BehaviorBase.gd`
**Used by**: GenomeRegistry (execute_gene), Creep (_physics_process), validate-gene.sh

---

## Class Declaration

```gdscript
class_name BehaviorBase
extends Resource
```

Behaviors extend `Resource` (not Node) so they can be instantiated without a scene tree,
serialized to `.tres`, and loaded headlessly in GUT tests.

---

## Required Methods (subclasses MUST implement)

### `_evaluate(context: Dictionary) -> Dictionary`

Called once per physics frame for each entity with this gene assigned.
MUST return within the gene execution budget (< 10ms; enforcement via execution_log).
MUST NOT exceed 100 loop iterations (enforced by validate-gene.sh static check).
MUST NOT call: `FileAccess`, `HTTPRequest`, `OS.execute`, or any networking API.

**Parameters**:

| Key | Type | Description |
|-----|------|-------------|
| `"entity"` | Node2D | The Tower or Creep node this gene is attached to |
| `"delta"` | float | Physics frame delta time in seconds |
| `"position"` | Vector2 | Entity's current global position |
| `"health"` | float | Entity's current health points |
| `"nearby_enemies"` | Array[Node2D] | Entities in opposite faction within 200px |
| `"nearby_towers"` | Array[Node2D] | Tower nodes within 300px |
| `"resource_nodes"` | Array[Node2D] | All resource nodes in scene |

**Return value** (Dictionary — include only keys you want to act on):

| Key | Type | Effect |
|-----|------|--------|
| `"move_direction"` | Vector2 | Normalized direction vector; Creep sets velocity |
| `"target"` | Node2D | Node to attack; Creep calls target.take_damage() |
| `"ability"` | String | Trigger an effect gene by name (e.g., `"freeze"`) |
| `"skip_frame"` | bool | If true, no action taken this frame |

**Contract violation handling**: If `_evaluate()` raises an error or returns a non-Dictionary,
GenomeRegistry records the failure, increments `error_count`, and returns `null`.
After 20 consecutive failures, `methylate_gene()` is called automatically.

---

### `initialize(params: Dictionary) -> void`

Called once after instantiation with the gene's `parameters` JSON from `genome.db`.
Default implementation does nothing (base class no-op). Subclasses override to
read and store numeric parameters for use in `_evaluate()`.

**Constraint**: MUST be idempotent. May be called multiple times (e.g., after
`override_tier()` reloads parameters). Side effects must be limited to `self`.

---

## Optional Methods (subclasses MAY implement)

### `get_display_name() -> String`

Human-readable name shown in Dashboard gene list. Defaults to `get_class()` if not
overridden.

### `get_description() -> String`

One-sentence description for PromptEditor preview panel. Defaults to `""`.

---

## Example Implementation

```gdscript
# res://godot/genes/behaviors/WalkPathBehavior.gd
class_name WalkPathBehavior
extends BehaviorBase

func _evaluate(context: Dictionary) -> Dictionary:
    var entity: Node2D = context["entity"]
    var direction: Vector2 = PathFollower.get_next_direction(entity)
    return {"move_direction": direction}

func get_display_name() -> String:
    return "Walk Path"

func get_description() -> String:
    return "Follows the defined creep path at base speed."
```

---

## validate-gene.sh Enforcement

The following are checked (in order) before any gene is inserted into GenomeRegistry:

1. `gdlint "$GENE_PATH"` exits 0 (syntax + lint valid; requires `gdtoolkit==4.*`)
2. File contains `extends BehaviorBase` (exact string)
3. File contains `func _evaluate(context` (method signature present)
4. File does NOT contain any of: `FileAccess`, `HTTPRequest`, `OS.execute`, `while true:`
5. Heuristic: no `for` loop with literal bound > 100
6. File size < 50 KB (prevents injection of large payloads)

Exit codes: `0` = valid, `1` = invalid (reason printed to stderr).
