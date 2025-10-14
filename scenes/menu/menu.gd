extends Control

@export var animator : AnimationPlayer

func _ready() -> void:
	MusicPlayer.play_music(MusicPlayer.MENU)

func _process(_delta: float) -> void:
	if Input.is_anything_pressed():
		animator.play("transition")
		MusicPlayer.stop_music()

func transition():
	Global.transition("res://scenes/start/start.tscn")
