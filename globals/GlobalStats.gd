extends Node

var churros_counter=0
signal call_Curros

signal player_death

func addChurrosCount():
	churros_counter+=1
	call_Curros.emit()

func end():
	player_death.emit()
