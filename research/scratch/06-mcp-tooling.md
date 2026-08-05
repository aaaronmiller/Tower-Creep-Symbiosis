# Research Notes Part 6: MCP & Tooling

## Document 23: Model Context Protocol (MCP)

### Overview
- Open standard by Anthropic (Nov 2024)
- "USB-C of AI integrations"
- Universal protocol for AI → tools/data
- Thousands of MCP servers built

### Architecture
- JSON-RPC 2.0 over STDIO, HTTP, or SSE
- One server works with multiple AI clients
- Built-in security, logging, governance

### Our Current MCP Usage
- Claude Code CLI harness
- Filesystem MCP for agents
- data/agent-harness.json config

### Enhancement Opportunities

1. **Per-Agent MCP Config**
   - behavior-synth: filesystem + code
   - asset-gen: filesystem + image gen
   - balance-tuner: database access
   - code-auditor: filesystem + analysis

2. **Custom MCP Servers**
   - Game state access
   - Gene registry queries
   - Metrics retrieval

### MiroFish Comparison
MiroFish uses MCP similarly but with more tools:
- GraphRAG integration
- External data access
- Report generation tools

---

## Document 24: Claude Code Integration

### Current Architecture
```
Game (Godot)
  └─ AgentBridge (IPC)
       └─ Bun process
            └─ Claude Code CLI
                 └─ MCP tools
```

### Alternative Patterns
1. **Direct MCP**: Claude → game directly
2. **File-based**: Results via JSON files
3. **HTTP**: REST API between game and agents

### Our Choice: File-based (correct)
- Simpler, more reliable
- Works with headless Claude Code
- No network complexity

---

## MCP Summary

### Keep Current
- File-based IPC
- Claude Code harness
- Per-agent MCP configs

### Future Enhancements
- Custom MCP for game state
- More sophisticated tool access
- But not critical for MVP
