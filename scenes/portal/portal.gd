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
	monitoring = false
	sfx_exit.play()

	if body.has_method("play_disappear_effect"):
		await body.play_disappear_effect()

	GlobalState.end_level()
