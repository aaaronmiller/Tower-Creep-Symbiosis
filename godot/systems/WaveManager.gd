extends Node
## WaveManager - Manages creep spawning and wave progression
##
## Handles wave configuration, creep spawning, and wave completion logic.

signal wave_started(wave_num: int)
signal wave_complete(wave_num: int)
signal creep_spawned(creep: Node)
signal all_creeps_defeated()

# Wave configuration
var wave_configs: Array[Dictionary] = []

# Current wave state
var current_wave_number: int = 0
var _creeps_to_spawn: int = 0
var _creeps_spawned: int = 0
var _creeps_killed: int = 0
var _spawn_timer: Timer = null
var _spawn_interval: float = 1.0

# Default wave configs
func _ready() -> void:
	_initialize_default_waves()
	_spawn_timer = Timer.new()
	_spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	add_child(_spawn_timer)
	print("[WaveManager] Initialized with %d wave configs" % wave_configs.size())

func _initialize_default_waves() -> void:
	# Default wave configurations
	wave_configs = [
		{"count": 3, "health": 80.0, "speed": 40.0, "gene_id": "walk_path", "gold_reward": 10, "spawn_interval": 2.0},
		{"count": 5, "health": 100.0, "speed": 45.0, "gene_id": "walk_path", "gold_reward": 12, "spawn_interval": 1.8},
		{"count": 8, "health": 120.0, "speed": 50.0, "gene_id": "walk_path", "gold_reward": 15, "spawn_interval": 1.5},
		{"count": 10, "health": 150.0, "speed": 55.0, "gene_id": "flank", "gold_reward": 18, "spawn_interval": 1.2},
		{"count": 15, "health": 200.0, "speed": 60.0, "gene_id": "walk_path", "gold_reward": 20, "spawn_interval": 1.0},
	]

## Start a wave by number
func start_wave(wave_num: int) -> void:
	if wave_num < 1 or wave_num > wave_configs.size():
		push_warning("[WaveManager] Invalid wave number: %d" % wave_num)
		return
	
	current_wave_number = wave_num
	var config = wave_configs[wave_num - 1]
	
	_creeps_to_spawn = config.count
	_creeps_spawned = 0
	_creeps_killed = 0
	_spawn_interval = config.spawn_interval
	
	GameState.start_wave(wave_num)
	wave_started.emit(wave_num)
	
	# Start spawning
	_spawn_timer.start(_spawn_interval)
	_spawn_next_creep()
	
	print("[WaveManager] Wave %d started - %d creeps, health: %.0f, speed: %.0f" % [
		wave_num, _creeps_to_spawn, config.health, config.speed
	])

func _spawn_next_creep() -> void:
	if _creeps_spawned >= _creeps_to_spawn:
		_spawn_timer.stop()
		return
	
	var config = wave_configs[current_wave_number - 1]
	
	# Create creep
	var creep_scene = preload("res://godot/entities/Creep.tscn")
	var creep = creep_scene.instantiate()
	creep.max_health = config.health
	creep.speed = config.speed
	creep.gold_reward = config.gold_reward
	creep.behavior_gene_id = config.gene_id
	
	# Find arena and add creep
	var arena = get_parent()
	if arena:
		var creep_layer = arena.get_node_or_null("CreepLayer")
		if creep_layer:
			creep_layer.add_child(creep)
			
			# Set spawn position
			if arena.has_method("get_spawn_point"):
				creep.global_position = arena.get_spawn_point()
	
	# Connect to creep signals
	creep.died.connect(_on_creep_died)
	creep.path_completed.connect(_on_creep_path_completed)
	
	_creeps_spawned += 1
	creep_spawned.emit(creep)

func _on_spawn_timer_timeout() -> void:
	_spawn_next_creep()

func _on_creep_died(killer_id: String) -> void:
	_creeps_killed += 1
	print("[WaveManager] Creep killed by %s - %d/%d remaining" % [killer_id, _creeps_to_spawn - _creeps_killed, _creeps_to_spawn])
	_check_wave_complete()

func _on_creep_path_completed() -> void:
	_creeps_killed += 1
	print("[WaveManager] Creep reached exit - %d/%d remaining" % [_creeps_to_spawn - _creeps_killed, _creeps_to_spawn])
	_check_wave_complete()

func _check_wave_complete() -> void:
	if _creeps_killed >= _creeps_to_spawn:
		_spawn_timer.stop()
		GameState.complete_wave(current_wave_number)
		wave_complete.emit(current_wave_number)
		print("[WaveManager] Wave %d complete!" % current_wave_number)

## Get current wave config
func get_current_config() -> Dictionary:
	if current_wave_number > 0 and current_wave_number <= wave_configs.size():
		return wave_configs[current_wave_number - 1]
	return {}

## Get total waves
func get_total_waves() -> int:
	return wave_configs.size()
