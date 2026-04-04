extends CharacterBody2D

@onready var tile_map: Node2D = _resolve_tile_map()

const SPEED = 300.0
const JUMP_VELOCITY = -400.0
const PUSH_FORCE = 100.0
const STEP_INTERVAL = 0.2
const LAND_STEP_DELAY = 0.15

@onready var sfx_step = $sfx_step
@onready var sfx_fall_after_jump = $sfxFallAfterJump
@onready var sfx_jump = $sfxJump

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
var spawn_effect := preload("res://scenes/player/spawnEffect/spawnEffect.tscn")

var is_exiting = false
var was_on_floor = false
var step_timer = 0.0
var step_delay_timer = 0.0

func _ready() -> void:
	set_physics_process(false)
	await spawn_appear_effect()
	set_physics_process(true)
	anim.visible = true

func _resolve_tile_map() -> Node2D:
	var parent_node := get_parent()
	if parent_node is Node2D and parent_node.name == "TileMap":
		return parent_node as Node2D

	var sibling_tile_map := get_node_or_null("../TileMap")
	if sibling_tile_map is Node2D:
		return sibling_tile_map as Node2D

	push_warning("player.gd: Could not resolve TileMap node for player.")
	return null
	
func _physics_process(delta: float) -> void:
	_resolve_stuck()
	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		sfx_jump.play()

	var direction := Input.get_axis("move_left", "move_right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	
	move_and_slide()
	_check_enemy_collision()
	
	update_animation(direction)
	
	if step_delay_timer > 0.0:
		step_delay_timer -= delta

	if not was_on_floor and is_on_floor():
		sfx_fall_after_jump.play()
		step_delay_timer = LAND_STEP_DELAY
		step_timer = STEP_INTERVAL

	var is_moving = abs(velocity.x) > 0.1

	if is_on_floor() and is_moving and step_delay_timer <= 0.0:
		step_timer -= delta
		if step_timer <= 0.0:
			sfx_step.play()
			step_timer = STEP_INTERVAL
	else:
		step_timer = 0.0
	
	was_on_floor = is_on_floor()

func spawn_appear_effect() -> void:
	var effect = spawn_effect.instantiate()
	get_parent().add_child.call_deferred(effect)
	effect.global_position = global_position
	await effect.finished

func play_disappear_effect() -> void:
	if is_exiting:
		return

	is_exiting = true
	set_physics_process(false)
	velocity = Vector2.ZERO
	anim.visible = false

	var effect = spawn_effect.instantiate()
	get_parent().add_child(effect)
	effect.global_position = global_position
	effect.start_animation = "disappear"

	await effect.finished
	
func update_animation(direction: float) -> void:
	if direction < 0:
		anim.flip_h = true
	elif direction > 0:
		anim.flip_h = false

	if not is_on_floor():
		if velocity.y < 0:
			play_anim("jump")
		else:
			play_anim("fall")
	else:
		if direction != 0:
			play_anim("run")
		else:
			play_anim("idle")

func play_anim(animation_name: String) -> void:
	if anim.animation != animation_name:
		anim.play(animation_name)

func _resolve_stuck() -> void:
	if tile_map == null:
		return

	if not test_move(global_transform, Vector2.ZERO):
		return

	var push_direction := Vector2.ZERO
	match tile_map.active_side_index:
		0: push_direction = Vector2.DOWN # top shadow
		2: push_direction = Vector2.UP # bottom shadow
		1, 3:
			take_damage() # horizontal unstuck is not allowed
			return
		_:
			return
		
	for i in range(1, 200, 2):
		var offset: Vector2 = push_direction * i
		var target_position: Vector2 = global_position + offset

		if _is_out_of_vertical_map_bounds(target_position):
			take_damage()
			return

		if not test_move(global_transform.translated(offset), Vector2.ZERO):
			global_position = target_position
			if push_direction == Vector2.UP:
				velocity.y = min(velocity.y, -PUSH_FORCE) # upward bump
			elif push_direction == Vector2.DOWN:
				velocity.y = max(velocity.y, PUSH_FORCE)
			break

func _is_out_of_vertical_map_bounds(world_position: Vector2) -> bool:
	var base_layer := tile_map.get_node_or_null("Base") as TileMapLayer
	if base_layer == null:
		return false

	var used_rect: Rect2i = base_layer.get_used_rect()
	if used_rect.size.y <= 0:
		return false

	var local_position: Vector2 = base_layer.to_local(world_position)
	var map_cell: Vector2i = base_layer.local_to_map(local_position)
	var min_y: int = used_rect.position.y
	var max_y: int = used_rect.position.y + used_rect.size.y - 1

	return map_cell.y < min_y or map_cell.y > max_y

func _check_enemy_collision() -> void:
	if is_exiting:
		return

	for i in range(get_slide_collision_count()):
		var collision := get_slide_collision(i)
		var collider := collision.get_collider()
		if collider is Enemy:
			take_damage()
			return

func take_damage() -> void:
	if is_exiting:
		return

	is_exiting = true
	set_physics_process(false)
	velocity = Vector2.ZERO
	anim.visible = false

	var effect = spawn_effect.instantiate()
	get_parent().add_child(effect)
	effect.global_position = global_position
	effect.start_animation = "disappear"

	await effect.finished
	GlobalState.reset_current_level()
	get_tree().reload_current_scene()
