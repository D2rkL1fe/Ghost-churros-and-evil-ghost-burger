extends CharacterBody2D
class_name BurgerBoss

@export var bullet_scene: PackedScene
@export var fire_interval: float = 2.0           # base seconds between bursts
@export var fire_jitter: float = 0.5             # +/- jitter in seconds
@export var bullet_speed: float = 200.0
@export var bullet_damage: int = 15
@export var bullet_count: int = 12
<<<<<<< Updated upstream
@export var spawn_offset: float = 20.0           # spawn outside boss collider
@export var bullet_bounces: int = 3
=======
@export var spawn_offset: float = 20.0
@export var bullet_bounces: int = 10
@export var laser_speed: float = 250.0
@export var laser_duration: float = 0.6
>>>>>>> Stashed changes

var _time_since_last_shot: float = 0.0
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()

func _process(delta: float) -> void:
	_time_since_last_shot += delta
	var threshold = fire_interval + rng.randf_range(-fire_jitter, fire_jitter)
	if _time_since_last_shot >= threshold:
		_time_since_last_shot = 0.0
		_fire_burst()

func _fire_burst() -> void:
	if bullet_scene == null:
		return

	for i in range(bullet_count):
		var angle = TAU * float(i) / float(bullet_count)   # float division to avoid integer truncation
		var dir = Vector2.RIGHT.rotated(angle)
		var bullet = bullet_scene.instantiate()
		# spawn a little offset so bullets don't overlap boss collider
		bullet.global_position = global_position + dir * spawn_offset
		# pass direction and parameters to bullet
		if "direction" in bullet:
			bullet.direction = dir
		else:
			# fallback: set rotation and rely on bullet to use rotation
			bullet.rotation = angle
		# these fields should exist on the bullet (BounceBullet.gd below)
		if "speed" in bullet:
			bullet.speed = bullet_speed
		if "damage" in bullet:
			bullet.damage = bullet_damage
		if "bounces_left" in bullet:
			bullet.bounces_left = bullet_bounces

		# add to scene
		get_tree().current_scene.add_child(bullet)
