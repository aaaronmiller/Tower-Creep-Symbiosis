extends Node2D
## Arena - Main game scene containing the playfield
##
## Manages the grid, tower placement, creep spawning, and wave system.
## All game entities exist as children of this scene.

signal wave_started(wave_num: int)
signal wave_completed(wave_num: int)
signal arena_ready()

# Grid properties
const GRID_WIDTH: int = 20
const GRID_HEIGHT: int = 12
const CELL_SIZE: int = 64

# Tower placement
var _selected_tower_type: String = ""
var _placement_valid: bool = false
var _hover_cell: Vector2i = Vector2i(-1, -1)

# Wave system
var _current_wave: int = 0
var _wave_active: bool = false

func _ready() -> void:
	print("[Arena] Arena scene initialized - Grid: %dx%d" % [GRID_WIDTH, GRID_HEIGHT])
	_create_grid_visual()
	_connect_signals()
	arena_ready.emit()

func _connect_signals() -> void:
	GameState.wave_complete.connect(_on_wave_complete)
	GameState.game_over.connect(_on_game_over)

func _create_grid_visual() -> void:
	# Create a simple grid visualization using ColorRects
	var grid_node = Node2D.new()
	grid_node.name = "GridVisual"
	add_child(grid_node)
	
	# Draw grid lines (simple approach - in production would use Line2D)
	for x in range(GRID_WIDTH + 1):
		var line = ColorRect.new()
		line.position = Vector2(x * CELL_SIZE, 0)
		line.size = Vector2(1, GRID_HEIGHT * CELL_SIZE)
		line.color = Color(0.3, 0.3, 0.35, 0.3)
		grid_node.add_child(line)
	
	for y in range(GRID_HEIGHT + 1):
		var line = ColorRect.new()
		line.position = Vector2(0, y * CELL_SIZE)
		line.size = Vector2(GRID_WIDTH * CELL_SIZE, 1)
		line.color = Color(0.3, 0.3, 0.35, 0.3)
		grid_node.add_child(line)
	
	print("[Arena] Grid visual created: %dx%d cells at %dpx each" % [GRID_WIDTH, GRID_HEIGHT, CELL_SIZE])

## Get grid cell from world position
func get_grid_cell(world_pos: Vector2) -> Vector2i:
	return Vector2i(
		int(floor(world_pos.x / CELL_SIZE)),
		int(floor(world_pos.y / CELL_SIZE))
	)

## Get world center of a grid cell
func get_cell_center(grid_cell: Vector2i) -> Vector2:
	return Vector2(
		grid_cell.x * CELL_SIZE + CELL_SIZE / 2,
		grid_cell.y * CELL_SIZE + CELL_SIZE / 2
	)

## Check if grid cell is valid for placement
func is_valid_placement(grid_cell: Vector2i) -> bool:
	# Must be within bounds
	if grid_cell.x < 0 or grid_cell.x >= GRID_WIDTH:
		return false
	if grid_cell.y < 0 or grid_cell.y >= GRID_HEIGHT:
		return false
	# TODO: Check for obstacles, other towers, etc.
	return true

## Start the next wave
func start_next_wave() -> void:
	_current_wave += 1
	_wave_active = true
	GameState.start_wave(_current_wave)
	wave_started.emit(_current_wave)
	print("[Arena] Wave %d started" % _current_wave)

func _on_wave_complete(wave_num: int) -> void:
	_wave_active = false
	wave_completed.emit(wave_num)
	print("[Arena] Wave %d completed" % wave_num)

func _on_game_over() -> void:
	_wave_active = false
	print("[Arena] Game over - Arena paused")

## Place a tower at the specified grid cell
func place_tower(tower_type: String, grid_cell: Vector2i) -> bool:
	if not is_valid_placement(grid_cell):
		push_warning("[Arena] Invalid tower placement at %s" % str(grid_cell))
		return false
	
	# TODO: Instantiate tower scene and add to TowerLayer
	print("[Arena] Placing %s tower at %s" % [tower_type, str(grid_cell)])
	GameState.towers_placed += 1
	return true

## Get spawn point (left edge of grid)
func get_spawn_point() -> Vector2:
	return get_cell_center(Vector2i(0, GRID_HEIGHT / 2))

## Get exit point (right edge of grid)
func get_exit_point() -> Vector2:
	return get_cell_center(Vector2i(GRID_WIDTH - 1, GRID_HEIGHT / 2))

## Get the current wave number
func get_current_wave() -> int:
	return _current_wave

## Check if a wave is currently active
func is_wave_active() -> bool:
	return _wave_active