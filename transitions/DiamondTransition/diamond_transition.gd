extends CanvasLayer

@export var animator : AnimationPlayer

func start_transition(scene):
	# additional effects
	SoundPlayer.play_sound(SoundPlayer.TRANSITION)
	
	# in
	animator.play("transition")
	await animator.animation_finished
	
	# change scene
	if scene == "reload":
		get_tree().reload_current_scene()
	else:
		get_tree().change_scene_to_file(scene)
	
	# out
	animator.play_backwards("transition")
	await animator.animation_finished
	
