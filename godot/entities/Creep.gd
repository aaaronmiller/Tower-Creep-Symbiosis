extends CharacterBody2D
## Creep - Enemy entity that follows path and drains player lives
##
## Creeps spawn at the path start, follow waypoints, and either
## reach the exit (draining lives) or die from tower attacks.

class_name Creep

signal died(killer_id: String)
signal path_completed()

# Configuration
@export var max_health: float = 100.0
@export var speed: float = 50.0
@export var gold_reward: int = 10
@export var behavior_gene_id: String = "walk_path"

# State
var health: float = 100.0
var _current_waypoint_index: int = 0
var _waypoints: Array[Vector2] = []
var _path_follower: Node = null
var _behavior_gene: Resource = null

func _ready() -> void:
	health = max_health
	_add_default_waypoints()
	
	# Load behavior gene if available
	if GenomeRegistry.has_node() and GenomeRegistry.has_gene(behavior_gene_id):
		_behavior_gene = GenomeRegistry.get_gene(behavior_gene_id)
	elif GenomeRegistry.has_node():
		GenomeRegistry.execute_gene(behavior_gene_id, {})  # Prime the gene
	
	print("[Creep] Spawned - Health: %.1f, Speed: %.1f, Gene: %s" % [health, speed, behavior_gene_id])

func _add_default_waypoints() -> void:
	# Default path: left to right across arena
	var arena = get_parent()
	if arena and arena.has_method("get_spawn_point") and arena.has_method("get_exit_point"):
		_waypoints.append(arena.get_spawn_point())
		_waypoints.append(arena.get_exit_point())
	else:
		# Fallback: basic horizontal path
		_waypoints.append(Vector2(0, 360))
		_waypoints.append(Vector2(1280, 360))

func _physics_process(delta: float) -> void:
	if _waypoints.is_empty():
		return
	
	# Get current target waypoint
	var target = _waypoints[_current_waypoint_index]
	var direction = (target - global_position).normalized()
	
	# Apply behavior gene if available
	var move_direction = direction
	if _behavior_gene and _behavior_gene.has_method("_evaluate"):
		var context = {
			"position": global_position,
			"target": target,
			"direction": direction,
			"health": health,
			"speed": speed
		}
		var behavior_result = _behavior_gene._evaluate(context)
		if behavior_result.has("move_direction"):
			move_direction = behavior_result.move_direction
	
	# Move toward waypoint
	velocity = move_direction * speed
	var collision = move_and_slide()
	
	# Check if reached waypoint
	var distance_to_waypoint = global_position.distance_to(target)
	if distance_to_waypoint < 5.0:
		_current_waypoint_index += 1
		if _current_waypoint_index >= _waypoints.size():
			_complete_path()

func _complete_path() -> void:
	# Reached exit - drain a life
	GameState.lose_life()
	path_completed.emit()
	queue_free()

## Apply damage to this creep
func take_damage(amount: float, source) -> void:
	health -= amount
	print("[Creep] Took %.1f damage - Health: %.1f" % [amount, health])
	
	if health <= 0:
		_die("tower")

func _die(killer_id: String) -> void:
	died.emit(killer_id)
	GameState.add_gold(gold_reward)
	print("[Creep] Died - Reward: %d gold" % gold_reward)
	queue_free()

## Set custom waypoints
func set_waypoints(waypoints: Array[Vector2]) -> void:
	_waypoints = waypoints
	_current_waypoint_index = 0

## Set behavior gene
func set_behavior(gene_id: String) -> void:
	behavior_gene_id = gene_id
	if GenomeRegistry.has_node():
		_behavior_gene = GenomeRegistry.get_gene(gene_id)
