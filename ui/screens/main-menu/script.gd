extends Control

@onready var start_scene: PackedScene = preload("res://scenes/levels/tutorial/tutorial-level.tscn")

func _on_start_pressed() -> void:
	GlobalState.start_new_run()
	get_tree().change_scene_to_packed(start_scene)


func _on_button_pressed() -> void:
	AudioManager.play_ui_button_click()
	get_tree().change_scene_to_file("res://ui/screens/credits/scene.tscn")
