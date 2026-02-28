# Windows 11 + WSL2 Setup Guide

1. **Enable WSL2**: Open an admin terminal and run:
   ```powershell
   wsl --install
   ```

2. **Install Ubuntu 22.04**: Download and install Ubuntu 22.04 from the Microsoft Store.

3. **Clone Repository**: Open Ubuntu and clone the project inside the WSL filesystem (e.g., `~`), **not** `/mnt/c/`.

4. **Install Dependencies in WSL**:
   - Install Bun:
     ```bash
     curl -fsSL https://bun.sh/install | bash
     ```
   - Install Claude Code CLI:
     ```bash
     npm install -g @anthropic/claude-code
     ```

5. **Run Godot Natively**: Download the Godot Windows export to your regular Windows filesystem (e.g., `C:\Games\`) and launch it normally.

6. **Start Orchestrator in WSL**: Start the agent orchestrator separately in your WSL terminal:
   ```bash
   bun run agents/orchestrator.ts
   ```

## Troubleshooting

- If agents are timing out, ensure WSL memory limits are properly configured in `.wslconfig`.
- Avoid storing the repository files on `/mnt/c/` to prevent severe file IO performance degradation.
