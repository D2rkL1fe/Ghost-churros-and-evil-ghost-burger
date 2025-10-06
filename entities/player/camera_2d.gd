extends Camera2D

@export var target_path: NodePath
@export var follow_speed: float = 5.0
@export var funky_strength: float = 16.0
@export var funky_speed: float = 3.0

var target: Node2D

func _ready():
	target = get_node_or_null(target_path)
	if target == null:
		push_warning("Camera2D: Target not set!")
		make_current()
func _process(delta: float) -> void:
	if target == null:
		return

	var target_pos = target.global_position
	global_position = global_position.lerp(target_pos, delta * follow_speed)

	var t = Time.get_ticks_msec() / 1000.0
	offset = Vector2(
		sin(t * funky_speed) * funky_strength,
		cos(t * funky_speed * 0.8) * funky_strength
	)
