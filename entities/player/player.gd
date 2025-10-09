class_name Player
extends CharacterBody2D

@export var sprite: AnimatedSprite2D
@export var speed: float = 150.0
@onready var cam: Camera2D = $Camera2D

var health: int = 100
var velocity_y_offset := 0.0
var float_timer := 0.0

func _physics_process(delta: float) -> void:
	var input_dir = Input.get_vector("left", "right", "up", "down")

	# Move and flip
	if input_dir.x:
		sprite.flip_h = input_dir.x < 0

	velocity = input_dir * speed
	move_and_slide()

	# Gentle float animation (makes the ghost look alive)
	float_timer += delta * 3.0
	velocity_y_offset = sin(float_timer) * 2.0
	sprite.position.y = velocity_y_offset

func take_damage(amount: int) -> void:
	health -= amount
	print("Player took damage:", amount, " | HP:", health)
	
	SoundPlayer.play_sound(SoundPlayer.HURT)

	if sprite:
		var flash_tween = get_tree().create_tween()
		flash_tween.tween_property(sprite, "modulate", Color(1, 0.3, 0.3), 0.1)
		flash_tween.tween_property(sprite, "modulate", Color(1, 1, 1), 0.2)

	if cam and cam.has_method("shake"):
		cam.shake(6.0, 0.25)

	if health <= 0:
		die()

func apply_knockback(force: Vector2) -> void:
	velocity += force

func die() -> void:
	SoundPlayer.play_sound(SoundPlayer.DEATH)
	MusicPlayer.play_music(MusicPlayer.DEATH)
	
	GlobalStats.end()
