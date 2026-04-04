extends CharacterBody2D


const SPEED = 300.0
const JUMP_VELOCITY = -400.0
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
	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		sfx_jump.play()

	var direction := Input.get_axis("ui_left", "ui_right")
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
