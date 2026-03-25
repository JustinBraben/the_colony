extends Node2D

@onready var pheromone_map: Node2D = $PheromoneMap
@onready var colonies_container: Node2D = $Colonies
@onready var food_sources: Node2D = $FoodSources
@onready var ants_container: Node2D = $Ants
@onready var colony_stats: VBoxContainer = $UI/ColonyStats

const COLONY_COUNT := 3
const COLONY_COLORS: Array[Color] = [
	Color(0.90, 0.22, 0.22),  # red
	Color(0.25, 0.48, 1.00),  # blue
	Color(0.20, 0.82, 0.32),  # green
]
const FIGHT_RANGE := 8.0
const FOOD_SOURCE_COUNT := 5
const FOOD_QUANTITY := 50
const COLONY_MARGIN := 80.0

var _colonies: Array[Colony] = []
var _stat_labels: Array[Label] = []


func _ready() -> void:
	pheromone_map.reinitialize(COLONY_COUNT, COLONY_COLORS)
	_spawn_food(get_viewport_rect().size)
	_spawn_colonies(get_viewport_rect().size)
	_build_stat_labels()
	get_viewport().size_changed.connect(_on_viewport_resized)


func _process(_delta: float) -> void:
	_check_interactions()
	_update_stats()


func _spawn_colonies(vp: Vector2) -> void:
	var positions: Array[Vector2] = [
		Vector2(COLONY_MARGIN, COLONY_MARGIN),
		Vector2(vp.x - COLONY_MARGIN, COLONY_MARGIN),
		Vector2(vp.x / 2.0, vp.y - COLONY_MARGIN),
	]
	for i in range(COLONY_COUNT):
		var col := Colony.new()
		colonies_container.add_child(col)
		col.global_position = positions[i]
		col.setup(i, COLONY_COLORS[i], pheromone_map, ants_container)
		_colonies.append(col)


func _build_stat_labels() -> void:
	for child in colony_stats.get_children():
		child.queue_free()
	_stat_labels.clear()
	for i in range(COLONY_COUNT):
		var lbl := Label.new()
		lbl.add_theme_font_size_override("font_size", 14)
		lbl.add_theme_color_override("font_color", COLONY_COLORS[i].lightened(0.3))
		colony_stats.add_child(lbl)
		_stat_labels.append(lbl)


func _update_stats() -> void:
	for i in range(_colonies.size()):
		var col: Colony = _colonies[i]
		if col.is_alive:
			_stat_labels[i].text = "Colony %d  Pop: %d  Food: %d" % [i + 1, col.population, col.food_collected]
		else:
			_stat_labels[i].text = "Colony %d  ELIMINATED" % (i + 1)


func _check_interactions() -> void:
	# Gather all living ants once per frame
	var all_ants: Array[Ant] = []
	for node in ants_container.get_children():
		var ant := node as Ant
		if ant != null and ant.is_inside_tree():
			all_ants.append(ant)

	var dead: Array[Ant] = []

	# Food pickup and colony delivery
	for ant: Ant in all_ants:
		if ant in dead:
			continue
		if ant.state == Ant.State.SEARCHING:
			for node in food_sources.get_children():
				var food := node as Food
				if food == null or food.quantity <= 0:
					continue
				if ant.global_position.distance_to(food.global_position) < 12.0:
					if food.take_food():
						ant.pick_up_food()
						break
		elif ant.state == Ant.State.RETURNING:
			var col: Colony = _colonies[ant.colony_id]
			if ant.global_position.distance_to(col.global_position) < Colony.COLONY_RADIUS:
				col.collect_food()
				ant.deliver_food()

	# Combat: O(n²) between ants of different colonies
	for i in range(all_ants.size()):
		var a: Ant = all_ants[i]
		if a in dead:
			continue
		for j in range(i + 1, all_ants.size()):
			var b: Ant = all_ants[j]
			if b in dead:
				continue
			if a.colony_id == b.colony_id:
				continue
			if a.global_position.distance_to(b.global_position) <= FIGHT_RANGE:
				dead.append(a)
				dead.append(b)
				break

	# Apply deaths
	for ant: Ant in dead:
		if ant.is_inside_tree():
			_colonies[ant.colony_id].on_ant_died()
			ant.queue_free()

	# Redraw any newly eliminated colonies
	for col: Colony in _colonies:
		if not col.is_alive:
			col.queue_redraw()


func _spawn_food(vp: Vector2) -> void:
	var food_scene := preload("res://scenes/food.tscn")
	var margin := 120.0
	for i in range(FOOD_SOURCE_COUNT):
		var food := food_scene.instantiate() as Food
		food.quantity = FOOD_QUANTITY
		food_sources.add_child(food)
		food.global_position = Vector2(
			randf_range(margin, vp.x - margin),
			randf_range(margin, vp.y - margin)
		)


func _on_viewport_resized() -> void:
	for child in ants_container.get_children():
		child.queue_free()
	for child in food_sources.get_children():
		child.queue_free()
	for child in colonies_container.get_children():
		child.queue_free()
	_colonies.clear()
	await get_tree().process_frame
	var vp := get_viewport_rect().size
	pheromone_map.reinitialize(COLONY_COUNT, COLONY_COLORS)
	_spawn_food(vp)
	_spawn_colonies(vp)
	_build_stat_labels()
