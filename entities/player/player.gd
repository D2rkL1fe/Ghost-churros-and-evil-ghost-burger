extends CharacterBody2D
class_name Player

@export var speed := 150.0
@export var bullet_scene: PackedScene
@export var shoot_cooldown := 0.25
@export var recoil_force := 360.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var health_bar: TextureProgressBar = $HealthBarComponent
@onready var cam: Camera2D = $Camera2D

var health := 100
var max_health := 100

var can_shoot := true

func _ready():
	health_bar.max_value = max_health
	health_bar.value = health
	if not is_in_group("player"): add_to_group("player")

func _physics_process(delta):
	var dir = Input.get_vector("left", "right", "up", "down")
	velocity = lerp(velocity, dir * speed, 16.0 * delta)
	
	move_and_slide()
	
	if dir.x != 0:
		sprite.flip_h = dir.x < 0
		sprite.play("run")
	else:
		sprite.play("idle")
	if Input.is_action_just_pressed("shoot") and GlobalStats.churros_counter > 0 and can_shoot:
		shoot_bullet()

func shoot_bullet():
	if not bullet_scene: return
	can_shoot = false
	var bullet = bullet_scene.instantiate()
	get_parent().add_child(bullet)
	bullet.global_position = global_position
	if "direction" in bullet:
		bullet.direction = (get_global_mouse_position() - global_position).normalized()
	apply_recoil(bullet.direction)
	
	GlobalStats.add_churros_bullets(-1)
	SoundPlayer.play_sound(SoundPlayer.SHOOT)
	
	await get_tree().create_timer(shoot_cooldown).timeout
	can_shoot = true

func apply_recoil(dir: Vector2):
	velocity -= dir * recoil_force

func take_damage(amount: int):
	if health <= 0: return
	health -= amount
	health_bar.value = health
	if cam and cam.has_method("shake"): cam.shake(6.0, 0.25)
	if health <= 0: die()

func die():
	Global.end()
