extends Control

@onready var start_scene: PackedScene = preload("res://scenes/levels/tutorial/tutorial-level.tscn")

func _on_start_pressed() -> void:
	GlobalState.start_level(1)
	get_tree().change_scene_to_packed(start_scene)


func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/credits/scene.tscn")
