# Research Notes: MiroFish Analysis for Tower-Creep Symbiosis

## Document 1: MiroFish Overview

**Source**: GitHub https://github.com/666ghj/MiroFish (26k stars, 3k forks)

### Core Concept
- Swarm Intelligence Engine for predicting anything
- Multi-agent simulation system built on OASIS (CAMEL-AI)
- Creates "digital twin" worlds from seed data (news, stories, financial signals)
- Agents interact autonomously; observers can inject variables dynamically

### Architecture Stack
- **Frontend**: Vue.js (41%)
- **Backend**: Python (58%)
- **Simulation Engine**: OASIS (Open Agent Social Interaction Simulations)
- **Memory**: Zep Cloud (long-term agent memory)
- **LLM**: Qwen-plus via Alibaba Bailian (configurable)

### Workflow Steps
1. Graph Building: Seed extraction + GraphRAG construction
2. Environment Setup: Entity relationships + persona generation
3. Simulation: Dual-platform parallel simulation
4. Report Generation: ReportAgent with tools
5. Deep Interaction: Chat with any simulated agent

---

## Document 2: OASIS Core Architecture

**Source**: https://docs.oasis.camel-ai.org/overview

### Core Components

1. **Platform**: Simulates social media environment (Twitter/Reddit-like)
   - Manages user accounts, content, relationships, engagement

2. **Agents**: LLM-powered users with unique profiles
   - Decision-making driven by large language models

3. **Actions**: Operations agents perform
   - Posts, comments, likes, follows, etc.

4. **Recommendation System**: Determines agent content feeds
   - Similar to real social media algorithms

5. **Simulation Engine**: Orchestration layer
   - Controls time progression, agent activation, overall flow

### Scale
- Designed for up to ONE MILLION agents
- Efficient database operations
- Multiple LLM instances for load balancing
- Concurrent request limiting

### Data Flow
- Initialization → Simulation Cycle → LLM Decision → Platform Updates → Data Collection
- SQLite database for all simulation data

---

## Document 3: MiroFish Technical Elements

### GraphRAG Integration
- Knowledge graph for entity relationships
- Dynamic temporal memory updates
- Multi-hop query resolution (94% accuracy with graph)

### Agent Memory (Zep)
- Long-term memory for agents
- Monthly free tier sufficient for basic use
- Enables "personalities" to persist across sessions

### Dual-Platform Parallel
- Two simulation platforms running in parallel
- Auto-parse prediction requirements
- Dynamic temporal memory updates

### ReportAgent
- Rich toolset for environment interaction
- Generates prediction reports
- Deep interaction capability with simulated world

---

## Document 4: Comparison to Tower-Creep Symbiosis

### Similarities
| MiroFish | Our Project | Relevance |
|----------|-------------|-----------|
| Agent persona generation | behavior-synth agent | HIGH |
| Gene/behavior registry | GenomeRegistry + SQLite | HIGH |
| Execution logging | ExecutionLog table | MEDIUM |
| Simulation engine | Game loop + WaveManager | MEDIUM |
| Report generation | balance-tuner agent | MEDIUM |
| Entity relationships | GeneLineage tracking | LOW |

### Differences
- MiroFish: Open-ended simulation (social media)
- Ours: Game-constrained (tower defense rules)
- MiroFish: Millions of agents
- Ours: Dozens/hundreds (game entities)
- MiroFish: Real-time LLM decision-making per agent
- Ours: Pre-defined gene behaviors, LLM for synthesis only

---

## Document 5: Applicable Elements

### HIGH PRIORITY - Adapt for Our Use

1. **GraphRAG for Gene Relationships**
   - Current: Flat gene_registry + lineage table
   - Enhancement: Knowledge graph of gene interactions
   - Use case: Understand how behaviors combine, emergent strategies

2. **Enhanced Agent Memory Architecture (Zep-like)**
   - Current: SQLite execution_log
   - Enhancement: Structured memory with semantic indexing
   - Use case: Better gene performance tracking, pattern detection

3. **Simulation Observer Pattern**
   - MiroFish's "God's eye view" for injecting variables
   - Our Dashboard could observe and inject balance changes
   - Enables live tuning without restart

4. **ReportAgent for Balance Analysis**
   - Current: balance-tuner agent generates JSON patches
   - Enhancement: Interactive report agent with tools
   - Use case: Detailed gameplay analysis, strategy recommendations

### MEDIUM PRIORITY - Consider

5. **Dual-Platform Parallel for Headless Testing**
   - Run simulation in parallel with live game
   - Use case: Faster evolution testing

6. **Recommendation System for Gene Selection**
   - Suggest genes based on game state
   - Use case: New player assistance, adaptive difficulty

7. **Persona Persistence**
   - Save/load agent personas across sessions
   - Use case: Persistent player-created behaviors

### LOW PRIORITY - Future Consideration

8. **MCP Tool Integration**
   - Current: Claude Code MCP
   - Enhancement: Filesystem + custom tools per agent type

9. **Multi-hop Query for Gene Analysis**
   - Query gene interactions semantically
   - Use case: Complex balance questions

---

## Document 6: Implementation Recommendations

### Phase 1: Memory Architecture Enhancement
- Add semantic indexing to execution_log
- Enable multi-query for gene analysis
- Similar to GraphRAG but simpler (no external DB needed)

### Phase 2: Observer Pattern Enhancement
- Make GenomeRegistry observable
- Dashboard can subscribe to gene events
- Enables live injection of balance changes

### Phase 3: Report Enhancement
- Add interactive query to balance-tuner output
- Natural language questions about gene pool
- Similar to ReportAgent

### Phase 4: Parallel Simulation
- Headless evolution runs parallel to game
- Faster iteration on balance changes
- Similar to MiroFish's dual-platform

---

## Document 7: Risks and Considerations

### Complexity
- GraphRAG adds significant complexity
- Only worth it if gene pool grows large
- Start simple, add if needed

### Performance
- OASIS designed for 1M agents; we have dozens
- Our current SQLite approach is sufficient for scale
- Don't over-engineer

### Architecture Fit
- MiroFish is open simulation; we're game-constrained
- Not all patterns translate well
- Adapt, don't copy

---

## Research Completion Status
- Documents analyzed: ~8
- Web searches completed: 2
- MiroFish repo: Explored
- OASIS docs: Explored
- Status: CONSOLIDATION PHASE NEXT
