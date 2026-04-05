extends Node2D

@export var base_layer: TileMapLayer
@export var top_layer: TileMapLayer
@export var left_layer: TileMapLayer
@export var bottom_layer: TileMapLayer
@export var right_layer: TileMapLayer

@export var sfx_switch: AudioStreamPlayer
@export var transition_duration: float = 0.2
@export var platform_light_material: Material

const DEFAULT_PLATFORM_LIGHT_MATERIAL_PATH := "res://scenes/levels/materials/platform_top_light.tres"

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
	_setup_base_light_material()
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

	_update_base_light_direction()
	
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
				_current_tween.tween_method(Callable(self , "_set_layer_cast_progress").bind(i), 0.0, 1.0, transition_duration)
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


func _setup_base_light_material() -> void:
	var shader_material := base_layer.material as ShaderMaterial

	if shader_material == null or not _shader_has_uniform(shader_material.shader, "top_tint"):
		var material_to_use: Material = platform_light_material
		if material_to_use == null:
			material_to_use = load(DEFAULT_PLATFORM_LIGHT_MATERIAL_PATH) as Material

		var light_material := material_to_use as ShaderMaterial
		if light_material == null:
			push_warning("tile-control.gd: Could not load platform top-light material.")
			return

		shader_material = light_material.duplicate() as ShaderMaterial
		base_layer.material = shader_material

	var tile_size := 32.0
	if base_layer.tile_set != null:
		tile_size = float(base_layer.tile_set.tile_size.y)

	shader_material.set_shader_parameter("tile_size", tile_size)
	shader_material.set_shader_parameter("grid_origin_y", base_layer.global_position.y)
	shader_material.set_shader_parameter("grid_origin_x", base_layer.global_position.x)
	shader_material.set_shader_parameter("light_position", _light_position_from_active_side())

	var edge_mask := _build_edge_mask(base_layer, tile_size)
	if edge_mask.is_empty():
		shader_material.set_shader_parameter("edge_mask_enabled", 0.0)
	else:
		shader_material.set_shader_parameter("edge_mask_enabled", 1.0)
		shader_material.set_shader_parameter("edge_mask_tex", edge_mask.texture)
		shader_material.set_shader_parameter("edge_mask_origin_x", edge_mask.origin_x)
		shader_material.set_shader_parameter("edge_mask_origin_y", edge_mask.origin_y)
		shader_material.set_shader_parameter("edge_mask_columns", edge_mask.columns)
		shader_material.set_shader_parameter("edge_mask_rows", edge_mask.rows)


func _update_base_light_direction() -> void:
	var shader_material := base_layer.material as ShaderMaterial
	if shader_material == null:
		return
	if not _shader_has_uniform(shader_material.shader, "light_position"):
		return

	shader_material.set_shader_parameter("light_position", _light_position_from_active_side())


func _shader_has_uniform(shader: Shader, uniform_name: StringName) -> bool:
	if shader == null:
		return false

	for uniform_data in shader.get_shader_uniform_list():
		if StringName(uniform_data.get("name", "")) == uniform_name:
			return true

	return false


func _light_position_from_active_side() -> int:
	# active_side_index order is [top, left, bottom, right].
	# shader light_position order is [top=0, bottom=1, left=2, right=3].
	match active_side_index:
		0: return 0
		1: return 2
		2: return 1
		3: return 3
		_: return 0


func _build_edge_mask(layer: TileMapLayer, tile_size: float) -> Dictionary:
	var used_cells := layer.get_used_cells()
	if used_cells.is_empty():
		return {}

	var min_cell_x := used_cells[0].x
	var max_cell_x := used_cells[0].x
	var min_cell_y := used_cells[0].y
	var max_cell_y := used_cells[0].y
	var occupied := {}

	for cell in used_cells:
		min_cell_x = min(min_cell_x, cell.x)
		max_cell_x = max(max_cell_x, cell.x)
		min_cell_y = min(min_cell_y, cell.y)
		max_cell_y = max(max_cell_y, cell.y)
		occupied[Vector2i(cell.x, cell.y)] = true

	var columns := max_cell_x - min_cell_x + 1
	var rows := max_cell_y - min_cell_y + 1
	var mask_image := Image.create(columns, rows, false, Image.FORMAT_RGBA8)

	for cell in used_cells:
		var left_edge := not occupied.has(Vector2i(cell.x - 1, cell.y))
		var right_edge := not occupied.has(Vector2i(cell.x + 1, cell.y))
		var top_edge := not occupied.has(Vector2i(cell.x, cell.y - 1))
		var bottom_edge := not occupied.has(Vector2i(cell.x, cell.y + 1))
		var image_x := cell.x - min_cell_x
		var image_y := cell.y - min_cell_y
		mask_image.set_pixel(
			image_x,
			image_y,
			Color(
				1.0 if left_edge else 0.0,
				1.0 if top_edge else 0.0,
				1.0 if bottom_edge else 0.0,
				1.0 if right_edge else 0.0
			)
		)

	var mask_texture := ImageTexture.create_from_image(mask_image)
	if mask_texture == null:
		return {}

	var origin_x := layer.global_position.x + float(min_cell_x) * tile_size
	var origin_y := layer.global_position.y + float(min_cell_y) * tile_size
	return {
		"texture": mask_texture,
		"origin_x": origin_x,
		"origin_y": origin_y,
		"columns": float(columns),
		"rows": float(rows),
	}


func _add_side_layer(layer: TileMapLayer, layer_name: String) -> void:
	if layer == null:
		push_warning("tile-control.gd: '%s_layer' is not assigned in the inspector." % layer_name)
		set_process_unhandled_input(false)
		return

	_side_layers.append(layer)
