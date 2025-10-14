shader_type canvas_item;

uniform sampler2D overlay: repeat_enable, filter_nearest;
uniform float scale = 0.01;
varying vec2 world_position;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	float mix_amount = floor(COLOR.r);
	vec4 overlay_color = texture(overlay, world_position * scale);
	COLOR = mix(COLOR, overlay_color, mix_amount);
}