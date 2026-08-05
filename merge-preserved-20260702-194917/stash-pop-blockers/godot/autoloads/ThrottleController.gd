extends Node
## ThrottleController - PID-based adaptive simulation throttle
##
## Adjusts simulation speed based on CPU/memory pressure to maintain
## target FPS. Reads tier-specific values from HardwareProfile.

signal tick_duration_changed(new_duration_ms: float)
signal work_budget_changed(new_budget: int)

# Target values (loaded from HardwareProfile)
var TARGET_CPU_UTILIZATION: float = 0.70
var TARGET_FRAME_TIME_MS: float = 14.0
var TARGET_MEMORY_PRESSURE: float = 0.60

# PID controller state
var _integral: float = 0.0
var _previous_error: float = 0.0
var _derivative: float = 0.0

# Current state
var current_frame_stress: float = 0.0
var work_budget_per_tick: int = 100
var current_tick_duration_ms: float = 16.0

# Tuning parameters
const KP: float = 0.8  # Proportional gain
const KI: float = 0.3  # Integral gain
const KD: float = .4   # Derivative gain

# Bounds
var min_tick_duration_ms: float = 16.0
var max_tick_duration_ms: float = 100.0
var min_work_budget: int = 1
var max_work_budget: int = 500

# Memory pressure handling
var _last_memory_warning_time: float = 0.0
var _memory_pressure_recovery_time: float = 5.0

func _ready() -> void:
	_load_tier_config()
	_print_initial_state()
	
	# Connect to HardwareProfile signals
	if HardwareProfile.has_node():
		HardwareProfile.low_memory_warning.connect(_on_low_memory)
		HardwareProfile.critical_memory_warning.connect(_on_critical_memory)

func _load_tier_config() -> void:
	if HardwareProfile.has_node():
		var throttle_config = HardwareProfile.get_throttle_config()
		TARGET_CPU_UTILIZATION = throttle_config.get("throttle_cpu_target", 0.70)
		TARGET_FRAME_TIME_MS = 1000.0 / HardwareProfile.get_fps_target()
		min_tick_duration_ms = throttle_config.get("throttle_min_tick_ms", 33.0)
		work_budget_per_tick = _frame_time_to_work_budget(min_tick_duration_ms)

func _print_initial_state() -> void:
	print("[ThrottleController] Target CPU: %.2f, Frame time: %.2fms, Min tick: %.2fms" % [
		TARGET_CPU_UTILIZATION, TARGET_FRAME_TIME_MS, min_tick_duration_ms
	])

## Called each frame to adjust throttle
func _process(delta: float) -> void:
	_adjust_throttle(delta)

## PID throttle adjustment
func _adjust_throttle(delta: float) -> void:
	# Calculate current frame stress: actual frame time / target frame time
	var target_frame_time_ms = 1000.0 / HardwareProfile.get_fps_target()
	current_frame_stress = Performance.get_monitor(Performance.TIME_PROCESS) / (target_frame_time_ms / 1000.0)
	
	# Compute error
	var error = current_frame_stress - TARGET_CPU_UTILIZATION
	
	# PID terms
	_integral = clampf(_integral + error * delta, -1.0, 1.0)
	_derivative = (error - _previous_error) / delta if delta > 0 else 0.0
	
	# Compute adjustment
	var adjustment = KP * error + KI * _integral + KD * _derivative
	
	# Apply to tick duration
	var new_duration = clampf(
		current_tick_duration_ms + adjustment * 10.0,
		min_tick_duration_ms,
		max_tick_duration_ms
	)
	
	if absf(new_duration - current_tick_duration_ms) > 0.1:
		current_tick_duration_ms = new_duration
		work_budget_per_tick = _frame_time_to_work_budget(new_duration)
		work_budget_changed.emit(work_budget_per_tick)
	
	_previous_error = error

## Convert frame time budget to work units
func _frame_time_to_work_budget(frame_time_ms: float) -> int:
	# Scale: 16ms = 100 units, 33ms = 50 units, etc.
	return int(clampf(1600.0 / frame_time_ms, float(min_work_budget), float(max_work_budget)))

## Memory pressure response: reduce work budget by half
func _on_low_memory(free_bytes: int) -> void:
	print("[ThrottleController] Low memory warning: %.1f GB free" % (float(free_bytes) / 1073741824.0))
	work_budget_per_tick = max(5, work_budget_per_tick / 2)
	work_budget_changed.emit(work_budget_per_tick)

## Critical memory: minimal work budget
func _on_critical_memory(free_bytes: int) -> void:
	print("[ThrottleController] CRITICAL memory: %.1f GB free" % (float(free_bytes) / 1073741824.0))
	work_budget_per_tick = 1
	work_budget_changed.emit(work_budget_per_tick)

## Get current throttle state
func get_status() -> Dictionary:
	return {
		"tick_duration_ms": current_tick_duration_ms,
		"work_budget": work_budget_per_tick,
		"frame_stress": current_frame_stress,
		"target_stress": TARGET_CPU_UTILIZATION
	}
