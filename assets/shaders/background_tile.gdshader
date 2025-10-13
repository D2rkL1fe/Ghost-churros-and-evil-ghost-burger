shader_type canvas_item;

uniform float scale : hint_range(0.1, 5.0) = 0.5;
uniform vec4 tint : source_color;

void fragment() {
	vec2 uv = vec2(UV.x + TIME * 0.6, UV.y + TIME * 0.2);
	COLOR = texture(TEXTURE, uv * scale) * tint;
}
