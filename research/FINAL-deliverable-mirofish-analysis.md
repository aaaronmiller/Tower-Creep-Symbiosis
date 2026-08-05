# Research Consolidation: MiroFish Analysis Final Deliverable

## Executive Summary

This document consolidates research findings from analyzing MiroFish (swarm intelligence engine), OASIS (simulation framework), TowerMind (LLM tower defense), and related game AI systems. The analysis identifies applicable architectural elements and proposes specific changes to the Tower-Creep Symbiosis project.

**Key Finding**: Our project occupies a unique niche—LLM-generated, self-evolving tower defense behaviors—that differs fundamentally from both MiroFish (LLM simulating agents) and TowerMind (LLM playing the game). Our approach is complementary, not competitive.

---

## Part I: MiroFish Architecture Analysis

### What MiroFish Does
- Multi-agent simulation engine (up to 1M agents)
- Builds "digital twin" worlds from seed data
- Agents interact autonomously with LLM-driven decisions
- GraphRAG for knowledge management
- Zep for long-term agent memory
- Dual-platform parallel simulation

### What We Do Differently
| Aspect | MiroFish | Our Project |
|--------|----------|-------------|
| Agent decisions | LLM per action | Pre-generated genes |
| Simulation type | Open-ended | Game-constrained |
| Scale | Millions | Dozens/hundreds |
| Behavior source | LLM at runtime | LLM generates code |
| Evolution | Agent learning | Gene parameter tuning |

### Applicable Elements from MiroFish

#### HIGH PRIORITY

1. **GraphRAG for Gene Relationships**
   - Current: Flat gene_registry + lineage table
   - Proposed: Knowledge graph of gene interactions
   - Rationale: Understand how behaviors combine, detect emergent strategies
   - Risk: Complexity; start simple

2. **Observer Pattern for Live Injection**
   - MiroFish's "God's eye view" for variable injection
   - Current: Static gene registry
   - Proposed: Observable GenomeRegistry with live balance modification
   - Rationale: Dashboard can modify balance without restart

3. **ReportAgent-Style Analysis**
   - Current: balance-tuner outputs JSON patches
   - Proposed: Interactive query capability
   - Rationale: Natural language questions about gene pool

#### MEDIUM PRIORITY

4. **Parallel Simulation (Headless)**
   - Run evolution in parallel with live game
   - Faster iteration on balance changes
   - Similar to MiroFish's dual-platform

5. **Enhanced MCP Tooling**
   - Current: Filesystem only
   - Proposed: Custom MCP for game state queries
   - Rationale: More context for behavior-synth

---

## Part II: Technical Architecture Findings

### SQLite WAL (Confirm: We're Correct)

Research confirms our SQLite WAL approach is optimal:
- Google Always On Memory Agent uses SQLite
- WAL mode enables concurrent reads/writes
- Best practice for AI agent systems

**Recommendation**: KEEP current architecture. Add periodic checkpoint management.

### Behavior Trees vs Genes

**Finding**: Our gene system is simpler and more evolvable than full BTs:
- Behavior trees: Complex, hierarchical decisions
- Our genes: Single-behavior executors, composable
- Evolution: Works better with simpler units

**Recommendation**: KEEP genes as single-behavior. Don't introduce full BT system.

### TowerMind Comparison

**Finding**: TowerMind tests LLM agents PLAYING tower defense.
- Different abstraction level than us
- Complementary, not competitive

**Recommendation**: Monitor TowerMind for potential integration (LLM-playing辅助), but don't change our LLM-generating approach.

---

## Part III: Balance System Validation

### B(state) Formula - Unique and Validated

Our balance formula aligns with academic research:
- Multi-objective optimization in game balancing (GEEvo)
- Dynamic difficulty adjustment via genetic algorithms
- Self-evolution mechanisms in procedural generation

**What Makes Us Unique**:
- Gene methylation (not deletion)
- Macro compilation (pattern → gene)
- Rollback on balance failure

**Recommendation**: KEEP and PROTECT these unique mechanisms.

### Research Gap Identified

Most game balancing research focuses on:
- Enemy difficulty curves
- Player power progression
- Economy balancing

Our focus on BEHAVIOR gene diversity is novel.

---

## Part IV: Proposed Changes to Project

### Change 1: Enhance GenomeRegistry with Observer Pattern

**File**: `godot/autoloads/GenomeRegistry.gd`

**Current**: Static registry with signals

**Proposed**:
```gdscript
# Add observer pattern for live balance injection
signal gene_modified(gene_id, param, old_value, new_value)

func modify_gene_parameter(gene_id: String, param: String, new_value) -> bool:
    # Allow external modification with rollback capability
    pass
```

**Rationale**: Enables MiroFish-style live injection

**Priority**: MEDIUM

---

### Change 2: Add Gene Interaction Graph (Light)

**File**: `data/schema.sql`

**Current**: Flat gene table + lineage

**Proposed**: Add `gene_interactions` table
```sql
CREATE TABLE gene_interactions (
    id INTEGER PRIMARY KEY,
    gene_a TEXT NOT NULL,
    gene_b TEXT NOT NULL,
    interaction_type TEXT, -- synergetic, antagonistic, neutral
    combined_fitness REAL,
    timestamp INTEGER
);
```

**Rationale**: Track how genes work together (GraphRAG-lite)

**Priority**: LOW (defer to Phase 2+)

---

### Change 3: Enhance AgentBridge Context

**File**: `godot/autoloads/AgentBridge.gd`

**Current**: Simple task queue

**Proposed**: More structured game state exposure
```gdscript
func get_simulation_context() -> Dictionary:
    return {
        "wave_number": GameState.wave_number,
        "active_creeps": get_active_creep_count(),
        "active_towers": get_active_tower_count(),
        "gene_pool_size": GenomeRegistry.get_gene_count(),
        "balance_score": SelfOptimizer.get_last_balance(),
        "recent_deaths": get_recent_death_types()
    }
```

**Rationale**: More context for behavior-synth agent

**Priority**: MEDIUM

---

### Change 4: Add Checkpoint Management

**File**: `godot/autoloads/GenomeRegistry.gd`

**Current**: WAL mode, no explicit checkpoints

**Proposed**:
```gdscript
func _periodic_checkpoint():
    db.execute("PRAGMA wal_checkpoint(TRUNCATE)")
```

**Rationale**: Prevent WAL bloat, per SQLite best practices

**Priority**: HIGH

---

### Change 5: Add Execution Pattern Detection

**File**: `godot/autoloads/MacroCompiler.gd`

**Current**: Action sequence detection

**Proposed**: Enhanced with frequency analysis
```gdscript
# Track not just sequences but also:
# - Gene usage frequency
# - Creep composition patterns  
# - Tower placement correlations
# - Win/loss correlations
```

**Rationale**: Better macro promotion decisions

**Priority**: MEDIUM

---

## Part V: Unresolved Items & Conflicts

### Conflict 1: GraphRAG Complexity vs Simplicity

**Position A**: Add GraphRAG for rich gene relationships
- Pro: Better understanding of gene interactions
- Con: Significant complexity increase

**Position B**: Keep simple flat structure
- Pro: Sufficient for our scale
- Con: May miss emergent patterns

**Resolution**: DEFER. Start with light gene_interactions table (Change 2). Add full GraphRAG only if gene pool grows large.

---

### Conflict 2: LLM-Playing vs LLM-Generating

**Position A**: Add TowerMind-style LLM-playing
- Pro: More dynamic gameplay
- Con: Different abstraction, loses gene evolution

**Position B**: Keep LLM-generating only
- Pro: Unique value proposition
- Con: Less dynamic than LLM-playing

**Resolution**: REJECT Position A. Our LLM-generating approach with self-evolution is our differentiator. Don't compete on LLM-playing.

---

### Conflict 3: Real-Time vs Batch Evolution

**Position A**: Real-time evolution (per-frame)
- Pro: Faster adaptation
- Con: Performance overhead

**Position B**: Batch evolution (per-wave)
- Pro: Predictable performance
- Con: Slower adaptation

**Resolution**: KEEP current batch approach. Our current per-wave/batch is correct for game constraints.

---

## Part VI: Implementation Plan

### Immediate (Keep Current)
1. SQLite WAL architecture ✓
2. Gene system (BehaviorBase) ✓
3. B(state) balance formula ✓
4. Claude Code harness ✓

### Phase 1 Enhancements (This Feature)
1. Checkpoint management (Change 4)
2. AgentBridge context enhancement (Change 3)

### Phase 2 Enhancements (Future)
1. Observer pattern for live injection (Change 1)
2. Gene interaction tracking (Change 2)
3. Enhanced pattern detection (Change 5)

---

## Conclusion

Our Tower-Creep Symbiosis project occupies a unique and valuable niche in the tower defense + AI space:

- **NOT MiroFish**: We generate genes, not simulate agents
- **NOT TowerMind**: We generate behaviors, not play the game  
- **UNIQUE**: Self-evolving gene system with balance metrics

The research validates our core architecture and identifies specific enhancement opportunities without compromising our unique value proposition.

**Primary recommendation**: Implement Changes 4 and 3 (checkpoint management, enhanced context) in current feature. Defer GraphRAG and observer pattern to future phases.
