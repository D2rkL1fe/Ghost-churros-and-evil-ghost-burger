extends Control


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("pause"):
		toggle()

func toggle():
	if visible:
		visible = false
		get_tree().paused = false
	else:
		visible = true
		get_tree().paused = true


func _on_slider_sfx_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(1, value)

func _on_slider_music_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(2, value)


func _on_check_sfx_toggled(toggled_on: bool) -> void:
	AudioServer.set_bus_mute(1, !toggled_on)

func _on_check_music_toggled(toggled_on: bool) -> void:
	AudioServer.set_bus_mute(2, !toggled_on)


func _on_restart_pressed() -> void:
	toggle()
	
	Global.transition("reload")

func _on_menu_pressed() -> void:
	toggle()
	
	Global.transition("res://scenes/menu/menu.tscn")
