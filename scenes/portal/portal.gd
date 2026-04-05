extends Area2D

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var sfx_exit = $sfxExit

const GAME_OVER_SCENE_PATH := "res://ui/screens/game-over/scene.tscn"
const BONUS_FINISH_SCENE_PATH := "res://scenes/bonus-finish/scene.tscn"
const MAIN_CAMPAIGN_END_LEVEL := 5
const BONUS_LEVEL_NUMBER := 6

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

	var completed_level: int = GlobalState.current_level
	GlobalState.end_level()
	if completed_level == BONUS_LEVEL_NUMBER:
		get_tree().change_scene_to_file(BONUS_FINISH_SCENE_PATH)
		return

	var next_scene_path: String = GlobalState.get_current_level_scene()
	var should_show_game_over: bool = completed_level == MAIN_CAMPAIGN_END_LEVEL
	if should_show_game_over or next_scene_path.is_empty():
		get_tree().change_scene_to_file(GAME_OVER_SCENE_PATH)
	else:
		GlobalState.start_level()
		get_tree().change_scene_to_file(next_scene_path)
