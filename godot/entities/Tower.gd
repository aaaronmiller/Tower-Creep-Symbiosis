extends StaticBody2D
## Tower - Defensive structure that shoots at creeps
##
## Towers detect creeps in range and fire projectiles at them.
## Each tower has a fire rate, damage, and range.

class_name Tower

signal tower_placed()
signal target_acquired(target: Node)
signal fired(projectile: Node)

# Configuration
@export var damage: float = 25.0
@export var fire_rate: float = 1.0  # Shots per second
@export var range_radius: float = 150.0
@export var projectile_speed: float = 300.0
@export var tower_type: String = "basic"

# State
var _fire_cooldown: float = 0.0
var _current_target: Node = null
var _target_search_interval: float = 0.25
var _time_since_last_search: float = 0.0

func _ready() -> void:
	_fire_cooldown = 0.0
	print("[Tower] Placed - Type: %s, Damage: %.1f, Range: %.1f" % [tower_type, damage, range_radius])
	tower_placed.emit()

func _process(delta: float) -> void:
	# Handle cooldown
	if _fire_cooldown > 0:
		_fire_cooldown -= delta
	
	# Search for targets periodically
	_time_since_last_search += delta
	if _time_since_last_search >= _target_search_interval:
		_time_since_last_search = 0.0
		_find_target()
	
	# Fire at target if ready
	if _current_target and is_instance_valid(_current_target) and _fire_cooldown <= 0:
		_fire_at_target()

func _find_target() -> void:
	var overlapping_bodies = $RangeArea.get_overlapping_bodies()
	
	if overlapping_bodies.is_empty():
		_current_target = null
		return
	
	# Find closest creep
	var closest: Node = null
	var closest_distance: float = INF
	
	for body in overlapping_bodies:
		if body is Creep:
			var dist = global_position.distance_to(body.global_position)
			if dist < closest_distance:
				closest = body
				closest_distance = dist
	
	_current_target = closest
	if _current_target:
		target_acquired.emit(_current_target)

func _fire_at_target() -> void:
	if not _current_target or not is_instance_valid(_current_target):
		return
	
	# Create projectile
	var projectile_scene = preload("res://godot/entities/Projectile.tscn")
	var projectile = projectile_scene.instantiate()
	projectile.target = _current_target
	projectile.damage = damage
	projectile.speed = projectile_speed
	
	# Add to parent (projectile layer)
	var parent = get_parent()
	if parent:
		parent.add_child(projectile)
		projectile.global_position = global_position
	
	# Reset cooldown
	_fire_cooldown = 1.0 / fire_rate
	fired.emit(projectile)

## Get current target
func get_target() -> Node:
	return _current_target

## Check if tower is ready to fire
func can_fire() -> bool:
	return _current_target != null and _fire_cooldown <= 0

## Apply effect gene modifier
func apply_effect(effect_name: String, modifier: float) -> void:
	match effect_name:
		"freeze":
			fire_rate *= (1.0 - modifier)
		"stun":
			_fire_cooldown += modifier
		"drain":
			damage *= (1.0 - modifier)
	print("[Tower] Applied %s effect - New fire_rate: %.2f, damage: %.1f" % [effect_name, fire_rate, damage])
