extends Area2D
class_name Bullet

@export var speed: float = 400
@export var damage: int = 20
var direction: Vector2 = Vector2.ZERO

func _physics_process(_delta):
	position += direction * speed * _delta
	# Remove bullet if offscreen
	if position.x < 0 or position.y < 0 or position.x > 5000 or position.y > 5000:
		queue_free()

func _on_Bullet_body_entered(body):
	if body.has_method("take_damage"):
		body.take_damage(damage)
	queue_free()
