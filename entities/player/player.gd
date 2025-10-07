class_name Player extends CharacterBody2D

@export var sprite : AnimatedSprite2D

@export var speed: float = 150.0
@onready var cam: Camera2D = $Camera2D

var health: int = 100

func _physics_process(_delta: float) -> void:
	var input_dir = Input.get_vector("left", "right", "up", "down")
	
	if input_dir.x:
		sprite.flip_h = input_dir.x < 0
	
	velocity = input_dir * speed
	move_and_slide()

@onready var flash_tween := create_tween()

func take_damage(amount: int) -> void:
	health -= amount
	print("Player took damage:", amount, " | HP:", health)
	if sprite:
		flash_tween.kill() # stop any ongoing flash
		flash_tween = get_tree().create_tween()
		flash_tween.tween_property(sprite, "modulate", Color(1,0.3,0.3), 0.1)
		flash_tween.tween_property(sprite, "modulate", Color(1,1,1), 0.2)
	if health <= 0:
		die()


func apply_knockback(force: Vector2) -> void:
	velocity += force

func die() -> void:
	print("Player died!")
	
	get_tree().call_deferred("change_scene_to_file", "res://scenes/start/start.tscn")
	#get_tree().reload_current_scene()
