extends CPUParticles2D

@export var react_to_movement: bool = true
@export var base_amount: int = 80
@export var max_extra_amount: int = 70
@export var base_initial_velocity: float = 40.0
@export var max_extra_initial_velocity: float = 30.0

var pulse_speed := 3.0
var min_scale := 0.8
var max_scale := 1.2
var time_accum := 0.0
var _external_speed := 0.0

func _ready():
	self.emitting = true
	self.preprocess = 0.5

func _process(delta: float) -> void:
	time_accum += delta
	var t := sin(time_accum * pulse_speed)
	var scale_amount := lerp(min_scale, max_scale, (t + 1.0) * 0.5)
	self.scale = Vector2(scale_amount, scale_amount)

	if react_to_movement:
		var speed := _external_speed
		self.amount = int(base_amount + clamp(speed / 3.0, 0.0, max_extra_amount))
		self.initial_velocity = base_initial_velocity + clamp(speed / 10.0, 0.0, max_extra_initial_velocity)

func set_speed(s: float) -> void:
	_external_speed = max(0.0, float(s))
