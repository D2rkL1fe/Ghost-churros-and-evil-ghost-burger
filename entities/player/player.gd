extends CharacterBody2D

@export var speed: float = 150.0
@onready var cam: Camera2D = $Camera2D

var health: int = 100

func _physics_process(_delta: float) -> void:
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = input_dir * speed
	move_and_slide()

# Called when hit by shockwave
func take_damage(amount: int) -> void:
	health -= amount
	print("Player took damage:", amount, " | HP:", health)
	if health <= 0:
		die()

func apply_knockback(force: Vector2) -> void:
	velocity += force

func die() -> void:
	print("Player died!")
	queue_free()
