shader_type canvas_item;
render_mode unshaded;

uniform vec4 shadow_color : source_color = vec4(0.0667, 0.0824, 0.1804, 0.55);

uniform int direction = 0;   // 0=Bottom, 1=Top, 2=Right, 3=Left
uniform int step_index = 0;  // 0, 1, 2

uniform float tile_size = 32.0;
uniform float max_tiles = 3.0;

uniform float cast_progress = 1.0;      // 0..1 shadow reveal
uniform float reveal_softness_px = 2.0;

uniform float pixel_block_px = 6.0;     // size of pixelized gradient steps
uniform float alpha_steps = 0.0;        // 0 = off, >1 = posterize
uniform float distortion_px = 2.5;      // subtle wobble amount
uniform float distortion_block_px = 4.0;// size of wobble groups

uniform float tail_opacity = 0.25;      // opacity at the far end of shadow

varying vec2 layer_pos;

void vertex() {
	layer_pos = VERTEX;
}

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	float src_alpha = texture(TEXTURE, UV).a;

	float along_px = 0.0;
	float across_px = 0.0;

	if (direction == 0) {          // Bottom
		along_px = UV.y * tile_size;
		across_px = UV.x * tile_size;
	} else if (direction == 1) {  // Top
		along_px = (1.0 - UV.y) * tile_size;
		across_px = UV.x * tile_size;
	} else if (direction == 2) {  // Right
		along_px = UV.x * tile_size;
		across_px = UV.y * tile_size;
	} else {                      // Left
		along_px = (1.0 - UV.x) * tile_size;
		across_px = UV.y * tile_size;
	}

	float max_dist = tile_size * max_tiles;
	float dist_px = float(step_index) * tile_size + along_px;

	// small blocky distortion across the shadow
	float block_id = floor(across_px / distortion_block_px);
	float jitter = (hash(vec2(block_id, float(direction) * 10.0 + float(step_index))) - 0.5) * 2.0;
	dist_px += jitter * distortion_px;

	// pixelize
	dist_px = floor(dist_px / pixel_block_px) * pixel_block_px;
	dist_px = clamp(dist_px, 0.0, max_dist);

	// base fade
	float fade = 1.0 - smoothstep(0.0, max_dist, dist_px);

	// keep tail more visible
	fade = mix(tail_opacity, 1.0, fade);

	// optional alpha posterization
	if (alpha_steps > 1.0) {
		fade = floor(fade * alpha_steps) / alpha_steps;
	}

	// reveal outward from panel side
	float cast_t = clamp(cast_progress, 0.0, 1.0);
	float reveal_limit = cast_t * (max_dist + reveal_softness_px) - reveal_softness_px;
	float reveal = 1.0 - smoothstep(reveal_limit, reveal_limit + reveal_softness_px, dist_px);

	COLOR = vec4(shadow_color.rgb, shadow_color.a * fade * reveal * src_alpha);
}