extends Control

@export var player: Node2D
@export var world_center := Vector2.ZERO
@export var pad := 48.0

@onready var sky: TextureRect = $Sky
@onready var clouds_back: TextureRect = $CloudsBack
@onready var clouds_front: TextureRect = $CloudsFront

func _ready():
	# root control has no Control parent, so give it an explicit rect
	anchor_left = 0.0
	anchor_top = 0.0
	anchor_right = 0.0
	anchor_bottom = 0.0

	position = Vector2.ZERO
	size = get_viewport_rect().size

	get_viewport().size_changed.connect(_on_viewport_size_changed)

	_setup_layer(sky)
	_setup_layer(clouds_back)
	_setup_layer(clouds_front)

func _on_viewport_size_changed():
	size = get_viewport_rect().size

func _setup_layer(layer: TextureRect):
	layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.offset_left = -pad
	layer.offset_top = -pad
	layer.offset_right = pad
	layer.offset_bottom = pad

func _process(_delta):
	if player == null:
		return

	var d := player.global_position - world_center

	sky.position = Vector2(-d.x * 0.01, -d.y * 0.005)
	clouds_back.position = Vector2(-d.x * 0.03, -d.y * 0.01)
	clouds_front.position = Vector2(-d.x * 0.06, -d.y * 0.02)
