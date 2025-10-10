extends Node

# churros
var churros_counter=0
signal call_Curros

# add churros and emit signal
func addChurrosCount():
	churros_counter+=1
	call_Curros.emit()
