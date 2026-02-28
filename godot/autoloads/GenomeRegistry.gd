extends Node

var default_memory: int
var memory_pressure_target: float

func _ready():
	if not HardwareProfile.is_ready:
		await HardwareProfile.profile_ready
	default_memory = HardwareProfile.game_memory_ceiling_bytes + HardwareProfile.agent_memory_ceiling_bytes
	memory_pressure_target = 0.8 # Generic default
