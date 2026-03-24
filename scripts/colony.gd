extends Node2D

const COLONY_RADIUS := 18.0
const ANT_COUNT := 60

var food_collected: int = 0


func setup(pheromone_map: Node2D, ants_container: Node2D) -> void:
	var ant_scene := preload("res://scenes/ant.tscn")
	var origin := global_position
	for i in range(ANT_COUNT):
		var ant := ant_scene.instantiate()
		ants_container.add_child(ant)
		ant.global_position = origin + Vector2(randf_range(-5.0, 5.0), randf_range(-5.0, 5.0))
		ant.pheromone_map = pheromone_map
		ant.colony_position = origin


func collect_food() -> void:
	food_collected += 1


func _draw() -> void:
	draw_circle(Vector2.ZERO, COLONY_RADIUS, Color(0.35, 0.20, 0.08))
	draw_arc(Vector2.ZERO, COLONY_RADIUS, 0.0, TAU, 32, Color(0.65, 0.42, 0.18), 2.5)
	draw_circle(Vector2.ZERO, COLONY_RADIUS * 0.45, Color(0.22, 0.12, 0.05))
