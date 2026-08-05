extends Node
## ResourceMonitor - System resource monitoring for process management
##
## Tracks CPU, memory, and GPU usage to prevent system overload.
## Feeds data to ThrottleController for adaptive performance.

signal cpu_usage_updated(usage: float)
signal memory_usage_updated(usage: float)
signal gpu_usage_updated(usage: float)
signal resource_critical(level: String)

var _sample_history: Array = []
var _max_history_size: int = 60

var peak_cpu_usage: float = 0.0
var peak_memory_usage: float = 0.0
var current_cpu_usage: float = 0.0
var current_memory_usage: float = 0.0

func _ready() -> void:
	print("[ResourceMonitor] Starting resource monitoring")

func _process(delta: float) -> void:
	_sample_resources()

func _sample_resources() -> void:
	# CPU usage (process time in last frame / wall time)
	var frame_time = Performance.get_monitor(Performance.TIME_PROCESS)
	var real_time = Performance.get_monitor(Performance.TIME_FPS)  # Frame time in seconds
	
	current_cpu_usage = frame_time / (real_time + 0.001)  # Avoid div by zero
	current_cpu_usage = clampf(current_cpu_usage, 0.0, 1.0)
	
	# Memory usage
	if HardwareProfile.has_node() and HardwareProfile.total_ram_bytes > 0:
		current_memory_usage = HardwareProfile.get_memory_pressure()
	else:
		current_memory_usage = 0.0
	
	# Track peaks
	peak_cpu_usage = maxf(peak_cpu_usage, current_cpu_usage)
	peak_memory_usage = maxf(peak_memory_usage, current_memory_usage)
	
	# Emit signals
	cpu_usage_updated.emit(current_cpu_usage)
	memory_usage_updated.emit(current_memory_usage)
	
	# Check for critical levels
	if current_cpu_usage > 0.95:
		resource_critical.emit("cpu")
	elif current_memory_usage > 0.90:
		resource_critical.emit("memory")
	
	# Buffer sample
	_sample_history.append({
		"cpu": current_cpu_usage,
		"memory": current_memory_usage,
		"timestamp": Time.get_unix_time_from_system()
	})
	
	if _sample_history.size() > _max_history_size:
		_sample_history.pop_front()

## Get averaged usage over recent samples
func get_average_usage(seconds: float = 5.0) -> Dictionary:
	var cutoff_time = Time.get_unix_time_from_system() - seconds
	var recent_samples = _sample_history.filter(func(s): return s.timestamp >= cutoff_time)
	
	if recent_samples.is_empty():
		return {"cpu": 0.0, "memory": 0.0}
	
	var avg_cpu = 0.0
	var avg_mem = 0.0
	for sample in recent_samples:
		avg_cpu += sample.cpu
		avg_mem += sample.memory
	
	avg_cpu /= recent_samples.size()
	avg_mem /= recent_samples.size()
	
	return {"cpu": avg_cpu, "memory": avg_mem}

## Reset peak tracking
func reset_peaks() -> void:
	peak_cpu_usage = 0.0
	peak_memory_usage = 0.0
	print("[ResourceMonitor] Peak values reset")

## Get current resource status
func get_status() -> Dictionary:
	return {
		"cpu_usage": current_cpu_usage,
		"memory_usage": current_memory_usage,
		"peak_cpu": peak_cpu_usage,
		"peak_memory": peak_memory_usage
	}