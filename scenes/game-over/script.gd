class_name GameOverScreen
extends Control

const REPLAY_BUTTON_SCENE: PackedScene = preload("res://scenes/main-menu/gui-elements/replay-button.tscn")
const LEVEL_SCENES: Dictionary = {
	1: "res://scenes/levels/tutorial/tutorial-level.tscn",
	2: "res://scenes/levels/level1.tscn",
	3: "",
	4: ""
}
const TOOLTIP_BG_COLOR: Color = Color(0.5137255, 0.10980392, 0.3254902, 0.8)

@onready var level_rows: VBoxContainer = $MarginContainer/VBoxContainer/LevelRows
@onready var replay_button_tooltip_theme: Theme = _create_replay_button_tooltip_theme()


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
	row.add_theme_constant_override("separation", 128)

	var metrics_label: Label = Label.new()
	metrics_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	metrics_label.theme_type_variation = &"HeaderMedium"
	metrics_label.add_theme_color_override("font_outline_color", Color(0.5137255, 0.10980392, 0.3254902, 1.0))
	metrics_label.add_theme_constant_override("outline_size", 20)

	var result: Dictionary = GlobalState.get_level_result(level)
	var stars: int = int(result.get("stars", 0))
	var time_seconds: float = float(result.get("time_seconds", 0.0))
	metrics_label.text = "Level %d   Stars: %d   Time: %s" % [level, stars, _format_time(time_seconds)]

	row.add_child(metrics_label)

	var restart_button: Button = REPLAY_BUTTON_SCENE.instantiate() as Button
	restart_button.custom_minimum_size = Vector2(50.0, 50.0)
	restart_button.expand_icon = true
	restart_button.theme = replay_button_tooltip_theme
	restart_button.tooltip_text = "Replay Level %d" % level
	var scene_path: String = str(LEVEL_SCENES.get(level, ""))

	if scene_path.is_empty():
		restart_button.disabled = true
	else:
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


func _create_replay_button_tooltip_theme() -> Theme:
	var tooltip_theme: Theme = Theme.new()
	tooltip_theme.set_font_size("font_size", "TooltipLabel", 20)

	var tooltip_panel_style: StyleBoxFlat = StyleBoxFlat.new()
	tooltip_panel_style.bg_color = TOOLTIP_BG_COLOR
	tooltip_theme.set_stylebox("panel", "TooltipPanel", tooltip_panel_style)

	return tooltip_theme
