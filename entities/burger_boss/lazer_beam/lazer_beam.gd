extends Line2D

@export var color: Color = Color("00d7d7ff")
@export var beam_width: float = 3.0
@export var length: float = 600.0
@export var move_speed: float = 500.0  

var _direction: Vector2
var _time_alive: float = 0.0
var _max_lifetime: float = 5.0  

@onready var lazer_start = $LazerStart
@onready var lazer_end = $LazerEnd
@onready var lazer_line = $LazerLine
@onready var hurtbox = $Hurtbox  

func _ready() -> void:
	default_color = color
	width = beam_width
	points = [Vector2.ZERO, Vector2.RIGHT * length]
	_set_particle_colors(color)

func setup(direction: Vector2) -> void:
	_direction = direction.normalized()
	rotation = _direction.angle()
	_set_particle_colors(color)

func _process(delta: float) -> void:
	global_position += _direction * move_speed * delta
	_time_alive += delta

	if _time_alive >= _max_lifetime:
		queue_free()

func _set_particle_colors(c: Color) -> void:
	for particle in [lazer_start, lazer_end, lazer_line]:
		if particle and particle.process_material:
			var mat = particle.process_material
			if mat is ParticleProcessMaterial:
				mat.color = c

func _on_hurtbox_body_entered(body: Node2D) -> void:
	if body is Player:
		body.take_damage(20)
		SoundPlayer.play_sound(SoundPlayer.HURT)
		queue_free()  
