extends Node
## EffectGeneBase - Base class for all effect genes
## Defines the interface for applying status effects to targets

class_name EffectGeneBase

var _params: Dictionary = {}

func _init(params: Dictionary = {}) -> void:
	_params = _get_default_params()

## Apply the effect to a target node
func apply(target: Node, intensity: float = 1.0) -> Dictionary:
	push_error("EffectGeneBase.apply() must be overridden")
	return {"applied": false, "reason": "not_implemented"}

## Called each tick while effect is active
func tick(target: Node, delta: float) -> Dictionary:
	return {"ticked": false}

## Called when effect expires or is removed
func remove(target: Node) -> void:
	pass

## Get display name for UI
func get_display_name() -> String:
	return "Unknown Effect"

## Get description for tooltips
func get_description() -> String:
	return "No description"

## Unique gene identifier
func get_gene_id() -> String:
	return "unknown"

## Get gene type for registry
func get_gene_type() -> String:
	return "effect"

## Set a parameter value
func set_param(key: String, value) -> void:
	_params[key] = value

## Get a parameter value
func get_param(key: String, default = null):
	return _params.get(key, default)

## Get all parameters as dictionary
func get_params() -> Dictionary:
	return _params.duplicate(true)

## Get the parameter schema for validation
func _get_param_schema() -> Dictionary:
	return {}

## Get default params from schema
func _get_default_params() -> Dictionary:
	var defaults: Dictionary = {}
	for key in _get_param_schema():
		defaults[key] = _get_param_schema()[key].get("default", null)
	return defaults

## Validate parameters against schema
func validate_params() -> Dictionary:
	var errors: Array = []
	for key in _params:
		if not _get_param_schema().has(key):
			errors.append("Unknown parameter: %s" % key)
	return {"valid": errors.size() == 0, "errors": errors}

## Clone this gene with fresh params
func clone() -> EffectGeneBase:
	var gene = get_script().new(_params)
	return gene
