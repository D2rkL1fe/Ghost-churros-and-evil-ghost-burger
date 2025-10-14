extends Node

const DEATH_PARTICLES = preload("uid://c84hwmb0dm4vj")

func create_particles(pos):
	var particles = DEATH_PARTICLES.instantiate()
	
	particles.global_position = pos
	
	get_tree().root.add_child(particles)
