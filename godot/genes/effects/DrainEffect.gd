extends "res://genes/effects/EffectGeneBase.gd"
## DrainEffect - Steals health and mana from target
## Applies drain effect that heals attacker

func apply(target: Node, intensity: float) -> Dictionary:
	if not target.has_method("take_damage"):
		return {"applied": false, "reason": "target_no_damage_method"}
	
	var health_drain_percent = _params.get("health_drain_percent", 0.1) * intensity
	var mana_drain_percent = _params.get("mana_drain_percent", 0.05) * intensity
	var duration = _params.get("duration", 3.0)
	
	target.add_status_effect("drain", {
		"health_drain_percent": health_drain_percent,
		"mana_drain_percent": mana_drain_percent,
		"duration": duration,
		"source": "drain"
	})
	
	return {
		"applied": true,
		"effect_type": "drain",
		"health_drain_percent": health_drain_percent,
		"mana_drain_percent": mana_drain_percent,
		"duration": duration
	}

func get_display_name() -> String:
	return "Drain"

func get_description() -> String:
	return "Drains %.0f%% HP and %.0f%% mana over %.1fs" % [
		_params.get("health_drain_percent", 0.1) * 100,
		_params.get("mana_drain_percent", 0.05) * 100,
		_params.get("duration", 3.0)
	]

func get_gene_id() -> String:
	return "drain"

func _get_param_schema() -> Dictionary:
	return {
		"health_drain_percent": {"type": TYPE_FLOAT, "default": 0.1, "min": 0.05, "max": 0.3},
		"mana_drain_percent": {"type": TYPE_FLOAT, "default": 0.05, "min": 0.0, "max": 0.2},
		"duration": {"type": TYPE_FLOAT, "default": 3.0, "min": 1.0, "max": 8.0}
	}
