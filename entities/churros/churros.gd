class_name Churros extends CharacterBody2D

func _on_area_2d_body_entered(_body: Node2D) -> void:
	queue_free()
	GlobalStats.addChurrosCount()
