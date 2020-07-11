extends Node2D

onready var player_scene = preload("res://scenes/Player.tscn")
onready var cam = get_node("Camera")

onready var key_scene = preload("res://scenes/Key.tscn")

onready var exit_scene = preload("res://scenes/Exit.tscn")

onready var GUI = get_node("GUI")

const cam_interpolation = 0.5

const dungeon_width = 3
const dungeon_height = 5

const number_of_columns = 1

const number_of_rooms = 4

const cell_size = 128
const room_size = Vector2(6, 6)

var players = []
var rooms = []
var room_scenes = []

onready var tutorial_room = preload("res://rooms/TutorialRoom.tscn")

var areas = []

const num_players = 2
const num_keys = 10

# alarm goes from 0 to 100
var alarm = 0
const alarm_reduction_rate = 1.0

var game_over_state = false

var word_dict = [
	"GAME",
	"PLAY",
	"GMTK",
	"JAM",
	"CAM",
	"KEY",
	"LOCK",
	"LIGHT",
	"GHOST",
	"ZEBRA",
	"WASD",
	"TIAMO",
	"PLAY",
	"KEYS",
	"CHEST",
	"GOLD", 
	"JUMP",
	"RUN",
	"MOVE",
]

var words = []
var available_keys = []

# const available_keys = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
const actions = [
	#'Jump Left',
	#'Jump Right',
	'Jump Up',
	'Smash Down',
	'Explode',
	'Roll Left',
	'Roll Right',
	#'Attack',
	#'Move'
]

func _ready():
	randomize()
	
	determine_areas()
	pick_words()
	preload_rooms()
	create_dungeon()
	create_players()
	place_keys()
	
	get_tree().paused = false
	
	# ensure camera stays nicely within dungeon bounds
	cam.limit_left = -cell_size
	cam.limit_right = ((dungeon_width+1)*number_of_columns)*room_size.x*cell_size
	cam.limit_top = -cell_size
	cam.limit_bottom = (dungeon_height)*room_size.y*cell_size

func determine_areas():
	# determine a set of distinct "areas"
	areas = [[0,1]]
	for y in range(2, dungeon_height):
		# create new area!
		if randf() <= 0.5:
			areas.append([y])
		
		# latch onto previous area!
			areas[areas.size()-1].append(y)

func pick_words():
	var num_words = areas.size()
	for i in range(num_words):
		var rand_word = word_dict[randi() % word_dict.size()]
		
		for j in range(rand_word.length()):
			var letter = rand_word.substr(j, 1)
			
			if not available_keys.has(letter):
				available_keys.append(letter)
		
		word_dict.erase(rand_word)
		words.append(rand_word)

func preload_rooms():
	for i in range(number_of_rooms):
		room_scenes.append(load("res://rooms/Room" + str(i) + ".tscn"))

func create_key(scancode = null, action = null):
	var key = key_scene.instance()

	if not action:
		action = actions[randi() % actions.size()]
	
	if not scancode:
		var rand_string = available_keys[randi() % available_keys.size()]
		available_keys.erase(rand_string)
		
		scancode = OS.find_scancode_from_string(rand_string)
	
	key.set_key(scancode, action)
	
	return key

func place_keys():
	# for each row in the dungeon, pick a random word
	# hide the keys inside this area
	for i in range(areas.size()):
		var area = areas[i]
		
		# pick a word, remove from list
		var picked_word = words[0]
		words.erase(picked_word)
		
		# grab all corresponding letters (that must still be created)
		var keys_to_place = []
		for j in range(picked_word.length()):
			var letter = picked_word.substr(j, 1)
			if available_keys.has(letter):
				available_keys.erase(letter)
				keys_to_place.append(letter)
		
		# immediately give keys to players
		# (form first row)
		if i == 0:
			for num in range(num_players):
				var action = 'Jump Right' if num == 0 else 'Jump Left'
				var first_letter = keys_to_place[0]
				var key = create_key(OS.find_scancode_from_string(first_letter), action)
				keys_to_place.erase(first_letter)
				
				key.set_position(players[num].get_position())
				call_deferred("add_child", key)
		
		for letter in keys_to_place:
			# create the key
			var letter_scancode = OS.find_scancode_from_string(letter)
			var key = create_key(letter_scancode)
			
			# get a random room on this row
			var rand_num = randi() % number_of_columns
			var rand_x = randi() % dungeon_width
			var rand_y = area[randi() % area.size()]
			
			var room = rooms[rand_num][rand_x][rand_y]
			
			# and find a random empty cell
			# (which is not further than the door)
			var rand_cell = Vector2(0,0)
			var cell_empty = false
			while not cell_empty:
				rand_cell.x = randi() % int(room_size.x)
				rand_cell.y = randi() % int(room_size.y)
				
				cell_empty = (room.get_cellv(rand_cell) == -1) and not (rand_cell.y >= room.door_pos.y)
			
			# finally, place the key there and add it to the game
			key.position = room.position + (rand_cell + Vector2(0.5, 0.5))*cell_size
			call_deferred("add_child", key)
		
		# remove all doors ...
		# except on the LAST row: keep them and set them to the right word
		for x in range(dungeon_width):
			for row in range(area.size()):
				var room = rooms[0][x][area[row]]
				
				for child in room.get_children():
					if child.is_in_group("Doors"):
						if row == (area.size() - 1):
							child.set_word(picked_word)
						else:
							child.queue_free()

func create_players():
	for i in range(num_players):
		var p = player_scene.instance()
		
		# create player at spawn position of first room
		# var start_room = rooms[i][temp_x][0]
		var temp_x = 0 if i == 0 else (dungeon_width-1)
		var start_room = rooms[0][temp_x][0]
		var room_pos = start_room.position
		var spawn_pos = (start_room.spawn_pos + Vector2(0.5, 0.5))*cell_size
		p.set_position(room_pos + spawn_pos)
		
		call_deferred('add_child', p)
		players.append(p)
		
		p.player_num = i

func create_dungeon():
	rooms.resize(number_of_columns)
	
	# place body of rooms
	for i in range(number_of_columns):
		rooms[i] = []
		rooms[i].resize(dungeon_width)
		
		for x in range(dungeon_width):
			rooms[i][x] = []
			rooms[i][x].resize(dungeon_height)
			
			for y in range(dungeon_height):
				place_fitting_room(i, x, y)
	
	# now close it off at the top and bottom
	for i in range(number_of_columns):
		for x in range(dungeon_width):
			for temp_x in range(int(room_size.x)):
				rooms[i][x][0].set_cell(temp_x, -1, 1, false, false, true)
				rooms[i][x][(dungeon_height-1)].set_cell(temp_x, int(room_size.y), 1, false, false, true)

	# finally, place exit underneath one of the doors
	var rand_x = randi() % dungeon_width
	var final_room = rooms[0][rand_x][(dungeon_height-1)]
	
	var exit = exit_scene.instance()
	var exit_pos = final_room.position + (final_room.door_pos + Vector2(0.5, 0.5))*cell_size
	exit.set_position(exit_pos)
	call_deferred("add_child", exit)
	

func pick_random_room():
	var rand_int = randi() % number_of_rooms
	return room_scenes[rand_int].instance()

func arrays_have_a_match(a, b):
	var size_a = a.size()
	var size_b = b.size()
	
	if size_a == 0 and size_b == 0:
		return true
	
	for i in range(size_a):
		var v = a[i]
		for j in range(size_b):
			var w = b[j]
			
			if v == w:
				return true
	
	return false

func check_room_fit(room, prev_room, left_room):
	return (
		(prev_room == null or arrays_have_a_match(room.opening_top, prev_room.opening_bottom)) and
		(left_room == null or arrays_have_a_match(room.opening_left, left_room.opening_right))
	)

func place_fitting_room(num, x, y):
	var prev_room = null
	var left_room = null
	
	if y > 0:
		prev_room = rooms[num][x][y - 1]
	
	if x > 0:
		left_room = rooms[num][x-1][y]

	var room_fits = false
	var room
	while not room_fits:
		room = pick_random_room()
		
		if y == 0:
			room_fits = true
		else:
			room_fits = check_room_fit(room, prev_room, left_room)
		
		if not room_fits:
			room.queue_free()
	
	# hacky way to ensure a tutorial room + correct texts at the top of the dungeon
	if y == 0 and x <= 1:
		room = tutorial_room.instance()
		
		if x == 1:
			room.get_node("TutorialImage3").show()
			room.get_node("TutorialImage1").hide()
			room.get_node("TutorialImage2").hide()
	
	var offset_x = num*(dungeon_width + 2.0/room_size.x)
	var room_pos = Vector2((x + offset_x)*cell_size*room_size.x, y*cell_size*room_size.y)
	room.set_position(room_pos)
	
	call_deferred("add_child", room)
	
	# add wall tiles if we're at the edges of our dungeon
	var left_edge = (x == 0)
	var right_edge = (x == (dungeon_width - 1))
	if left_edge or right_edge:
		var temp_x = -1 if left_edge else int(room_size.x)
		for temp_y in range(int(room_size.y)):
			room.set_cell(temp_x, temp_y, 1, right_edge)
	
	rooms[num][x][y] = room

func get_random_action():
	return actions[randi() % actions.size()]

func game_over(we_won):
	game_over_state = true
	GUI.game_over(we_won)

func raise_alarm(da):
	alarm += da
	GUI.update_alarm_bar(alarm)
	
	if alarm >= 100.0:
		game_over(false)

func _physics_process(dt):
	# gradually reduce alarm
	if alarm > 0.0:
		raise_alarm(-alarm_reduction_rate*dt)
	
	# position and zoom camera properly
	var avg_pos = Vector2.ZERO
	for i in range(2):
		avg_pos += 0.5*players[i].position
	
	var screen_size = get_viewport().size
	var required_size = Vector2(abs(players[0].position.x - players[1].position.x), abs(players[0].position.y - players[1].position.y))
	var zoom_margin = Vector2(300, 300)
	
	required_size += zoom_margin
	
	var required_zoom = max(required_size.x / screen_size.x, required_size.y / screen_size.y)
	var minimum_zoom = 1.0
	var final_zoom = Vector2.ONE * max(minimum_zoom, required_zoom)
	
	cam.position = lerp(cam.position, avg_pos, cam_interpolation)
	cam.zoom = lerp(cam.zoom, final_zoom, cam_interpolation)
