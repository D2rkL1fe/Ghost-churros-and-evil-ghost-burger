extends Area2D


func _on_body_entered(body: Node2D) -> void:
	print(body)
	if body is Player:
		SoundPlayer.play_sound(SoundPlayer.TELEPORT)
		Global.transition("res://scenes/boss_fight/boss_fight.tscn")
