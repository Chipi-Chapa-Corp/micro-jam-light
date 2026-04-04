extends "res://scenes/enemies/enemy.gd"

@export var bullet_scene: PackedScene = preload("res://scenes/enemies/bullet/bullet.tscn")
@export var shoot_interval: float = 1.0

var shoot_timer: float = 0.0
var bullet_offset_x: float = 10.0 
var bullet_offset_y: float = 5.0  

func _physics_process(delta: float) -> void:
	sees_player_now = can_see_player()

	if sees_player_now and _is_player_in_front():
		is_patrolling = false
		velocity = Vector2.ZERO  # Stops
		shoot_timer += delta
		if shoot_timer >= shoot_interval:
			shoot_timer = 0.0
			if anim:
				anim.play("shoot")
				await anim.animation_finished
			shoot()
	else:
		shoot_timer = shoot_interval  # Reset shoot timer when player is not seen
		is_patrolling = true
		if anim:
			anim.play("walk")
		patrol()
	
	update_facing_direction()
	move_and_slide()
	_check_player_collision()

func shoot() -> void:
	if not is_instance_valid(player) or not _is_player_in_front():
		return

	var bullet = bullet_scene.instantiate()
	var spawn_offset := Vector2(
		float(facing_direction_x) * bullet_offset_x, bullet_offset_y
	)
	bullet.global_position = global_position + spawn_offset
	bullet.direction = (player.global_position - global_position).normalized()
	get_parent().add_child(bullet)

func _is_player_in_front() -> bool:
	if not is_instance_valid(player):
		return false

	var to_player_x := player.global_position.x - global_position.x
	if abs(to_player_x) <= 0.01:
		return true

	return int(sign(to_player_x)) == facing_direction_x
