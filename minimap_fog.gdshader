shader_type canvas_item;

uniform sampler2D texture;
uniform sampler2D fog_mask_texture;
uniform sampler2D noise_texture; 
uniform vec2 minimap_size = vec2(512.0, 512.0);
uniform float time;

void fragment() {
	vec2 uv = FRAGCOORD.xy / minimap_size;
	
	vec4 minimap_content_color = texture(texture, uv);
	float mask_value = texture(fog_mask_texture, uv).r;

    vec2 noise_uv = uv + vec2(time * 0.05, time * 0.02);
    float noise = texture(noise_texture, noise_uv).r;
    
    vec4 UNEXPLORED_FOG_COLOR = vec4(0.9, 0.9, 0.9, 1.0);
    vec4 EXPLORED_MEMORY_COLOR = vec4(0.0, 0.0, 0.0, 0.6);
    
    UNEXPLORED_FOG_COLOR.rgb *= (0.7 + noise * 0.3);

	if (mask_value > 0.9) {
		COLOR = minimap_content_color;
	} else if (mask_value > 0.1) {
		COLOR = mix(minimap_content_color, EXPLORED_MEMORY_COLOR, 0.8);
	} else {
		COLOR = UNEXPLORED_FOG_COLOR;
	}
}