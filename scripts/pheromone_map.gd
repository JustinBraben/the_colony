extends Node2D

## Grid-based pheromone map supporting N colony layers.
## Each colony has its own food and home pheromone channel.
## Trails are visualised with each colony's colour, blended where they overlap.

const CELL_SIZE := 4
const EVAPORATION_RATE := 0.9975
const TEXTURE_UPDATE_INTERVAL := 0.05

var grid_width: int
var grid_height: int
var colony_count: int = 0

var colony_food: Array[PackedFloat32Array] = []
var colony_home: Array[PackedFloat32Array] = []
var colony_colors: Array[Color] = []

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


func reinitialize(count: int, colors: Array[Color]) -> void:
	colony_count = count
	colony_colors = colors

	var viewport_size := get_viewport_rect().size
	grid_width = int(viewport_size.x) / CELL_SIZE
	grid_height = int(viewport_size.y) / CELL_SIZE

	var total := grid_width * grid_height
	colony_food.clear()
	colony_home.clear()
	for i in range(colony_count):
		var food_arr := PackedFloat32Array()
		food_arr.resize(total)
		colony_food.append(food_arr)
		var home_arr := PackedFloat32Array()
		home_arr.resize(total)
		colony_home.append(home_arr)

	_image = Image.create(grid_width, grid_height, false, Image.FORMAT_RGBA8)
	_texture = ImageTexture.create_from_image(_image)
	if _sprite:
		_sprite.texture = _texture

	_texture_timer = 0.0


func _process(delta: float) -> void:
	if colony_count == 0:
		return
	_evaporate()
	_texture_timer += delta
	if _texture_timer >= TEXTURE_UPDATE_INTERVAL:
		_texture_timer = 0.0
		_update_texture()


func _evaporate() -> void:
	for c in range(colony_count):
		var food := colony_food[c]
		var home := colony_home[c]
		for i in range(food.size()):
			food[i] *= EVAPORATION_RATE
			home[i] *= EVAPORATION_RATE


func _update_texture() -> void:
	var total := grid_width * grid_height
	for i in range(total):
		var x := i % grid_width
		var y := i / grid_width
		var r := 0.0
		var g := 0.0
		var b := 0.0
		var a := 0.0
		for c in range(colony_count):
			var strength := maxf(colony_food[c][i], colony_home[c][i]) * 0.7
			if strength > 0.005:
				var col := colony_colors[c]
				r += col.r * strength
				g += col.g * strength
				b += col.b * strength
				a = maxf(a, strength)
		if a < 0.01:
			_image.set_pixel(x, y, Color(0, 0, 0, 0))
		else:
			_image.set_pixel(x, y, Color(minf(r, 1.0), minf(g, 1.0), minf(b, 1.0), a * 0.85))
	_texture.update(_image)


func _world_to_idx(world_pos: Vector2) -> int:
	var x := clampi(int(world_pos.x) / CELL_SIZE, 0, grid_width - 1)
	var y := clampi(int(world_pos.y) / CELL_SIZE, 0, grid_height - 1)
	return y * grid_width + x


func add_food_pheromone(world_pos: Vector2, amount: float, colony_id: int) -> void:
	var idx := _world_to_idx(world_pos)
	colony_food[colony_id][idx] = minf(colony_food[colony_id][idx] + amount, 1.0)


func add_home_pheromone(world_pos: Vector2, amount: float, colony_id: int) -> void:
	var idx := _world_to_idx(world_pos)
	colony_home[colony_id][idx] = minf(colony_home[colony_id][idx] + amount, 1.0)


func sample_food_pheromone(world_pos: Vector2, colony_id: int) -> float:
	return colony_food[colony_id][_world_to_idx(world_pos)]


func sample_home_pheromone(world_pos: Vector2, colony_id: int) -> float:
	return colony_home[colony_id][_world_to_idx(world_pos)]
