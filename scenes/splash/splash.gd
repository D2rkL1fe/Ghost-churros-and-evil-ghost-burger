extends Control

func transition():
	Global.transition("res://scenes/menu/menu.tscn")

func whoosh():
	SoundPlayer.play_sound(SoundPlayer.WHOOSH)

func whiip():
	SoundPlayer.play_sound(SoundPlayer.WHIIP)
