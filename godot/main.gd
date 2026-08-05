extends Node2D
## Main entry point - scene switcher and startup sequence

signal startup_complete

var arena_scene: PackedScene = preload("res://godot/scenes/Arena.tscn")
var current_arena: Node = null

func _ready() -> void:
	print("[Main] Tower-Creep Symbiosis starting...")
	
	# Wait for HardwareProfile to initialize first
	await _wait_for_hardware_profile()
	
	# Initialize other autoloads in order
	_print_autoload_status("GameState", GameState)
	_print_autoload_status("GenomeRegistry", GenomeRegistry)
	_print_autoload_status("ThrottleController", ThrottleController)
	_print_autoload_status("AgentBridge", AgentBridge)
	
	# Load the arena scene
	_load_arena()
	
	startup_complete.emit()
	print("[Main] Startup complete - Arena loaded")

func _wait_for_hardware_profile() -> void:
	if HardwareProfile.has_node():
		if HardwareProfile.profile_ready.isconnected(_on_profile_ready):
			pass
		else:
			HardwareProfile.profile_ready.connect(_on_profile_ready)
	if HardwareProfile.get("performance_tier") > -1:
		return  # Already initialized
	await HardwareProfile.profile_ready
	print("[Main] HardwareProfile initialized")

func _on_profile_ready(tier: int) -> void:
	print("[Main] Hardware profile ready: tier=%d" % tier)

func _print_autoload_status(name: String, autoload: Node) -> void:
	if autoload and is_instance_valid(autoload):
		print("[Main] %s: OK" % name)
	else:
		push_error("[Main] %s: FAILED TO LOAD" % name)

func _load_arena() -> void:
	if arena_scene:
		current_arena = arena_scene.instantiate()
		add_child(current_arena)
		print("[Main] Arena scene instantiated")
		
		# Start wave 1 after short delay
		await get_tree().create_timer(1.0).timeout
		var wave_manager = current_arena.get_node_or_null("WaveManager")
		if wave_manager:
			wave_manager.start_wave(1)
			print("[Main] Wave 1 started")
	else:
		push_error("[Main] Arena scene not found - game cannot start")
		OS.alert("Failed to load Arena scene!", "Startup Error")
		get_tree().quit(1)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("game_pause"):
		get_tree().paused = not get_tree().paused
		print("[Main] Game paused: %s" % str(get_tree().paused))
