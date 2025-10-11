extends CharacterBody2D

@export var bullet_scene: PackedScene
@export var fire_interval: float = 1.5
@export var bullet_speed: float = 250.0
@export var bullet_damage: int = 10

var _fire_timer: float = 0.0

func _ready() -> void:
	_fire_timer = fire_interval

func _process(delta: float) -> void:
	_fire_timer -= delta
	if _fire_timer <= 0.0:
		_fire_timer = fire_interval
		shoot_bullet()

func shoot_bullet() -> void:
	if bullet_scene == null:
		print("⚠️ No bullet_scene assigned to boss!")
		return

	var player = get_tree().get_first_node_in_group("player")
	if player == null:
		print("⚠️ No player found in group 'player'!")
		return

	# Create bullet instance
	var bullet = bullet_scene.instantiate()
	bullet.global_position = global_position

	# Aim at player
	var dir = (player.global_position - global_position).normalized()
	bullet.rotation = dir.angle()

	# Pass data to bullet if variables exist
	if bullet.has_variable("speed"):
		bullet.speed = bullet_speed
	if bullet.has_variable("damage"):
		bullet.damage = bullet_damage

	get_tree().current_scene.add_child(bullet)

	print("💥 Boss fired bullet toward player!")
