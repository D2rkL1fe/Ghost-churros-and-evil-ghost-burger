extends Node

# all music
const MEOW = preload("uid://b3ysjvdtlo7p2")
const DEATH = preload("uid://dtrwrjbh6k1hp")
const MENU = preload("uid://dpxf36w5wccjl")
const GAMEPLAY = preload("uid://c8qdj0eyb5q75")

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
