extends Node
## MacroCompiler - Translates natural language commands to game actions
##
## Takes player or agent natural language commands and converts them to
## executable game macros. Also handles command history and alias expansion.

signal macro_compiled(macro: Dictionary)
signal compilation_failed(error: String)
signal syntax_error(command: String, error: String)

# Pattern definitions for command parsing
var _verb_patterns: Array = [
	{"pattern": "^build\\s+(\\w+)", "action": "build_tower", "params": ["tower_type"]},
	{"pattern": "^place\\s+(\\w+)\\s+at\\s+(\\d+),?\\s*(\\d+)", "action": "place_entity", "params": ["entity_type", "x", "y"]},
	{"pattern": "^upgrade\\s+(\\w+)", "action": "upgrade_tower", "params": ["tower_id"]},
	{"pattern": "^sell\\s+(\\w+)", "action": "sell_tower", "params": ["tower_id"]},
	{"pattern": "^set\\s+(\\w+)\\s+to\\s+(.+)","action": "set_property", "params": ["target", "value"]},
	{"pattern": "^spawn\\s+(\\w+)", "action": "spawn_creep", "params": ["creep_type"]},
	{"pattern": "^pause", "action": "pause_game", "params": []},
	{"pattern": "^resume", "action": "resume_game", "params": []},
	{"pattern": "^speed\\s+(\\d+)", "action": "set_speed", "params": ["speed"]}
]

var _alias_map: Dictionary = {
	"t": "tower",
	"c": "creep",
	"b": "build",
	"p": "place",
	"s": "spawn",
	"u": "upgrade",
	"x": "sell"
}

var _command_history: Array = []
var _max_history: int = 50

func _ready() -> void:
	# Connect to AgentBridge for incoming commands
	if AgentBridge.has_node():
		AgentBridge.agent_command_ready.connect(_on_agent_command)
	print("[MacroCompiler] Initialized")

func _on_agent_command(command: String) -> void:
	var result = compile_command(command)
	if result.get("success"):
		macro_compiled.emit(result)
	else:
		compilation_failed.emit(result.get("error", "Unknown error"))

## Compile a natural language command into a game macro
func compile_command(command: String) -> Dictionary:
	if command.is_empty():
		return {"success": false, "error": "Empty command"}
	
	# Expand aliases
	command = _expand_aliases(command)
	
	# Add to history
	_add_to_history(command)
	
	# Try each pattern
	for pattern_def in _verb_patterns:
		var regex = RegEx.new()
		regex.compile(pattern_def.pattern)
		var match_result = regex.search(command)
		
		if match_result:
			return _build_macro(pattern_def, match_result)
	
	# No pattern matched
	syntax_error.emit(command, "Unrecognized command format")
	return {
		"success": false,
		"error": "Unrecognized command: '%s'" % command,
		"original_command": command
	}

func _expand_aliases(command: String) -> String:
	var words = command.split(" ")
	var expanded_words: Array = []
	
	for word in words:
		if _alias_map.has(word.to_lower()):
			expanded_words.append(_alias_map[word.to_lower()])
		else:
			expanded_words.append(word)
	
	return " ".join(expanded_words)

func _build_macro(pattern_def: Dictionary, match: RegExMatch) -> Dictionary:
	var macro = {
		"success": true,
		"action": pattern_def.action,
		"params": {},
		"original_command": match.get_string(0)
	}
	
	var param_names = pattern_def.params
	for i in range(param_names.size()):
		if i + 1 < match.get_string_count():
			var value = match.get_string(i + 1)
			# Try to convert numbers
			if value.is_valid_int():
				macro.params[param_names[i]] = value.to_int()
			elif value.is_valid_float():
				macro.params[param_names[i]] = value.to_float()
			else:
				macro.params[param_names[i]] = value
	
	print("[MacroCompiler] Compiled: %s -> %s" % [macro.original_command, macro.action])
	return macro

func _add_to_history(command: String) -> void:
	_command_history.append({
		"command": command,
		"timestamp": Time.get_unix_time_from_system()
	})
	
	if _command_history.size() > _max_history:
		_command_history.pop_front()

## Get recent command history
func get_history(count: int = 10) -> Array:
	var result: Array = []
	var start = max(0, _command_history.size() - count)
	for i in range(start, _command_history.size()):
		result.append(_command_history[i])
	return result

## Clear command history
func clear_history() -> void:
	_command_history.clear()

## Add a custom alias
func add_alias(short: String, long: String) -> void:
	_alias_map[short.to_lower()] = long.to_lower()
	print("[MacroCompiler] Added alias: %s -> %s" % [short, long])