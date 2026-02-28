extends Node

enum PerformanceTier {
	STANDARD = 0,
	ENHANCED = 1
}

var os_name: String
var cpu_architecture: String
var logical_core_count: int
var total_ram_bytes: int
var gpu_name: String
var performance_tier: PerformanceTier
var game_memory_ceiling_bytes: int
var agent_memory_ceiling_bytes: int
var max_concurrent_agents: int
var renderer_hint: String

signal low_memory_warning(free_bytes: int)
signal critical_memory_warning(free_bytes: int)
signal profile_ready(tier: int)

var _platform_config: Dictionary
var is_ready: bool = false

func is_supported() -> bool:
	return total_ram_bytes >= 16 * 1073741824

func _ready() -> void:
	total_ram_bytes = OS.get_memory_info()["physical"]
	if not is_supported():
		OS.alert("Tower-Creep Symbiosis requires at least 16 GB of RAM.\n\nDetected: %d GB" % [total_ram_bytes / 1073741824], "Unsupported Hardware")
		get_tree().quit(1)
		return

	os_name = OS.get_name()
	cpu_architecture = Engine.get_architecture_name()
	logical_core_count = OS.get_processor_count()
	gpu_name = RenderingServer.get_video_adapter_name()

	var file := FileAccess.open("res://data/platform-config.json", FileAccess.READ)
	if file:
		var json_str := file.get_as_text()
		var test_json_conv := JSON.new()
		if test_json_conv.parse(json_str) == OK:
			_platform_config = test_json_conv.get_data()
		else:
			push_error("Failed to parse platform-config.json")
			_platform_config = {}
	else:
		push_error("Failed to open platform-config.json")
		_platform_config = {}

	if total_ram_bytes < 24 * 1073741824:
		performance_tier = PerformanceTier.STANDARD
	else:
		performance_tier = PerformanceTier.ENHANCED

	var tier_name: String = "STANDARD" if performance_tier == PerformanceTier.STANDARD else "ENHANCED"
	var tier_config: Dictionary = _platform_config.get(tier_name, {})

	var game_ceiling_gb: float = tier_config.get("game_memory_ceiling_gb", 4.0 if tier_name == "STANDARD" else 8.0)
	var agent_ceiling_gb: float = tier_config.get("agent_memory_ceiling_gb", 2.0 if tier_name == "STANDARD" else 4.0)

	game_memory_ceiling_bytes = min(int(total_ram_bytes * 0.25), int(game_ceiling_gb * 1073741824))
	agent_memory_ceiling_bytes = min(int(total_ram_bytes * 0.125), int(agent_ceiling_gb * 1073741824))

	max_concurrent_agents = tier_config.get("max_concurrent_agents", 2 if tier_name == "STANDARD" else 4)
	renderer_hint = tier_config.get("renderer_hint", "opengl3" if tier_name == "STANDARD" else "vulkan")

	var timer := Timer.new()
	timer.wait_time = 0.5
	timer.timeout.connect(_on_memory_check)
	add_child(timer)
	timer.start()

	print("[HardwareProfile] Performance tier: %s | For best results on this hardware, launch with: --rendering-driver %s" % [PerformanceTier.keys()[performance_tier], renderer_hint])

	is_ready = true
	profile_ready.emit(performance_tier)

func _on_memory_check() -> void:
	var free := get_free_ram_bytes()
	if free < 536870912:
		critical_memory_warning.emit(free)
	elif free < 1073741824:
		low_memory_warning.emit(free)

func get_free_ram_bytes() -> int:
	return OS.get_memory_info()["free"]

func get_memory_pressure() -> float:
	return clampf(1.0 - float(get_free_ram_bytes()) / float(total_ram_bytes), 0.0, 1.0)

func override_tier(tier: PerformanceTier) -> void:
	performance_tier = tier
	var tier_name: String = "STANDARD" if performance_tier == PerformanceTier.STANDARD else "ENHANCED"
	var tier_config: Dictionary = _platform_config.get(tier_name, {})

	var game_ceiling_gb: float = tier_config.get("game_memory_ceiling_gb", 4.0 if tier_name == "STANDARD" else 8.0)
	var agent_ceiling_gb: float = tier_config.get("agent_memory_ceiling_gb", 2.0 if tier_name == "STANDARD" else 4.0)

	game_memory_ceiling_bytes = min(int(total_ram_bytes * 0.25), int(game_ceiling_gb * 1073741824))
	agent_memory_ceiling_bytes = min(int(total_ram_bytes * 0.125), int(agent_ceiling_gb * 1073741824))

	max_concurrent_agents = tier_config.get("max_concurrent_agents", 2 if tier_name == "STANDARD" else 4)
	renderer_hint = tier_config.get("renderer_hint", "opengl3" if tier_name == "STANDARD" else "vulkan")
