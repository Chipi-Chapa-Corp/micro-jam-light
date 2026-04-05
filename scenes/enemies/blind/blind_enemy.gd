extends "res://scenes/enemies/enemy.gd"

func _ready() -> void:
	super._ready()
	_ensure_patrol_waypoints()
	_set_initial_waypoint_index()

func _ensure_patrol_waypoints() -> void:
	if is_zero_approx(waypoint_block_count_left) and is_zero_approx(waypoint_block_count_right):
		is_stationary = true
		if anim:
			anim.play("idle")
		return

	if not waypoints.is_empty():
		return

	var patrol_half_distance := maxf(float(DEFAULT_WAYPOINT_DISTANCE), waypoint_block_size)
	waypoints = [
		global_position - Vector2(patrol_half_distance, 0.0),
		global_position + Vector2(patrol_half_distance, 0.0)
	]
	current_waypoint_index = 0
	is_stationary = false
	if anim:
		anim.play("walk")

func _set_initial_waypoint_index() -> void:
	if waypoints.size() != 2:
		return

	current_waypoint_index = 1 if default_face_right else 0
