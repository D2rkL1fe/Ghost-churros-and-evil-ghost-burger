extends Node

# all sounds
const DEATH = preload("uid://cgmoamwlys8vp")
const EXPLOSION = preload("uid://um2kp0wi7aw")
const HOVER = preload("uid://drynyh42dmb45")
const HURT = preload("uid://dyjikxfimftn3")
const PICKUP = preload("uid://c7b1v4xqxdh6m")
const SELECT = preload("uid://c1u2hqrhsrg3v")
const TRANSITION = preload("uid://g86slrcoec47")
const SHOOT = preload("uid://dmcaxlh133wnr")
const TELEPORT = preload("uid://dvgpriif0rjtc")
const WHOOSH = preload("uid://d4cd48wa3eyvt")

const WHIIP = preload("uid://c45rupbv8wd3t")
const WHOOP = preload("uid://6iuhqa88tp6u")

# store all audio/sound players
var audio_players

# get them
func _ready() -> void:
	audio_players = get_children()

# handle audio/sound playing
func play_sound(sound):
	if audio_players:
		for audio_player in audio_players:
			if !audio_player.playing:
				audio_player.stream = sound
				audio_player.pitch_scale = randf_range(0.95, 1.05)
				
				audio_player.play()
				
				break
