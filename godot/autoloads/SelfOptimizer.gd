extends Node
## SelfOptimizer - Self-modifying game balance system
##
## Monitors gameplay metrics and adjusts game parameters to maintain
## engagement. Uses simple AI to tune difficulty curve and asset balance.

signal balance_adjusted(adjustments: Dictionary)
signal optimization_complete(report: Dictionary)

var _metric_buffer: Array = []
var _max_buffer_size: int = 1000

var _current_balance_state: Dictionary = {}
var _target_balance: float = 0.6
var _adjustment_cooldown: float = 0.0
var _cooldown_duration: float = 30.0  # Seconds between adjustments

# Balance parameters (these get adjusted)
var creep_health_modifier: float = 1.0
var tower_damage_modifier: float = 1.0
var gold_multiplier: float = 1.0
var spawn_rate_modifier: float = 1.0

# Thresholds for adjustment
var _retention_low_threshold: float = 0.4
var _retention_high_threshold: float = 0.8
var _diversity_low_threshold: float = 0.3

func _ready() -> void:
	_current_balance_state = GameState.get_balance_state()
	_print_initial_state()
	
	# Connect to game state changes
	GameState.state_changed.connect(_on_game_state_changed)

func _print_initial_state() -> void:
	print("[SelfOptimizer] Initial balance modifiers - Health: %.2f, Damage: %.2f, Gold: %.2f" % [
		creep_health_modifier, tower_damage_modifier, gold_multiplier
	])

func _process(delta: float) -> void:
	_adjustment_cooldown -= delta
	if _adjustment_cooldown <= 0:
		_analyze_and_adjust()

func _on_game_state_changed() -> void:
	_buffer_metric(GameState.get_balance_state())

func _buffer_metric(state: Dictionary) -> void:
	_metric_buffer.append({
		"state": state,
		"timestamp": Time.get_unix_time_from_system()
	})
	
	if _metric_buffer.size() > _max_buffer_size:
		_metric_buffer.pop_front()

func _analyze_and_adjust() -> void:
	if _metric_buffer.size() < 10:
		return  # Need enough data
	
	# Compute average metrics over recent window
	var avg_retention = 0.0
	var avg_diversity = 0.0
	var avg_variety = 0.0
	
	var window_size = min(50, _metric_buffer.size())
	for i in range(_metric_buffer.size() - window_size, _metric_buffer.size()):
		var entry = _metric_buffer[i]
		avg_retention += entry.state.get("player_retention", 0.5)
		avg_diversity += entry.state.get("strategy_diversity", 0.5)
		avg_variety += entry.state.get("asset_variety", 0.5)
	
	avg_retention /= window_size
	avg_diversity /= window_size
	avg_variety /= window_size
	
	var adjustments: Dictionary = {}
	
	# Retention too low = game too hard, need to ease up
	if avg_retention < _retention_low_threshold:
		creep_health_modifier *= 0.95
		tower_damage_modifier *= 1.05
		gold_multiplier *= 1.02
		adjustments["easement"] = true
		print("[SelfOptimizer] Low retention (%.2f) - Easing difficulty" % avg_retention)
	
	# Retention too high = game too easy, need to increase challenge
	elif avg_retention > _retention_high_threshold:
		creep_health_modifier *= 1.05
		tower_damage_modifier *= 0.95
		gold_multiplier *= 0.98
		adjustments["challenge"] = true
		print("[SelfOptimizer] High retention (%.2f) - Increasing challenge" % avg_retention)
	
	# Diversity too low = players stuck in same strategies
	if avg_diversity < _diversity_low_threshold:
		# Boost rewards for new strategies
		gold_multiplier *= 1.03
		spawn_rate_modifier *= 0.95
		adjustments["diversity_boost"] = true
		print("[SelfOptimizer] Low diversity (%.2f) - Encouraging variety" % avg_diversity)
	
	# Clamp modifiers to reasonable ranges
	creep_health_modifier = clampf(creep_health_modifier, 0.5, 2.0)
	tower_damage_modifier = clampf(tower_damage_modifier, 0.5, 2.0)
	gold_multiplier = clampf(gold_multiplier, 0.5, 2.0)
	spawn_rate_modifier = clampf(spawn_rate_modifier, 0.5, 2.0)
	
	if adjustments.size() > 0:
		adjustments["creep_health_modifier"] = creep_health_modifier
		adjustments["tower_damage_modifier"] = tower_damage_modifier
		adjustments["gold_multiplier"] = gold_multiplier
		adjustments["spawn_rate_modifier"] = spawn_rate_modifier
		adjustments["avg_retention"] = avg_retention
		adjustments["avg_diversity"] = avg_diversity
		balance_adjusted.emit(adjustments)
	
	_adjustment_cooldown = _cooldown_duration
	
	# Report optimization
	optimization_complete.emit({
		"metrics": {
			"retention": avg_retention,
			"diversity": avg_diversity,
			"variety": avg_variety
		},
		"adjustments": adjustments
	})

## Get current balance modifiers
func get_balance_modifiers() -> Dictionary:
	return {
		"creep_health_modifier": creep_health_modifier,
		"tower_damage_modifier": tower_damage_modifier,
		"gold_multiplier": gold_multiplier,
		"spawn_rate_modifier": spawn_rate_modifier
	}