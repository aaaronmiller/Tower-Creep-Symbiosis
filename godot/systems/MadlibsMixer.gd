extends Node
## MadlibsMixer - Procedural prompt generator for AI agents
## Combines templates with game state to generate contextual prompts

signal prompt_generated(template_id: String, prompt: String)

var _templates: Dictionary = {}
var _active_templates: Array = []
var _template_dir: String = "res://data/prompt-templates/"

func _ready() -> void:
	_load_templates()
	print("[MadlibsMixer] Initialized with %d templates" % _templates.size())

func _load_templates() -> void:
	_templates = {
		"wave_intel": {
			"id": "wave_intel",
			"slots": ["wave_num", "creep_count", "creep_types", "difficulty"],
			"template": "Wave {wave_num}: {creep_count} creeps of types [{creep_types}], difficulty {difficulty}"
		},
		"tower_status": {
			"id": "tower_status",
			"slots": ["tower_type", "health", "position", "kills"],
			"template": "Tower at {position}: {tower_type}, {health}% HP, {kills} kills"
		},
		"strategy_suggestion": {
			"id": "strategy_suggestion",
			"slots": ["lives", "gold", "wave", "recommendation"],
			"template": "Lives: {lives}, Gold: {gold}, Wave: {wave} - {recommendation}"
		},
		"creep_threat": {
			"id": "creep_threat",
			"slots": ["creep_type", "health", "speed", "armor"],
			"template": "Threat: {creep_type} with {health} HP, speed {speed}, armor {armor}"
		},
		"balance_report": {
			"id": "balance_report",
			"slots": ["creep_mod", "tower_mod", "gold_mod", "spawn_mod"],
			"template": "Balance: Creep HP {creep_mod:.0%}, Tower DMG {tower_mod:.0%}, Gold {gold_mod:.0%}, Spawn {spawn_mod:.0%}"
		}
	}

## Fill a template with game state values
func fill(template_id: String, values: Dictionary) -> String:
	if not _templates.has(template_id):
		push_warning("[MadlibsMixer] Unknown template: %s" % template_id)
		return ""
	
	var tmpl = _templates[template_id]
	var result = tmpl.template
	
	for key in tmpl.slots:
		var value = values.get(key, "<?>")
		result = result.replace("{%s}" % key, str(value))
	
	prompt_generated.emit(template_id, result)
	return result

## Generate a contextual wave intel prompt
func generate_wave_intel(wave_num: int, creeps: Array) -> String:
	var creep_types: Array = []
	var total_health: float = 0.0
	var avg_speed: float = 0.0
	
	for creep in creeps:
		if creep.has("creep_type"):
			creep_types.append(creep.creep_type)
		if creep.has("health"):
			total_health += creep.health
		if creep.has("speed"):
			avg_speed += creep.speed
	
	var difficulty = "medium"
	if total_health > 500:
		difficulty = "hard"
	elif total_health < 200:
		difficulty = "easy"
	
	return fill("wave_intel", {
		"wave_num": wave_num,
		"creep_count": creeps.size(),
		"creep_types": ", ".join(creep_types),
		"difficulty": difficulty
	})

## Generate tower status prompt
func generate_tower_status(tower: Node) -> String:
	return fill("tower_status", {
		"tower_type": tower.get("tower_type") if tower.has("tower_type") else "Unknown",
		"health": tower.get("health") if tower.has("health") else 100,
		"position": tower.get("position") if tower.has("position") else Vector2.ZERO,
		"kills": tower.get("kill_count") if tower.has("kill_count") else 0
	})

## Generate strategy suggestion based on game state
func generate_strategy(gamestate: Dictionary) -> String:
	var recommendation = "Hold position and build defenses."
	
	var lives = gamestate.get("lives", 20)
	var gold = gamestate.get("gold", 100)
	var wave = gamestate.get("wave", 1)
	
	if lives <= 5:
		recommendation = "CRITICAL: Focus fire on high-threat targets!"
	elif lives <= 10:
		recommendation = "Consider selling underperforming towers."
	elif gold > 500:
		recommendation = "Strong economy - upgrade key towers."
	elif wave > 10:
		recommendation = "Late game - prioritize crowd control."
	
	return fill("strategy_suggestion", {
		"lives": lives,
		"gold": gold,
		"wave": wave,
		"recommendation": recommendation
	})

## Get list of available template IDs
func get_available_templates() -> Array:
	return _templates.keys()
