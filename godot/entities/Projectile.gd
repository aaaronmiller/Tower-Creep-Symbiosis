extends Area2D
## Projectile - Fired by towers toward creeps
##
## Projectiles travel toward their target and apply damage on impact.

class_name Projectile

signal hit(target: Node)
signal expired()

# Configuration
var damage: float = 25.0
var speed: float = 300.0
var target: Node = null

func _ready() -> void:
	# Set collision layer/mask
	collision_layer = 8
	collision_mask = 2
	
	# Connect body entered signal
	body_entered.connect(_on_body_entered)
	
	# Add visual
	var rect = ColorRect.new()
	rect.offset_left = -4.0
	rect.offset_top = -4.0
	rect.offset_right = 4.0
	rect.offset_bottom = 4.0
	rect.color = Color(1.0, 0.8, 0.2, 1.0)
	add_child(rect)

func _physics_process(delta: float) -> void:
	if target == null or not is_instance_valid(target):
		expired.emit()
		queue_free()
		return
	
	# Move toward target
	var direction = (target.global_position - global_position).normalized()
	position += direction * speed * delta
	
	# Check if reached target
	var distance = global_position.distance_to(target.global_position)
	if distance < 10.0:
		_hit_target()

func _on_body_entered(body: Node) -> void:
	if body == target:
		_hit_target()

func _hit_target() -> void:
	if target and is_instance_valid(target):
		if target.has_method("take_damage"):
			target.take_damage(damage, self)
		hit.emit(target)
	queue_free()
