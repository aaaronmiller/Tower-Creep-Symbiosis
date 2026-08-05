# Research Notes Part 5: Balance & Evolution

## Document 20: Game Balance Research

### Sources
- "Game Balancing via PCG and Simulations" (AAAI)
- "GEEvo: Game Economy Generation and Balancing with Evolutionary Algorithms"
- "Dynamic Difficulty Adjustment in Digital Games Using Genetic Algorithms"
- "Automated Game Balancing in Ms PacMan and StarCraft Using Evolutionary Algorithms"

### Key Concepts

1. **Search-Based Optimization**
   - Use game simulations to estimate balance
   - Optimize parameters automatically

2. **Evolutionary Approaches**
   - GEEvo: Generate and balance game economies
   - Parameters evolve toward balance goals
   - Multi-objective optimization

3. **Dynamic Difficulty Adjustment (DDA)**
   - Adjust difficulty in real-time
   - Player skill tracking
   - Procedural adaptation

### Our Balance System Comparison

| Aspect | Traditional | Our Approach |
|--------|-------------|---------------|
| Balance Target | Fixed difficulty | B(state) formula |
| Method | Playtesting | Automated metrics |
| Adaptation | Manual | Self-evolving |
| Speed | Days/weeks | Real-time |

### Our B(state) Formula
```
B(state) = 0.4 × strategy_diversity + 0.4 × player_retention + 0.2 × asset_variety
```

This is UNIQUE in the industry:
- Strategy diversity (Gini coefficient)
- Player retention (session continuation)
- Asset variety (unique asset usage)

### Research Gap
Most game balancing research focuses on:
- Enemy difficulty
- Player power curves
- Economy balancing

Our approach focuses on:
- Gene/behavior diversity
- Evolution toward balance
- Self-correction (rollback)

---

## Document 21: Self-Evolution in Games

### Related Work
- Neuroevolution for game AI
- Procedural content generation via evolution
- Quality diversity algorithms

### Our Unique Approach

1. **Gene Methylation**
   - Genes that fail get "silenced" (methylated)
   - Not deleted, archived
   - Can be revived

2. **Macro Compilation**
   - Detect repeated action patterns
   - Promote to new genes
   - Emergent behaviors

3. **Rollback Mechanism**
   - If B(state) drops below 0.5
   - Revert changes
   - Log for analysis

---

## Document 22: Competitive Analysis - Balance

### Tower Defense Specific
- TowerMind: No self-balancing
- Traditional TD: Manual tuning
- Our project: Self-evolving

### Unique Value
No other tower defense game has:
- Automated balance metrics
- Gene methylation
- Self-correction mechanism

---

## Balance System Summary

### Keep Current
- B(state) formula (unique)
- Rollback mechanism
- Gene methylation

### Potential Enhancements
- More diverse metrics
- Player skill tracking
- Wave difficulty adaptation
