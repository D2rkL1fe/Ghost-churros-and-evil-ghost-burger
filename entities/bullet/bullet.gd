extends Area2D
class_name Bullet

@export var speed: float = 400
@export var damage: int = 20
var direction: Vector2 = Vector2.ZERO

func _physics_process(_delta):
	position += direction * speed * _delta
	look_at(position + direction)
	# Remove bullet if offscreen
	if position.x < -1500 or position.y < -1500 or position.x > 800 or position.y > 800:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Enemy") or body.is_in_group("EnemyBoss"):
		body.take_damage(damage)
		queue_free()
