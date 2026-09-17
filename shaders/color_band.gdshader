shader_type canvas_item;

uniform float scroll_speed : hint_range(0.1, 5.0) = 1.5;
uniform float band_width : hint_range(0.01, 0.5) = 0.12;
uniform float band_angle : hint_range(0.0, 3.14) = 0.6;
uniform vec4 band_color : source_color = vec4(1.0, 1.0, 1.0, 0.6);
uniform float glow_intensity : hint_range(0.0, 2.0) = 1.2;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);

	float pos = UV.x * cos(band_angle) + UV.y * sin(band_angle);
	float scroll = fract(pos - TIME * scroll_speed * 0.3);

	float half_w = band_width * 0.5;
	float band = smoothstep(0.0, half_w, scroll) - smoothstep(half_w, half_w * 2.0, scroll);
	band = clamp(band * 2.0, 0.0, 1.0);

	float glow = smoothstep(0.0, half_w * 3.0, scroll) - smoothstep(half_w * 3.0, half_w * 6.0, scroll);
	glow = clamp(glow * glow_intensity * 0.3, 0.0, 0.5);

	vec3 final_color = mix(tex.rgb, band_color.rgb, band * band_color.a * tex.a);
	final_color += band_color.rgb * glow * tex.a;

	COLOR = vec4(final_color, tex.a);
}
