extends Node

# states
var transitioning : bool = false

# game state signals
signal player_death
signal transitioned

func restart():
	GlobalStats.churros_counter = 0

# end the game
func end():
	player_death.emit()

# transition from scene to scene
func transition(scene):
	if !transitioning:
		transitioning = true
		get_tree().paused = true
		
		await DiamondTransition.start_transition(scene)
		
		transitioning = false
		get_tree().paused = false
		
		restart()
