class_name Food
extends Node2D

const BASE_RADIUS := 10.0
const RESPAWN_TIME := 20.0
const RESPAWN_QUANTITY := 50

var quantity: int = 50:
	set(v):
		quantity = v
		queue_redraw()

var _respawn_timer: float = -1.0


func take_food() -> bool:
	if quantity <= 0:
		return false
	quantity -= 1
	if quantity == 0:
		_respawn_timer = RESPAWN_TIME
	return true


func _process(delta: float) -> void:
	if _respawn_timer > 0.0:
		_respawn_timer -= delta
		if _respawn_timer <= 0.0:
			_respawn_timer = -1.0
			quantity = RESPAWN_QUANTITY


func _draw() -> void:
	if quantity <= 0:
		# Show a faint outline while respawning
		draw_arc(Vector2.ZERO, BASE_RADIUS * 0.4, 0.0, TAU, 16, Color(0.1, 0.35, 0.1, 0.4), 1.0)
		return
	var t := float(quantity) / float(RESPAWN_QUANTITY)
	var radius := BASE_RADIUS * (0.4 + 0.6 * t)
	draw_circle(Vector2.ZERO, radius, Color(0.15, 0.78, 0.15))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 24, Color(0.05, 0.50, 0.05), 1.5)
