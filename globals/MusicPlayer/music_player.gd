extends Node

# all music
const MEOW = preload("uid://b3ysjvdtlo7p2")
const DEATH = preload("uid://dtrwrjbh6k1hp")

# main music player
@export var music_player : AudioStreamPlayer

# handle music playing
func play_music(music):
	if music_player:
		music_player.stream = music
		music_player.play()

# stop la musica
func stop_music():
	music_player.stop()
