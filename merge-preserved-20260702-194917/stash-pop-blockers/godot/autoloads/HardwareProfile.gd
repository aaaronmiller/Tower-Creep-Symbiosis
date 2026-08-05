extends Node
## HardwareProfile - Detects system resources and assigns performance tier
##
## Detects CPU, RAM, GPU at startup and classifies into STANDARD or ENHANCED tier.
## All other systems read from this singleton to adapt behavior.

class_name HardwareProfile

## Performance tier enumeration
enum PerformanceTier {
	STANDARD = 0,  ## 16GB systems, Intel iGPU, 30 FPS target
	ENHANCED = 1,  ## 36GB+ systems, M-series, 60 FPS target
}

## Signal: Emitted when free RAM drops below 1GB
signal low_memory_warning(free_bytes: int)

## Signal: Emitted when free RAM drops below 512MB
signal critical_memory_warning(free_bytes: int)

## Signal: Emitted when profile initialization is complete
signal profile_ready(tier: int)

# Read-only exported properties
@export var os_name: String = ""
@export var cpu_architecture: String = ""
@export var logical_core_count: int = 0
@export var total_ram_bytes: int = 0
@export var gpu_name: String = ""
@export var performance_tier: PerformanceTier = PerformanceTier.STANDARD
@export var game_memory_ceiling_bytes: int = 0
@export var agent_memory_ceiling_bytes: int = 0
@export var max_concurrent_agents: int = 2
@export var renderer_hint: String = "opengl3"

# Internal state
var _platform_config: Dictionary = {}
var _memory_check_timer: Timer = null
var _initialized: bool = false

func _ready() -> void:
	_detect_hardware()
	_load_platform_config()
	_classify_tier()
	_compute_limits()
	_start_memory_monitoring()
	_initialized = true
	profile_ready.emit(performance_tier)

func _detect_hardware() -> void:
	os_name = OS.get_name()
	cpu_architecture = Engine.get_architecture_name()
	logical_core_count = OS.get_processor_count()
	
	var mem_info = OS.get_memory_info()
	total_ram_bytes = mem_info.get("physical", 0)
	
	gpu_name = RenderingServer.get_video_adapter_name()
	
	print("[HardwareProfile] OS: %s | CPU: %s (%d cores) | RAM: %.1f GB | GPU: %s" % [
		os_name, cpu_architecture, logical_core_count, 
		float(total_ram_bytes) / 1073741824.0, gpu_name
	])

func _load_platform_config() -> void:
	var config_path = "res://data/platform-config.json"
	var file = FileAccess.open(config_path, FileAccess.READ)
	
	if file:
		var json_str = file.get_as_text()
		file.close()
		var json = JSON.new()
		if json.parse(json_str) == OK:
			_platform_config = json.get_data()
			print("[HardwareProfile] Loaded platform config")
		else:
			push_warning("[HardwareProfile] Failed to parse platform config - using defaults")
			_platform_config = _get_default_config()
	else:
		push_warning("[HardwareProfile] platform-config.json not found - using defaults")
		_platform_config = _get_default_config()

func _get_default_config() -> Dictionary:
	return {
		"STANDARD": {
			"fps_target": 30,
			"max_concurrent_agents": 2,
			"game_memory_ceiling_gb": 4.0,
			"agent_memory_ceiling_gb": 2.0,
			"renderer_hint": "opengl3",
			"throttle_min_tick_ms": 33.0,
			"throttle_cpu_target": 0.60
		},
		"ENHANCED": {
			"fps_target": 60,
			"max_concurrent_agents": 4,
			"game_memory_ceiling_gb": 8.0,
			"agent_memory_ceiling_gb": 4.0,
			"renderer_hint": "vulkan",
			"throttle_min_tick_ms": 16.0,
			"throttle_cpu_target": 0.70
		}
	}

func _classify_tier() -> void:
	# Minimum 16GB required
	if total_ram_bytes < 16 * 1073741824:
		_is_supported()  # Will exit if unsupported
	
	# Classify: < 24GB = STANDARD, >= 24GB = ENHANCED
	if total_ram_bytes < 24 * 1073741824:
		performance_tier = PerformanceTier.STANDARD
	else:
		performance_tier = PerformanceTier.ENHANCED
	
	print("[HardwareProfile] Tier: %s" % PerformanceTier.keys()[performance_tier])

func _compute_limits() -> void:
	var tier_key = "STANDARD" if performance_tier == PerformanceTier.STANDARD else "ENHANCED"
	var tier_config = _platform_config.get(tier_key, {})
	
	# Game memory ceiling: min(25% of RAM, configured ceiling)
	var configured_game_gb = tier_config.get("game_memory_ceiling_gb", 4.0)
	var computed_game_bytes = min(
		int(float(total_ram_bytes) * 0.25),
		int(configured_game_gb * 1073741824)
	)
	game_memory_ceiling_bytes = computed_game_bytes
	
	# Agent memory ceiling: min(12.5% of RAM, configured ceiling)
	var configured_agent_gb = tier_config.get("agent_memory_ceiling_gb", 2.0)
	var computed_agent_bytes = min(
		int(float(total_ram_bytes) * 0.125),
		int(configured_agent_gb * 1073741824)
	)
	agent_memory_ceiling_bytes = computed_agent_bytes
	
	# Max concurrent agents from config
	max_concurrent_agents = tier_config.get("max_concurrent_agents", 2)
	
	# Renderer hint
	renderer_hint = tier_config.get("renderer_hint", "opengl3")
	
	# Print renderer guidance
	print("[HardwareProfile] Performance tier: %s | For best results on this hardware, launch with: --rendering-driver %s" % [
		PerformanceTier.keys()[performance_tier], renderer_hint
	])

func _start_memory_monitoring() -> void:
	_memory_check_timer = Timer.new()
	_memory_check_timer.wait_time = 0.5
	_memory_check_timer.timeout.connect(_on_memory_check)
	add_child(_memory_check_timer)
	_memory_check_timer.start()

func _on_memory_check() -> void:
	var free = get_free_ram_bytes()
	
	if free < 1073741824:  # < 1GB
		low_memory_warning.emit(free)
	
	if free < 536870912:  # < 512MB
		critical_memory_warning.emit(free)

## Check if hardware meets minimum requirements
func is_supported() -> bool:
	return total_ram_bytes >= 16 * 1073741824

## Check if hardware meets minimum requirements - quit if not
func _is_supported() -> bool:
	if not is_supported():
		OS.alert("Tower-Creep Symbiosis requires at least 16 GB of RAM.\n\nDetected: %.1f GB" % [
			float(total_ram_bytes) / 1073741824.0
		], "Unsupported Hardware")
		get_tree().quit(1)
		return false
	return true

## Get current free RAM in bytes
func get_free_ram_bytes() -> int:
	var mem_info = OS.get_memory_info()
	return mem_info.get("free", 0)

## Get current memory pressure as 0.0-1.0
func get_memory_pressure() -> float:
	if total_ram_bytes <= 0:
		return 0.0
	var free = get_free_ram_bytes()
	return clampf(1.0 - float(free) / float(total_ram_bytes), 0.0, 1.0)

## Override the performance tier (for testing or manual override)
func override_tier(tier: PerformanceTier) -> void:
	performance_tier = tier
	_compute_limits()  # Reload tier-specific values from config
	print("[HardwareProfile] Tier overridden to: %s" % PerformanceTier.keys()[performance_tier])

## Get the current FPS target for this tier
func get_fps_target() -> int:
	var tier_key = "STANDARD" if performance_tier == PerformanceTier.STANDARD else "ENHANCED"
	var tier_config = _platform_config.get(tier_key, {})
	return tier_config.get("fps_target", 30)

## Get throttle configuration for this tier
func get_throttle_config() -> Dictionary:
	var tier_key = "STANDARD" if performance_tier == PerformanceTier.STANDARD else "ENHANCED"
	return _platform_config.get(tier_key, {
		"throttle_min_tick_ms": 33.0,
		"throttle_cpu_target": 0.60
	})
