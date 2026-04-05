extends CanvasLayer

@export_multiline var hint_text := "Put your hint text here"
@export var dynamic_tutorial_mode := false
@export var auto_show_static_hint := false
@export var show_only_once_per_level := true
@export var show_as_modal := false
@export_range(0.0, 30.0, 0.1, "or_greater") var hover_intro_seconds := 5.0
@export var place_bottom_right := false

const TUTORIAL_HINTS := [
	"Use A and D to move",
	"Use W or Space to jump",
	"There is One Light Source which creates Shadows. Control its position using Arrow Keys",
	"Shadows are Solid, you can stand on them or make them push you up. Too easy? Try collecting all the Stars.",
]

@onready var modal_dim: Control = $ModalDim
@onready var modal_container: Control = $ModalCenterContainer
@onready var modal_icon: Control = $ModalCenterContainer/MarginContainer/ContentVBox/IconCenter/Icon
@onready var modal_label: Label = $ModalCenterContainer/MarginContainer/ContentVBox/BubblePanel/BubbleMargin/Label
@onready var ok_button: Button = $ModalCenterContainer/MarginContainer/ContentVBox/OkButton

@onready var hover_root: Control = $HoverRoot
@onready var hover_icon: Control = $HoverRoot/HoverIcon
@onready var hover_bubble: Control = $HoverRoot/HoverBubble
@onready var hover_label: Label = $HoverRoot/HoverBubble/BubblePanel/BubbleMargin/Label

var pulse_tween: Tween
var _pulse_target: Control
var tutorial_step := 0
var _is_modal_open := false
var _paused_for_hint := false
var _hover_intro_active := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_apply_hover_corner()
	_configure_hover_events()
	_hide_everything()

	if dynamic_tutorial_mode:
		if _should_skip_auto_hint():
			return
		_mark_auto_hint_seen()
		set_process(true)
		_show_tutorial_step(0)
		return

	if auto_show_static_hint:
		if _should_skip_auto_hint():
			return
		_mark_auto_hint_seen()
		set_process(false)
		if show_as_modal:
			_show_static_modal_hint()
		else:
			_show_static_hover_hint()
		return

	set_process(false)
	_show_hover_idle()


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


func _show_static_modal_hint() -> void:
	modal_label.text = hint_text
	_show_modal()


func _show_tutorial_step(step: int) -> void:
	tutorial_step = clampi(step, 0, TUTORIAL_HINTS.size() - 1)
	modal_label.text = TUTORIAL_HINTS[tutorial_step]
	_show_modal()


func _show_modal() -> void:
	visible = true
	modal_dim.visible = true
	modal_container.visible = true
	hover_root.visible = false
	_is_modal_open = true
	_hover_intro_active = false
	_pause_game_for_hint()
	start_pulse(modal_icon)
	if is_instance_valid(ok_button):
		ok_button.grab_focus()


func _hide_modal() -> void:
	_is_modal_open = false
	stop_pulse()
	modal_dim.visible = false
	modal_container.visible = false
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


func _show_static_hover_hint() -> void:
	_show_hover_idle()
	hover_label.text = hint_text
	_hover_intro_active = hover_intro_seconds > 0.0
	_open_hover_bubble()
	if _hover_intro_active:
		var intro_timer := get_tree().create_timer(hover_intro_seconds)
		intro_timer.timeout.connect(_on_hover_intro_timeout, CONNECT_ONE_SHOT)


func _show_hover_idle() -> void:
	visible = true
	hover_root.visible = true
	modal_dim.visible = false
	modal_container.visible = false
	hover_label.text = hint_text
	_close_hover_bubble()
	start_pulse(hover_icon)


func _apply_hover_corner() -> void:
	if not place_bottom_right:
		return

	hover_root.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT, false)
	# Keep the original icon-left / bubble-right layout, but pin the whole hint to bottom-right.
	hover_root.offset_left = -556.0
	hover_root.offset_top = -86.0
	hover_root.offset_right = -16.0
	hover_root.offset_bottom = -16.0

	hover_icon.offset_left = 0.0
	hover_icon.offset_top = 0.0
	hover_icon.offset_right = 40.0
	hover_icon.offset_bottom = 40.0

	hover_bubble.offset_left = 41.0
	hover_bubble.offset_top = 7.0
	hover_bubble.offset_right = 81.0
	hover_bubble.offset_bottom = 47.0


func _open_hover_bubble() -> void:
	hover_bubble.visible = true
	hover_bubble.modulate.a = 1.0


func _close_hover_bubble() -> void:
	hover_bubble.visible = false
	hover_bubble.modulate.a = 0.0


func _on_hover_intro_timeout() -> void:
	if not _hover_intro_active:
		return

	_hover_intro_active = false
	_close_hover_bubble()


func _on_hover_icon_entered() -> void:
	if _is_modal_open or _hover_intro_active:
		return
	_open_hover_bubble()


func _on_hover_icon_exited() -> void:
	if _is_modal_open or _hover_intro_active:
		return
	_close_hover_bubble()


func _on_hover_ui_input(event: InputEvent) -> void:
	if not _hover_intro_active:
		return
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT:
			_hover_intro_active = false
			_close_hover_bubble()
			get_viewport().set_input_as_handled()


func _configure_hover_events() -> void:
	hover_icon.mouse_entered.connect(_on_hover_icon_entered)
	hover_icon.mouse_exited.connect(_on_hover_icon_exited)
	hover_icon.gui_input.connect(_on_hover_ui_input)
	hover_bubble.gui_input.connect(_on_hover_ui_input)


func _hide_everything() -> void:
	visible = false
	modal_dim.visible = false
	modal_container.visible = false
	hover_root.visible = false


func start_pulse(target: Control) -> void:
	if pulse_tween:
		pulse_tween.kill()
	if is_instance_valid(_pulse_target):
		_pulse_target.scale = Vector2.ONE

	_pulse_target = target
	_pulse_target.scale = Vector2.ONE
	pulse_tween = create_tween()
	pulse_tween.set_loops()
	pulse_tween.tween_property(_pulse_target, "scale", Vector2(1.06, 1.06), 0.45)
	pulse_tween.tween_property(_pulse_target, "scale", Vector2.ONE, 0.45)


func stop_pulse() -> void:
	if pulse_tween:
		pulse_tween.kill()
	if is_instance_valid(_pulse_target):
		_pulse_target.scale = Vector2.ONE


func _is_move_pressed() -> bool:
	return Input.is_action_just_pressed("move_left") or Input.is_action_just_pressed("move_right")


func _is_shadow_control_pressed() -> bool:
	return (
		Input.is_action_just_pressed("shadow_left")
		or Input.is_action_just_pressed("shadow_right")
		or Input.is_action_just_pressed("shadow_up")
		or Input.is_action_just_pressed("shadow_down")
	)


func _should_skip_auto_hint() -> bool:
	if not show_only_once_per_level:
		return false

	return GlobalState.has_seen_hint()


func _mark_auto_hint_seen() -> void:
	if not show_only_once_per_level:
		return

	GlobalState.mark_hint_seen()
