extends Area2D

@export var speed : float = 400
@export var damage : int = 10
var direction : Vector2

func _ready():
	$Timer.start()

func _process(delta):
	position += direction * speed * delta

func _on_Timer_timeout():
	queue_free()

func _on_Area2D_body_entered(body):
	if body.is_in_group("enemy"):
		body.take_damage(damage)
		queue_free()
