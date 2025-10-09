class_name DeathScreen
extends Control


func _ready() -> void:
	GlobalStats.player_death.connect(_on_player_death)

func _on_player_death():
	visible = true
	get_tree().paused = true

func _on_restart_pressed() -> void:
	get_tree().paused = false
	
	get_tree().reload_current_scene()

func _on_menu_pressed() -> void:
	get_tree().paused = false
	
	get_tree().change_scene_to_file("res://scenes/menu/menu.tscn")
