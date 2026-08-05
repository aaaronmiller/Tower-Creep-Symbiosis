extends Resource
class_name BehaviorBase
## BehaviorBase - Base class for all behavior genes
##
## All creep behaviors must extend this class and implement _evaluate().

func _evaluate(context: Dictionary) -> Dictionary:
	push_error("[BehaviorBase] _evaluate() not implemented in %s" % get_class())
	return {"move_direction": Vector2(0, 0), "error": "not_implemented"}

func initialize(params: Dictionary) -> void:
	pass

func get_display_name() -> String:
	return "Unnamed Behavior"

func get_description() -> String:
	return "No description"

func get_gene_id() -> String:
	return "unnamed_behavior"
