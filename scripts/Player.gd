extends RigidBody2D

const key_move_interpolation = 0.1
const move_speed = 10.0
var keys = []

func _ready():
	pass # Replace with function body.

func _input(ev):
	# check if any of the keys are being pressed
	for i in range(keys.size()):
		var k = keys[i].properties
		
		if Input.is_key_pressed(k.scancode):
			print(OS.get_scancode_string(k.scancode) + " is pressed!")
			execute_action(k.action)

func execute_action(a):
	pass

func _integrate_forces(state):
	# move keys with the player (smoothly)
	var num_keys = keys.size()
	var time = OS.get_system_time_msecs() / 1000.0
	for i in range(num_keys):
		var k = keys[i]
		
		var offset = Vector2((-num_keys*0.5 + i)*40, -60)
		var wobble = Vector2(sin(time), cos(time))*10
		var target_position = position + offset + wobble
		
		k.position = lerp(k.position, target_position, key_move_interpolation)
	
	# move player
	var horizontal = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	var vertical = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	var vel = Vector2(horizontal, vertical)
	
	state.set_linear_velocity(state.get_linear_velocity() + vel*move_speed)

func add_key(k):
	# basically, turn off all physics properties on the key
	k.call_deferred('set_mode', MODE_KINEMATIC)
	k.call_deferred('set_collision_layer', 0)
	k.call_deferred('set_collision_mask', 0)
	
	# and add it to our list
	k.remove_from_group("Keys")
	keys.append(k)

func _on_Area_body_entered(body):
	if body.is_in_group("Keys"):
		add_key(body)
