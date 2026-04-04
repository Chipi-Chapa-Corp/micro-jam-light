extends Node2D

@export var base_layer: TileMapLayer
@export var top_layer: TileMapLayer
@export var left_layer: TileMapLayer
@export var bottom_layer: TileMapLayer
@export var right_layer: TileMapLayer

var _side_layers: Array[TileMapLayer] = []
var active_side_index := 0


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

	active_side_index = 0
	_apply_layer_state()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F:
			_step_side_layer(1)
		elif event.keycode == KEY_E:
			_step_side_layer(-1)


func _step_side_layer(direction: int) -> void:
	if _side_layers.is_empty():
		return

	active_side_index = posmod(active_side_index + direction, _side_layers.size())
	_apply_layer_state()


func _apply_layer_state() -> void:
	base_layer.enabled = true

	for i in range(_side_layers.size()):
		_side_layers[i].enabled = (i == active_side_index)


func _add_side_layer(layer: TileMapLayer, layer_name: String) -> void:
	if layer == null:
		push_warning("tile-control.gd: '%s_layer' is not assigned in the inspector." % layer_name)
		set_process_unhandled_input(false)
		return

	_side_layers.append(layer)
