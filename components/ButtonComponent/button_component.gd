class_name ButtonComponent
extends Node

func _ready() -> void:
	var button = get_parent() as Button
	
	if button:
		button.mouse_entered.connect(on_hover)
		button.pressed.connect(on_press)

func on_hover():
	SoundPlayer.play_sound(SoundPlayer.HOVER)

func on_press():
	SoundPlayer.play_sound(SoundPlayer.SELECT)
