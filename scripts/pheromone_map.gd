extends Node2D

## Grid-based pheromone map with two layers:
##   food_pheromones - dropped by ants carrying food (guides searchers to food)
##   home_pheromones - dropped by searching ants (guides returning ants home)

const CELL_SIZE := 4
const EVAPORATION_RATE := 0.9975
const TEXTURE_UPDATE_INTERVAL := 0.05

var grid_width: int
var grid_height: int
var food_pheromones: PackedFloat32Array
var home_pheromones: PackedFloat32Array

var _image: Image
var _texture: ImageTexture
var _sprite: Sprite2D
var _texture_timer: float = 0.0


func _ready() -> void:
	_sprite = Sprite2D.new()
	_sprite.centered = false
	_sprite.scale = Vector2(CELL_SIZE, CELL_SIZE)
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(_sprite)
	reinitialize()


func reinitialize() -> void:
	var viewport_size := get_viewport_rect().size
	grid_width = int(viewport_size.x) / CELL_SIZE
	grid_height = int(viewport_size.y) / CELL_SIZE

	var total := grid_width * grid_height
	food_pheromones = PackedFloat32Array()
	food_pheromones.resize(total)
	home_pheromones = PackedFloat32Array()
	home_pheromones.resize(total)

	_image = Image.create(grid_width, grid_height, false, Image.FORMAT_RGBA8)
	_texture = ImageTexture.create_from_image(_image)
	if _sprite:
		_sprite.texture = _texture

	_texture_timer = 0.0


func _process(delta: float) -> void:
	_evaporate()
	_texture_timer += delta
	if _texture_timer >= TEXTURE_UPDATE_INTERVAL:
		_texture_timer = 0.0
		_update_texture()


func _evaporate() -> void:
	for i in range(food_pheromones.size()):
		food_pheromones[i] *= EVAPORATION_RATE
		home_pheromones[i] *= EVAPORATION_RATE


func _update_texture() -> void:
	for i in range(food_pheromones.size()):
		var x := i % grid_width
		var y := i / grid_width
		var food := minf(food_pheromones[i], 1.0)
		var home := minf(home_pheromones[i], 1.0)
		var alpha := maxf(food, home) * 0.85
		if alpha < 0.01:
			_image.set_pixel(x, y, Color(0, 0, 0, 0))
		else:
			# food = blue-green teal, home = warm orange
			_image.set_pixel(x, y, Color(home * 0.85, food * 0.65, food * 0.95, alpha))
	_texture.update(_image)


func _world_to_idx(world_pos: Vector2) -> int:
	var x := clampi(int(world_pos.x) / CELL_SIZE, 0, grid_width - 1)
	var y := clampi(int(world_pos.y) / CELL_SIZE, 0, grid_height - 1)
	return y * grid_width + x


func add_food_pheromone(world_pos: Vector2, amount: float) -> void:
	var idx := _world_to_idx(world_pos)
	food_pheromones[idx] = minf(food_pheromones[idx] + amount, 1.0)


func add_home_pheromone(world_pos: Vector2, amount: float) -> void:
	var idx := _world_to_idx(world_pos)
	home_pheromones[idx] = minf(home_pheromones[idx] + amount, 1.0)


func sample_food_pheromone(world_pos: Vector2) -> float:
	return food_pheromones[_world_to_idx(world_pos)]


func sample_home_pheromone(world_pos: Vector2) -> float:
	return home_pheromones[_world_to_idx(world_pos)]
