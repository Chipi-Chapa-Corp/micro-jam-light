extends Control

func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://ui/screens/main-menu/scene.tscn")
