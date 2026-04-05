extends Node2D

@export var base_layer: TileMapLayer
@export var top_layer: TileMapLayer
@export var left_layer: TileMapLayer
@export var bottom_layer: TileMapLayer
@export var right_layer: TileMapLayer

@export var sfx_switch: AudioStreamPlayer
@export var transition_duration: float = 0.2

var _side_layers: Array[TileMapLayer] = []
var active_side_index := 0
var previous_side_index := -1
var _current_tween: Tween

func _ready() -> void:
	if base_layer == null:
		push_error("tile-control.gd: 'base_layer' is not assigned in the inspector.")
		set_process_unhandled_input(false)
		return

	_side_layers.clear()
	_add_side_layer(top_layer, "top")
	_add_side_layer(left_layer, "left")
	_add_side_layer(bottom_layer, "bottom")
	_add_side_layer(right_layer, "right")
	
	base_layer.enabled = true

	# Initialize all side layers as disabled and offset
	for i in range(_side_layers.size()):
		var layer = _side_layers[i]
		layer.enabled = false
		layer.position = _get_hidden_offset(i)

	active_side_index = 0
	_apply_layer_state(true)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("shadow_down"):
		_set_active_side(0)
	elif event.is_action_pressed("shadow_right"):
		_set_active_side(1)
	elif event.is_action_pressed("shadow_up"):
		_set_active_side(2)
	elif event.is_action_pressed("shadow_left"):
		_set_active_side(3)


func _set_active_side(index: int) -> void:
	if index >= 0 and index < _side_layers.size() and index != active_side_index:
		previous_side_index = active_side_index
		active_side_index = index
		_apply_layer_state()
		
		if sfx_switch:
			sfx_switch.play()


func _apply_layer_state(instant: bool = false) -> void:
	if _current_tween:
		_current_tween.kill()
	
	for i in range(_side_layers.size()):
		var layer = _side_layers[i]
		var hidden_pos = _get_hidden_offset(i)
		
		if i == active_side_index:
			if instant:
				layer.position = Vector2.ZERO
				layer.enabled = true
			else:
				# Always start from hidden position to ensure sync
				layer.position = hidden_pos
				layer.enabled = true
				
				_current_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
				_current_tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
				_current_tween.tween_property(layer, "position", Vector2.ZERO, transition_duration)
		else:
			# Instantly hide and disable all other layers
			layer.enabled = false
			layer.position = hidden_pos


func _get_hidden_offset(index: int) -> Vector2:
	# Hidden offset should be roughly the length of the shadow.
	# From shadow.tres, max_tiles is 3, so 3 * 32 = 96.
	const OFFSET_VAL = 96.0
	match index:
		0: return Vector2(0, -OFFSET_VAL) # Top shadow grows DOWN
		1: return Vector2(-OFFSET_VAL, 0) # Left shadow grows RIGHT
		2: return Vector2(0, OFFSET_VAL)  # Bottom shadow grows UP
		3: return Vector2(OFFSET_VAL, 0)  # Right shadow grows LEFT
	return Vector2.ZERO


func _add_side_layer(layer: TileMapLayer, layer_name: String) -> void:
	if layer == null:
		push_warning("tile-control.gd: '%s_layer' is not assigned in the inspector." % layer_name)
		set_process_unhandled_input(false)
		return

	_side_layers.append(layer)
