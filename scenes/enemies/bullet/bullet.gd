extends Area2D
class_name Bullet

@export var speed: float = 200.0
@export var despawn_margin: float = 32.0
var direction: Vector2 = Vector2.RIGHT

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	position += direction * speed * delta

	var visible_rect := get_viewport().get_visible_rect()
	var screen_pos := get_viewport().get_canvas_transform() * global_position
	var expanded_rect := visible_rect.grow(despawn_margin)
	if not expanded_rect.has_point(screen_pos):
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):  # Assume player is in "player" group
		body.take_damage()  # Add take_damage method to player.gd
		queue_free()
