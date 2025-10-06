class_name Player extends CharacterBody2D

@export var sprite : AnimatedSprite2D

var speed : float = 160.0

func _physics_process(delta: float) -> void:
	var direction = Input.get_vector("left", "right", "up", "down")
	
	if direction.x:
		sprite.flip_h = direction.x < 0
	
	velocity = lerp(velocity, speed * direction, 16.0 * delta)
	
	move_and_slide()
