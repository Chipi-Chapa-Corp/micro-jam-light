extends "res://scenes/enemies/enemy.gd"

const BOUNDARY_EPSILON: float = 1.0

func _physics_process(delta: float) -> void:
	if not is_stationary:
		_update_facing_for_overhead_player()
	sees_player_now = can_see_player()

	if is_stationary:
		_handle_stationary_behavior(delta)
		velocity = Vector2.ZERO
		_play_idle_or_walk("idle")
		move_and_slide()
		_check_player_collision()
		return

	if sees_player_now and is_instance_valid(player):
		is_patrolling = false
		var x_direction: int = sign(player.global_position.x - global_position.x)
		var bounds := _get_waypoint_bounds()
		if _hits_waypoint_boundary_while_chasing(x_direction, bounds):
			velocity = Vector2.ZERO
			_play_idle_or_walk("idle")
		else:
			velocity.x = x_direction * speed
			velocity.y = 0.0
			_play_idle_or_walk("walk")
	else:
		is_patrolling = true
		_play_idle_or_walk("walk")
		patrol()

	_apply_waypoint_velocity_limits()
	update_facing_direction()
	move_and_slide()
	_clamp_to_waypoint_bounds()
	_check_player_collision()

func _hits_waypoint_boundary_while_chasing(x_direction: int, bounds: Dictionary) -> bool:
	if x_direction == 0:
		return false

	if x_direction > 0 and global_position.x >= bounds.max_x - BOUNDARY_EPSILON:
		return true
	if x_direction < 0 and global_position.x <= bounds.min_x + BOUNDARY_EPSILON:
		return true
	return false

func _apply_waypoint_velocity_limits() -> void:
	if waypoints.is_empty():
		return

	var bounds := _get_waypoint_bounds()
	if global_position.x <= bounds.min_x and velocity.x < 0.0:
		velocity.x = 0.0
	if global_position.x >= bounds.max_x and velocity.x > 0.0:
		velocity.x = 0.0
	if global_position.y <= bounds.min_y and velocity.y < 0.0:
		velocity.y = 0.0
	if global_position.y >= bounds.max_y and velocity.y > 0.0:
		velocity.y = 0.0

func _clamp_to_waypoint_bounds() -> void:
	if waypoints.is_empty():
		return

	var bounds := _get_waypoint_bounds()
	global_position = Vector2(
		clampf(global_position.x, bounds.min_x, bounds.max_x),
		clampf(global_position.y, bounds.min_y, bounds.max_y)
	)

func _get_waypoint_bounds() -> Dictionary:
	var min_x := waypoints[0].x
	var max_x := waypoints[0].x
	var min_y := waypoints[0].y
	var max_y := waypoints[0].y

	for point: Vector2 in waypoints:
		min_x = min(min_x, point.x)
		max_x = max(max_x, point.x)
		min_y = min(min_y, point.y)
		max_y = max(max_y, point.y)

	return {
		"min_x": min_x,
		"max_x": max_x,
		"min_y": min_y,
		"max_y": max_y
	}

func _play_idle_or_walk(preferred_animation: StringName) -> void:
	if anim == null:
		return

	var frames := anim.sprite_frames
	if frames == null:
		return

	if frames.has_animation(preferred_animation):
		anim.play(preferred_animation)
	elif frames.has_animation(&"walk"):
		anim.play(&"walk")
