extends Line2D

@export var color: Color = Color("ff2222")
@export var beam_width: float = 3.0
@export var length: float = 600.0

var _direction: Vector2
var _speed: float
var _time_alive: float = 0.0
var _duration: float = 0.5

# Particle nodes
@onready var lazer_start = $LazerStart
@onready var lazer_end = $LazerEnd
@onready var lazer_line = $LazerLine

func _ready() -> void:
	default_color = color
	width = beam_width
	points = [Vector2.ZERO, Vector2.RIGHT * length]
	
	_set_particle_colors(color)

func setup(direction: Vector2, speed: float, duration: float) -> void:
	_direction = direction
	_speed = speed
	_duration = duration
	rotation = direction.angle()
	
	_set_particle_colors(color)

func _process(delta: float) -> void:
	global_position += _direction * _speed * delta
	_time_alive += delta
	if _time_alive >= _duration:
		queue_free()

func _set_particle_colors(c: Color) -> void:
	for particle in [lazer_start, lazer_end, lazer_line]:
		if particle and particle.process_material:
			var mat = particle.process_material
			if mat is ParticleProcessMaterial:
				# Set a solid color for all particles
				mat.color = c
