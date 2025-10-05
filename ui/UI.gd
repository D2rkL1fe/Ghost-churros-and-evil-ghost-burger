extends CanvasLayer
@export var label : Label

func _ready():
	GlobalStats.call_Curros.connect(churrosChanged);

func churrosChanged():
	label.text="Churros: "+str(GlobalStats.churros_counter);
	set("theme_override_colors/font_color", Color("Red"))
