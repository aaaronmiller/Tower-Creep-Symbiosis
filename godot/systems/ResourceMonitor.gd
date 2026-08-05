extends Node
## ResourceMonitor - Tracks system resource usage
## Monitors CPU, memory, VRAM, and reports to agent systems

signal resource_update(stats: Dictionary)
signal resource_warning(level: String, message: String)

var _stats_history: Array = []
var _max_history: int = 300
var _update_interval: float = 1.0
var _time_since_update: float = 0.0

var _last_cpu_usage: float = 0.0
var _last_memory_used: float = 0.0

func _ready() -> void:
	print("[ResourceMonitor] Initialized")
	_update_initial_reading()

func _process(delta: float) -> void:
	_time_since_update += delta
	if _time_since_update >= _update_interval:
		_time_since_update = 0.0
		_poll_resources()

func _update_initial_reading() -> void:
	var initial_stats = _collect_stats()
	_stats_history.append(initial_stats)

func _poll_resources() -> void:
	var stats = _collect_stats()
	_buffer_stats(stats)
	_check_warnings(stats)
	resource_update.emit(stats)

func _collect_stats() -> Dictionary:
	var mem_total = OS.get_memory_usageMb()
	var mem_free = OS.get_free_memory_mb()
	var mem_used = mem_total - mem_free
	var cpu_usage = OS.get_processor_usage()
	
	# VRAM detection (simplified - actual GPU queries are platform-specific)
	var vram_total = 0.0
	var vram_free = 0.0
	if DisplayServer.has_method("get_window_safe_area"):
		# Placeholder - real VRAM queries require platform extensions
		vram_total = 8192.0  # Assume 8GB default
		vram_free = vram_total * 0.3
	
	return {
		"timestamp": Time.get_unix_time_from_system(),
		"memory": {
			"total_mb": mem_total,
			"used_mb": mem_used,
			"free_mb": mem_free,
			"usage_percent": (mem_used / mem_total) * 100.0 if mem_total > 0 else 0.0
		},
		"cpu": {
			"usage_percent": cpu_usage * 100.0,
			"core_count": OS.get_processor_count()
		},
		"vram": {
			"total_mb": vram_total,
			"free_mb": vram_free,
			"usage_percent": ((vram_total - vram_free) / vram_total) * 100.0 if vram_total > 0 else 0.0
		},
		"fps": Engine.get_frames_per_second(),
		"delta_time": Engine.get_iterations_per_second()
	}

func _buffer_stats(stats: Dictionary) -> void:
	_stats_history.append(stats)
	if _stats_history.size() > _max_history:
		_stats_history.pop_front()

func _check_warnings(stats: Dictionary) -> void:
	var mem_free = stats.memory.free_mb
	
	if mem_free < 512:
		resource_warning.emit("critical", "Critical: Less than 512 MB free memory!")
	elif mem_free < 1024:
		resource_warning.emit("low", "Warning: Less than 1 GB free memory!")
	
	if stats.cpu.usage_percent > 90:
		resource_warning.emit("cpu_high", "CPU usage above 90%%")
	
	if stats.memory.usage_percent > 85:
		resource_warning.emit("memory_high", "Memory usage above 85%%")

## Get recent stats history
func get_history(seconds: int = 60) -> Array:
	var cutoff = Time.get_unix_time_from_system() - seconds
	var result: Array = []
	for entry in _stats_history:
		if entry.timestamp >= cutoff:
			result.append(entry)
	return result

## Get average stats over time window
func get_average_stats(window_seconds: int = 60) -> Dictionary:
	var history = get_history(window_seconds)
	if history.size() == 0:
		return {}
	
	var sum_mem = 0.0
	var sum_cpu = 0.0
	var sum_fps = 0.0
	var count = 0
	
	for entry in history:
		sum_mem += entry.memory.usage_percent
		sum_cpu += entry.cpu.usage_percent
		sum_fps += entry.fps
		count += 1
	
	return {
		"avg_memory_percent": sum_mem / count,
		"avg_cpu_percent": sum_cpu / count,
		"avg_fps": sum_fps / count,
		"sample_count": count
	}

## Get current resource state summary
func get_current_stats() -> Dictionary:
	if _stats_history.size() == 0:
		return _collect_stats()
	return _stats_history[_stats_history.size() - 1]
