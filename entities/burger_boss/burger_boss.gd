extends CharacterBody2D
class_name BurgerBoss

# Scenes
@export var bullet_scene: PackedScene
@export var laser_scene: PackedScene

# Firing intervals
@export var bullet_interval: float = 3.0
@export var laser_interval: float = 4.5

# Bullet settings
@export var bullet_speed: float = 200.0
@export var bullet_damage: int = 15
@export var bullet_count: int = 12
@export var spawn_offset: float = 20.0
@export var bullet_bounces: int = 3

# Laser settings
@export var laser_speed: float = 500.0
@export var laser_duration: float = 0.6

var _bullet_timer: float = 0.0
var _laser_timer: float = 0.0
var rng := RandomNumberGenerator.new()
var player: Node2D

func _ready() -> void:
	rng.randomize()
	player = get_tree().get_first_node_in_group("player")

func _process(delta: float) -> void:
	if not player:
		return

	_bullet_timer += delta
	_laser_timer += delta

	if _bullet_timer >= bullet_interval:
		_bullet_timer = 0.0
		_fire_bullets()

	if _laser_timer >= laser_interval:
		_laser_timer = 0.0
		_fire_laser_at_player()

# ------------------ BULLETS ------------------
func _fire_bullets() -> void:
	if bullet_scene == null:
		return

	for i in range(bullet_count):
		var angle = TAU * float(i) / float(bullet_count)
		var dir = Vector2.RIGHT.rotated(angle)
		var bullet = bullet_scene.instantiate()

		bullet.global_position = global_position + dir * spawn_offset
		if "direction" in bullet:
			bullet.direction = dir
		else:
			bullet.rotation = angle

		if "speed" in bullet:
			bullet.speed = bullet_speed
		if "damage" in bullet:
			bullet.damage = bullet_damage
		if "bounces_left" in bullet:
			bullet.bounces_left = bullet_bounces

		get_tree().current_scene.add_child(bullet)

# ------------------ LASER ------------------
func _fire_laser_at_player() -> void:
	if laser_scene == null or player == null:
		return

	var dir = (player.global_position - global_position).normalized()
	var laser = laser_scene.instantiate()

	var laser_offset = spawn_offset * 0.3  
	laser.global_position = global_position + dir * laser_offset

	if "setup" in laser:
		laser.setup(dir, laser_speed, laser_duration)

	get_tree().current_scene.add_child(laser)
