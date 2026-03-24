extends Node2D

@onready var pheromone_map: Node2D = $PheromoneMap
@onready var colony: Node2D = $Colony
@onready var food_sources: Node2D = $FoodSources
@onready var ants_container: Node2D = $Ants
@onready var food_label: Label = $UI/Label

const FOOD_SOURCE_COUNT := 4
const FOOD_QUANTITY := 50


func _ready() -> void:
	var viewport_size := get_viewport_rect().size
	colony.position = viewport_size / 2.0

	_spawn_food(viewport_size)
	colony.setup(pheromone_map, ants_container)


func _process(_delta: float) -> void:
	food_label.text = "Food collected: %d" % colony.food_collected
	_check_interactions()


func _check_interactions() -> void:
	for ant in ants_container.get_children():
		if not ant.is_inside_tree():
			continue

		if ant.state == ant.State.SEARCHING:
			for food in food_sources.get_children():
				if food.quantity > 0:
					if ant.global_position.distance_to(food.global_position) < 12.0:
						if food.take_food():
							ant.pick_up_food()
							break

		elif ant.state == ant.State.RETURNING:
			if ant.global_position.distance_to(colony.global_position) < colony.COLONY_RADIUS:
				colony.collect_food()
				ant.deliver_food()


func _spawn_food(viewport_size: Vector2) -> void:
	var food_scene := preload("res://scenes/food.tscn")
	var margin := 100.0

	for i in range(FOOD_SOURCE_COUNT):
		var food := food_scene.instantiate()
		food.quantity = FOOD_QUANTITY
		food_sources.add_child(food)
		food.global_position = Vector2(
			randf_range(margin, viewport_size.x - margin),
			randf_range(margin, viewport_size.y - margin)
		)
