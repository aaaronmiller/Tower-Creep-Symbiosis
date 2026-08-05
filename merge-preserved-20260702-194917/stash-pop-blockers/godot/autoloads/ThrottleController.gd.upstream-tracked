extends Node

var throttle_cpu_target: float
var throttle_min_tick_ms: float
var target_frame_time_ms: float

var current_frame_stress := 0.0
var work_budget_per_tick := 10

signal work_budget_changed(budget: int)

func _ready():
	if not HardwareProfile.is_ready:
		await HardwareProfile.profile_ready
	var tier_name = "STANDARD" if HardwareProfile.performance_tier == HardwareProfile.PerformanceTier.STANDARD else "ENHANCED"
	var tier_config = HardwareProfile._platform_config.get(tier_name, {})
	throttle_cpu_target = tier_config.get("throttle_cpu_target", 0.6 if tier_name == "STANDARD" else 0.7)
	throttle_min_tick_ms = tier_config.get("throttle_min_tick_ms", 33.0 if tier_name == "STANDARD" else 16.0)
	target_frame_time_ms = 1000.0 / tier_config.get("fps_target", 30 if tier_name == "STANDARD" else 60)

	HardwareProfile.low_memory_warning.connect(_on_low_memory)
	HardwareProfile.critical_memory_warning.connect(_on_critical_memory)

func _on_low_memory(_free_bytes: int):
	work_budget_per_tick = max(5, work_budget_per_tick / 2)
	work_budget_changed.emit(work_budget_per_tick)

func _on_critical_memory(_free_bytes: int):
	work_budget_per_tick = 1
	work_budget_changed.emit(1)

func _adjust_throttle():
	current_frame_stress = Performance.get_monitor(Performance.TIME_PROCESS) / (target_frame_time_ms / 1000.0)

func _compute_stress() -> float:
	return current_frame_stress / max(0.01, throttle_cpu_target)
