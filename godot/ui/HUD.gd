extends Control
## HUD - Main heads-up display overlay
## Shows lives, gold, wave info, and game controls

signal button_pressed(action: String)

@onready var _lives_label: Label = get_node_or_null("Panel/VBox/LivesRow/LivesValue")
@onready var _gold_label: Label = get_node_or_null("Panel/VBox/GoldRow/GoldValue")
@onready var _wave_label: Label = get_node_or_null("Panel/VBox/WaveRow/WaveValue")
@onready var _fps_label: Label = get_node_or_null("Panel/VBox/FPSRow/FPSValue")

var _minimized: bool = false

func _ready() -> void:
	GameState.lives_changed.connect(_on_lives_changed)
	GameState.gold_changed.connect(_on_gold_changed)
	GameState.wave_started.connect(_on_wave_started)
	GameState.state_changed.connect(_on_state_changed)
	
	_update_display()
	print("[HUD] Initialized")

func _process(_delta: float) -> void:
	# Update FPS display every 0.5 seconds
	var fps = Engine.get_frames_per_second()
	if _fps_label:
		_fps_label.text = "%d FPS" % fps

func _on_lives_changed(new_lives: int) -> void:
	if _lives_label:
		_lives_label.text = str(new_lives)
		# Flash red if low
		if new_lives <= 5:
			_lives_label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2))

func _on_gold_changed(new_gold: float) -> void:
	if _gold_label:
		_gold_label.text = "%.0f" % new_gold

func _on_wave_started(wave_num: int) -> void:
	if _wave_label:
		_wave_label.text = "Wave %d" % wave_num

func _on_state_changed() -> void:
	_update_display()

func _update_display() -> void:
	if GameState:
		if _lives_label:
			_lives_label.text = str(GameState.lives)
		if _gold_label:
			_gold_label.text = "%.0f" % GameState.gold
		if _wave_label:
			_wave_label.text = "Wave %d" % GameState.current_wave

func _on_pause_pressed() -> void:
	button_pressed.emit("pause")
	get_tree().paused = not get_tree().paused

func _on_speed_1x_pressed() -> void:
	button_pressed.emit("speed_1x")
	Engine.set_time_scale(1.0)

func _on_speed_2x_pressed() -> void:
	button_pressed.emit("speed_2x")
	Engine.set_time_scale(2.0)

func _on_toggle_minimap_pressed() -> void:
	_minimized = not _minimized
	visible = not _minimized

func show_game_over(victory: bool) -> void:
	var panel = get_node_or_null("Panel/VBox/GameOverLabel")
	if panel:
		panel.visible = true
		panel.text = "VICTORY!" if victory else "GAME OVER"
