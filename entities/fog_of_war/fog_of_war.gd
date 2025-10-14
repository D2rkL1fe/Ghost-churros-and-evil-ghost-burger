extends Control

@export var player : Player

@export var fog : PackedScene

var offset : float = 50.0

var x_times : int = 100
var y_times : int = 100

func _ready():
	spawn_fog()

func generate_fog():
	for x in range(x_times):
		for y in range(y_times):
			var instance = fog.instantiate()
			
			var x_pos = x * offset - x_times / 2 * offset + randf_range(-16, 16)
			var y_pos = y * offset - y_times / 2 * offset + randf_range(-16, 16)
			instance.position = Vector2(x_pos, y_pos)
			
			instance.setup(player)
			
			add_child(instance)

func spawn_fog():
	self_modulate.a = 0
	
	for x in range(x_times):
		for y in range(y_times):
			var instance = fog.instantiate()
			
			var offset_x = size.x / x_times
			var offset_y = size.y / y_times
			
			var x_pos = x * offset_x + randf_range(-16, 16)
			var y_pos = y * offset_y + randf_range(-16, 16)
			instance.position = Vector2(x_pos, y_pos)
			
			instance.setup(player)
			
			add_child(instance)
