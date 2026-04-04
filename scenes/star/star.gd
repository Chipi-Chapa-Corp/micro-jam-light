extends Area2D

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var sfx_collect = $sfxCollect

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	anim.play("idle")

func _on_body_entered(body: Node) -> void:
	print("gay")
	if body.is_in_group("player"):
		GlobalState.record_star()
		sfx_collect.play()
		anim.hide()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_sfx_collect_finished() -> void:
	queue_free()
