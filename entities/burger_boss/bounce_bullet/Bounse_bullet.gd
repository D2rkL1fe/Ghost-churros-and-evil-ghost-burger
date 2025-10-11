extends RigidBody2D

@export var speed: float = 250.0
@export var damage: int = 10
@export var lifetime: float = 6.0

@onready var hit_area: Area2D = $Area2D

func _ready() -> void:
	# Launch in facing direction
	linear_velocity = Vector2.RIGHT.rotated(rotation) * speed
	
	# Connect Area2D to detect player
	hit_area.body_entered.connect(_on_body_entered)
	
	# Destroy after lifetime
	await get_tree().create_timer(lifetime).timeout
	if is_instance_valid(self):
		queue_free()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
		queue_free()
