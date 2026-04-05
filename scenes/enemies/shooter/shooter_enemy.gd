extends "res://scenes/enemies/enemy.gd"

@export var bullet_scene: PackedScene = preload("res://scenes/enemies/bullet/bullet.tscn")
@export var shoot_interval: float = 1.0
@export_group("Stationary")
@export var is_stationary_mode: bool = false
@export var facing_right_in_stationary: bool = false

var shoot_timer: float = 0.0
var bullet_offset_x: float = 10.0 
var bullet_offset_y: float = 5.0  
var is_attacking: bool = false
var is_shoot_animation_playing: bool = false

func _ready() -> void:
	super._ready()
	is_stationary = is_stationary_mode
	stationary_can_turn_around = false

	if is_stationary_mode:
		facing_direction_x = 1 if facing_right_in_stationary else -1
		_apply_facing_visual()
	else:
		_ensure_non_stationary_waypoints()

	if anim:
		anim.play("idle" if is_stationary else "walk")
	if anim and not anim.animation_finished.is_connected(_on_animation_finished):
		anim.animation_finished.connect(_on_animation_finished)

func _physics_process(delta: float) -> void:
	sees_player_now = can_see_player()

	if is_stationary_mode:
		velocity = Vector2.ZERO
		facing_direction_x = 1 if facing_right_in_stationary else -1
		_apply_facing_visual()
		if sees_player_now and is_instance_valid(player) and _is_player_in_front():
			_start_attack(delta)
		else:
			_handle_stationary_behavior(delta)
			_stop_attack()
			if anim:
				anim.play("idle")

		move_and_slide()
		_check_player_collision()
		return

	_update_facing_for_overhead_player()

	if sees_player_now and is_instance_valid(player):
		_face_player()
		_start_attack(delta)
	else:
		_stop_attack()
		
		if not is_attacking:
			if anim:
				anim.play("walk")
			patrol()
	
	update_facing_direction()
	move_and_slide()
	_check_player_collision()

func _start_attack(delta: float) -> void:
	var attack_just_started := not is_attacking
	is_attacking = true
	is_patrolling = false
	velocity = Vector2.ZERO

	if attack_just_started:
		# Start shooting immediately when player is spotted,
		# so walk animation is interrupted without delay.
		shoot_timer = shoot_interval

	if is_shoot_animation_playing:
		return

	shoot_timer += delta
	if shoot_timer >= shoot_interval:
		is_shoot_animation_playing = true
		if anim and _has_animation(&"shoot"):
			anim.play("shoot")
		else:
			# Fallback if there is no shoot animation: fire immediately.
			is_shoot_animation_playing = false
			shoot_timer = 0.0
			shoot()

func _stop_attack() -> void:
	if not is_attacking:
		return

	is_attacking = false
	is_patrolling = true
	shoot_timer = 0.0
	is_shoot_animation_playing = false

func shoot() -> void:
	if not is_instance_valid(player):
		return

	var bullet = bullet_scene.instantiate()
	var spawn_offset := Vector2(
		float(facing_direction_x) * bullet_offset_x, bullet_offset_y
	)
	bullet.global_position = global_position + spawn_offset
	bullet.direction = (player.global_position - global_position).normalized()
	get_parent().add_child(bullet)

func _face_player() -> void:
	if not is_instance_valid(player):
		return

	var to_player_x := player.global_position.x - global_position.x
	if abs(to_player_x) <= 0.01:
		return

	facing_direction_x = int(sign(to_player_x))
	if anim:
		anim.flip_h = facing_direction_x > 0

func _on_animation_finished() -> void:
	if not is_shoot_animation_playing:
		return

	is_shoot_animation_playing = false
	shoot_timer = 0.0

	if not is_attacking:
		return

	if can_see_player() and is_instance_valid(player):
		if is_stationary_mode and not _is_player_in_front():
			return
		if not is_stationary_mode:
			_face_player()
		shoot()

func _has_animation(animation_name: StringName) -> bool:
	if anim == null or anim.sprite_frames == null:
		return false
	return anim.sprite_frames.has_animation(animation_name)

func _ensure_non_stationary_waypoints() -> void:
	if not waypoints.is_empty():
		return

	var patrol_half_distance := maxf(float(DEFAULT_WAYPOINT_DISTANCE), waypoint_block_size)
	waypoints = [
		global_position - Vector2(patrol_half_distance, 0.0),
		global_position + Vector2(patrol_half_distance, 0.0)
	]
	current_waypoint_index = 0

func _is_player_in_front() -> bool:
	if not is_instance_valid(player):
		return false

	var to_player_x := player.global_position.x - global_position.x
	if abs(to_player_x) <= 0.01:
		return true

	return int(sign(to_player_x)) == facing_direction_x
