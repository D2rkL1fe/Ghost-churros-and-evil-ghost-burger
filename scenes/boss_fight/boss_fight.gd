extends Node2D

@export var churros_scene: PackedScene
@export var spawn_interval: float = 5.0
@export var max_churros: int = 5
@export var max_spawn_attempts: int = 25

@export var min_x: float = 0
@export var max_x: float = 1024
@export var min_y: float = 0
@export var max_y: float = 600

@export var collision_check_radius: float = 16.0

var _current_churros := 0
var _spawn_timer: Timer

func _ready():
	if not churros_scene:
		push_error("churros_scene is not assigned!")
		return

	_spawn_timer = Timer.new()
	_spawn_timer.wait_time = spawn_interval
	_spawn_timer.one_shot = false
	_spawn_timer.autostart = true
	add_child(_spawn_timer)
	_spawn_timer.timeout.connect(_spawn_churros)

func _spawn_churros():
	if _current_churros >= max_churros:
		return
	
	for i in range(max_spawn_attempts):
		var random_pos = Vector2(
			randf_range(min_x, max_x),
			randf_range(min_y, max_y)
		)

		if _is_position_valid(random_pos) and _is_position_free(random_pos):
			var churros_instance = churros_scene.instantiate()
			churros_instance.position = random_pos
			add_child(churros_instance)
			_current_churros += 1

			if churros_instance.has_signal("body_entered"):
				churros_instance.body_entered.connect(func(body):
					if body is Player:
						_current_churros = max(_current_churros - 1, 0)
						churros_instance.queue_free()
				)
			return 

# Check bounds
func _is_position_valid(pos: Vector2) -> bool:
	return pos.x >= min_x and pos.x <= max_x and pos.y >= min_y and pos.y <= max_y


func _is_position_free(pos: Vector2) -> bool:
	var space_state = get_world_2d().direct_space_state

	var shape = CircleShape2D.new()
	shape.radius = collision_check_radius

	var query = PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0, pos)
	query.collide_with_areas = true
	query.collide_with_bodies = true

	var result = space_state.intersect_shape(query, 1)
	return result.size() == 0
