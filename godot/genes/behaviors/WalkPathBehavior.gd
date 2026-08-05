extends BehaviorBase
## WalkPathBehavior - Standard path-following behavior
##
## Creeps using this behavior follow the predefined path waypoints.

func _evaluate(context: Dictionary) -> Dictionary:
	var direction = context.get("direction", Vector2(1, 0))
	return {"move_direction": direction}

func get_display_name() -> String:
	return "Walk Path"

func get_description() -> String:
	return "Follows the predefined path waypoints"

func get_gene_id() -> String:
	return "walk_path"
