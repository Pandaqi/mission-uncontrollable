extends CanvasLayer

var game_over_state = false

onready var game_over_message_node = get_node("GameOver/ColorRect/VBoxContainer/Message")
onready var game_over_result_node = get_node("GameOver/ColorRect/VBoxContainer/Result")
onready var alarm_bar = get_node("Control/AlarmBar/CenterContainer/TextureProgress")

const messages = {
	"WIN": 
		[
			"Fantastic! You escaped out of CONTROL!",
			"Great job! The situation is under control."
		],
	
	"LOSE": 
		[
			"Hmm, you let it slip out of your control ...",
			"Ehm ... that situation got out of control.",
			"It seems you're not completely in control."
		]
}

func _input(ev):
	if not (ev is InputEventKey):
		return
	
	if not game_over_state:
		return
	
	if ev.scancode == KEY_R:
		get_tree().reload_current_scene()

func final_game_pause():
	pass
	# I actually like it without the pausing?
	#get_tree().paused = true

func update_alarm_bar(a):
	alarm_bar.value = a

func game_over(we_won):
	if game_over_state:
		return
	
	game_over_state = true
	get_node("AnimationPlayer").play("ScreenAppear")
	
	var msg
	var res = "You won!"
	if we_won:
		msg = messages.WIN[randi() % messages.WIN.size()]
	else:
		res = "You lost!"
		msg = messages.LOSE[randi() % messages.LOSE.size()]
	
	game_over_message_node.set_text(msg)
	game_over_result_node.set_text(res)
