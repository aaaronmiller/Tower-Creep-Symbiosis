# Research Notes Part 3: Technical Architecture

## Document 13: SQLite WAL for AI Agents

**Source**: Multiple (Zylos, MVP Factory, DEV Community)

### Key Insights
1. **WAL Mode Benefits**
   - Concurrent reads during writes
   - No reader/writer blocking
   - Zero operational overhead

2. **Patterns for Production**
   - Checkpoint management (prevent WAL bloat)
   - Connection pooling strategies
   - WAL size monitoring

3. **Our Current Approach**
   - We use SQLite WAL (correct!)
   - Already aligned with best practices

### Relevance
- Our genome.db and metrics.db use WAL
- This confirms we're on the right track
- Consider: checkpoint scheduling

---

## Document 14: Agent Memory Systems

**Source**: Multiple DEV Community articles, Google Always On Memory Agent

### Memory Architecture Patterns

1. **Vector Database (Overrated)**
   - Traditional recommendation: embeddings + similarity search
   - Overkill for structured agent data
   - Expensive, complex

2. **SQLite Memory (Recommended)**
   - Google Always On Memory Agent uses SQLite
   - Structured queries > embeddings for agent state
   - FTS5 for text search when needed

3. **Claw-Stack Pattern**
   - Remember decisions, not just context
   - Session persistence
   - Cross-session learning

### Our Current Approach
- SQLite execution_log: Good
- Could enhance with structured memory queries
- FTS5 not needed yet (our text is small)

---

## Document 15: Claude Code + MCP Integration

**Source**: Our project CLAUDE.md

### Current Architecture
- Bun-based orchestrator
- Claude Code CLI as harness
- MCP tools for filesystem

### Enhancement Opportunities
- Add more MCP tools per agent type
- Similar to MiroFish's approach
- But: Keep simple for game constraints

---

## Document 16: Game State Synchronization

### Concepts from MiroFish
- Observer pattern for simulation
- Inject variables dynamically
- Real-time observation

### Our Implementation
- GenomeRegistry already observable
- Signals for gene events
- Could enhance: live balance injection

---

## Technical Architecture Summary

### What We're Doing Right

1. ✓ SQLite WAL mode
2. ✓ AgentBridge IPC
3. ✓ Observable gene registry
4. ✓ Signal-based events
5. ✓ Claude Code harness

### Potential Enhancements

1. **Checkpoint Management**
   - Add periodic WAL checkpoint
   - Prevent unbounded growth

2. **Structured Memory Queries**
   - More complex queries on execution_log
   - Similar to agent memory systems

3. **Live Injection**
   - Observer pattern for balance changes
   - Dashboard can modify genes live

4. **MCP Expansion**
   - More tools per agent type
   - But keep simple for now

---

## Competitive Analysis Update

### Our Position
| Approach | Us | TowerMind | MiroFish |
|----------|-----|-----------|----------|
| Behavior Generation | LLM → Gene | LLM plays | LLM simulates |
| Persistence | SQLite WAL | ? | Zep + SQLite |
| Evolution | Self-evolving | No | No |
| Scale | Dozens | Hundreds | Millions |

### Unique Value
- LLM-generated, self-evolving genes
- Natural language → executable code
- Game-constrained simulation
