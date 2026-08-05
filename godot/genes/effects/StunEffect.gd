extends "res://genes/effects/EffectGeneBase.gd"
## StunEffect - Temporarily disables target
## Applies a stun that prevents movement and actions

func apply(target: Node, intensity: float) -> Dictionary:
	if not target.has_method("apply_stun"):
		return {"applied": false, "reason": "target_no_stun_method"}
	
	var duration = _params.get("duration", 1.0) * intensity
	
	target.apply_stun(duration)
	
	return {
		"applied": true,
		"effect_type": "stun",
		"duration": duration
	}

func get_display_name() -> String:
	return "Stun"

func get_description() -> String:
	return "Stuns target for %.1fs" % [
		_params.get("duration", 1.0)
	]

func get_gene_id() -> String:
	return "stun"

func _get_param_schema() -> Dictionary:
	return {
		"duration": {"type": TYPE_FLOAT, "default": 1.0, "min": 0.2, "max": 3.0}
	}
