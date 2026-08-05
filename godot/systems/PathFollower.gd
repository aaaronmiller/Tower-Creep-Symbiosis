extends Node
## PathFollower - Waypoint-based path traversal for entities
##
## Provides waypoint following logic for creeps and other path-following entities.

class_name PathFollower

signal path_completed()
signal waypoint_reached(waypoint_index: int)

# Configuration
var waypoints: Array[Vector2] = []
var current_waypoint_index: int = 0

## Advance an entity along the path
func advance(entity: Node2D, delta: float) -> Vector2:
	if waypoints.is_empty() or current_waypoint_index >= waypoints.size():
		return Vector2.ZERO
	
	var target = waypoints[current_waypoint_index]
	var direction = (target - entity.global_position).normalized()
	
	# Check if reached waypoint
	var distance = entity.global_position.distance_to(target)
	if distance < 5.0:
		current_waypoint_index += 1
		waypoint_reached.emit(current_waypoint_index - 1)
		
		if current_waypoint_index >= waypoints.size():
			path_completed.emit()
			return Vector2.ZERO
	
	return direction

## Get the next direction for an entity without advancing
func get_next_direction(entity: Node2D) -> Vector2:
	if waypoints.is_empty() or current_waypoint_index >= waypoints.size():
		return Vector2.ZERO
	
	var target = waypoints[current_waypoint_index]
	return (target - entity.global_position).normalized()

## Set waypoints for this follower
func set_waypoints(points: Array[Vector2]) -> void:
	waypoints = points
	current_waypoint_index = 0

## Reset to beginning
func reset() -> void:
	current_waypoint_index = 0

## Get progress along path (0.0 to 1.0)
func get_progress(entity: Node2D) -> float:
	if waypoints.is_empty():
		return 1.0
	
	var total_distance = 0.0
	var traveled_distance = 0.0
	
	for i in range(waypoints.size() - 1):
		total_distance += waypoints[i].distance_to(waypoints[i + 1])
	
	for i in range(current_waypoint_index):
		traveled_distance += waypoints[i].distance_to(waypoints[i + 1])
	
	if current_waypoint_index < waypoints.size():
		traveled_distance += entity.global_position.distance_to(waypoints[current_waypoint_index])
	
	if total_distance <= 0:
		return 1.0
	
	return clampf(traveled_distance / total_distance, 0.0, 1.0)
