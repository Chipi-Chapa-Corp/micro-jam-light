extends Area2D

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var sfx_exit = $sfxExit

var activated := false

func _ready() -> void:
	anim.play("out_flag")
	await anim.animation_finished
	anim.play("idle")

func _on_body_entered(body: Node) -> void:
	if activated:
		return

	if not body.is_in_group("player"):
		return

	activated = true
	set_deferred("monitoring", false)
	sfx_exit.play()

	if body.has_method("play_disappear_effect"):
		await body.play_disappear_effect()

	GlobalState.end_level()
	var next_scene_path: String = GlobalState.get_current_level_scene()
	if next_scene_path.is_empty():
		get_tree().change_scene_to_file("res://scenes/game-over/scene.tscn")
	else:
		GlobalState.start_level()
		get_tree().change_scene_to_file(next_scene_path)
