class_name Colony
extends Node2D

const COLONY_RADIUS := 18.0
const INITIAL_ANTS := 15
const MAX_POPULATION := 35
const FOOD_PER_ANT := 5

var colony_id: int = 0
var colony_color: Color = Color.WHITE
var population: int = 0
var food_collected: int = 0
var food_for_reproduction: int = 0
var is_alive: bool = true

var _pheromone_map: Node2D
var _ants_container: Node2D
var _ant_scene: PackedScene


func setup(id: int, color: Color, p_pheromone_map: Node2D, p_ants_container: Node2D) -> void:
	colony_id = id
	colony_color = color
	_pheromone_map = p_pheromone_map
	_ants_container = p_ants_container
	_ant_scene = preload("res://scenes/ant.tscn")

	population = 0
	food_collected = 0
	food_for_reproduction = 0
	is_alive = true

	for i in range(INITIAL_ANTS):
		spawn_ant()


func spawn_ant() -> void:
	if population >= MAX_POPULATION or not is_alive:
		return
	var ant := _ant_scene.instantiate()
	_ants_container.add_child(ant)
	ant.global_position = global_position + Vector2(randf_range(-5.0, 5.0), randf_range(-5.0, 5.0))
	ant.pheromone_map = _pheromone_map
	ant.colony_position = global_position
	ant.colony_id = colony_id
	ant.colony_color = colony_color
	population += 1


func collect_food() -> void:
	food_collected += 1
	food_for_reproduction += 1
	if food_for_reproduction >= FOOD_PER_ANT:
		food_for_reproduction = 0
		spawn_ant()


func on_ant_died() -> void:
	population -= 1
	if population <= 0:
		population = 0
		is_alive = false


func _draw() -> void:
	if not is_alive:
		return
	var dark := colony_color.darkened(0.55)
	var mid := colony_color.darkened(0.25)
	draw_circle(Vector2.ZERO, COLONY_RADIUS, dark)
	draw_arc(Vector2.ZERO, COLONY_RADIUS, 0.0, TAU, 32, mid, 2.5)
	draw_circle(Vector2.ZERO, COLONY_RADIUS * 0.45, colony_color.darkened(0.65))
