# Research Notes Part 4: Godot AI Systems

## Document 17: Behavior Trees in Godot

**Sources**: Multiple Godot BT implementations

### Available Libraries

1. **LimboAI** (GDExtension)
   - Behavior trees + state machines
   - For Godot 4.x
   - Production-ready

2. **BehaviourToolkit**
   - Collection of AI tools
   - Modular

3. **GodotBT** (kagenash1)
   - GDScript implementation
   - 213 stars

4. **Behave** (bitbrain)
   - Behavior tree addon
   - MIT licensed

### Our Approach vs BT Libraries

| Aspect | Our Genes | Behavior Trees |
|--------|-----------|----------------|
| Granularity | Single behavior | Composite nodes |
| Evolution | Self-evolving | Static |
| LLM Generation | ✓ | ✗ |
| Complexity | Simple | Complex |

### Decision
Our gene system is simpler than full BTs.
Each gene = one behavior, not a tree.
Keep current approach (BehaviorBase) but note BT libraries for future.

---

## Document 18: Our Behavior System Architecture

### Current Design
```
BehaviorBase (abstract)
├── _evaluate(context) -> Dictionary
├── WalkPathBehavior
├── FlankBehavior
└── (LLM-generated behaviors)
```

### MiroFish Comparison
MiroFish agents:
- Complex decision-making per action
- LLM-driven

Our genes:
- Simple behavior functions
- LLM generates the code, game executes

### Key Insight
We don't need full BTs because:
1. Game rules constrain possible behaviors
2. LLM generates deterministic code
3. Evolution operates on parameters, not structure

---

## Document 19: State Machines vs Genes

### Tower Defense Patterns

1. **Finite State Machine (FSM)**
   - States: Idle, Moving, Attacking, Dying
   - Transitions between states
   - Simple, predictable

2. **Behavior Trees**
   - Hierarchical, complex decisions
   - More flexible, harder to evolve

3. **Our Gene System**
   - Each gene = one behavior aspect
   - Genes combine for complex behavior
   - Evolution changes parameters

### Recommendation
Keep genes as single-behavior executors.
Combine genes for complex creeps.
Use FSM for entity lifecycle states.

---

## Godot AI Summary

### What to Keep
- BehaviorBase abstract class
- Gene registry system
- LLM-to-code generation

### Future Enhancements
- Consider LimboAI for complex NPC AI
- But not for core gene system
- Genes are simpler, more evolvable
