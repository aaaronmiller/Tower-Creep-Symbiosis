extends GutTest

## Test suite for Tower-Creep-Symbiosis core systems

func test_genome_registry_has_behaviors() -> void:
	var registry = get_node_or_null("/root/GenomeRegistry")
	if registry == null:
		pass_pending("GenomeRegistry not loaded")
		return
	
	var behaviors = registry.list_genes("behavior")
	assert_true(behaviors.size() >= 2, "Should have at least WalkPath and Flank behaviors")

func test_wave_manager_signals() -> void:
	var wave_manager = get_node_or_null("/root/WaveManager")
	if wave_manager == null:
		pass_pending("WaveManager not loaded")
		return
	
	# Verify signals exist without duplicates
	var signals = wave_manager.get_signal_list()
	var signal_names = signals.map(func(s): return s["name"])
	
	var wave_started_count = signal_names.count("wave_started")
	assert_eq(wave_started_count, 1, "wave_started signal should appear exactly once")
	
	var wave_complete_count = signal_names.count("wave_complete")
	assert_eq(wave_complete_count, 1, "wave_complete signal should appear exactly once")

func test_hardware_profile_tiers() -> void:
	var hw = get_node_or_null("/root/HardwareProfile")
	if hw == null:
		pass_pending("HardwareProfile not loaded")
		return
	
	var tier = hw.get_performance_tier()
	assert_true(tier == "STANDARD" or tier == "ENHANCED", "Tier should be STANDARD or ENHANCED")

func test_macro_compiler_aliases() -> void:
	var compiler = get_node_or_null("/root/MacroCompiler")
	if compiler == null:
		pass_pending("MacroCompiler not loaded")
		return
	
	# Test alias expansion
	var result = compiler.compile_command("b arrow")
	assert_true(result.get("success", false), "Should compile 'b arrow' (alias for 'build tower')")
	assert_eq(result.get("action"), "build_tower")

func test_self_optimizer_modifiers() -> void:
	var optimizer = get_node_or_null("/root/SelfOptimizer")
	if optimizer == null:
		pass_pending("SelfOptimizer not loaded")
		return
	
	var mods = optimizer.get_balance_modifiers()
	assert_true(mods.has("creep_health_modifier"), "Should have creep_health_modifier")
	assert_true(mods.has("tower_damage_modifier"), "Should have tower_damage_modifier")
	assert_true(mods.has("gold_multiplier"), "Should have gold_multiplier")
	assert_true(mods.has("spawn_rate_modifier"), "Should have spawn_rate_modifier")
