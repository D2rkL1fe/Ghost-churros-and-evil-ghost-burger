extends RigidBody2D
class_name BounceBullet

@export var speed: float = 200.0
@export var damage: int = 15
@export var lifetime: float = 6.0
@export var bounces_left: int = 3
@export var knockback_force: float = 200.0
@export var spawn_offset: float = 16.0

@export var min_active_speed: float = 40.0      
@export var stuck_despawn_time: float = 0.5   

var direction: Vector2 = Vector2.RIGHT
var lifetime_timer: float
var bounce_cooldown: float = 0.0
var last_bounce_normal: Vector2 = Vector2.ZERO
var slow_time: float = 0.0               

const SEPARATION_FIX: float = 3.0
const BOUNCE_COOLDOWN: float = 0.08

func _ready() -> void:
	contact_monitor = true
	max_contacts_reported = 4
	collision_layer = 1 << 3
	collision_mask = (1 << 0) | (1 << 1)

	if direction == Vector2.ZERO:
		direction = Vector2(cos(rotation), sin(rotation))

	global_position += direction.normalized() * spawn_offset
	linear_velocity = direction.normalized() * speed
	lifetime_timer = lifetime

	if not is_connected("body_entered", Callable(self, "_on_body_entered")):
		connect("body_entered", Callable(self, "_on_body_entered"))

func _physics_process(delta: float) -> void:
	lifetime_timer -= delta
	if lifetime_timer <= 0.0:
		queue_free()
		return

	if bounce_cooldown > 0.0:
		bounce_cooldown -= delta

	if linear_velocity.length() < min_active_speed:
		slow_time += delta
		if slow_time >= stuck_despawn_time:
			queue_free()
			return
	else:
		slow_time = 0.0

func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	if bounce_cooldown > 0.0:
		return

	var contact_count = state.get_contact_count()
	if contact_count == 0:
		return

	var normal = state.get_contact_local_normal(0)
	if normal == Vector2.ZERO:
		return

	if normal.dot(last_bounce_normal) > 0.95:
		return

	if bounces_left > 0:
		var reflected = linear_velocity.bounce(normal).normalized() * speed
		global_position += normal * SEPARATION_FIX
		linear_velocity = reflected
		direction = reflected.normalized()
		bounces_left -= 1
		last_bounce_normal = normal
		bounce_cooldown = BOUNCE_COOLDOWN
	else:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if not body:
		return
	if body.is_in_group("player") or body.name == "Player":
		if body.has_method("take_damage"):
			body.take_damage(damage)
			
			SoundPlayer.play_sound(SoundPlayer.HURT)
		if body.has_method("apply_knockback"):
			var push_dir = (body.global_position - global_position).normalized()
			body.apply_knockback(push_dir * knockback_force)
		queue_free()
