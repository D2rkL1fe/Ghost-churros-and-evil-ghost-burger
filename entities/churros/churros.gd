class_name Churros extends CharacterBody2D

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is Player:
		queue_free()
		
		SoundPlayer.play_sound(SoundPlayer.PICKUP)
		GlobalStats.addChurrosCount()
