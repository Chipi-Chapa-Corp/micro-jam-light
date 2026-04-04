extends Area2D

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var sfx_collect = $sfxCollect

var collected: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	anim.play("idle")

func _on_body_entered(body: Node) -> void:
	if collected:
		return
		
	if body.is_in_group("player"):
		collected = true
		GlobalState.record_star()
		sfx_collect.play()
		anim.hide()

func _on_sfx_collect_finished() -> void:
	queue_free()
