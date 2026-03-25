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
const COLONY_MARGIN := 80.0

# --- Runtime-configurable parameters (edited by DevPanel before restart) ---
var cfg_initial_ants: int = 15
var cfg_food_source_count: int = 5
var cfg_food_quantity: int = 50
var cfg_fight_range: float = 8.0
var cfg_random_positions: bool = false

# --- Simulation state ---
var sim_time: float = 0.0
var combat_events: int = 0

var _colonies: Array[Colony] = []
var _stat_labels: Array[Label] = []


func _ready() -> void:
	pheromone_map.reinitialize(COLONY_COUNT, COLONY_COLORS)
	_spawn_food(get_viewport_rect().size)
	_spawn_colonies(get_viewport_rect().size)
	_build_stat_labels()
	get_viewport().size_changed.connect(_on_viewport_resized)


func _process(delta: float) -> void:
	if not get_tree().paused:
		sim_time += delta
	_check_interactions()
	_update_stats()


# --- Public API for DevPanel ---

func restart() -> void:
	if get_tree().paused:
		resume_sim()
	_clear_simulation()
	sim_time = 0.0
	combat_events = 0
	# Use call_deferred so queue_free nodes are removed before re-spawning
	call_deferred("_deferred_restart")


func _deferred_restart() -> void:
	var vp := get_viewport_rect().size
	pheromone_map.reinitialize(COLONY_COUNT, COLONY_COLORS)
	_spawn_food(vp)
	_spawn_colonies(vp)
	_build_stat_labels()


func pause_sim() -> void:
	get_tree().paused = true


func resume_sim() -> void:
	get_tree().paused = false


func is_paused() -> bool:
	return get_tree().paused


# --- Internal helpers ---

func _clear_simulation() -> void:
	for child in ants_container.get_children():
		child.queue_free()
	for child in food_sources.get_children():
		child.queue_free()
	for child in colonies_container.get_children():
		child.queue_free()
	_colonies.clear()


func _spawn_colonies(vp: Vector2) -> void:
	var positions := _colony_positions(vp)
	for i in range(COLONY_COUNT):
		var col := Colony.new()
		colonies_container.add_child(col)
		col.global_position = positions[i]
		col.setup(i, COLONY_COLORS[i], pheromone_map, ants_container, cfg_initial_ants)
		_colonies.append(col)


func _colony_positions(vp: Vector2) -> Array[Vector2]:
	if not cfg_random_positions:
		return [
			Vector2(COLONY_MARGIN, COLONY_MARGIN),
			Vector2(vp.x - COLONY_MARGIN, COLONY_MARGIN),
			Vector2(vp.x / 2.0, vp.y - COLONY_MARGIN),
		]
	# Random placement with minimum separation
	const MIN_SEP := 200.0
	var positions: Array[Vector2] = []
	var attempts := 0
	while positions.size() < COLONY_COUNT and attempts < 500:
		attempts += 1
		var pos := Vector2(
			randf_range(COLONY_MARGIN, vp.x - COLONY_MARGIN),
			randf_range(COLONY_MARGIN, vp.y - COLONY_MARGIN)
		)
		var ok := true
		for existing: Vector2 in positions:
			if pos.distance_to(existing) < MIN_SEP:
				ok = false
				break
		if ok:
			positions.append(pos)
	# Fallback to fixed if random placement failed
	if positions.size() < COLONY_COUNT:
		return [
			Vector2(COLONY_MARGIN, COLONY_MARGIN),
			Vector2(vp.x - COLONY_MARGIN, COLONY_MARGIN),
			Vector2(vp.x / 2.0, vp.y - COLONY_MARGIN),
		]
	return positions


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
			if a.global_position.distance_to(b.global_position) <= cfg_fight_range:
				dead.append(a)
				dead.append(b)
				break

	if not dead.is_empty():
		combat_events += 1

	for ant: Ant in dead:
		if ant.is_inside_tree():
			_colonies[ant.colony_id].on_ant_died()
			ant.queue_free()

	for col: Colony in _colonies:
		if not col.is_alive:
			col.queue_redraw()


func _spawn_food(vp: Vector2) -> void:
	var food_scene := preload("res://scenes/food.tscn")
	var margin := 120.0
	for i in range(cfg_food_source_count):
		var food := food_scene.instantiate() as Food
		food.quantity = cfg_food_quantity
		food_sources.add_child(food)
		food.global_position = Vector2(
			randf_range(margin, vp.x - margin),
			randf_range(margin, vp.y - margin)
		)


func _on_viewport_resized() -> void:
	_clear_simulation()
	await get_tree().process_frame
	var vp := get_viewport_rect().size
	sim_time = 0.0
	combat_events = 0
	pheromone_map.reinitialize(COLONY_COUNT, COLONY_COLORS)
	_spawn_food(vp)
	_spawn_colonies(vp)
	_build_stat_labels()
