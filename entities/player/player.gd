extends CharacterBody2D
class_name Player

@export var speed: float = 150.0
@export var bullet_scene: PackedScene
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var health_bar: TextureProgressBar = $HealthBar
@onready var ammo_bar: TextureProgressBar = $AmmoBar
@onready var churros_count_label: Label = $ChurrosCount
@onready var cam: Camera2D = $Camera2D

var health: int = 100
var max_health: int = 100
var ammo: int = 0

func _ready():
	health = max_health
	health_bar.max_value = max_health
	health_bar.value = health
	ammo_bar.max_value = 100
	ammo_bar.value = ammo
	churros_count_label.text = str(ammo)

func _physics_process(_delta):
	# Movement
	var input_dir = Input.get_vector("left", "right", "up", "down")
	velocity = input_dir * speed
	move_and_slide()

	# Sprite flip
	if input_dir.x != 0:
		sprite.flip_h = input_dir.x < 0
		if sprite.animation != "run":
			sprite.play("run")
	elif sprite.animation != "idle":
		sprite.play("idle")

	# Shooting
	if Input.is_action_just_pressed("shoot") and ammo > 0:
		shoot_bullet()

func shoot_bullet():
	var bullet = bullet_scene.instantiate()
	get_parent().add_child(bullet)
	bullet.global_position = global_position
	bullet.direction = (get_global_mouse_position() - global_position).normalized()
	ammo -= 1
	ammo_bar.value = ammo
	churros_count_label.text = str(ammo)

func take_damage(amount: int):
	health -= amount
	health_bar.value = health
	SoundPlayer.play_sound(SoundPlayer.HURT)
	if cam and cam.has_method("shake"):
		cam.shake(6.0, 0.25)
	if health <= 0:
		die()

func apply_knockback(force: Vector2):
	velocity += force

func die():
	SoundPlayer.play_sound(SoundPlayer.DEATH)
	Global.end()
