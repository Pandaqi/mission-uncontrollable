extends RigidBody2D

var properties = {}
var transition = 0
var wobble_offsets = [0,0,0,0]

onready var label = get_node("Sprite/Label")

func _ready():
	for i in range(4):
		wobble_offsets[i] = randf()*2*PI

func set_key(scancode, action):
	properties.scancode = scancode
	properties.action = action
	properties.taken = false
	
	get_node("Sprite/Label").set_text(OS.get_scancode_string(scancode))
