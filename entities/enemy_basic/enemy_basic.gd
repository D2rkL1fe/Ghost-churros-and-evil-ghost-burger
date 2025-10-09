extends CharacterBody2D

@export_enum("defender", "attacker") var role: String = "defender"

@export var move_speed: float = 45.0
@export var shockwave_damage: int = 20
@export var attack_cooldown: float = 1.3
@export var knockback_force: float = 250.0
@export var shockwave_scale_time: float = 0.25
@export var shockwave_max_scale: float = 3.0
@export var detection_radius: float = 250.0
@export var attack_range: float = 70.0
@export var defense_radius: float = 300.0
@export var attack_variance: float = 0.4

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var shockwave: Area2D = $Shockwave
@onready var aura_sprite: Sprite2D = $Shockwave/Sprite2D
@onready var shockwave_shape: CollisionShape2D = $Shockwave/CollisionShape2D
@onready var aura_particles: GPUParticles2D = $Shockwave/FireParticles
@onready var cam: Camera2D = get_tree().get_first_node_in_group("camera")

var churros: Node2D
var player: Node2D
var can_attack: bool = true
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()

	player = _find_node_recursive(get_tree().get_current_scene(), "Player")
	churros = _find_node_recursive(get_tree().get_current_scene(), "Churros")

	if not player:
		push_warning("Enemy: couldn't find Player node!")
	if not churros:
		push_warning("Enemy: couldn't find Churros node!")

	shockwave.monitoring = false
	shockwave.monitorable = false
	if not shockwave.is_connected("body_entered", Callable(self, "_on_Shockwave_body_entered")):
		shockwave.connect("body_entered", Callable(self, "_on_Shockwave_body_entered"))

func _find_node_recursive(root: Node, target_name: String) -> Node:
	if not root:
		return null
	if root.name == target_name:
		return root
	for child in root.get_children():
		if child is Node:
			var found = _find_node_recursive(child, target_name)
			if found:
				return found
	return null

func _physics_process(delta: float) -> void:
	if not player or not churros:
		return

	match role:
		"defender":
			defender_behavior(delta)
		"attacker":
			attacker_behavior(delta)

	move_and_slide()

func defender_behavior(delta: float) -> void:
	var to_churros = churros.global_position - global_position
	var to_player = player.global_position - global_position
	var player_close = player.global_position.distance_to(churros.global_position) <= defense_radius

	if player_close:
		# Move to player if near churros
		velocity = to_player.normalized() * move_speed
		sprite.flip_h = to_player.x < 0
		if sprite.animation != "run":
			sprite.play("run")

		if can_attack and to_player.length() <= attack_range:
			start_attack()
	else:
		# Return near churros if player is gone
		if to_churros.length() > 30:
			velocity = to_churros.normalized() * (move_speed * 0.8)
			sprite.flip_h = to_churros.x < 0
			if sprite.animation != "run":
				sprite.play("run")
		else:
			velocity = Vector2.ZERO
			if sprite.animation != "idle":
				sprite.play("idle")

func attacker_behavior(delta: float) -> void:
	var to_player = player.global_position - global_position

	# Always chase player
	velocity = to_player.normalized() * move_speed
	sprite.flip_h = to_player.x < 0

	if sprite.animation != "run":
		sprite.play("run")

	if can_attack and to_player.length() <= attack_range:
		start_attack()

func start_attack() -> void:
	can_attack = false
	attack()
	var delay = attack_cooldown * rng.randf_range(1.0, 1.0 + attack_variance)
	get_tree().create_timer(delay).timeout.connect(func(): can_attack = true)

func attack() -> void:
	if not aura_sprite or not shockwave_shape:
		return

	shockwave.monitoring = true
	shockwave.monitorable = true
	aura_sprite.visible = true
	aura_sprite.scale = Vector2(0.1, 0.1)
	shockwave_shape.scale = Vector2(0.1, 0.1)

	SoundPlayer.play_sound(SoundPlayer.EXPLOSION)
	if cam and cam.has_method("shake"):
		cam.shake(3.0, 0.1)
	if aura_particles:
		aura_particles.restart()

	var tween := get_tree().create_tween()
	tween.set_parallel()
	tween.tween_property(aura_sprite, "scale", Vector2(shockwave_max_scale, shockwave_max_scale), shockwave_scale_time)
	tween.tween_property(shockwave_shape, "scale", Vector2(shockwave_max_scale, shockwave_max_scale), shockwave_scale_time)
	tween.tween_property(aura_sprite, "modulate:a", 0.0, shockwave_scale_time)
	await tween.finished

	aura_sprite.visible = false
	aura_sprite.modulate.a = 1.0
	aura_sprite.scale = Vector2(0.1, 0.1)
	shockwave_shape.scale = Vector2(0.1, 0.1)
	shockwave.monitoring = false
	shockwave.monitorable = false

func _on_Shockwave_body_entered(body: Node) -> void:
	if not body or body.name != "Player":
		return
	if body.has_method("take_damage"):
		body.take_damage(shockwave_damage)
	if body.has_method("apply_knockback"):
		var push = (body.global_position - global_position).normalized() * knockback_force
		body.apply_knockback(push)
