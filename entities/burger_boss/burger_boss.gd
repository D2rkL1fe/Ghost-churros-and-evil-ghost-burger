extends CharacterBody2D
class_name BurgerBoss

@export var bullet_scene: PackedScene
@export var burger_laser_scene: PackedScene

@export var bullet_interval: float = 3.0
@export var laser_interval: float = 4.5
@export var bullet_speed: float = 200.0
@export var bullet_damage: int = 15
@export var bullet_count: int = 12
@export var spawn_offset: float = 20.0
@export var bullet_bounces: int = 3
@export var laser_speed: float = 250.0
@export var laser_duration: float = 0.6

@export var base_move_speed: float = 150.0
@export var aggressive_move_speed: float = 190.0
@export var stop_time: float = 1.0
@export var min_distance: float = 100.0
@export var max_distance: float = 800.0
@export var low_hp_threshold: float = 0.3
@export var move_change_interval: float = 2.0
@export var engage_distance: float = 600.0
@export var aggressive_distance: float = 900.0
@export var max_hp: int = 700

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var health_bar: TextureProgressBar = $HealthBarComponent

var hp: int
var _bullet_timer = 0.0
var _laser_timer = 0.0
var _stop_timer = 0.0
var _move_timer = 0.0
var _is_attacking = false
var _move_dir = Vector2.ZERO
var rng := RandomNumberGenerator.new()
var player: Node2D

func _ready():
	hp = max_hp
	health_bar.max_value = max_hp
	health_bar.value = hp
	rng.randomize()
	player = get_tree().get_first_node_in_group("player")

func _process(delta):
	if not player: return
	_bullet_timer += delta
	_laser_timer += delta

	var low_player = _player_health_ratio() <= 0.4

	if not _is_attacking and global_position.distance_to(player.global_position) <= (aggressive_distance if low_player else engage_distance):
		if _bullet_timer >= bullet_interval:
			_start_attack("_fire_bullets")
			_bullet_timer = 0
		elif _laser_timer >= laser_interval:
			_start_attack("_fire_laser_at_player")
			_laser_timer = 0

	if _is_attacking:
		_stop_timer -= delta
		if _stop_timer <= 0:
			_is_attacking = false
		
		sprite.play("idle")
	else:
		_move(delta, low_player)
		
		sprite.play("run")

func _move(delta, low_player):
	if not player: return
	_move_timer -= delta
	var to_player = player.global_position - global_position
	
	sprite.flip_h = to_player.x < 0

	if _move_timer <= 0:
		_move_timer = move_change_interval + rng.randf_range(-0.3, 0.3)
		var angle_dev = rng.randf_range(-PI/12, PI/12) if hp < max_hp * low_hp_threshold else rng.randf_range(-PI/20, PI/20)
		_move_dir = (to_player if hp >= max_hp * low_hp_threshold else -to_player).normalized().rotated(angle_dev)

	var cur_speed = aggressive_move_speed if low_player else base_move_speed
	var noise = Vector2(rng.randf_range(-0.03, 0.03), rng.randf_range(-0.03, 0.03))
	
	velocity = (_move_dir + noise).normalized() * cur_speed
	move_and_slide()

func _start_attack(method_name: String):
	_is_attacking = true
	_stop_timer = stop_time
	velocity = Vector2.ZERO
	move_and_slide()
	call_deferred(method_name)

func _fire_bullets():
	if not bullet_scene: return
	for i in range(bullet_count):
		var angle = TAU * i / bullet_count
		var b = bullet_scene.instantiate()
		b.global_position = global_position + Vector2.RIGHT.rotated(angle) * spawn_offset
		for prop in ["direction", "speed", "damage", "bounces_left"]:
			if prop in b:
				match prop:
					"direction": b.direction = Vector2.RIGHT.rotated(angle)
					"speed": b.speed = bullet_speed
					"damage": b.damage = bullet_damage
					"bounces_left": b.bounces_left = bullet_bounces
		get_tree().current_scene.add_child(b)

func _fire_laser_at_player():
	if not burger_laser_scene or not player:
		return

	var dir = (player.global_position - global_position).normalized()
	var l = burger_laser_scene.instantiate()
	l.global_position = global_position + dir * spawn_offset
	l.setup(dir)
	get_tree().current_scene.add_child(l)


func take_damage(amount: int):
	hp -= amount
	if health_bar:
		health_bar.value = hp
	if hp <= 0:
		queue_free()
		SoundPlayer.play_sound(SoundPlayer.EXPLOSION)
		
		Global.transition("res://scenes/outro/outro.tscn")

func _player_health_ratio() -> float:
	if not player or not ("health" in player and "max_health" in player) or player.max_health <= 0:
		return 1.0
	return float(player.health) / float(player.max_health)
