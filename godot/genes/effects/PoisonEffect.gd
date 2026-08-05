extends "res://genes/effects/EffectGeneBase.gd"
## PoisonEffect - Damage over time that bypasses armor
## Applies poison that deals damage regardless of defense

func apply(target: Node, intensity: float) -> Dictionary:
	if not target.has_method("take_damage"):
		return {"applied": false, "reason": "target_no_damage_method"}
	
	var duration = _params.get("duration", 4.0)
	var dps = _params.get("dps", 3.0) * intensity
	
	target.add_status_effect("poison", {
		"dps": dps,
		"duration": duration,
		"source": "poison",
		"bypasses_armor": true
	})
	
	return {
		"applied": true,
		"effect_type": "poison",
		"dps": dps,
		"duration": duration,
		"bypasses_armor": true
	}

func get_display_name() -> String:
	return "Poison"

func get_description() -> String:
	return "Deals %.1f DPS for %.1fs, bypasses armor" % [
		_params.get("dps", 3.0),
		_params.get("duration", 4.0)
	]

func get_gene_id() -> String:
	return "poison"

func _get_param_schema() -> Dictionary:
	return {
		"duration": {"type": TYPE_FLOAT, "default": 4.0, "min": 1.0, "max": 12.0},
		"dps": {"type": TYPE_FLOAT, "default": 3.0, "min": 1.0, "max": 15.0}
	}
