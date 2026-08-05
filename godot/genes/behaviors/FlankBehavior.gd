extends BehaviorBase
## FlankBehavior - Aggressive behavior that avoids tower range
##
## Creeps using this behavior attempt to move around tower range zones.

func _evaluate(context: Dictionary) -> Dictionary:
	var position = context.get("position", Vector2.ZERO)
	var direction = context.get("direction", Vector2(1, 0))
	
	# Find nearest tower and bias away from its range
	var nearest_tower_pos: Vector2 = Vector2(-1, -1)
	var nearest_distance: float = INF
	
	# This would need access to tower positions - simplified for now
	# In full implementation, this would query the game state
	
	# Default: just follow path
	var move_direction = direction
	
	# If near a tower's range, try to flank
	if nearest_tower_pos.x >= 0:
		var tower_range = 150.0
		var dist_to_tower = position.distance_to(nearest_tower_pos)
		
		if dist_to_tower < tower_range * 1.5:
			# Bias perpendicular to the tower direction
			var to_tower = (nearest_tower_pos - position).normalized()
			var perpendicular = Vector2(-to_tower.y, to_tower.x)
			move_direction = (direction + perpendicular * 0.5).normalized()
	
	return {"move_direction": move_direction}

func get_display_name() -> String:
	return "Flank"

func get_description() -> String:
	return "Avoids tower range zones"

func get_gene_id() -> String:
	return "flank"
