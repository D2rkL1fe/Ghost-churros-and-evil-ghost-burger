extends CanvasLayer
@export var label : Label

func _ready():
	# GlobalStats.call_Curros.connect(churrosChanged);
	GlobalStats.churros_bullet.connect(churrosChanged);

func churrosChanged():
	label.text = "Churros: " + str(GlobalStats.churros_counter);
