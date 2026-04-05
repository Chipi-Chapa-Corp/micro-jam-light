extends "res://scenes/enemies/enemy.gd"

func _ready() -> void:
	super._ready()
	_ensure_patrol_waypoints()

func _ensure_patrol_waypoints() -> void:
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
