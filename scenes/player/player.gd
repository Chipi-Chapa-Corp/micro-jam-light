extends CharacterBody2D


const SPEED = 300.0
const JUMP_VELOCITY = -400.0
const PUSH_FORCE = 100.0
const STEP_INTERVAL = 0.2
const LAND_STEP_DELAY = 0.15

@onready var sfx_step = $sfx_step
@onready var sfx_fall_after_jump = $sfxFallAfterJump
@onready var sfx_jump = $sfxJump

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

var was_on_floor = false
var step_timer = 0.0
var step_delay_timer = 0.0
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

func play_anim(name: String) -> void:
	if anim.animation != name:
		anim.play(name)

func _resolve_stuck() -> void:
	if not test_move(global_transform, Vector2.ZERO):
		return
		
	var tile_control = get_parent()
	if not tile_control or not "active_side_index" in tile_control:
		return
		
	var push_direction := Vector2.ZERO
	match tile_control.active_side_index:
		0: push_direction = Vector2.DOWN # top shadow
		1: push_direction = Vector2.RIGHT # left shadow
		2: push_direction = Vector2.UP # bottom shadow
		3: push_direction = Vector2.LEFT # right shadow
		
	for i in range(1, 200, 2):
		var offset = push_direction * i
		if not test_move(global_transform.translated(offset), Vector2.ZERO):
			global_position += offset
			if push_direction == Vector2.UP:
				velocity.y = min(velocity.y, -PUSH_FORCE) # upward bump
			elif push_direction == Vector2.DOWN:
				velocity.y = max(velocity.y, PUSH_FORCE)
			elif push_direction == Vector2.LEFT:
				velocity.x = min(velocity.x, -PUSH_FORCE)
			elif push_direction == Vector2.RIGHT:
				velocity.x = max(velocity.x, PUSH_FORCE)
			break
