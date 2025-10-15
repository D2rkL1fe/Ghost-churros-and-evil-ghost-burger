extends Control

@export var animator : AnimationPlayer

func _ready() -> void:
	MusicPlayer.play_music(MusicPlayer.MENU)

func _process(_delta: float) -> void:
	if Input.is_anything_pressed():
		MusicPlayer.stop_music()
		animator.play("transition")

func transition():
	Global.transition("res://scenes/intro/intro.tscn")
