shader_type canvas_item;

uniform vec2 speed = vec2(0.6, 0.4);
uniform float scale : hint_range(0.1, 5.0) = 0.5;

uniform vec4 tint : source_color;


void fragment() {
	vec2 uv = vec2(UV.x + TIME * speed.x, UV.y + TIME * speed.y);
	COLOR = texture(TEXTURE, uv * scale) * tint;
}
