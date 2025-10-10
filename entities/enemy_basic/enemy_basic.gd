extends CharacterBody2D

@export_enum("defender", "attacker") var role: String = "defender"
@export var move_speed: float = 60.0
@export var attack_cooldown: float = 1.3
@export var knockback_force: float = 250.0
@export var shockwave_scale_time: float = 0.25
@export var shockwave_max_scale: float = 3.0
@export var shockwave_damage: int = 20
@export var detection_radius: float = 150.0
@export var attack_range: float = 48.0
@export var defense_radius: float = 300.0
@export var orbit_distance: float = 64.0
@export var orbit_speed: float = 1.6
@export var orbit_spread: float = 0.9

var rng = RandomNumberGenerator.new()
var orbit_phase = 0.0
var orbit_speed_offset = 1.0
var orbit_phase_offset = 0.0
var player: Node2D
var churros_list = []
var defending_target: Node2D
var can_attack = true
var idle_timer = 0.0
var last_moving = false
var wiggle_timer = 0.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var shockwave: Area2D = $Shockwave
@onready var aura_sprite: Sprite2D = $Shockwave/Sprite2D
@onready var shockwave_shape: CollisionShape2D = $Shockwave/CollisionShape2D
@onready var aura_particles: GPUParticles2D = $Shockwave/FireParticles
@onready var cam: Camera2D = get_tree().get_first_node_in_group("camera")

func _ready():
	rng.randomize()
	orbit_phase = rng.randf_range(0, TAU)
	orbit_phase_offset = rng.randf_range(0, TAU)
	orbit_speed_offset = rng.randf_range(1 - orbit_spread, 1 + orbit_spread)
	orbit_distance += rng.randf_range(-10, 10)
	player = get_tree().get_current_scene().get_node_or_null("Player")
	churros_list = get_tree().get_nodes_in_group("churros")
	aura_sprite.visible = false
	aura_sprite.scale = Vector2(0.1, 0.1)
	shockwave_shape.scale = Vector2(0.1, 0.1)
	shockwave.monitoring = false
	shockwave.monitorable = false
	if not shockwave.is_connected("body_entered", _on_Shockwave_body_entered):
		shockwave.body_entered.connect(_on_Shockwave_body_entered)
	add_to_group("enemies")

func _physics_process(delta):
	if not player:
		player = get_tree().get_current_scene().get_node_or_null("Player")
	if churros_list.size() == 0:
		churros_list = get_tree().get_nodes_in_group("churros")
	_ensure_attacker_exists()
	if role == "defender":
		_defender_behavior(delta)
	else:
		_attacker_behavior(delta)
	move_and_slide()

func _defender_behavior(delta):
	if not defending_target or not is_instance_valid(defending_target):
		defending_target = _select_nearest_churros()
	if not defending_target:
		velocity = Vector2.ZERO
		_play_idle()
		return

	var center = defending_target.global_position
	var to_player = player.global_position - global_position

	if player.global_position.distance_to(center) <= defense_radius:
		if to_player.length() <= attack_range and can_attack:
			start_attack()
		if to_player.length() > 6:
			velocity = to_player.normalized() * move_speed
			_play_run(to_player.x)
		else:
			velocity = Vector2.ZERO
			_play_idle()
	else:
		orbit_phase += orbit_speed * orbit_speed_offset * delta
		var orbit_pos = center + Vector2(orbit_distance, 0).rotated(orbit_phase + orbit_phase_offset)
		var dir = orbit_pos - global_position
		if dir.length() > 4:
			velocity = dir.normalized() * move_speed * 0.8
			_play_run(dir.x)
		else:
			velocity = Vector2.ZERO
			_play_idle()
		wiggle_timer += delta
		sprite.rotation = sin(wiggle_timer * 6) * 0.07

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
	var timer = get_tree().create_timer(attack_cooldown * rng.randf_range(1, 1.25))
	timer.timeout.connect(func():
		can_attack = true
	)

func attack():
	aura_sprite.visible = true
	aura_sprite.scale = Vector2(0.1, 0.1)
	shockwave_shape.scale = Vector2(0.1, 0.1)
	shockwave.monitoring = true
	shockwave.monitorable = true
	aura_particles.restart()
	if Engine.has_singleton("SoundPlayer"):
		SoundPlayer.play_sound(SoundPlayer.EXPLOSION)
	if cam and cam.has_method("shake"):
		cam.shake(3, 0.08)

	var tween = get_tree().create_tween()
	tween.set_parallel()
	tween.tween_property(aura_sprite, "scale", Vector2(shockwave_max_scale, shockwave_max_scale), shockwave_scale_time)
	tween.tween_property(aura_sprite, "modulate:a", 0, shockwave_scale_time)
	tween.tween_property(shockwave_shape, "scale", Vector2(shockwave_max_scale, shockwave_max_scale), shockwave_scale_time)
	await tween.finished

	aura_sprite.visible = false
	aura_sprite.modulate.a = 1
	aura_sprite.scale = Vector2(0.1, 0.1)
	shockwave_shape.scale = Vector2(0.1, 0.1)
	shockwave.monitoring = false
	shockwave.monitorable = false

func _on_Shockwave_body_entered(body):
	if body and body.name == "Player":
		if body.has_method("take_damage"):
			body.take_damage(shockwave_damage)
		if body.has_method("apply_knockback"):
			body.apply_knockback((body.global_position - global_position).normalized() * knockback_force)

func _get_churros_defender_counts():
	var counts = {}
	for c in churros_list:
		counts[c] = 0
	for e in get_tree().get_nodes_in_group("enemies"):
		if e and e.has_method("get") and e.get("role") == "defender" and e.defending_target and counts.has(e.defending_target):
			counts[e.defending_target] += 1
	return counts

func _select_nearest_churros():
	var best = INF
	var nearest: Node2D
	var counts = _get_churros_defender_counts()
	for c in churros_list:
		if not c:
			continue
		var d = global_position.distance_to(c.global_position) + counts.get(c, 0) * 200
		if d < best:
			best = d
			nearest = c
	return nearest

func _ensure_attacker_exists():
	for e in get_tree().get_nodes_in_group("enemies"):
		if e and e.has_method("get") and e.get("role") == "attacker":
			return
	var best = INF
	var best_e
	for e in get_tree().get_nodes_in_group("enemies"):
		if e and player:
			var d = e.global_position.distance_to(player.global_position)
			if d < best:
				best = d
				best_e = e
	if best_e == self:
		role = "attacker"
		can_attack = false
		var t = get_tree().create_timer(0.2)
		t.timeout.connect(func():
			can_attack = true
		)

func _play_run(hx):
	sprite.flip_h = hx < 0
	if sprite.animation != "run":
		sprite.play("run")

func _play_idle():
	if sprite.animation != "idle":
		sprite.play("idle")
