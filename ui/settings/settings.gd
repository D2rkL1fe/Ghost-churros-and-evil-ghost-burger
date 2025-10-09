extends Control


func _process(delta: float) -> void:
	if Input.is_action_just_pressed("pause"):
		toggle()

func toggle():
	visible = !visible
	get_tree().paused = !get_tree().paused


func _on_slider_sfx_value_changed(value: float) -> void:
	pass # Replace with function body.

func _on_slider_music_value_changed(value: float) -> void:
	pass # Replace with function body.


func _on_check_sfx_toggled(toggled_on: bool) -> void:
	AudioServer.set_bus_mute(1, !toggled_on)

func _on_check_music_toggled(toggled_on: bool) -> void:
	pass # Replace with function body.


func _on_restart_pressed() -> void:
	toggle()
	
	get_tree().reload_current_scene()

func _on_menu_pressed() -> void:
	toggle()
	
	get_tree().change_scene_to_file("res://scenes/menu/menu.tscn")
