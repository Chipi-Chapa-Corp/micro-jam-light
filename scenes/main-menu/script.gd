extends Control

@onready var start_scene: PackedScene = preload("res://scenes/levels/tutorial/tutorial-level.tscn")

func _on_start_pressed() -> void:
	get_tree().change_scene_to_packed(start_scene)


func _on_button_pressed() -> void:
	pass # Replace with function body.
