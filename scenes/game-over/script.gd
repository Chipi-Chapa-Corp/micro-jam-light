class_name GameOverScreen
extends Control

const THEMED_BUTTON_SCENE: PackedScene = preload("res://scenes/main-menu/gui-elements/button.tscn")
const LEVEL_SCENES: Dictionary = {
	1: "res://scenes/levels/tutorial/tutorial-level.tscn",
	2: "res://scenes/levels/level1.tscn",
	3: "",
	4: ""
}

@onready var level_rows: VBoxContainer = $MarginContainer/VBoxContainer/LevelRows


func _ready() -> void:
	_populate_level_rows()


func _populate_level_rows() -> void:
	for child: Node in level_rows.get_children():
		child.queue_free()

	for level: int in range(1, GlobalState.LEVEL_COUNT + 1):
		level_rows.add_child(_build_level_row(level))


func _build_level_row(level: int) -> HBoxContainer:
	var row: HBoxContainer = HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var metrics_label: Label = Label.new()
	metrics_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var result: Dictionary = GlobalState.get_level_result(level)
	var stars: int = int(result.get("stars", 0))
	var time_seconds: float = float(result.get("time_seconds", 0.0))
	metrics_label.text = "Level %d   Stars: %d   Time: %s" % [level, stars, _format_time(time_seconds)]

	row.add_child(metrics_label)

	var restart_button: Button = THEMED_BUTTON_SCENE.instantiate() as Button
	var scene_path: String = str(LEVEL_SCENES.get(level, ""))

	if scene_path.is_empty():
		restart_button.text = "Restart L%d (TBD)" % level
		restart_button.disabled = true
	else:
		restart_button.text = "Restart L%d" % level
		restart_button.pressed.connect(_on_restart_level_pressed.bind(level, scene_path))

	row.add_child(restart_button)
	return row


func _on_restart_level_pressed(level: int, scene_path: String) -> void:
	GlobalState.current_level = level
	GlobalState.start_level(level)
	get_tree().change_scene_to_file(scene_path)


func _format_time(time_seconds: float) -> String:
	var total_centiseconds: int = int(round(time_seconds * 100.0))
	var minutes: int = total_centiseconds / 6000
	var seconds: int = (total_centiseconds / 100) % 60
	var centiseconds: int = total_centiseconds % 100
	return "%02d:%02d.%02d" % [minutes, seconds, centiseconds]
