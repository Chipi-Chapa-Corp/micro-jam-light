shader_type canvas_item;
render_mode unshaded;

uniform vec4 glow_color : source_color = vec4(1.0, 0.9, 0.5, 0.35);
uniform float glow_intensity = 1.0;
uniform float edge_spread_px = 72.0;
uniform float edge_softness_px = 72.0;
// 0 = top, 1 = bottom, 2 = left, 3 = right
uniform int light_position = 0;

void fragment() {
	float dist_uv = 0.0;
	float axis_px = 1.0 / max(SCREEN_PIXEL_SIZE.y, 0.000001);

	if (light_position == 0) {
		dist_uv = UV.y;
		axis_px = 1.0 / max(SCREEN_PIXEL_SIZE.y, 0.000001);
	} else if (light_position == 1) {
		dist_uv = 1.0 - UV.y;
		axis_px = 1.0 / max(SCREEN_PIXEL_SIZE.y, 0.000001);
	} else if (light_position == 2) {
		dist_uv = UV.x;
		axis_px = 1.0 / max(SCREEN_PIXEL_SIZE.x, 0.000001);
	} else {
		dist_uv = 1.0 - UV.x;
		axis_px = 1.0 / max(SCREEN_PIXEL_SIZE.x, 0.000001);
	}

	float dist_px = dist_uv * max(axis_px, 1.0);
	float spread_px = max(edge_spread_px, 0.0);
	float soft_px = max(edge_softness_px, 0.001);
	float mask = 1.0 - smoothstep(spread_px, spread_px + soft_px, dist_px);

	float alpha = glow_color.a * glow_intensity * mask;
	COLOR = vec4(glow_color.rgb, alpha);
}
