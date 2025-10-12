extends RigidBody2D
class_name BounceBullet

# Exports
@export var speed: float = 200.0
@export var damage: int = 15
@export var lifetime: float = 6.0
@export var bounces_left: int = 3
@export var knockback_force: float = 200.0
@export var spawn_offset: float = 16.0  # distance in pixels to spawn away from shooter

# Set by spawner
var direction: Vector2 = Vector2.RIGHT

func _ready() -> void:
	# Ensure this RigidBody2D reports contacts
	contact_monitor = true
	max_contacts_reported = 4

	# Collision layers: bullets on layer 4, collide with player (1) and walls (2)
	collision_layer = 1 << 3
	collision_mask = (1 << 0) | (1 << 1)

	# Connect body_entered signal
	var cb := Callable(self, "_on_body_entered")
	if not is_connected("body_entered", cb):
		connect("body_entered", cb)

	# Move bullet slightly forward at spawn to avoid hitting shooter
	global_position += direction.normalized() * spawn_offset

	# Set initial velocity
	if direction == Vector2.ZERO:
		direction = Vector2(cos(rotation), sin(rotation))
	linear_velocity = direction.normalized() * speed

	# Start lifetime timer
	_start_lifetime_timer()

func _start_lifetime_timer() -> void:
	var t = get_tree().create_timer(lifetime)
	t.timeout.connect(func():
		if is_instance_valid(self):
			queue_free()
	)

func _integrate_forces(state) -> void:
	# Keep constant speed
	if linear_velocity.length() > 0:
		linear_velocity = linear_velocity.normalized() * speed

	# Handle bounces
	var contacts = state.get_contact_count()
	if contacts > 0:
		var normal = state.get_contact_local_normal(0)
		if normal != Vector2.ZERO:
			if bounces_left > 0:
				linear_velocity = linear_velocity.bounce(normal).normalized() * speed
				bounces_left -= 1
			else:
				queue_free()

func _on_body_entered(body: Node) -> void:
	if not body:
		return

	# Damage player on contact
	if body.is_in_group("player") or body.name == "Player":
		if body.has_method("take_damage"):
			body.take_damage(damage)
		if body.has_method("apply_knockback"):
			var push_dir = (body.global_position - global_position)
			push_dir = direction.normalized() if push_dir.length() == 0 else push_dir.normalized()
			body.apply_knockback(push_dir * knockback_force)
		queue_free()
