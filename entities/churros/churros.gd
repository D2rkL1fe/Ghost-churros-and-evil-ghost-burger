extends Area2D
class_name Churros

@export var bullets_amount: int = 5

func _ready():
	connect("body_entered", Callable(self, "_on_body_entered"))

func _on_body_entered(body):
	if body is Player:
		GlobalStats.add_churros_bullets(bullets_amount)
		SoundPlayer.play_sound(SoundPlayer.PICKUP)
		queue_free()
