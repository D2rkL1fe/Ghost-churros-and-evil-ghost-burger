extends CharacterBody2D
class_name Enemy

@export_enum("defender", "attacker") var role: String = "defender"
@export var move_speed: float = 60.0
@export var shockwave_damage: int = 20
@export var attack_cooldown: float = 1.3
@export var detection_radius: float = 150.0
@export var attack_range: float = 48.0
@export var defense_radius: float = 300.0
@export var orbit_distance: float = 64.0
@export var orbit_speed: float = 1.6
@export var orbit_spread: float = 0.9
@export var knockback_force: float = 250.0

var rng := RandomNumberGenerator.new()
var orbit_phase: float = 0.0
var orbit_speed_offset: float = 1.0
var orbit_phase_offset: float = 0.0
var can_attack: bool = true
var player: Node2D
var churros_list: Array = []
var defending_target: Node2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var shockwave: Area2D = $Shockwave
@onready var aura_sprite: Sprite2D = $Shockwave/Sprite2D
@onready var shockwave_shape: CollisionShape2D = $Shockwave/CollisionShape2D
@onready var aura_particles: GPUParticles2D = $Shockwave/FireParticles

func _ready():
	rng.randomize()
	orbit_phase = rng.randf_range(0.0, TAU)
	orbit_phase_offset = rng.randf_range(0.0, TAU)
	orbit_speed_offset = rng.randf_range(1.0 - orbit_spread, 1.0 + orbit_spread)
	orbit_distance += rng.randf_range(-10.0, 10.0)
	player = get_tree().get_current_scene().get_node("Player")
	churros_list = get_tree().get_nodes_in_group("churros")
	if aura_sprite:
		aura_sprite.visible = false
		aura_sprite.scale = Vector2(0.1, 0.1)
	if shockwave_shape:
		shockwave_shape.scale = Vector2(0.1, 0.1)
	if shockwave and not shockwave.is_connected("body_entered", Callable(self, "_on_Shockwave_body_entered")):
		shockwave.body_entered.connect(Callable(self, "_on_Shockwave_body_entered"))
	add_to_group("enemies")

func _physics_process(_delta):
	if role == "defender":
		_defender_behavior(_delta)
	else:
		_attacker_behavior(_delta)
	move_and_slide()

func _defender_behavior(_delta):
	if defending_target == null or not is_instance_valid(defending_target):
		defending_target = _select_nearest_churros()
	if defending_target == null:
		velocity = Vector2.ZERO
		_play_idle()
		return

	var target_pos = defending_target.global_position
	var to_player = player.global_position - global_position
	if target_pos.distance_to(player.global_position) <= defense_radius:
		if to_player.length() <= attack_range and can_attack:
			start_attack()
		if to_player.length() > 6:
			velocity = to_player.normalized() * move_speed
			_play_run(to_player.x)
		else:
			velocity = Vector2.ZERO
			_play_idle()
	else:
		velocity = Vector2.ZERO
		_play_idle()

func _attacker_behavior(_delta):
	var to_player = player.global_position - global_position
	if to_player.length() > 8:
		velocity = to_player.normalized() * move_speed
		_play_run(to_player.x)
	else:
		velocity = Vector2.ZERO
		_play_idle()
	if can_attack and to_player.length() <= attack_range:
		start_attack()

func start_attack():
	can_attack = false
	attack()
	get_tree().create_timer(attack_cooldown).timeout.connect(func(): can_attack = true)

func attack():
	if aura_sprite:
		aura_sprite.visible = true
		aura_sprite.scale = Vector2(0.1, 0.1)
	if shockwave_shape:
		shockwave_shape.scale = Vector2(0.1, 0.1)
	if shockwave:
		shockwave.monitoring = true
		shockwave.monitorable = true
	if aura_particles:
		aura_particles.restart()
	var tween = get_tree().create_tween()
	tween.tween_property(aura_sprite, "scale", Vector2(3,3), 0.25)
	tween.tween_property(aura_sprite, "modulate:a", 0.0, 0.25)
	tween.tween_property(shockwave_shape, "scale", Vector2(3,3), 0.25)
	await tween.finished
	aura_sprite.visible = false
	aura_sprite.scale = Vector2(0.1,0.1)
	shockwave_shape.scale = Vector2(0.1,0.1)
	shockwave.monitoring = false
	shockwave.monitorable = false

func _on_Shockwave_body_entered(body):
	if body.has_method("take_damage"):
		body.take_damage(shockwave_damage)
	if body.has_method("apply_knockback"):
		body.apply_knockback((body.global_position - global_position).normalized() * knockback_force)

func _select_nearest_churros():
	var nearest = null
	var best = INF
	for c in churros_list:
		var d = global_position.distance_to(c.global_position)
		if d < best:
			best = d
			nearest = c
	return nearest

func _play_run(hx):
	if sprite:
		sprite.flip_h = hx < 0
		if sprite.animation != "run":
			sprite.play("run")

func _play_idle():
	if sprite and sprite.animation != "idle":
		sprite.play("idle")
