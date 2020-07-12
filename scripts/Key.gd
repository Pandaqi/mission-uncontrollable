extends RigidBody2D

var properties = {}
var transition = 0
var wobble_offsets = [0,0,0,0]
var should_teleport = null
var should_impulse = false

onready var label = get_node("Sprite/Label")

func _ready():
	for i in range(4):
		wobble_offsets[i] = randf()*2*PI

func highlight():
	get_node("Sprite").set_scale(Vector2(1.3, 1.3))

func unhighlight():
	get_node("Sprite").set_scale(Vector2(1.0, 1.0))

func set_key(scancode, action):
	properties.scancode = scancode
	properties.action = action
	properties.taken = false
	
	get_node("Sprite/Label").set_text(OS.get_scancode_string(scancode))
	
	$ActionIcon.set_frame(Global.action_to_icon_dict[action])

func disable():
	if properties.taken:
		return
	
	# basically, turn off all physics properties on the key
	call_deferred('set_mode', MODE_KINEMATIC)
	call_deferred('set_collision_layer', 0)
	call_deferred('set_collision_mask', 0)
	
	rotation = 0
	
	# and remember this key is taken
	remove_from_group("Keys")
	properties.taken = true
	
	# and show action icon
	$ActionIcon.show()

func enable():
	properties.taken = false
	
	set_mode(MODE_RIGID)
	set_collision_layer(1)
	set_collision_mask(1)
	
	add_to_group("Keys")
	
	$ActionIcon.hide()

func _integrate_forces(state):
	if should_impulse:
		var angle = rand_range(PI, 2*PI)
		var place_vec = Vector2(cos(angle), sin(angle))
		apply_impulse(Vector2.ZERO, place_vec*200)
		
		print("APPLYING IMPULSE")
		
		should_impulse = false
	
	if should_teleport != null:
		unhighlight()
		state.transform.origin = should_teleport
		
		should_teleport = null
		should_impulse = true
