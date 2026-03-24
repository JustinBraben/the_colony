extends Node2D

enum State { SEARCHING, RETURNING }

const SPEED := 80.0
const TURN_SPEED := 4.0
const WANDER_STRENGTH := 3.0
const SENSOR_DIST := 28.0
const SENSOR_ANGLE := PI / 5.0
const PHEROMONE_STRENGTH := 0.35
const PHEROMONE_INTERVAL := 0.08

var state: State = State.SEARCHING
var direction: float = 0.0
var pheromone_map: Node2D = null
var colony_position: Vector2 = Vector2.ZERO

var _pheromone_timer: float = 0.0


func _ready() -> void:
	direction = randf() * TAU


func _process(delta: float) -> void:
	_steer(delta)
	_move(delta)
	_drop_pheromone(delta)
	queue_redraw()


func _steer(delta: float) -> void:
	direction += randf_range(-WANDER_STRENGTH, WANDER_STRENGTH) * delta

	if pheromone_map != null:
		_follow_pheromones(delta)

	if state == State.RETURNING:
		_steer_toward_colony(delta)

	_bounce_walls(delta)


func _follow_pheromones(delta: float) -> void:
	var left_pos := global_position + Vector2.from_angle(direction - SENSOR_ANGLE) * SENSOR_DIST
	var fwd_pos := global_position + Vector2.from_angle(direction) * SENSOR_DIST
	var right_pos := global_position + Vector2.from_angle(direction + SENSOR_ANGLE) * SENSOR_DIST

	var left_val: float
	var fwd_val: float
	var right_val: float

	if state == State.SEARCHING:
		left_val = pheromone_map.sample_food_pheromone(left_pos)
		fwd_val = pheromone_map.sample_food_pheromone(fwd_pos)
		right_val = pheromone_map.sample_food_pheromone(right_pos)
	else:
		left_val = pheromone_map.sample_home_pheromone(left_pos)
		fwd_val = pheromone_map.sample_home_pheromone(fwd_pos)
		right_val = pheromone_map.sample_home_pheromone(right_pos)

	if fwd_val >= left_val and fwd_val >= right_val:
		pass  # continue straight
	elif left_val > right_val:
		direction -= TURN_SPEED * delta
	else:
		direction += TURN_SPEED * delta


func _steer_toward_colony(delta: float) -> void:
	var target_angle := (colony_position - global_position).angle()
	var diff := angle_difference(direction, target_angle)
	direction += clampf(diff, -TURN_SPEED * 2.0 * delta, TURN_SPEED * 2.0 * delta)


func _bounce_walls(delta: float) -> void:
	var rect := get_viewport_rect()
	var margin := 20.0
	if global_position.x < margin:
		direction = lerp_angle(direction, 0.0, delta * 8.0)
	elif global_position.x > rect.size.x - margin:
		direction = lerp_angle(direction, PI, delta * 8.0)
	if global_position.y < margin:
		direction = lerp_angle(direction, PI * 0.5, delta * 8.0)
	elif global_position.y > rect.size.y - margin:
		direction = lerp_angle(direction, -PI * 0.5, delta * 8.0)


func _move(delta: float) -> void:
	global_position += Vector2.from_angle(direction) * SPEED * delta


func _drop_pheromone(delta: float) -> void:
	if pheromone_map == null:
		return
	_pheromone_timer += delta
	if _pheromone_timer >= PHEROMONE_INTERVAL:
		_pheromone_timer = 0.0
		if state == State.SEARCHING:
			pheromone_map.add_home_pheromone(global_position, PHEROMONE_STRENGTH)
		else:
			pheromone_map.add_food_pheromone(global_position, PHEROMONE_STRENGTH)


func pick_up_food() -> void:
	state = State.RETURNING
	direction = (colony_position - global_position).angle()


func deliver_food() -> void:
	state = State.SEARCHING
	direction += PI


func _draw() -> void:
	var body_color := Color(0.9, 0.8, 0.1) if state == State.RETURNING else Color(0.15, 0.08, 0.03)
	draw_circle(Vector2.ZERO, 3.5, body_color)
	# Direction indicator
	var tip := Vector2.from_angle(direction) * 5.5
	draw_line(Vector2.ZERO, tip, Color(1.0, 1.0, 1.0, 0.45), 1.0)
