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
var _layer_shadow_materials: Array = []

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
	_cache_layer_shadow_materials()

	# Initialize all side layers as disabled in-place.
	for i in range(_side_layers.size()):
		var layer = _side_layers[i]
		layer.enabled = false
		layer.position = Vector2.ZERO

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
		
		if i == active_side_index:
			layer.position = Vector2.ZERO
			layer.enabled = true

			if instant:
				_set_layer_cast_progress(1.0, i)
			else:
				# Reveal in-place via shader progress; no positional offset.
				_set_layer_cast_progress(0.0, i)
				
				_current_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
				_current_tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
				_current_tween.tween_method(Callable(self, "_set_layer_cast_progress").bind(i), 0.0, 1.0, transition_duration)
		else:
			# Instantly hide and disable all other layers
			layer.enabled = false
			layer.position = Vector2.ZERO


func _cache_layer_shadow_materials() -> void:
	_layer_shadow_materials.clear()

	for layer in _side_layers:
		var materials: Array = []
		var seen := {}

		if layer.tile_set == null:
			_layer_shadow_materials.append(materials)
			continue

		for cell in layer.get_used_cells():
			var source_id := layer.get_cell_source_id(cell)
			if source_id == -1:
				continue

			var tile_source := layer.tile_set.get_source(source_id)
			if tile_source is TileSetAtlasSource:
				var atlas_source := tile_source as TileSetAtlasSource
				var atlas_coords := layer.get_cell_atlas_coords(cell)
				var alternative := layer.get_cell_alternative_tile(cell)
				var tile_data := atlas_source.get_tile_data(atlas_coords, alternative)
				if tile_data == null:
					continue

				var tile_material := tile_data.material
				if tile_material is ShaderMaterial:
					var shader_material := tile_material as ShaderMaterial
					var mat_id := shader_material.get_instance_id()
					if not seen.has(mat_id):
						seen[mat_id] = true
						materials.append(shader_material)

		_layer_shadow_materials.append(materials)


func _set_layer_cast_progress(progress: float, layer_index: int) -> void:
	if layer_index < 0 or layer_index >= _layer_shadow_materials.size():
		return

	var clamped_progress := clampf(progress, 0.0, 1.0)
	for shader_mat in _layer_shadow_materials[layer_index]:
		if shader_mat is ShaderMaterial:
			(shader_mat as ShaderMaterial).set_shader_parameter("cast_progress", clamped_progress)


func _add_side_layer(layer: TileMapLayer, layer_name: String) -> void:
	if layer == null:
		push_warning("tile-control.gd: '%s_layer' is not assigned in the inspector." % layer_name)
		set_process_unhandled_input(false)
		return

	_side_layers.append(layer)
