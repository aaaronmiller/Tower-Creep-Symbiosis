# Ubuntu 22.04 Setup Guide (x86-64)

## Prerequisites

1. **Godot 4.3**: Download from [godotengine.org](https://godotengine.org) and extract.
2. **Bun**: Install via:
   ```bash
   curl -fsSL https://bun.sh/install | bash
   ```
3. **Claude Code CLI**: Install via:
   ```bash
   npm install -g @anthropic/claude-code
   ```
4. **API Key**: Configure Claude Code via:
   ```bash
   claude config
   ```

## Launching the Game

To launch the game:
```bash
./tower-creep-symbiosis.x86_64
```

## Verification

Run the following paste-ready verification commands from `quickstart.md`:

```bash
# 1. Smoke test (SC-001)
./tower-creep-symbiosis.x86_64 --headless --quit-after 5

# 2. Agent test (SC-002)
bun run agents/orchestrator.ts
```
