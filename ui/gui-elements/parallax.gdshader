shader_type canvas_item;

uniform float saturation : hint_range(0.0, 1.0) = 0.8;
uniform float fade : hint_range(0.0, 1.0) = 0.12;
uniform vec4 tint : source_color = vec4(0.98, 0.98, 1.0, 1.0);

void fragment() {
	vec4 tex = texture(TEXTURE, UV);

	float gray = dot(tex.rgb, vec3(0.299, 0.587, 0.114));
	vec3 desat = mix(vec3(gray), tex.rgb, saturation);
	vec3 faded = mix(desat, vec3(1.0), fade);
	faded *= tint.rgb;

	COLOR = vec4(faded, tex.a);
}