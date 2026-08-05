extends Control
## Dashboard - Side panel showing game statistics and agent status
## Displays balance modifiers, wave info, and agent connection status

@onready var _wave_value: Label = get_node_or_null("Panel/VBox/WaveInfo/Value")
@onready var _enemy_value: Label = get_node_or_null("Panel/VBox/EnemyInfo/Value")
@onready var _tower_value: Label = get_node_or_null("Panel/VBox/TowerInfo/Value")
@onready var _creep_mod_value: Label = get_node_or_null("Panel/VBox/CreepMod/Value")
@onready var _tower_mod_value: Label = get_node_or_null("Panel/VBox/TowerMod/Value")
@onready var _gold_mod_value: Label = get_node_or_null("Panel/VBox/GoldMod/Value")
@onready var _agent_status_dot: Label = get_node_or_null("Panel/VBox/AgentStatus/StatusDot")
@onready var _agent_status_label: Label = get_node_or_null("Panel/VBox/AgentStatus/StatusLabel")

var _agent_connected: bool = false

func _ready() -> void:
	GameState.wave_started.connect(_on_wave_started)
	GameState.state_changed.connect(_on_state_changed)
	
	# Connect to AgentBridge if available
	if has_node("/root/AgentBridge"):
		_agent_connected = true
		_update_agent_status()
	
	_update_display()
	print("[Dashboard] Initialized")

func _on_wave_started(wave_num: int) -> void:
	if _wave_value:
		_wave_value.text = str(wave_num)

func _on_state_changed() -> void:
	_update_display()

func _update_display() -> void:
	# Update wave info
	if GameState and _wave_value:
		_wave_value.text = str(GameState.current_wave)
	
	# Update enemy count
	var enemy_count = _count_enemies()
	if _enemy_value:
		_enemy_value.text = str(enemy_count)
	
	# Update tower count
	var tower_count = _count_towers()
	if _tower_value:
		_tower_value.text = str(tower_count)
	
	# Update balance modifiers from SelfOptimizer
	if has_node("/root/SelfOptimizer"):
		var optimizer = get_node("/root/SelfOptimizer")
		var mods = optimizer.get_balance_modifiers()
		if _creep_mod_value:
			_creep_mod_value.text = "%.0f%%" % (mods.get("creep_health_modifier", 1.0) * 100)
		if _tower_mod_value:
			_tower_mod_value.text = "%.0f%%" % (mods.get("tower_damage_modifier", 1.0) * 100)
		if _gold_mod_value:
			_gold_mod_value.text = "%.0f%%" % (mods.get("gold_multiplier", 1.0) * 100)

func _count_enemies() -> int:
	var count = 0
	var arena = get_tree().get_first_node_in_group("arena")
	if arena:
		count = arena.get_child_count()
	return count

func _count_towers() -> int:
	var count = 0
	if has_node("/root/GameState"):
		# Count towers through game state
		pass
	return count

func _update_agent_status() -> void:
	if _agent_status_dot:
		_agent_status_dot.add_theme_color_override("font_color", 
			Color(0.2, 1.0, 0.2) if _agent_connected else Color(1.0, 0.2, 0.2))
	if _agent_status_label:
		_agent_status_label.text = "Connected" if _agent_connected else "Disconnected"
