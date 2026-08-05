extends "res://genes/effects/EffectGeneBase.gd"
## FreezeEffect - Slows target movement speed
## Applies a slowing effect that reduces movement speed for duration

func apply(target: Node, intensity: float) -> Dictionary:
	if not target.has_method("apply_slow"):
		return {"applied": false, "reason": "target_no_slow_method"}
	
	var duration = _params.get("duration", 2.0)
	var slow_factor = _params.get("slow_factor", 0.5) * intensity
	
	target.apply_slow(slow_factor, duration)
	
	return {
		"applied": true,
		"effect_type": "freeze",
		"slow_factor": slow_factor,
		"duration": duration
	}

func get_display_name() -> String:
	return "Freeze"

func get_description() -> String:
	return "Slows target movement by %.0f%% for %.1fs" % [
		(1.0 - _params.get("slow_factor", 0.5)) * 100,
		_params.get("duration", 2.0)
	]

func get_gene_id() -> String:
	return "freeze"

func _get_param_schema() -> Dictionary:
	return {
		"duration": {"type": TYPE_FLOAT, "default": 2.0, "min": 0.5, "max": 5.0},
		"slow_factor": {"type": TYPE_FLOAT, "default": 0.5, "min": 0.1, "max": 0.9}
	}
