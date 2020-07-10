extends RigidBody2D

var properties = {}

onready var label = get_node("Sprite/Label")

func set_key(scancode, action):
	properties.scancode = scancode
	properties.action = action
	
	get_node("Sprite/Label").set_text(OS.get_scancode_string(scancode))
