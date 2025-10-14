extends CharacterBody2D

@export_enum("defender", "attacker") var role: String = "defender"
@export var move_speed: float = 60.0
@export var shockwave_damage: int = 20
@export var attack_cooldown: float = 1.3
@export var knockback_force: float = 250.0
@export var shockwave_scale_time: float = 0.25
@export var shockwave_max_scale: float = 3.0
@export var detection_radius: float = 25.0
@export var attack_range: float = 48.0
@export var defense_radius: float = 150.0
@export var orbit_distance: float = 64.0
@export var orbit_speed: float = 1.6
@export var orbit_spread: float = 0.9
@export var health: int = 60
@export var health_bar: TextureProgressBar
@export var dialog_scene: PackedScene

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
var idle_buffer_time := 0.2
var idle_timer := 0.0
var last_moving := false
var wiggle_timer := 0.0
var wiggle_dir := 1.0
var dialog_instance: Control = null
var dialog_rng := RandomNumberGenerator.new()

func _ready() -> void:
	add_to_group("enemies")
	rng.randomize()
	dialog_rng.randomize()

	orbit_phase = rng.randf_range(0.0, TAU)
	orbit_phase_offset = rng.randf_range(0.0, TAU)
	orbit_speed_offset = rng.randf_range(1.0 - orbit_spread, 1.0 + orbit_spread)
	orbit_distance += rng.randf_range(-10.0, 10.0)

	player = _find_node_recursive(get_tree().get_current_scene(), "Player")
	churros_list = _find_all_churros(get_tree().get_current_scene())

	health_bar.max_value = health

	if aura_sprite:
		aura_sprite.visible = false
		aura_sprite.scale = Vector2(0.1, 0.1)
	if shockwave_shape:
		shockwave_shape.scale = Vector2(0.1, 0.1)
	if shockwave:
		shockwave.monitoring = false
		shockwave.monitorable = false
		if not shockwave.is_connected("body_entered", _on_Shockwave_body_entered):
			shockwave.body_entered.connect(Callable(self, "_on_Shockwave_body_entered"))

	if dialog_scene:
		dialog_instance = dialog_scene.instantiate()
		add_child(dialog_instance)
		dialog_instance.hide()

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

func _defender_behavior(delta: float) -> void:
	if defending_target == null or not is_instance_valid(defending_target):
		defending_target = _select_nearest_churros_to_self()
	if defending_target == null:
		velocity = Vector2.ZERO
		_play_idle()
		return

	var center = defending_target.global_position
	var dist_player_to_target = player.global_position.distance_to(center)
	var to_player = player.global_position - global_position

	if dist_player_to_target <= defense_radius:
		if to_player.length() <= attack_range and can_attack:
			start_attack()

		if to_player.length() > 6:
			velocity += to_player.normalized() * move_speed * 0.75
			velocity = velocity.clamp(Vector2(-60, -60), Vector2(60, 60))
			_play_run(to_player.x)
		else:
			velocity = Vector2.ZERO
			_play_idle()
	else:
		orbit_phase += orbit_speed * orbit_speed_offset * delta
		var target_angle = orbit_phase + orbit_phase_offset
		var orbit_pos = center + Vector2(orbit_distance, 0).rotated(target_angle)
		var dir = orbit_pos - global_position

		if dir.length() > 4:
			velocity = dir.normalized() * move_speed * 0.8
			_play_run(dir.x)
			last_moving = true
			idle_timer = 0.0
		else:
			if last_moving:
				idle_timer += delta
				if idle_timer >= idle_buffer_time:
					last_moving = false
					velocity = Vector2.ZERO
					_play_idle()
			else:
				velocity = Vector2.ZERO
				_play_idle()

	wiggle_timer += delta
	sprite.rotation = sin(wiggle_timer * 6.0) * 0.07

func _get_churros_defender_counts() -> Dictionary:
	var counts := {}
	for c in churros_list:
		if c:
			counts[c] = 0

	for e in get_tree().get_nodes_in_group("enemies"):
		if e and e.has_method("get") and e.get("role") == "defender" and e.defending_target and counts.has(e.defending_target):
			counts[e.defending_target] += 1
	return counts

func _select_nearest_churros_to_self() -> Node2D:
	var nearest: Node2D = null
	var best := INF
	var counts = _get_churros_defender_counts()

	for c in churros_list:
		if not c:
			continue
		var defenders_here = counts.get(c, 0)
		var d = global_position.distance_to(c.global_position) + defenders_here * 200.0
		if d < best:
			best = d
			nearest = c
	return nearest

func _attacker_behavior(_delta: float) -> void:
	var to_player = player.global_position - global_position
	if to_player.length() > 8:
		velocity = to_player.normalized() * move_speed
		_play_run(to_player.x)
	else:
		velocity = Vector2.ZERO
		_play_idle()

	if can_attack and to_player.length() <= attack_range:
		start_attack()

func start_attack() -> void:
	can_attack = false
	attack()
	if dialog_instance:
		dialog_instance.call("show_random_dialog")
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

func _play_run(hx: float) -> void:
	if sprite:
		sprite.flip_h = hx < 0
		if sprite.animation != "run":
			sprite.play("run")

func _play_idle() -> void:
	if sprite:
		if sprite.animation != "idle":
			sprite.play("idle")

func take_damage(damage: int) -> void:
	health -= damage
	if health_bar:
		health_bar.value = health
	if health <= 0:
		queue_free()
		SoundPlayer.play_sound(SoundPlayer.EXPLOSION)

func die() -> void:
	queue_free()

func apply_knockback(force: Vector2) -> void:
	velocity += force
