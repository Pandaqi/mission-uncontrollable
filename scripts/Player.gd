extends RigidBody2D

const key_move_interpolation = 0.1

const jump_speed = 500.0
const move_speed = 20.0
var keys = []

var player_num = -1

var random_mode = false
const random_mode_timer = { "min": 0.2, "max": 2.0 }

const explode_radius = 200.0
const explode_alarm_raise = 30.0

onready var main_node = get_node("/root/Main")
onready var timer = get_node("Timer")
onready var random_mode_text = get_node("RandomModeText")

onready var explode_sensor = get_node("ExplodeArea")
onready var explode_particles = get_node("ExplodeParticles")

onready var alarm_indicator = get_node("AlarmIndicator")
var being_seen = false

var rolling_mode = false
const roll_speed = 40.0
const climb_speed = 200.0
const roll_ray_range = 24.0
var stick_ray_normal = Vector2.UP
var rolling_dir = 1

func _ready():
	# give text to main node, so it doesn't rotate with our player
	remove_child(random_mode_text)
	main_node.add_child(random_mode_text)
	
	remove_child(alarm_indicator)
	main_node.add_child(alarm_indicator)

func _input(ev):
	if not (ev is InputEventKey):
		return
	
	if main_node.game_over_state:
		return
	
	# check for key switch
	# (holding control + typing another key)
	if Input.is_action_pressed("control"):
		if !ev.pressed:
			switch_key(ev.scancode)
		return 
	
	# check if any of the keys do something
	for i in range(keys.size()):
		var k = keys[i].properties
		
		# key PRESS
		if ev.scancode == k.scancode && ev.pressed:
			execute_action_pressed(k.action)
		
		# key RELEASE
		if ev.scancode == k.scancode && !ev.pressed:
			execute_action_released(k.action)
	
	if ev.scancode == KEY_E:
		rolling_dir = -1
		rolling_mode = ev.pressed

func execute_action_pressed(a):
	match(a):
		'Roll Left':
			rolling_mode = true
			rolling_dir = -1
			
		'Roll Right':
			rolling_mode = true
			rolling_dir = 1

func execute_action_released(a):
	match(a):
		'Jump Left':
			var rand_angle = rand_range(2,3)*0.5*PI
			var rand_impulse = Vector2(cos(rand_angle), sin(rand_angle))
			apply_impulse(Vector2.ZERO, rand_impulse*jump_speed)			
		
		'Jump Right':
			var rand_angle = rand_range(-1,0)*0.5*PI
			var rand_impulse = Vector2(cos(rand_angle), sin(rand_angle))
			apply_impulse(Vector2.ZERO, rand_impulse*jump_speed)
		
		'Jump Up':
			apply_impulse(Vector2.ZERO, Vector2.UP*jump_speed)
		
		'Smash Down':
			apply_impulse(Vector2.ZERO, Vector2.DOWN*jump_speed*3.0)
		
		'Explode':
			explode()
		
		'Roll Left':
			rolling_mode = false
		
		'Roll Right':
			rolling_mode = false

func explode():
	var b = explode_sensor.get_overlapping_bodies()
	
	# raises the alarm
	main_node.raise_alarm(explode_alarm_raise)
	
	for i in range(b.size()):
		var body = b[i]
		
		# blow monsters backwards
		if body.is_in_group("Monsters"):
			body.explode( body.position - position )
		
		# destroy surveillance
		if body.is_in_group("Surv"):
			body.explode()
		
		# destroy tilemap cells
		# TO DO: Give us gold if we break a gold tile
		if body.is_in_group("Tilemaps"):
			var used_cells = body.get_used_cells()
			for cell in used_cells:
				var pos = body.position + cell*main_node.cell_size
				var dist = (pos - position).length()
				if dist <= explode_radius and body.get_cellv(cell) != 1:
					body.set_cellv(cell, -1)
	
	explode_particles.set_emitting(false)
	explode_particles.set_emitting(true)

func sticking(input, dir):
	var space_state = get_world_2d().direct_space_state
	var ray_range = roll_ray_range
	
	var downward_offset = Vector2(0, 5)
	
	var from = global_position + downward_offset
	var to = from + dir*ray_range + downward_offset
	var exclude_bodies = [self]
	
	var result = space_state.intersect_ray(from, to, exclude_bodies)
	
	main_node.get_node("Debug").set_line(from, to)
	main_node.get_node("Debug").update()
	
	# if we have a result AND our input points in the same direction
	if result and input*dir.x > 0:
		stick_ray_normal = result.normal
		return true
	
	return false

func _physics_process(_dt):
	# if we're being seen, display indicator
	alarm_indicator.set_visible(being_seen)
	if being_seen:
		alarm_indicator.position = position + Vector2(0, -64)
		alarm_indicator.get_node("AnimationPlayer").play('AlarmIndicator')
	else:
		alarm_indicator.get_node("AnimationPlayer").stop()
	
	# reset variable that checks if someone sees us (at END of function, important!)
	being_seen = false

func _integrate_forces(state):
	# move keys with the player (smoothly)
	var num_keys = keys.size()
	var time = OS.get_system_time_msecs() / 1000.0
	for i in range(num_keys):
		var k = keys[i]
		var o = k.wobble_offsets
		
		var offset = Vector2((-num_keys*0.5 + i + 0.5)*80, -60)
		var wobble = Vector2(sin(time + o[0]) + cos(time + o[1]), sin(time + o[2]) + cos(time + o[3]))*5
		
		var target_position = position + offset + wobble
		
		k.position = lerp(k.position, target_position, key_move_interpolation)
		
		if k.transition > 0:
			k.transition -= 0.016
	
	# move control text to right position (if visible)
	if random_mode:
		var offset = Vector2(0, -30)
		random_mode_text.position = position + offset
	
	var climbing = false
	if rolling_mode:
		physics_material_override.friction = 1.0
		set_angular_velocity(rolling_dir * roll_speed)
		
		var check_dir = Vector2.RIGHT if rolling_dir == 1 else Vector2.LEFT
		
		if sticking(rolling_dir, check_dir):
			climbing = true
	
	# move player (if needed/allowed)
	var vel = state.get_linear_velocity()
	
	if climbing:
		vel = Vector2(-stick_ray_normal.y, stick_ray_normal.x)*climb_speed
		vel.y = -abs(vel.y)
		vel.x = rolling_dir * abs(vel.x)

	state.set_linear_velocity(vel)

func start_random_mode():
	random_mode = true
	random_mode_text.show()
	
	_on_Timer_timeout()

func end_random_mode():
	random_mode = false
	random_mode_text.hide()
	
	timer.stop()

func switch_key(k):
	var key = null
	for i in range(keys.size()):
		if keys[i].properties.scancode == k and keys[i].transition <= 0.0:
			key = keys[i]
			keys.erase(key)
			break
	
	if not key:
		return
	
	var other_player = (player_num + 1) % 2
	
	key.transition = 0.5
	
	main_node.players[other_player].add_key(key)
	
	if keys.size() <= 0:
		start_random_mode()

func add_key(k):
	if not k.properties.taken:
		# basically, turn off all physics properties on the key
		k.call_deferred('set_mode', MODE_KINEMATIC)
		k.call_deferred('set_collision_layer', 0)
		k.call_deferred('set_collision_mask', 0)
		
		k.rotation = 0
		
		# and remember this key is taken
		k.remove_from_group("Keys")
		k.properties.taken = true
	
	# we have a key, should always end random mode
	end_random_mode()
	
	# and add it to our list
	keys.append(k)

func check_word_match(word):
	var matches = 0
	for key in keys:
		var letter = OS.get_scancode_string(key.properties.scancode)
		
		if letter in word:
			matches += 1
	
	return (matches == word.length())

func _on_Area_body_entered(body):
	if body.is_in_group("Keys"):
		add_key(body)
	
	if body.get_parent().is_in_group("Doors"):
		var is_match = check_word_match(body.get_parent().word)
		
		if is_match:
			body.get_parent().queue_free()

func _on_Timer_timeout():
	execute_action_released(main_node.get_random_action())
	
	timer.wait_time = rand_range(random_mode_timer.min, random_mode_timer.max)
	timer.start()
