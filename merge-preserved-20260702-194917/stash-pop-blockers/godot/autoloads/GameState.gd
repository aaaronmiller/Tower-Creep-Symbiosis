extends Node
## GameState - Global singleton tracking player progress and game statistics
##
## Manages lives, gold, wave number, and player cycles.
## All game entities reference this singleton to query/modify game state.

signal state_changed()
signal lives_changed(new_lives: int)
signal gold_changed(new_gold: int)
signal wave_complete(wave_num: int)
signal game_over()
signal territory_claimed(territory_id: String)

# Core player stats
var player_cycles: int = 100  ## Cycles available for AI synthesis (depleted on use)
var lives: int = 20
var gold: int = 150
var wave_number: int = 0

# Game configuration
var max_lives: int = 20
var starting_gold: int = 150
var starting_lives: int = 20
var cycle_cost_per_synthesis: int = 10

# Balance metrics (for SelfOptimizer)
var strategy_diversity: float = 0.5  # How varied are player strategies
var player_retention: float = 0.6      # How long players stay engaged
var asset_variety: float = 0.5          # Diversity of assets used

# Session tracking
var session_start_time: int = 0
var creeps_spawned: int = 0
var creeps_killed: int = 0
var towers_placed: int = 0

func _ready() -> void:
	session_start_time = Time.get_unix_time_from_system()
	_print_initial_state()

func _print_initial_state() -> void:
	print("[GameState] Initialized - Lives: %d, Gold: %d, Cycles: %d" % [
		lives, gold, player_cycles
	])

## Called when player claims a territory
func claim_territory(territory_id: String) -> void:
	territory_claimed.emit(territory_id)
	state_changed.emit()

## Increment gold by amount
func add_gold(amount: int) -> void:
	gold += amount
	gold_changed.emit(gold)
	state_changed.emit()
	print("[GameState] Gold +%d = %d" % [amount, gold])

## Spend gold (returns true if successful)
func spend_gold(amount: int) -> bool:
	if gold >= amount:
		gold -= amount
		gold_changed.emit(gold)
		state_changed.emit()
		return true
	return false

## Deduct cycles for AI synthesis
func deduct_cycles(amount: int) -> bool:
	if player_cycles >= amount:
		player_cycles -= amount
		state_changed.emit()
		return true
	return false

## Refund cycles on failed synthesis
func refund_cycles(amount: int) -> void:
	player_cycles += amount
	state_changed.emit()

## Lose a life when creep reaches exit
func lose_life() -> void:
	lives -= 1
	lives_changed.emit(lives)
	state_changed.emit()
	print("[GameState] Life lost! Lives remaining: %d" % lives)
	
	if lives <= 0:
		trigger_game_over()

## Trigger game over
func trigger_game_over() -> void:
	print("[GameState] GAME OVER - Wave %d" % wave_number)
	game_over.emit()

## Start a new wave
func start_wave(num: int) -> void:
	wave_number = num
	state_changed.emit()
	print("[GameState] Starting wave %d" % wave_number)

## Complete a wave
func complete_wave(num: int) -> void:
	wave_number = num
	wave_complete.emit(num)
	state_changed.emit()
	print("[GameState] Wave %d complete!" % num)

## Get current balance state for SelfOptimizer
func get_balance_state() -> Dictionary:
	return {
		"strategy_diversity": strategy_diversity,
		"player_retention": player_retention,
		"asset_variety": asset_variety,
		"composite_balance": 0.4 * strategy_diversity + 0.4 * player_retention + 0.2 * asset_variety
	}

## Spawn a creep with given gene (stub for future expansion)
func spawn_creep_with_behavior(gene_id: String) -> void:
	creeps_spawned += 1
	state_changed.emit()
