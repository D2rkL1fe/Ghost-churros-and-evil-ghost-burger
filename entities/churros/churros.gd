extends Area2D
class_name Churros

func _ready():
	connect("body_entered", Callable(self, "_on_area_2d_body_entered"))

func _on_area_2d_body_entered(body):
	if body is Player:
		queue_free()
		SoundPlayer.play_sound(SoundPlayer.PICKUP)
		body.ammo += 5
		body.ammo_bar.value = body.ammo
		body.churros_count_label.text = str(body.ammo)
