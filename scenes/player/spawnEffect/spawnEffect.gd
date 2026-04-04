extends Node2D

signal finished

@export var start_animation: StringName = "appear"

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	anim.animation_finished.connect(_on_animation_finished)
	anim.play(start_animation)

func _on_animation_finished() -> void:
	finished.emit()
	queue_free()