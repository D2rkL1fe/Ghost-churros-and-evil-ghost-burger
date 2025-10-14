extends CharacterBody2D

# --------------------------------------------------------------------------
## Exported Variables
# --------------------------------------------------------------------------
@export_enum("defender", "wanderer") var role: String = "defender"
@export var move_speed: float = 60.0
@export var shockwave_damage: int = 20
@export var attack_cooldown: float = 1.3
@export var knockback_force: float = 250.0
@export var shockwave_scale_time: float = 0.25
@export var shockwave_max_scale: float = 3.0
@export var attack_range: float = 48.0
@export var defense_radius: float = 150.0
@export var orbit_distance: float = 64.0
@export var orbit_speed: float = 1.6
@export var orbit_spread: float = 0.9
@export var health: int = 100
# ACTION REQUIRED: This MUST be assigned in the Inspector.
@export var health_bar: TextureProgressBar 
@export var dialog_scene: PackedScene
@export var wander_radius: float = 300.0

# --------------------------------------------------------------------------
## Node References
# --------------------------------------------------------------------------
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var shockwave: Area2D = $Shockwave
@onready var aura_sprite: Sprite2D = $Shockwave/Sprite2D
@onready var shockwave_shape: CollisionShape2D = $Shockwave/CollisionShape2D
@onready var aura_particles: GPUParticles2D = $Shockwave/FireParticles
@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D
@onready var blast_sound: AudioStreamPlayer2D = $BlastSound
@onready var cam: Camera2D = get_tree().get_first_node_in_group("camera")

# --------------------------------------------------------------------------
## State Variables
# --------------------------------------------------------------------------
var player: Node2D = null
var churros_list: Array[Node2D] = []
var defending_target: Node2D = null

var can_attack: bool = true
var alert_state: bool = false
var orbit_phase: float = 0.0
var orbit_speed_offset: float = 1.0
var orbit_phase_offset: float = 0.0
var wander_target_position: Vector2 = Vector2.ZERO
var wiggle_timer := 0.0
var dialog_instance: Control = null
var rng := RandomNumberGenerator.new()

# --------------------------------------------------------------------------
## Built-in Godot Functions
# --------------------------------------------------------------------------
func _ready() -> void:
	# --- ESSENTIAL NODE CHECKS ---
	if not navigation_agent:
		push_error("Missing NavigationAgent2D node! Movement will not work.")
		set_physics_process(false) 
		return
	if not health_bar:
		# Error line 72/75 (Warning)
		push_warning("HealthBar (TextureProgressBar) not assigned to @export var! Assign it in the Inspector.")
	# ------------------------------

	add_to_group("enemies")
	rng.randomize()

	_initialize_defender_orbit()
	_initialize_wanderer_state()
	
	player = get_tree().get_first_node_in_group("player")
	
	var nodes_in_group = get_tree().get_nodes_in_group("churros")
	churros_list = []
	for node in nodes_in_group:
		if node is Node2D:
			churros_list.append(node as Node2D)

	_setup_shockwave()
	_setup_dialog()
	_setup_navigation()


func _physics_process(delta: float) -> void:
	if not is_instance_valid(player):
		velocity = Vector2.ZERO
		_play_idle()
		return

	_ensure_wanderer_exists()

	if role == "defender":
		_defender_behavior(delta)
	else: # role == "wanderer"
		_wanderer_behavior(delta)

	move_and_slide()

# --------------------------------------------------------------------------
## Setup Functions
# --------------------------------------------------------------------------
func _initialize_defender_orbit() -> void:
	orbit_phase = rng.randf_range(0.0, TAU)
	orbit_phase_offset = rng.randf_range(0.0, TAU)
	orbit_speed_offset = rng.randf_range(1.0 - orbit_spread, 1.0 + orbit_spread)
	orbit_distance += rng.randf_range(-10.0, 10.0)

func _initialize_wanderer_state() -> void:
	if role == "wanderer":
		_set_new_wander_target()

func _setup_shockwave() -> void:
	if aura_sprite: aura_sprite.visible = false
	if shockwave: shockwave.monitoring = false
	shockwave.body_entered.connect(_on_shockwave_body_entered)

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

# --------------------------------------------------------------------------
## Behavior Logic
# --------------------------------------------------------------------------
func _wanderer_behavior(_delta: float) -> void:
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

func _defender_behavior(delta: float) -> void:
	var needs_new_target = not is_instance_valid(defending_target) or Engine.get_physics_frames() % 60 == 0
	
	if needs_new_target:
		defending_target = _find_best_churro_to_defend()

	if not is_instance_valid(defending_target):
		_navigate_to(global_position)
		return

	var center = defending_target.global_position
	var to_player = player.global_position - global_position
	
	var current_defense_radius = defense_radius * (0.5 if alert_state else 1.0)
	var current_orbit_distance = orbit_distance * (0.75 if alert_state else 1.0)

	var target_pos: Vector2
	if player.global_position.distance_to(center) <= current_defense_radius:
		target_pos = player.global_position
		if to_player.length() <= attack_range and can_attack:
			start_attack()
	else:
		orbit_phase += orbit_speed * orbit_speed_offset * delta
		var target_angle = orbit_phase + orbit_phase_offset
		target_pos = center + Vector2(current_orbit_distance, 0).rotated(target_angle)

	_navigate_to(target_pos)
	
	wiggle_timer += delta
	sprite.rotation = sin(wiggle_timer * 6.0) * 0.07

# --------------------------------------------------------------------------
## Navigation
# --------------------------------------------------------------------------
func _navigate_to(target_position: Vector2) -> void:
	navigation_agent.target_position = target_position
	var next_path_pos = navigation_agent.get_next_path_position()
	
	var desired_velocity = (next_path_pos - global_position).normalized() * move_speed
	
	navigation_agent.set_velocity(desired_velocity)

func _on_velocity_computed(safe_velocity: Vector2) -> void:
	# This is where the enemy's final velocity is set for move_and_slide()
	velocity = safe_velocity
	
	if velocity.length() > 0.1:
		_play_run(velocity.x)
	else:
		_play_idle()

# --------------------------------------------------------------------------
## Target Selection
# --------------------------------------------------------------------------
func _find_best_churro_to_defend() -> Node2D:
	var nearest_churro: Node2D = null
	var best_score = INF
	var defender_counts = _get_churros_defender_counts()

	for churro in churros_list:
		if not is_instance_valid(churro):
			continue
		
		var defenders_here = defender_counts.get(churro, 0)
		var defense_cost = 200.0 * (0.5 if alert_state else 1.0)
		var score = global_position.distance_to(churro.global_position) + defenders_here * defense_cost
		
		if score < best_score:
			best_score = score
			nearest_churro = churro
			
	return nearest_churro

func _get_churros_defender_counts() -> Dictionary:
	var counts := {}
	for c in churros_list:
		if is_instance_valid(c):
			counts[c] = 0

	for enemy in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(enemy):
			var defender_enemy = enemy as CharacterBody2D
			if defender_enemy.has_method("get") and defender_enemy.get("role") == "defender":
				if is_instance_valid(defender_enemy.defending_target) and counts.has(defender_enemy.defending_target):
					counts[defender_enemy.defending_target] += 1
	return counts

func _set_new_wander_target() -> void:
	var random_angle = rng.randf_range(0, TAU)
	var random_distance = rng.randf_range(50.0, wander_radius)
	var offset = Vector2.from_angle(random_angle) * random_distance
	
	var query_parameters = NavigationPathQueryParameters2D.new()
	query_parameters.map = get_world_2d().navigation_map
	
	var new_pos = NavigationServer2D.map_get_closest_point(query_parameters.map, global_position + offset)
	wander_target_position = new_pos


# --------------------------------------------------------------------------
## Attack and Damage
# --------------------------------------------------------------------------
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
	# Error line 323 (Error)
	if is_instance_valid(health_bar):
		health_bar.value = health
	else:
		push_error("HealthBar is null or invalid! Did you forget to assign it in the Inspector?")

	if health <= 0:
		die()

func die() -> void:
	if role == "wanderer":
		_alert_all_defenders()
	queue_free()

func apply_knockback(force: Vector2) -> void:
	velocity += force

# --------------------------------------------------------------------------
## Alert System & Role Management
# --------------------------------------------------------------------------
func _ensure_wanderer_exists() -> void:
	for e in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(e) and (e as CharacterBody2D).role == "wanderer":
			return

	var all_defenders = get_tree().get_nodes_in_group("enemies").filter(
		func(e): return is_instance_valid(e) and (e as CharacterBody2D).role == "defender"
	)
	
	if all_defenders.is_empty():
		return

	all_defenders.sort_custom(
		func(a, b): return (a as Node2D).global_position.distance_to(player.global_position) < (b as Node2D).global_position.distance_to(player.global_position)
	)
	
	var closest_defender = all_defenders[0] as CharacterBody2D
	if closest_defender == self:
		role = "wanderer"
		_set_new_wander_target()
		
		can_attack = false
		get_tree().create_timer(0.2).timeout.connect(func(): can_attack = true)
		
		_alert_all_defenders()

func _alert_all_defenders() -> void:
	for e in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(e):
			var enemy = e as CharacterBody2D
			if enemy.has_method("get") and enemy.get("role") == "defender":
				enemy.alert_state = true

# --------------------------------------------------------------------------
## Animation
# --------------------------------------------------------------------------
func _play_run(x_direction: float) -> void:
	sprite.flip_h = x_direction < 0
	if sprite.animation != "run":
		sprite.play("run")

func _play_idle() -> void:
	if sprite.animation != "idle":
		sprite.play("idle")
