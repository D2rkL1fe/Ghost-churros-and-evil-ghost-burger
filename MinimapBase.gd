extends Control

@export var player : Node2D
@export var sight_range_world : float = 400.0
@export var level_size := Vector2(2000, 2000)

@onready var container = $SubViewportContainer
@onready var minimap_material: ShaderMaterial = container.material

var fog_texture_size := 100
var fog_image := Image.create(fog_texture_size, fog_texture_size, false, Image.FORMAT_L8)
var fog_texture := ImageTexture.create_from_image(fog_image)
var FOG_UNIFORM_NAME = "fog_mask_texture"
var explored_image := Image.create(fog_texture_size, fog_texture_size, false, Image.FORMAT_L8)

func _ready():
	# Initializing the images. fill() works directly.
	fog_image.fill(Color.BLACK)
	explored_image.fill(Color.BLACK)
	
	fog_texture.update(fog_image)

	if minimap_material:
		minimap_material.set_shader_parameter(FOG_UNIFORM_NAME, fog_texture)
		minimap_material.set_shader_parameter("minimap_size", container.size)
	
	set_process(true)

func _process(_delta):
	if is_instance_valid(player):
		update_fog_mask()
		
	if minimap_material:
		minimap_material.set_shader_parameter("time", Time.get_ticks_msec() / 1000.0)

func world_to_texture_coord(world_pos : Vector2) -> Vector2i:
	var normalized_pos = world_pos + (level_size / 2.0)
	var scale_factor = float(fog_texture_size) / level_size.x
	var texture_coord = normalized_pos * scale_factor
	return Vector2i(texture_coord)

# Helper function to manually draw a filled circle using set_pixel (works directly in Godot 4)
func draw_circle_on_image(image: Image, center: Vector2i, radius: int, color: Color):
	var r_sq = radius * radius
	for x in range(-radius, radius + 1):
		for y in range(-radius, radius + 1):
			if x*x + y*y <= r_sq:
				var target_x = center.x + x
				var target_y = center.y + y
				if target_x >= 0 and target_x < fog_texture_size and target_y >= 0 and target_y < fog_texture_size:
					image.set_pixel(target_x, target_y, color)

func update_fog_mask():
	var player_pos_tex = world_to_texture_coord(player.global_position)
	var radius_tex = int(sight_range_world / level_size.x * fog_texture_size)
	
	# Mark explored area in gray (Memory)
	draw_circle_on_image(explored_image, player_pos_tex, radius_tex, Color(0.5, 0.5, 0.5))
	
	# Start with the memory fog texture (blit the explored area onto the current fog map)
	fog_image.blit_rect(explored_image, Rect2i(Vector2i.ZERO, Vector2i(fog_texture_size, fog_texture_size)), Vector2i.ZERO)
	
	# Clear the immediate area around the player in white (Current Sight)
	# Draw the current sight area directly onto the final fog_image
	draw_circle_on_image(fog_image, player_pos_tex, radius_tex, Color.WHITE)
	
	# Update the texture used by the shader
	fog_texture.update(fog_image)
