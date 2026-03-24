extends Node2D

const BASE_RADIUS := 10.0

var quantity: int = 50:
	set(v):
		quantity = v
		queue_redraw()


func take_food() -> bool:
	if quantity <= 0:
		return false
	quantity -= 1
	return true


func _draw() -> void:
	if quantity <= 0:
		return
	var t := float(quantity) / 50.0
	var radius := BASE_RADIUS * (0.4 + 0.6 * t)
	draw_circle(Vector2.ZERO, radius, Color(0.15, 0.78, 0.15))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 24, Color(0.05, 0.50, 0.05), 1.5)
