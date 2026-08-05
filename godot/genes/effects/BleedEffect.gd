extends "res://genes/effects/EffectGeneBase.gd"
## BleedEffect - Deals damage over time
## Applies a bleeding effect that deals damage each tick

func apply(target: Node, intensity: float) -> Dictionary:
	if not target.has_method("take_damage"):
		return {"applied": false, "reason": "target_no_damage_method"}
	
	var duration = _params.get("duration", 3.0)
	var damage_per_tick = _params.get("damage_per_tick", 5.0) * intensity
	var tick_interval = _params.get("tick_interval", 0.5)
	
	target.add_status_effect("bleed", {
		"damage_per_tick": damage_per_tick,
		"tick_interval": tick_interval,
		"duration": duration,
		"source": "bleed"
	})
	
	return {
		"applied": true,
		"effect_type": "bleed",
		"damage_per_tick": damage_per_tick,
		"duration": duration
	}

func get_display_name() -> String:
	return "Bleed"

func get_description() -> String:
	return "Deals %.1f damage every %.1fs for %.1fs" % [
		_params.get("damage_per_tick", 5.0),
		_params.get("tick_interval", 0.5),
		_params.get("duration", 3.0)
	]

func get_gene_id() -> String:
	return "bleed"

func _get_param_schema() -> Dictionary:
	return {
		"duration": {"type": TYPE_FLOAT, "default": 3.0, "min": 1.0, "max": 10.0},
		"damage_per_tick": {"type": TYPE_FLOAT, "default": 5.0, "min": 1.0, "max": 20.0},
		"tick_interval": {"type": TYPE_FLOAT, "default": 0.5, "min": 0.1, "max": 2.0}
	}
