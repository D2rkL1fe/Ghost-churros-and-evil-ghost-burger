extends Control

func transition():
	print(123)
	Global.transition("res://scenes/menu/menu.tscn")

func whoosh():
	print(321)
	SoundPlayer.play_sound(SoundPlayer.WHOOSH)

func whiip():
	print(444)
	SoundPlayer.play_sound(SoundPlayer.WHIIP)
