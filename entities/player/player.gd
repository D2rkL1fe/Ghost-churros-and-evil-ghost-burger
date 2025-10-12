extends CharacterBody2D
class_name Player

@export var speed: float = 150.0
@export var bullet_scene: PackedScene
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var health_bar: TextureProgressBar = $HealthBarComponent
@onready var cam: Camera2D = $Camera2D

var health: int = 100
var max_health: int = 100
var ammo: int = 0

func _ready() -> void:
	health = max_health
	health_bar.max_value = max_health
	health_bar.value = health
	# make sure this node is in the "player" group (you can also add it in editor)
	if not is_in_group("player"):
		add_to_group("player")

func _physics_process(_delta: float) -> void:
	var input_dir = Input.get_vector("left", "right", "up", "down")
	velocity = input_dir * speed
	move_and_slide()

	# animations
	if input_dir.x != 0:
		sprite.flip_h = input_dir.x < 0
		if sprite.animation != "run":
			sprite.play("run")
	elif sprite.animation != "idle":
		sprite.play("idle")

	# player shooting (if you use it)
	if Input.is_action_just_pressed("shoot") and ammo > 0:
		shoot_bullet()

func shoot_bullet() -> void:
	if bullet_scene == null:
		return
	var bullet = bullet_scene.instantiate()
	get_parent().add_child(bullet)
	bullet.global_position = global_position
	# If bullet expects a direction property (see BounceBullet.gd), set it:
	if bullet.has_meta("direction") or "direction" in bullet:
		bullet.direction = (get_global_mouse_position() - global_position).normalized()
	ammo -= 1
	# optional global updates / sounds
	# GlobalStats.add_churros_bullets(-1)
	# SoundPlayer.play_sound(SoundPlayer.SHOOT)

func take_damage(amount: int) -> void:
	if health <= 0:
		return
	health -= amount
	health_bar.value = health
	# SoundPlayer.play_sound(SoundPlayer.HURT)
	if cam and cam.has_method("shake"):
		cam.shake(6.0, 0.25)
	if health <= 0:
		die()

func apply_knockback(force: Vector2) -> void:
	velocity += force

func die() -> void:
	# SoundPlayer.play_sound(SoundPlayer.DEATH)
	Global.end()
