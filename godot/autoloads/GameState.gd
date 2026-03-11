extends Node

signal game_started
signal game_over
signal state_changed

var score: int = 0
var wave: int = 1
var base_health: int = 100
var resources: int = 500

var active_towers := []
var active_creeps := []
var player_actions := []

var _tower_type_counts := {}
var _action_type_counts := {}

var strategy_diversity: float = 0.0:
	get:
		if player_actions.size() == 0:
			return 0.0
		return clamp(float(_action_type_counts.size()) / float(max(1, player_actions.size())), 0.0, 1.0)

var player_retention: float = 0.0:
	get:
		return clamp(float(wave) / 100.0, 0.0, 1.0) # Normalizing roughly to wave 100

var asset_variety: float = 0.0:
	get:
		return clamp(float(_tower_type_counts.size()) / 10.0, 0.0, 1.0) # Assume 10 max types

func add_tower(tower_ref) -> void:
	active_towers.append(tower_ref)
	var type_id = tower_ref.get("type_id") if tower_ref.get("type_id") else "default"
	_tower_type_counts[type_id] = _tower_type_counts.get(type_id, 0) + 1
	state_changed.emit()

func remove_tower(tower_ref) -> void:
	if tower_ref in active_towers:
		var type_id = tower_ref.get("type_id") if tower_ref.get("type_id") else "default"
		_tower_type_counts[type_id] -= 1
		if _tower_type_counts[type_id] <= 0:
			_tower_type_counts.erase(type_id)
		active_towers.erase(tower_ref)
		state_changed.emit()

func log_action(action_type: String) -> void:
	player_actions.append(action_type)
	_action_type_counts[action_type] = _action_type_counts.get(action_type, 0) + 1
	if player_actions.size() > 100:
		var removed_action = player_actions.pop_front() # Keep a sliding window
		_action_type_counts[removed_action] -= 1
		if _action_type_counts[removed_action] <= 0:
			_action_type_counts.erase(removed_action)
	state_changed.emit()

func add_resources(amount: int) -> void:
	resources += amount
	state_changed.emit()

func spend_resources(amount: int) -> bool:
	if resources >= amount:
		resources -= amount
		state_changed.emit()
		return true
	return false

func take_damage(amount: int) -> void:
	base_health = max(0, base_health - amount)
	state_changed.emit()
	if base_health == 0:
		game_over.emit()

func next_wave() -> void:
	wave += 1
	state_changed.emit()

func calculate_b_state() -> float:
	return 0.4 * strategy_diversity + 0.4 * player_retention + 0.2 * asset_variety
