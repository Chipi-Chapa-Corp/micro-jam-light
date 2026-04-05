shader_type canvas_item;
render_mode unshaded;

uniform vec3 rim_color : source_color = vec3(1.0, 1.0, 1.0);
uniform float rim_strength = 0.35;
uniform float rim_width_px = 1.0;
uniform float rim_soft_width_px = 2.0;
// 0 = top, 1 = bottom, 2 = left, 3 = right
uniform int light_position = 0;
// AnimatedSprite2D.flip_h compensation so world left/right stays consistent.
uniform float sprite_flip_h = 0.0;

void fragment() {
	vec4 tex = texture(TEXTURE, UV) * COLOR;
	if (tex.a <= 0.001) {
		COLOR = vec4(0.0);
	} else {
		vec2 dir = vec2(0.0, -1.0);
		if (light_position == 1) {
			dir = vec2(0.0, 1.0);
		} else if (light_position == 2) {
			dir = vec2(-1.0, 0.0);
		} else if (light_position == 3) {
			dir = vec2(1.0, 0.0);
		}

		if (sprite_flip_h > 0.5) {
			dir.x *= -1.0;
		}

		vec2 step_uv_1 = dir * max(rim_width_px, 0.001) * TEXTURE_PIXEL_SIZE;
		vec2 step_uv_2 = dir * max(rim_soft_width_px, rim_width_px) * TEXTURE_PIXEL_SIZE;

		float a1 = texture(TEXTURE, UV + step_uv_1).a;
		float a2 = texture(TEXTURE, UV + step_uv_2).a;
		float edge = clamp((tex.a - a1) * 0.7 + (tex.a - a2) * 0.5, 0.0, 1.0);

		float blend = clamp(edge * rim_strength, 0.0, 1.0);
		// Additive rim so we never darken base sprite colors.
		vec3 lit = min(tex.rgb + rim_color * blend, vec3(1.0));
		COLOR = vec4(lit, tex.a);
	}
}
