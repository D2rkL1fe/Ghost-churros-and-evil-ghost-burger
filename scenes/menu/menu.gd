extends Control

@export var animator : AnimationPlayer

func _process(_delta: float) -> void:
	if Input.is_anything_pressed():
		animator.play("transition")

func transition():
	Global.transition("res://scenes/start/start.tscn")
