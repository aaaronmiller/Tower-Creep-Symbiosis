extends Node
## AgentBridge - Communication layer between TypeScript agents and Godot
##
## Manages CLIProxyAPI connections for AI-driven commands and Claude Code
## headless sub-processes for agentic operations. Reads configuration from
## agent-harness.json.

signal command_received(command: Dictionary)
signal agent_command_ready(command: String)
signal response_ready(response_data: Dictionary)

var _cli_proxy_available: bool = false
var _ccproxy_available: bool = false
var _command_queue: Array = []

func _ready() -> void:
	_load_agent_config()
	_connect_to_agents()
	print("[AgentBridge] Initializing - CLIProxyAPI: %s, ccproxy: %s" % [
		"connected" if _cli_proxy_available else "unavailable",
		"connected" if _ccproxy_available else "unavailable"
	])

func _load_agent_config() -> void:
	var config_path = "res://data/agent-harness.json"
	var file = FileAccess.open(config_path, FileAccess.READ)
	
	if file:
		var json_str = file.get_as_text()
		file.close()
		var json = JSON.new()
		if json.parse(json_str) == OK:
			var config = json.get_data()
			print("[AgentBridge] Loaded agent harness config")
		else:
			push_warning("[AgentBridge] Failed to parse agent harness config")
	else:
		push_warning("[AgentBridge] agent-harness.json not found")

func _connect_to_agents() -> void:
	# Check for CLIProxyAPI on port 3000
	_cli_proxy_available = _check_port("localhost", 3000)
	
	# Check for ccproxy on port 8082
	_ccproxy_available = _check_port("localhost", 8082)
	
	if _cli_proxy_available:
		print("[AgentBridge] CLIProxyAPI available on port 3000")
	if _ccproxy_available:
		print("[AgentBridge] Claude Code proxy available on port 8082")

func _check_port(host: String, port: int) -> bool:
	# Stub: actual port checking happens via HTTPClient
	# For now, return false until external services are running
	return false

## Execute a natural language command from player
func execute_player_command(command: String) -> void:
	print("[AgentBridge] Player command: %s" % command)
	command_received.emit({"type": "player_command", "text": command})
	
	# Emit for MacroCompiler to process
	agent_command_ready.emit(command)

## Spawn a headless Claude Code agent for long-running tasks
func spawn_agent(task_type: String, parameters: Dictionary) -> void:
	if not _ccproxy_available:
		push_warning("[AgentBridge] ccproxy not available - cannot spawn agent")
		return
	
	print("[AgentBridge] Spawning agent: %s with params: %s" % [task_type, str(parameters)])
	# In production, this would POST to ccproxy /api/spawn

## Query the game state for agent consumption
func query_game_state() -> Dictionary:
	return {
		"lives": GameState.lives,
		"gold": GameState.gold,
		"wave": GameState.wave_number,
		"cycles": GameState.player_cycles,
		"creeps_spawned": GameState.creeps_spawned,
		"towers_placed": GameState.towers_placed
	}

## Report agent results back to the game
func report_agent_result(result: Dictionary) -> void:
	print("[AgentBridge] Agent result: %s" % str(result))
	response_ready.emit(result)