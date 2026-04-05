extends Control

@export_multiline var hint_text := "Put your hint text here"

@export var hover_icon: Control
@export var bubble: Control
@export var label: Label

var bubble_pos: Vector2
var tween: Tween
var pulse_tween: Tween

func _ready() -> void:
	label.text = hint_text
	bubble_pos = bubble.position
	bubble.visible = false
	bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE

	hover_icon.mouse_entered.connect(_on_hover_entered)
	hover_icon.mouse_exited.connect(_on_hover_exited)

	start_pulse()

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
