extends Control

@export var dialog_lines: Array = ["The oily king stands!", "Get lost!", "Go away sucker!", "You won't pass beyond us!", "No cure for fools"]
@export var display_time: float 

var rng := RandomNumberGenerator.new()
@export  var label: Label
@export  var anim: AnimationPlayer

func _ready():
	rng.randomize()
	anim.speed_scale=randf_range(0.8,1.2)
	display_time=10*anim.speed_scale

func show_random_dialog():
	label.text = dialog_lines[rng.randi() % dialog_lines.size()]
	label.show()
