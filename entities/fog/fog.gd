extends Sprite2D

var player : Player

var cooldown : float = 0.0

func _physics_process(delta: float) -> void:
	if !player:
		return
	
	var distance = player.global_position - global_position
	
	if distance.length() < 125:
		modulate.a = lerp(modulate.a, 0.0, 16.0 * delta)
		cooldown = 0
	else:
		cooldown += delta
		
		if cooldown >= 5:
			modulate.a = lerp(modulate.a, 1.0, 16.0 * delta)

func setup(target):
	player = target
