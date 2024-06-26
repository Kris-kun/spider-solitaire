shader_type canvas_item;

uniform float darken_modifier: hint_range(0.0, 1.0, 0.05) = 0.9;

void fragment() {
	vec4 color = texture(TEXTURE, UV);
	color.rgb *= darken_modifier;
	COLOR = color;
}
