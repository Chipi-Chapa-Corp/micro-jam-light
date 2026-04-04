extends Control

@onready var bg := $BG
@onready var clouds_back := $CloudsBack
@onready var clouds_front := $CloudsFront

@export var bg_strength := Vector2(8, 4)
@export var back_strength := Vector2(18, 10)
@export var front_strength := Vector2(30, 16)
@export var smooth_speed := 6.0

var bg_base: Vector2
var back_base: Vector2
var front_base: Vector2

func _ready():
	bg_base = bg.position
	back_base = clouds_back.position
	front_base = clouds_front.position

func _process(delta):
	var view_size = get_viewport_rect().size
	var center = view_size * 0.5
	var mouse = get_viewport().get_mouse_position()

	# mouse range -> -1 to 1
	var offset = (mouse - center) / center

	bg.position = bg.position.lerp(bg_base - offset * bg_strength, delta * smooth_speed)
	clouds_back.position = clouds_back.position.lerp(back_base - offset * back_strength, delta * smooth_speed)
	clouds_front.position = clouds_front.position.lerp(front_base - offset * front_strength, delta * smooth_speed)
