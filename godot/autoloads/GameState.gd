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

var strategy_diversity: float = 0.0:
	get:
		if player_actions.size() == 0:
			return 0.0
		var unique_actions = {}
		for action in player_actions:
			unique_actions[action] = true
		return clamp(float(unique_actions.size()) / float(max(1, player_actions.size())), 0.0, 1.0)

var player_retention: float = 0.0:
	get:
		return clamp(float(wave) / 100.0, 0.0, 1.0) # Normalizing roughly to wave 100

var asset_variety: float = 0.0:
	get:
		var types = {}
		for tower in active_towers:
			types[tower.get("type_id") if tower.get("type_id") else "default"] = true
		return clamp(float(types.size()) / 10.0, 0.0, 1.0) # Assume 10 max types

func add_tower(tower_ref) -> void:
	active_towers.append(tower_ref)
	state_changed.emit()

func remove_tower(tower_ref) -> void:
	active_towers.erase(tower_ref)
	state_changed.emit()

func log_action(action_type: String) -> void:
	player_actions.append(action_type)
	if player_actions.size() > 100:
		player_actions.pop_front() # Keep a sliding window
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
