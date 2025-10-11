extends Node

# churros
var churros_counter = 0
signal call_Curros

signal churros_bullet

# add churros and emit signal
func addChurrosCount():
	churros_counter+=1
	call_Curros.emit()

func add_churros_bullets(amount):
	churros_counter += amount
	churros_bullet.emit()
