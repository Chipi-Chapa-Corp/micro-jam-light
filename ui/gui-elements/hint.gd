extends CanvasLayer

@export_multiline var hint_text := "Put your hint text here"
@export var dynamic_tutorial_mode := false
@export var auto_show_static_hint := false

const TUTORIAL_HINTS := [
	"Use A and D to move",
	"Use W or Space to jump",
	"There is One Light Source which creates Shadows. Control its position using Arrow Keys",
	"Shadows are Solid, you can stand on them or make them push you up. Too easy? Try collecting all the Stars.",
]

@onready var icon: Control = $CenterContainer/MarginContainer/ContentVBox/IconCenter/Icon
@onready var label: Label = $CenterContainer/MarginContainer/ContentVBox/BubblePanel/BubbleMargin/Label
@onready var ok_button: Button = $CenterContainer/MarginContainer/ContentVBox/OkButton

var pulse_tween: Tween
var tutorial_step := 0
var _is_modal_open := false
var _paused_for_hint := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

	if dynamic_tutorial_mode:
		set_process(true)
		_show_tutorial_step(0)
		return

	if auto_show_static_hint:
		set_process(false)
		_show_static_hint()
		return

	set_process(false)


func _exit_tree() -> void:
	_resume_game_for_hint()


func _process(_delta: float) -> void:
	if not dynamic_tutorial_mode or _is_modal_open:
		return

	if tutorial_step == 0 and _is_move_pressed():
		_show_tutorial_step(1)
	elif tutorial_step == 1 and Input.is_action_just_pressed("jump"):
		_show_tutorial_step(2)
	elif tutorial_step == 2 and _is_shadow_control_pressed():
		_show_tutorial_step(3)


func _show_static_hint() -> void:
	label.text = hint_text
	_show_modal()


func _show_tutorial_step(step: int) -> void:
	tutorial_step = clampi(step, 0, TUTORIAL_HINTS.size() - 1)
	label.text = TUTORIAL_HINTS[tutorial_step]
	_show_modal()


func _show_modal() -> void:
	visible = true
	_is_modal_open = true
	_pause_game_for_hint()
	start_pulse()
	if is_instance_valid(ok_button):
		ok_button.grab_focus()


func _hide_modal() -> void:
	_is_modal_open = false
	stop_pulse()
	visible = false
	_resume_game_for_hint()


func _pause_game_for_hint() -> void:
	if get_tree().paused:
		_paused_for_hint = false
		return

	get_tree().paused = true
	_paused_for_hint = true


func _resume_game_for_hint() -> void:
	if not _paused_for_hint:
		return

	_paused_for_hint = false
	get_tree().paused = false


func _on_ok_button_pressed() -> void:
	AudioManager.play_ui_button_click()
	_hide_modal()

	if dynamic_tutorial_mode and tutorial_step >= TUTORIAL_HINTS.size() - 1:
		set_process(false)


func start_pulse() -> void:
	if pulse_tween:
		pulse_tween.kill()

	icon.scale = Vector2.ONE
	pulse_tween = create_tween()
	pulse_tween.set_loops()
	pulse_tween.tween_property(icon, "scale", Vector2(1.06, 1.06), 0.45)
	pulse_tween.tween_property(icon, "scale", Vector2.ONE, 0.45)


func stop_pulse() -> void:
	if pulse_tween:
		pulse_tween.kill()
	icon.scale = Vector2.ONE


func _is_move_pressed() -> bool:
	return Input.is_action_just_pressed("move_left") or Input.is_action_just_pressed("move_right")


func _is_shadow_control_pressed() -> bool:
	return (
		Input.is_action_just_pressed("shadow_left")
		or Input.is_action_just_pressed("shadow_right")
		or Input.is_action_just_pressed("shadow_up")
		or Input.is_action_just_pressed("shadow_down")
	)
