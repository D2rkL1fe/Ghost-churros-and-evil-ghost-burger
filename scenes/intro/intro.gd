extends Control

@export var story_label : Label
@export var story_animator : AnimationPlayer

var story_text : Array[String] = [
	"Once upon a time there was a hungry ghost who loved to eat churros but everything changed when evil Burger King attacked.",
	"The evil Burger King took all of the churros and occupied Churros-Landia... ",
	"Now it's time for you to banish him with his minion army and to bring back all the churros!"
]

var n_text : int = 0

func _ready() -> void:
	update_story()

func _physics_process(_delta: float) -> void:
	if Input.is_action_just_pressed("continue"):
		if n_text < story_text.size() - 1:
			n_text += 1
			update_story()
		else:
			transition()

func update_story():
	story_label.text = story_text[n_text]
	
	story_animator.stop()
	story_animator.play("in")

	SoundPlayer.play_sound(SoundPlayer.SELECT)

func transition():
	Global.transition("res://scenes/the_beginning/the_beginning.tscn")
