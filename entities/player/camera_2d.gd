extends Camera2D

var shake_intensity := 0.0
var shake_duration := 0.0
var shake_timer := 0.0
var original_offset := Vector2.ZERO

func _ready() -> void:
	original_offset = offset
	add_to_group("camera")

func _process(delta: float) -> void:
	if shake_timer < shake_duration:
		shake_timer += delta
		offset = original_offset + Vector2(
			randf_range(-shake_intensity, shake_intensity),
			randf_range(-shake_intensity, shake_intensity)
		)
	else:
		offset = original_offset

func shake(intensity: float = 8.0, duration: float = 0.2) -> void:
	shake_intensity = intensity
	shake_duration = duration
	shake_timer = 0.0
