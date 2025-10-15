extends CharacterBody2D

@export var move_speed: float = 60.0
@export var shockwave_damage: int = 20
@export var attack_cooldown: float = 0.8
@export var knockback_force: float = 250.0
@export var shockwave_scale_time: float = 0.25
@export var shockwave_max_scale: float = 3.0
@export var attack_range: float = 200.0
@export var health: int = 60
@export var health_bar: TextureProgressBar
@export var dialog_scene: PackedScene
@export var wander_radius: float = 400.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var shockwave: Area2D = $Shockwave
@onready var aura_sprite: Sprite2D = $Shockwave/Sprite2D
@onready var shockwave_shape: CollisionShape2D = $Shockwave/CollisionShape2D
@onready var aura_particles: GPUParticles2D = $Shockwave/FireParticles
@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D
@onready var blast_sound: AudioStreamPlayer2D = $BlastSound
@onready var cam: Camera2D = get_tree().get_first_node_in_group("camera")

var player: Node2D = null
var can_attack: bool = true
var wander_target_position: Vector2 = Vector2.ZERO
var dialog_instance: Control = null
var rng := RandomNumberGenerator.new()
var is_initialized: bool = false

func _ready() -> void:
	if not navigation_agent:
		push_error("Missing NavigationAgent2D node! Movement will not work.")
		set_physics_process(false) 
		return
	if not health_bar:
		push_warning("HealthBar (TextureProgressBar) not assigned to @export var! Assign it in the Inspector.")

	add_to_group("enemies")
	rng.randomize()

	health_bar.max_value = health
	if aura_sprite:
		aura_sprite.visible = false
		aura_sprite.scale = Vector2(0.1, 0.1)
	if shockwave_shape:
		shockwave_shape.scale = Vector2(0.1, 0.1)
	if shockwave:
		shockwave.monitoring = false
		shockwave.monitorable = false
	
	player = get_tree().get_first_node_in_group("player")

	_setup_dialog()
	_setup_navigation()


func _physics_process(delta: float) -> void:
	if not is_initialized:
		var map_rid = get_world_2d().navigation_map
		if map_rid.is_valid() and NavigationServer2D.map_get_iteration_id(map_rid) > 0:
			_set_new_wander_target()
			is_initialized = true
		else:
			velocity = Vector2.ZERO
			return

	if not is_instance_valid(player):
		velocity = Vector2.ZERO
		_play_idle()
		return

	_ai_behavior(delta)

	move_and_slide()

func _setup_dialog() -> void:
	if dialog_scene:
		dialog_instance = dialog_scene.instantiate()
		add_child(dialog_instance)
		dialog_instance.hide()

func _setup_navigation() -> void:
	navigation_agent.avoidance_enabled = true
	navigation_agent.velocity_computed.connect(_on_velocity_computed)
	if not get_world_2d().navigation_map.is_valid():
		push_warning("No valid Navigation Map found! Check your NavigationRegion2D setup and baked mesh.")

func _ai_behavior(_delta: float) -> void:
	var to_player = player.global_position - global_position
	var target_pos: Vector2

	if to_player.length() <= wander_radius:
		target_pos = player.global_position
		if can_attack and to_player.length() <= attack_range:
			start_attack()
	else:
		target_pos = wander_target_position
		if global_position.distance_to(target_pos) < 16.0:
			_set_new_wander_target()

	_navigate_to(target_pos)

func _navigate_to(target_position: Vector2) -> void:
	navigation_agent.target_position = target_position
	var next_path_pos = navigation_agent.get_next_path_position()
	
	var desired_velocity = (next_path_pos - global_position).normalized() * move_speed
	
	navigation_agent.set_velocity(desired_velocity)

func _on_velocity_computed(safe_velocity: Vector2) -> void:
	if navigation_agent.is_navigation_finished():
		velocity = Vector2.ZERO
		_play_idle()
	else:
		velocity = safe_velocity
		
		if velocity.length() > 0.1:
			_play_run(velocity.x)
		else:
			_play_idle()

func _set_new_wander_target() -> void:
	var random_angle = rng.randf_range(0, TAU)
	var random_distance = rng.randf_range(50.0, wander_radius)
	var offset = Vector2.from_angle(random_angle) * random_distance
	
	var query_parameters = NavigationPathQueryParameters2D.new()
	query_parameters.map = get_world_2d().navigation_map
	
	var new_pos = NavigationServer2D.map_get_closest_point(query_parameters.map, global_position + offset)
	wander_target_position = new_pos

func start_attack() -> void:
	if not can_attack:
		return
	can_attack = false
	
	_perform_attack_visuals()
	
	if dialog_instance:
		dialog_instance.call("show_random_dialog")
		
	var delay = attack_cooldown * rng.randf_range(1.0, 1.25)
	get_tree().create_timer(delay).timeout.connect(func(): can_attack = true)


func _perform_attack_visuals() -> void:
	shockwave.monitoring = true
	aura_sprite.visible = true
	aura_sprite.scale = Vector2.ONE * 0.1
	aura_sprite.modulate.a = 1.0
	shockwave_shape.scale = Vector2.ONE * 0.1
	aura_particles.restart()

	if blast_sound: blast_sound.play()
		
	if cam and cam.has_method("shake"):
		cam.shake(3.0, 0.08)

	var tween = create_tween().set_parallel()
	var final_scale = Vector2.ONE * shockwave_max_scale
	tween.tween_property(aura_sprite, "scale", final_scale, shockwave_scale_time)
	tween.tween_property(aura_sprite, "modulate:a", 0.0, shockwave_scale_time)
	tween.tween_property(shockwave_shape, "scale", final_scale, shockwave_scale_time)

	await tween.finished
	
	shockwave.monitoring = false
	aura_sprite.visible = false

func _on_shockwave_body_entered(body: Node) -> void:
	if body != player: return
	
	if body.has_method("take_damage"):
		body.take_damage(shockwave_damage)
	if body.has_method("apply_knockback"):
		var push_direction = (body.global_position - global_position).normalized()
		body.apply_knockback(push_direction * knockback_force)

func take_damage(damage: int) -> void:
	health -= damage
	if is_instance_valid(health_bar):
		health_bar.value = health
	else:
		push_error("HealthBar is null or invalid! Did you forget to assign it in the Inspector?")

	if health <= 0:
		die()

func die() -> void:
	SoundPlayer.play_sound(SoundPlayer.EXPLOSION)
	Particles.create_particles(global_position)
	
	queue_free()

func apply_knockback(force: Vector2) -> void:
	velocity += force

func _play_run(x_direction: float) -> void:
	sprite.flip_h = x_direction < 0
	if sprite.animation != "run":
		sprite.play("run")

func _play_idle() -> void:
	if sprite.animation != "idle":
		sprite.play("idle")
