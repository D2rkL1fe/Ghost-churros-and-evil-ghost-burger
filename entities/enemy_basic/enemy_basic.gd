extends CharacterBody2D
@export_enum("defender", "attacker") var role: String = "defender"

@export var move_speed: float = 80.0
@export var shockwave_damage: int = 20
@export var attack_cooldown: float = 1.3
@export var knockback_force: float = 250.0
@export var shockwave_scale_time: float = 0.25
@export var shockwave_max_scale: float = 3.0
@export var detection_radius: float = 200.0
@export var attack_range: float = 48.0
@export var defense_radius: float = 300.0

# Orbit tuning
@export var orbit_distance: float = 64.0
@export var orbit_speed: float = 1.6
@export var orbit_spread: float = 0.9

var rng := RandomNumberGenerator.new()
var orbit_phase: float = 0.0
var orbit_speed_offset: float = 1.0
var orbit_phase_offset: float = 0.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var shockwave: Area2D = $Shockwave
@onready var aura_sprite: Sprite2D = $Shockwave/Sprite2D
@onready var shockwave_shape: CollisionShape2D = $Shockwave/CollisionShape2D
@onready var aura_particles: GPUParticles2D = $Shockwave/FireParticles
@onready var cam: Camera2D = get_tree().get_first_node_in_group("camera")

var player: Node2D = null
var churros_list: Array = []
var defending_target: Node2D = null
var can_attack: bool = true

func _ready() -> void:
	rng.randomize()
	orbit_phase = rng.randf_range(0.0, TAU)
	orbit_phase_offset = rng.randf_range(0.0, TAU)
	orbit_speed_offset = rng.randf_range(1.0 - orbit_spread, 1.0 + orbit_spread)

	player = _find_node_recursive(get_tree().get_current_scene(), "Player")
	churros_list = _find_all_churros(get_tree().get_current_scene())

	if not player:
		push_warning("Enemy: Player node not found.")
	if churros_list.is_empty():
		push_warning("Enemy: No churros found (add to group 'churros' or include 'churro' in name).")

	if aura_sprite:
		aura_sprite.visible = false
		aura_sprite.scale = Vector2(0.1, 0.1)
	if shockwave_shape:
		shockwave_shape.scale = Vector2(0.1, 0.1)
	if shockwave:
		shockwave.monitoring = false
		shockwave.monitorable = false
		if not shockwave.is_connected("body_entered", Callable(self, "_on_Shockwave_body_entered")):
			shockwave.connect("body_entered", Callable(self, "_on_Shockwave_body_entered"))

	add_to_group("enemies")

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

func _find_all_churros(root: Node) -> Array:
	var list: Array = []
	for n in get_tree().get_nodes_in_group("churros"):
		if n is Node2D and not list.has(n):
			list.append(n)
	if list.is_empty():
		_collect_churros_recursive(root, list)
	return list

func _collect_churros_recursive(node: Node, out_list: Array) -> void:
	for child in node.get_children():
		if child is Node2D:
			var lower = child.name.to_lower()
			if lower.find("churro") != -1 and not out_list.has(child):
				out_list.append(child)
		_collect_churros_recursive(child, out_list)

func _physics_process(delta: float) -> void:
	if not player:
		player = _find_node_recursive(get_tree().get_current_scene(), "Player")
	if churros_list.is_empty():
		churros_list = _find_all_churros(get_tree().get_current_scene())

	if not player:
		return

	_ensure_attacker_exists()

	if role == "defender":
		_defender_behavior(delta)
	else:
		_attacker_behavior(delta)

	move_and_slide()
# DEFENDER
func _defender_behavior(delta: float) -> void:
	if defending_target == null or not is_instance_valid(defending_target):
		defending_target = _select_nearest_churros_to_self()
	if defending_target == null:
		velocity = Vector2.ZERO
		_play_idle()
		return

	var center = defending_target.global_position
	var dist_player_to_target = player.global_position.distance_to(center)
	var dist_to_target = global_position.distance_to(center)
	var to_player = player.global_position - global_position

	if dist_player_to_target <= defense_radius:
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
		var target_angle = orbit_phase + orbit_phase_offset
		var orbit_pos = center + Vector2(orbit_distance, 0).rotated(target_angle)
		var dir = orbit_pos - global_position

		if dir.length() > 6:
			velocity = dir.normalized() * move_speed * 0.8
			_play_run(dir.x)
		else:
			velocity = Vector2.ZERO
			_play_idle()

func _select_nearest_churros_to_self() -> Node2D:
	var nearest: Node2D = null
	var best := INF
	for c in churros_list:
		if not c:
			continue
		var d = global_position.distance_to(c.global_position)
		if d < best:
			best = d
			nearest = c
	return nearest

# ATTACKER
func _attacker_behavior(delta: float) -> void:
	var to_player = player.global_position - global_position
	if to_player.length() > 8:
		velocity = to_player.normalized() * move_speed
		_play_run(to_player.x)
	else:
		velocity = Vector2.ZERO
		_play_idle()

	if can_attack and to_player.length() <= attack_range:
		start_attack()

# ATTACK / SHOCKWAVE
func start_attack() -> void:
	can_attack = false
	attack()
	var delay = attack_cooldown * rng.randf_range(1.0, 1.0 + 0.25)
	var t = get_tree().create_timer(delay)
	t.timeout.connect(func(): can_attack = true)

func attack() -> void:
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
	if Engine.has_singleton("SoundPlayer"):
		SoundPlayer.play_sound(SoundPlayer.EXPLOSION)
	if cam and cam.has_method("shake"):
		cam.shake(3.0, 0.08)

	var tween = get_tree().create_tween()
	tween.set_parallel()
	if aura_sprite:
		tween.tween_property(aura_sprite, "scale", Vector2(shockwave_max_scale, shockwave_max_scale), shockwave_scale_time)
		tween.tween_property(aura_sprite, "modulate:a", 0.0, shockwave_scale_time)
	if shockwave_shape:
		tween.tween_property(shockwave_shape, "scale", Vector2(shockwave_max_scale, shockwave_max_scale), shockwave_scale_time)
	await tween.finished

	if aura_sprite:
		aura_sprite.visible = false
		aura_sprite.modulate.a = 1.0
		aura_sprite.scale = Vector2(0.1, 0.1)
	if shockwave_shape:
		shockwave_shape.scale = Vector2(0.1, 0.1)
	if shockwave:
		shockwave.monitoring = false
		shockwave.monitorable = false

func _on_Shockwave_body_entered(body: Node) -> void:
	if not body:
		return
	if body.name != "Player":
		return
	if body.has_method("take_damage"):
		body.take_damage(shockwave_damage)
	if body.has_method("apply_knockback"):
		var push = (body.global_position - global_position).normalized() * knockback_force
		body.apply_knockback(push)

# GROUP 

func _ensure_attacker_exists() -> void:
	var enemies = get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		if e == null:
			continue
		if e.has_method("get") and e.get("role") == "attacker":
			return
	var best := INF
	var best_e = null
	for e in enemies:
		if e == null:
			continue
		if player:
			var d = e.global_position.distance_to(player.global_position)
			if d < best:
				best = d
				best_e = e
	if best_e and best_e == self:
		role = "attacker"
		can_attack = false
		get_tree().create_timer(0.2).timeout.connect(func(): can_attack = true)

# ANIMATION
func _play_run(hx: float) -> void:
	if sprite:
		sprite.flip_h = hx < 0
		if sprite.animation != "run":
			sprite.play("run")

func _play_idle() -> void:
	if sprite:
		if sprite.animation != "idle":
			sprite.play("idle")
