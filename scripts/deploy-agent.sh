#!/bin/bash
# deploy-agent.sh - Deploy and connect agent to game

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
AGENT_DIR="$PROJECT_ROOT/agent"
LOG_DIR="$PROJECT_ROOT/logs"

mkdir -p "$LOG_DIR"

echo "=== Agent Deployment Script ==="
echo "Project: $PROJECT_ROOT"
echo ""

# Check prerequisites
check_prereq() {
    if ! command -v "$1" &> /dev/null; then
        echo "ERROR: $1 not found in PATH"
        exit 1
    fi
    echo "OK: $1 found"
}

echo "--- Checking Prerequisites ---"
check_prereq claude
check_prereq node
check_prereq npm

echo ""
echo "--- Starting Agent Bridge ---"

# Check if AgentBridge config exists
if [ ! -f "$PROJECT_ROOT/data/agent-harness.json" ]; then
    echo "WARNING: agent-harness.json not found, creating default"
    echo '{"harness": "claude-code", "config": {}}' > "$PROJECT_ROOT/data/agent-harness.json"
fi

# Check if agent directory exists
if [ ! -d "$AGENT_DIR" ]; then
    echo "WARNING: agent directory not found, creating"
    mkdir -p "$AGENT_DIR"
fi

echo ""
echo "--- Agent Status ---"
echo "Agent directory: $AGENT_DIR"
echo "Logs: $LOG_DIR"
echo ""
echo "To start agent manually:"
echo "  cd $AGENT_DIR"
echo "  claude --headless"
echo ""
echo "Agent deployment complete!"
