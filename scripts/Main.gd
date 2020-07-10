extends Node2D

onready var player_scene = preload("res://scenes/Player.tscn")
onready var cam = get_node("Camera")

onready var key_scene = preload("res://scenes/Key.tscn")

const cam_interpolation = 0.5

const dungeon_width = 2
const dungeon_height = 10

const number_of_rooms = 4

const cell_size = 32
const room_size = Vector2(5, 5)

var players = []
var rooms = []
var room_scenes = []

const num_players = 2
const num_keys = 10

const available_keys = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
const actions = [
	'Jump',
	'Roll',
	'Attack',
	'Explode',
	'Move'
]

func _ready():
	randomize()
	
	preload_rooms()
	create_dungeon()
	create_players()
	place_keys()

func preload_rooms():
	for i in range(number_of_rooms):
		room_scenes.append(load("res://rooms/Room" + str(i) + ".tscn"))

func place_keys():
	# for each key ...
	for i in range(num_keys):
		# create the key
		var key = key_scene.instance()
		var rand_string = available_keys.substr(randi() % available_keys.length(), 1)
		var rand_action = actions[randi() % actions.size()]
		var scancode = OS.find_scancode_from_string(rand_string)
		key.set_key(scancode, rand_action)
		
		# get a random room
		var rand_num = round(randf())
		var rand_x = randi() % dungeon_width
		var rand_y = randi() % dungeon_height
		
		var room = rooms[rand_num][rand_x][rand_y]
		
		# and find a random empty cell
		var rand_cell = Vector2(0,0)
		var cell_empty = false
		while not cell_empty:
			rand_cell.x = randi() % int(room_size.x)
			rand_cell.y = randi() % int(room_size.y)
			
			cell_empty = (room.get_cellv(rand_cell) == -1)
		
		# finally, place the key there and add it to the game
		key.position = room.position + rand_cell*cell_size
		call_deferred("add_child", key)

func create_players():
	for i in range(num_players):
		var p = player_scene.instance()
		
		var temp_x = 0 if i == 0 else (dungeon_width-1)
		var room_pos = rooms[i][temp_x][0].position
		var spawn_pos = rooms[i][temp_x][0].spawn_pos*cell_size
		p.set_position(room_pos + spawn_pos)
		
		call_deferred('add_child', p)
		players.append(p)

func create_dungeon():
	rooms.resize(num_players)
	
	for i in range(num_players):
		rooms[i] = []
		rooms[i].resize(dungeon_width)
		
		for x in range(dungeon_width):
			rooms[i][x] = []
			rooms[i][x].resize(dungeon_height)
			
			for y in range(dungeon_height):
				place_fitting_room(i, x, y)

func pick_random_room():
	var rand_int = randi() % number_of_rooms
	return room_scenes[rand_int].instance()

func check_room_fit(room, prev_room, left_room):
	return (
		(prev_room == null or room.opening_top == prev_room.opening_bottom) and
		(left_room == null or room.opening_left == left_room.opening_right)
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

func _physics_process(_dt):
	# position and zoom camera properly
	var avg_pos = Vector2.ZERO
	for i in range(2):
		avg_pos += 0.5*players[i].position
	
	var screen_size = get_viewport().size
	var required_size = Vector2(abs(players[0].position.x - players[1].position.x), abs(players[0].position.y - players[1].position.y))
	var zoom_margin = Vector2(100, 100)
	
	required_size += zoom_margin
	
	var required_zoom = Vector2.ONE * max(required_size.x / screen_size.x, required_size.y / screen_size.y)
	
	cam.position = lerp(cam.position, avg_pos, cam_interpolation)
	cam.zoom = lerp(cam.zoom, required_zoom, cam_interpolation)
