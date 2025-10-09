extends Node

# all music
const DEATH = preload("uid://b3ysjvdtlo7p2")

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
