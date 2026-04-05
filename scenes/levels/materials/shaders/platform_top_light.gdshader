shader_type canvas_item;
render_mode unshaded, world_vertex_coords;

// Simple debug top band directly on platform tiles.
uniform vec3 top_tint : source_color = vec3(1.0, 0.0, 0.0);
uniform float top_band_px = 8.0;
uniform float tint_strength = 1.0;
uniform float tile_size = 32.0;
uniform float grid_origin_y = 0.0;
uniform float grid_origin_x = 0.0;
// 0 = top band, 1 = bottom band, 2 = left band, 3 = right band
uniform int light_position = 0;
uniform sampler2D edge_mask_tex : filter_nearest, repeat_disable;
uniform float edge_mask_enabled = 0.0;
uniform float edge_mask_origin_x = 0.0;
uniform float edge_mask_origin_y = 0.0;
uniform float edge_mask_columns = 1.0;
uniform float edge_mask_rows = 1.0;

varying vec2 world_pos;

void vertex() {
	world_pos = VERTEX;
}

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	if (tex.a <= 0.0) {
		COLOR = vec4(0.0);
	} else {
		float safe_tile_size = max(tile_size, 0.001);
		float local_y = mod(world_pos.y - grid_origin_y, safe_tile_size);
		if (local_y < 0.0) {
			local_y += safe_tile_size;
		}
		float local_x = mod(world_pos.x - grid_origin_x, safe_tile_size);
		if (local_x < 0.0) {
			local_x += safe_tile_size;
		}
		float band_dist = local_y;
		if (light_position == 1) {
			band_dist = safe_tile_size - local_y;
		} else if (light_position == 2) {
			band_dist = local_x;
		} else if (light_position == 3) {
			band_dist = safe_tile_size - local_x;
		}

		float edge_mask_value = 1.0;
		if (edge_mask_enabled > 0.5) {
			float cell_fx = floor((world_pos.x - edge_mask_origin_x) / safe_tile_size);
			float cell_fy = floor((world_pos.y - edge_mask_origin_y) / safe_tile_size);
			float in_x = step(0.0, cell_fx) * step(cell_fx, edge_mask_columns - 1.0);
			float in_y = step(0.0, cell_fy) * step(cell_fy, edge_mask_rows - 1.0);
			float in_bounds = in_x * in_y;
			float sample_u = clamp((cell_fx + 0.5) / max(edge_mask_columns, 1.0), 0.0, 1.0);
			float sample_v = clamp((cell_fy + 0.5) / max(edge_mask_rows, 1.0), 0.0, 1.0);
			vec4 edge_sample = texture(edge_mask_tex, vec2(sample_u, sample_v));
			if (light_position == 0) {
				edge_mask_value = edge_sample.g * in_bounds; // top
			} else if (light_position == 1) {
				edge_mask_value = edge_sample.b * in_bounds; // bottom
			} else if (light_position == 2) {
				edge_mask_value = edge_sample.r * in_bounds; // left
			} else if (light_position == 3) {
				edge_mask_value = edge_sample.a * in_bounds; // right
			}
		}

		float band_mask = 1.0 - smoothstep(0.0, max(top_band_px, 0.001), band_dist);
		float blend = clamp(band_mask * tint_strength * edge_mask_value, 0.0, 1.0);
		vec3 lit = mix(tex.rgb, top_tint, blend);
		COLOR = vec4(lit, tex.a);
	}
}
