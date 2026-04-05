extends Control

@export_multiline var hint_text := "Put your hint text here"
@export var dynamic_tutorial_mode := false

@export var hover_icon: Control
@export var bubble: Control
@export var label: Label

const TUTORIAL_HINTS := [
	"Use A and D to move",
	"Use W or Space to jump",
	"There is only One Light Source which creates Shadows. Control its position using Arrow Keys",
	"Shadows are Solid, you can stand on them or make them push you up. Too easy? Try collecting all the Stars.",
]

var bubble_pos: Vector2
var tween: Tween
var pulse_tween: Tween
var tutorial_step := 0

func _ready() -> void:
	label.text = hint_text
	bubble_pos = bubble.position
	bubble.visible = false
	bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if dynamic_tutorial_mode:
		set_process(true)
		hover_icon.visible = true
		_set_tutorial_step(0)
		_show_bubble_immediately()
		start_pulse()
		return

	set_process(false)
	hover_icon.mouse_entered.connect(_on_hover_entered)
	hover_icon.mouse_exited.connect(_on_hover_exited)

	start_pulse()


func _process(_delta: float) -> void:
	if not dynamic_tutorial_mode:
		return

	if tutorial_step == 0 and _is_move_pressed():
		_advance_tutorial_step()
	elif tutorial_step == 1 and Input.is_action_just_pressed("jump"):
		_advance_tutorial_step()
	elif tutorial_step == 2 and _is_shadow_control_pressed():
		_advance_tutorial_step()

func _on_hover_entered() -> void:
	open_hint()

func _on_hover_exited() -> void:
	close_hint()

func open_hint() -> void:
	if tween:
		tween.kill()

	bubble.visible = true
	bubble.position = bubble_pos + Vector2(0, 6)
	bubble.modulate.a = 0.0

	tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(bubble, "position", bubble_pos, 0.15)
	tween.tween_property(bubble, "modulate:a", 1.0, 0.15)

func close_hint() -> void:
	if tween:
		tween.kill()

	tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(bubble, "position", bubble_pos + Vector2(0, 6), 0.10)
	tween.tween_property(bubble, "modulate:a", 0.0, 0.10)

	tween.finished.connect(func():
		bubble.visible = false
		bubble.position = bubble_pos
	)

func start_pulse() -> void:
	if pulse_tween:
		pulse_tween.kill()

	hover_icon.scale = Vector2.ONE
	pulse_tween = create_tween()
	pulse_tween.set_loops()
	pulse_tween.tween_property(hover_icon, "scale", Vector2(1.06, 1.06), 0.45)
	pulse_tween.tween_property(hover_icon, "scale", Vector2.ONE, 0.45)

func stop_pulse() -> void:
	if pulse_tween:
		pulse_tween.kill()
	hover_icon.scale = Vector2.ONE


func _set_tutorial_step(step: int) -> void:
	tutorial_step = clampi(step, 0, TUTORIAL_HINTS.size() - 1)
	label.text = TUTORIAL_HINTS[tutorial_step]
	if dynamic_tutorial_mode:
		_show_bubble_immediately()


func _advance_tutorial_step() -> void:
	if tutorial_step >= TUTORIAL_HINTS.size() - 1:
		set_process(false)
		return

	_set_tutorial_step(tutorial_step + 1)
	if tutorial_step >= TUTORIAL_HINTS.size() - 1:
		set_process(false)


func _is_move_pressed() -> bool:
	return Input.is_action_just_pressed("move_left") or Input.is_action_just_pressed("move_right")


func _is_shadow_control_pressed() -> bool:
	return (
		Input.is_action_just_pressed("shadow_left")
		or Input.is_action_just_pressed("shadow_right")
		or Input.is_action_just_pressed("shadow_up")
		or Input.is_action_just_pressed("shadow_down")
	)


func _show_bubble_immediately() -> void:
	if tween:
		tween.kill()
	bubble.visible = true
	bubble.position = bubble_pos
	bubble.modulate.a = 1.0
