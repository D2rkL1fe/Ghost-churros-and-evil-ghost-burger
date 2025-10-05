extends Node

var churros_counter=0
signal call_Curros

func addChurrosCount():
	churros_counter+=1
	call_Curros.emit()
