extends Node

var _pending_tasks := []

func _ready():
	if not HardwareProfile.is_ready:
		await HardwareProfile.profile_ready

func queue_task(task: String) -> String:
	if _pending_tasks.size() >= HardwareProfile.max_concurrent_agents:
		push_warning("Agent queue full for tier " + str(HardwareProfile.performance_tier))
		return ""
	_pending_tasks.append(task)
	return "queued"
