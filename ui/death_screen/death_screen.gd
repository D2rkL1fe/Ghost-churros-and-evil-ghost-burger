class_name DeathScreen
extends Control


func _ready() -> void:
	Global.player_death.connect(_on_player_death)

func _on_player_death():
	visible = true
	get_tree().paused = true

func _on_restart_pressed() -> void:
	get_tree().paused = false
	visible = false
	
	MusicPlayer.stop_music()
	Global.transition("reload")

func _on_menu_pressed() -> void:
	get_tree().paused = false
	visible = false
	
	MusicPlayer.stop_music()
	Global.transition("res://scenes/menu/menu.tscn")
