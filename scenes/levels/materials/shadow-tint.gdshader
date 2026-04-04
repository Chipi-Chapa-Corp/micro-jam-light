shader_type canvas_item;

uniform vec4 tint_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float tint_strength : hint_range(0.0, 1.0) = 0.5;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	vec4 base_color = texture(TEXTURE, UV) * COLOR;
	float amount = clamp(tint_strength * tint_color.a, 0.0, 1.0);
	base_color.rgb = mix(base_color.rgb, base_color.rgb * tint_color.rgb, amount);
	COLOR = base_color;
}