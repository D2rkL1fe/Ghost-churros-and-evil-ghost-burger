extends CharacterBody2D

@export var move_speed: float = 60.0
@export var shockwave_damage: int = 20
@export var attack_cooldown: float = 2.0
@export var knockback_force: float = 200.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var shockwave: Area2D = $Shockwave
@onready var aura_sprite: Sprite2D = $Shockwave/Sprite2D

var player: Node2D = null
var can_attack: bool = true

func _ready() -> void:
	# Find the Player node anywhere under the current scene root (safe recursive search)
	player = _find_node_recursive(get_tree().get_current_scene(), "Player")
	if not player:
		push_warning("Enemy: couldn't find a node named 'Player' in the current scene.")

	# Disable the shockwave Area2D by default
	if shockwave:
		shockwave.monitoring = false
		shockwave.monitorable = false

	# Connect the shockwave collision once
	if shockwave and not shockwave.is_connected("body_entered", Callable(self, "_on_Shockwave_body_entered")):
		shockwave.connect("body_entered", Callable(self, "_on_Shockwave_body_entered"))


# Recursive helper to find a node by name (returns the first match)
func _find_node_recursive(root: Node, target_name: String) -> Node:
	if root == null:
		return null
	if root.name == target_name:
		return root
	for child in root.get_children():
		if child is Node:
			var found = _find_node_recursive(child, target_name)
			if found:
				return found
	return null


# Enemy movement (simple chase)
func _physics_process(_delta: float) -> void:
	if not player:
		return

	var dir = (player.global_position - global_position)
	if dir.length() == 0.0:
		velocity = Vector2.ZERO
	else:
		velocity = dir.normalized() * move_speed

	move_and_slide()


# Handles timing for aura attack
func _process(_delta: float) -> void:
	if can_attack:
		can_attack = false
		await attack()
		await get_tree().create_timer(attack_cooldown).timeout
		can_attack = true


# Performs visual + functional aura blast
func attack() -> void:
	if not aura_sprite:
		return

	# Visual effect
	aura_sprite.scale = Vector2(0.1, 0.1)
	aura_sprite.visible = true
	shockwave.monitoring = true
	shockwave.monitorable = true

	var tween = get_tree().create_tween()
	tween.tween_property(aura_sprite, "scale", Vector2(3, 3), 0.3)
	tween.tween_property(aura_sprite, "modulate:a", 0.0, 0.3)
	await tween.finished

	# Reset
	aura_sprite.visible = false
	aura_sprite.modulate.a = 1.0
	aura_sprite.scale = Vector2(0.1, 0.1)
	shockwave.monitoring = false
	shockwave.monitorable = false


# Called when player is hit by the shockwave
func _on_Shockwave_body_entered(body: Node) -> void:
	if body == null:
		return
	# name check is simple; you can use groups instead for more robust checks
	if body.name == "Player":
		if body.has_method("take_damage"):
			body.take_damage(shockwave_damage)
		if body.has_method("apply_knockback"):
			var push = (body.global_position - global_position)
			if push.length() != 0:
				push = push.normalized() * knockback_force
			body.apply_knockback(push)
