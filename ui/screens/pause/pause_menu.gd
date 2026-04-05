extends CanvasLayer
const MAIN_MENU_SCENE: PackedScene = preload("res://ui/screens/main-menu/scene.tscn")

@onready var resume_button: Button = %ResumeButton

var _is_open: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if _is_open:
			resume_game()
		else:
			pause_game()
		get_viewport().set_input_as_handled()


func pause_game() -> void:
	_is_open = true
	visible = true
	get_tree().paused = true
	resume_button.grab_focus()


func resume_game() -> void:
	get_tree().paused = false
	visible = false
	_is_open = false


func _on_resume_button_pressed() -> void:
	resume_game()


func _on_main_menu_button_pressed() -> void:
	get_tree().paused = false
	visible = false
	_is_open = false
	get_tree().change_scene_to_packed(MAIN_MENU_SCENE)


func _on_quit_button_pressed() -> void:
	get_tree().paused = false
	get_tree().quit()
