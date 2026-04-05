extends Control

func _on_button_pressed() -> void:
	AudioManager.play_ui_button_click()
	get_tree().change_scene_to_file("res://ui/screens/main-menu/scene.tscn")
