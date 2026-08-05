extends Node
## SpriteLoader - Async sprite atlas loader with memory management
## Handles procedural sprite generation for HUD elements

signal sprite_loaded(texture_id: String, texture: Texture2D)
signal sprite_unloaded(texture_id: String)
signal memory_warning(free_mb: float)

var _cache: Dictionary = {}
var _load_queue: Array = []
var _max_cache_size_mb: float = 128.0
var _current_cache_size_mb: float = 0.0
var _loading: bool = false

func _ready() -> void:
	_check_memory()
	print("[SpriteLoader] Initialized, cache limit: %.0f MB" % _max_cache_size_mb)

## Get a sprite, loading async if needed
func get_sprite(sprite_id: String) -> Texture2D:
	if _cache.has(sprite_id):
		return _cache[sprite_id]
	
	# Queue for loading
	if not sprite_id in _load_queue:
		_load_queue.append(sprite_id)
		_process_load_queue.call_deferred()
	
	return null

## Generate a procedural icon sprite
func generate_icon(icon_type: String, size: Vector2 = Vector2(64, 64)) -> Texture2D:
	var image = Image.create(int(size.x), int(size.y), false, Image.FORMAT_RGBA8)
	
	match icon_type:
		"heart":
			_draw_heart(image, size)
		"coin":
			_draw_coin(image, size)
		"tower":
			_draw_tower(image, size)
		"creep":
			_draw_creep(image, size)
		"wave":
			_draw_wave(image, size)
		"skull":
			_draw_skull(image, size)
		_:
			_draw_default(image, size)
	
	var texture = ImageTexture.create_from_image(image)
	var sprite_id = "generated_%s_%.0fx%.0f" % [icon_type, size.x, size.y]
	_cache[sprite_id] = texture
	return texture

func _draw_heart(image: Image, size: Vector2) -> void:
	var color = Color(1.0, 0.2, 0.3, 1.0)
	var cx = size.x / 2
	var cy = size.y / 2
	var r = min(size.x, size.y) * 0.4
	
	for y in range(int(size.y)):
		for x in range(int(size.x)):
			var dx = x - cx
			var dy = y - cy
			# Heart shape
			var val = (dx * dx + dy * dy - r * r) * (dx * dx + dy * dy - r * r) * (dx * dx + dy * dy - r * r) - r * r * r * r * (dx * dx - dy * dy)
			if val < 0 and dy < 0:
				image.set_pixel(x, y, color)

func _draw_coin(image: Image, size: Vector2) -> void:
	var color = Color(1.0, 0.84, 0.0, 1.0)
	var cx = size.x / 2
	var cy = size.y / 2
	var r = min(size.x, size.y) * 0.45
	
	for y in range(int(size.y)):
		for x in range(int(size.x)):
			var dist = Vector2(x - cx, y - cy).length()
			if dist < r:
				image.set_pixel(x, y, color)

func _draw_tower(image: Image, size: Vector2) -> void:
	var color = Color(0.3, 0.6, 1.0, 1.0)
	var cx = size.x / 2
	var w = size.x * 0.6
	var h = size.y * 0.8
	var y_base = size.y * 0.9
	
	for y in range(int(size.y * 0.1), int(size.y)):
		for x in range(int(cx - w/2), int(cx + w/2)):
			var ty = (y - size.y * 0.1) / (size.y * 0.8)
			if y < y_base - h * 0.3:
				image.set_pixel(x, y, color.darkened(ty * 0.5))

func _draw_creep(image: Image, size: Vector2) -> void:
	var color = Color(0.6, 0.3, 0.1, 1.0)
	var cx = size.x / 2
	var cy = size.y / 2
	var r = min(size.x, size.y) * 0.35
	
	for y in range(int(size.y)):
		for x in range(int(size.x)):
			var dist = Vector2(x - cx, y - cy).length()
			if dist < r:
				image.set_pixel(x, y, color)

func _draw_wave(image: Image, size: Vector2) -> void:
	var color = Color(0.2, 0.8, 0.4, 1.0)
	var cx = size.x / 2
	var cy = size.y / 2
	
	for y in range(int(size.y)):
		var wave = sin((y - cy) * 0.2) * size.x * 0.3
		var x_center = cx + wave
		for x in range(int(x_center - 3), int(x_center + 3)):
			if x >= 0 and x < size.x:
				image.set_pixel(x, y, color)

func _draw_skull(image: Image, size: Vector2) -> void:
	var color = Color(0.9, 0.9, 0.9, 1.0)
	var cx = size.x / 2
	var cy = size.y / 2
	var r = min(size.x, size.y) * 0.4
	
	for y in range(int(size.y)):
		for x in range(int(size.x)):
			var dist = Vector2(x - cx, y - cy).length()
			if dist < r:
				# Eye sockets
				var eye_left = Vector2(cx - r*0.4, cy - r*0.2)
				var eye_right = Vector2(cx + r*0.4, cy - r*0.2)
				var dist_left = Vector2(x - eye_left.x, y - eye_left.y).length()
				var dist_right = Vector2(x - eye_right.x, y - eye_right.y).length()
				if dist_left < r*0.25 or dist_right < r*0.25:
					image.set_pixel(x, y, Color(0.1, 0.1, 0.1, 1.0))
				else:
					image.set_pixel(x, y, color)

func _draw_default(image: Image, size: Vector2) -> void:
	var color = Color(0.5, 0.5, 0.5, 1.0)
	for y in range(int(size.y)):
		for x in range(int(size.x)):
			image.set_pixel(x, y, color)

func _process_load_queue() -> void:
	if _loading or _load_queue.size() == 0:
		return
	
	_loading = true
	var sprite_id = _load_queue.pop_front()
	
	# Check if already cached
	if _cache.has(sprite_id):
		_loading = false
		return
	
	# Try to load from disk
	var path = "res://sprites/%s.png" % sprite_id
	if ResourceLoader.exists(path):
		var tex = load(path)
		if tex:
			_cache_sprite(sprite_id, tex)
			sprite_loaded.emit(sprite_id, tex)
	
	_loading = false

func _cache_sprite(sprite_id: String, texture: Texture2D) -> void:
	_cache[sprite_id] = texture
	
	# Estimate memory usage (rough)
	var w = texture.get_width()
	var h = texture.get_height()
	var size_mb = (w * h * 4) / (1024 * 1024)
	_current_cache_size_mb += size_mb
	
	# Evict if over limit
	if _current_cache_size_mb > _max_cache_size_mb:
		_evict_oldest()

func _evict_oldest() -> void:
	if _cache.size() > 0:
		var oldest_key = _cache.keys()[0]
		_cache.erase(oldest_key)
		_current_cache_size_mb *= 0.8
		sprite_unloaded.emit(oldest_key)

func _check_memory() -> void:
	var free_mem = OS.get_free_memory_mb()
	if free_mem < 1024:
		memory_warning.emit(free_mem)
		_evict_oldest()

## Clear the sprite cache
func clear_cache() -> void:
	_cache.clear()
	_current_cache_size_mb = 0.0
	print("[SpriteLoader] Cache cleared")

## Get cache statistics
func get_stats() -> Dictionary:
	return {
		"cached_sprites": _cache.size(),
		"cache_size_mb": _current_cache_size_mb,
		"max_cache_mb": _max_cache_size_mb,
		"queue_size": _load_queue.size()
	}
