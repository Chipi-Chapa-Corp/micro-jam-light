extends Node2D

signal finished

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	anim.animation_finished.connect(_on_animation_finished)
	anim.play("appear")

func _on_animation_finished() -> void:
	finished.emit()
	queue_free()
