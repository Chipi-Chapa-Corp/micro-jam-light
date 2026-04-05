class_name BonusFinishScreen
extends Control

const BONUS_LEVEL_NUMBER: int = 6
const MAIN_MENU_SCENE: PackedScene = preload("res://ui/screens/main-menu/scene.tscn")

@onready var subtitle_label: Label = $MarginContainer/VBoxContainer/Subtitle

func _ready() -> void:
	_update_bonus_time()


func _update_bonus_time() -> void:
	var bonus_time_seconds: float = GlobalState.get_level_time_seconds(BONUS_LEVEL_NUMBER)
	subtitle_label.text = "Total time: %s" % _format_time(bonus_time_seconds)


func _on_main_menu_pressed() -> void:
	AudioManager.play_ui_button_click()
	get_tree().change_scene_to_packed(MAIN_MENU_SCENE)


func _format_time(time_seconds: float) -> String:
	var total_centiseconds: int = int(round(time_seconds * 100.0))
	var minutes: int = floori(total_centiseconds / 6000.0)
	var seconds: int = floori(total_centiseconds / 100.0) % 60
	var centiseconds: int = total_centiseconds % 100
	return "%02d:%02d.%02d" % [minutes, seconds, centiseconds]
