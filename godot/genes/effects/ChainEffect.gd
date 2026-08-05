extends "res://genes/effects/EffectGeneBase.gd"
## ChainEffect - Chains damage to nearby targets
## Initial hit chains to nearby enemies

func apply(target: Node, intensity: float) -> Dictionary:
	if not target.has_method("take_damage"):
		return {"applied": false, "reason": "target_no_damage_method"}
	
	var chain_count = _params.get("chain_count", 3) * intensity
	var chain_range = _params.get("chain_range", 100.0)
	var damage_reduction = _params.get("damage_reduction", 0.7)
	
	target.add_status_effect("chain", {
		"chain_count": int(chain_count),
		"chain_range": chain_range,
		"damage_reduction": damage_reduction,
		"source": "chain"
	})
	
	return {
		"applied": true,
		"effect_type": "chain",
		"chain_count": int(chain_count),
		"chain_range": chain_range,
		"damage_reduction": damage_reduction
	}

func get_display_name() -> String:
	return "Chain"

func get_description() -> String:
	return "Chains to %d targets within %.0fpx, %.0f%% damage per chain" % [
		_params.get("chain_count", 3),
		_params.get("chain_range", 100.0),
		(1.0 - _params.get("damage_reduction", 0.7)) * 100
	]

func get_gene_id() -> String:
	return "chain"

func _get_param_schema() -> Dictionary:
	return {
		"chain_count": {"type": TYPE_INT, "default": 3, "min": 1, "max": 8},
		"chain_range": {"type": TYPE_FLOAT, "default": 100.0, "min": 50.0, "max": 300.0},
		"damage_reduction": {"type": TYPE_FLOAT, "default": 0.7, "min": 0.3, "max": 0.9}
	}
