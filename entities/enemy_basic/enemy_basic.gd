extends CharacterBody2D

@export var move_speed: float = 20.0
@export var shockwave_damage: int = 20
@export var attack_cooldown: float = 2.0
@export var knockback_force: float = 200.0
@export var shockwave_scale_time: float = 0.3
@export var shockwave_max_scale: float = 3.0
@export var detection_radius: float = 200.0
@export var attack_variance: float = 0.8

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var shockwave: Area2D = $Shockwave
@onready var aura_sprite: Sprite2D = $Shockwave/Sprite2D
@onready var shockwave_shape: CollisionShape2D = $Shockwave/CollisionShape2D
@onready var aura_particles: GPUParticles2D = $Shockwave/FireParticles
@onready var cam: Camera2D = get_tree().get_first_node_in_group("camera")

var player: Node2D = null
var can_attack: bool = true
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()
	player = _find_node_recursive(get_tree().get_current_scene(), "Player")
	if not player:
		push_warning("Enemy: couldn't find Player node in the scene!")

	if shockwave:
		shockwave.monitoring = false
		shockwave.monitorable = false

	if shockwave and not shockwave.is_connected("body_entered", Callable(self, "_on_Shockwave_body_entered")):
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

func _physics_process(_delta: float) -> void:
	if not player:
		return
	var to_player := player.global_position - global_position
	
	if to_player.length() <= detection_radius:
		velocity = to_player.normalized() * move_speed
		sprite.flip_h = to_player.x < 0
		
		sprite.play("run")
	else:
		velocity =  Vector2.ZERO
		
		sprite.play("idle")
	
	move_and_slide()

func _process(_delta: float) -> void:
	if can_attack and player and global_position.distance_to(player.global_position) <= detection_radius:
		can_attack = false
		await attack()
		var delay = attack_cooldown * rng.randf_range(1.0, 1.0 + attack_variance)
		await get_tree().create_timer(delay).timeout
		can_attack = true

func attack() -> void:
	if not aura_sprite or not shockwave_shape:
		return

	shockwave.monitoring = true
	shockwave.monitorable = true
	aura_sprite.visible = true

	aura_sprite.scale = Vector2(0.1, 0.1)
	shockwave_shape.scale = Vector2(0.1, 0.1)

	# audio
	SoundPlayer.play_sound(SoundPlayer.EXPLOSION)
	
	# particles
	if aura_particles:
		aura_particles.restart()
	
	# camera shaky shaky
	if cam and cam.has_method("shake"):
		cam.shake(3.0, 0.1)

	# war crimes
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
