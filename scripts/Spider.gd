extends RigidBody2D

onready var timer = get_node("Timer")
const timer_range = { "min": 1.0, "max": 3.0 }
const jump_speed = 400.0

var closest_player = null

var p

const sight_radius = 200.0
const hit_radius = 90

func _ready():
	p = get_node("/root/Main").players
	timer.start()

func attack():
	queue_free()

func explode(vec):
	queue_free()

func _physics_process(_dt):
	for i in range(p.size()):
		var pp = p[i]
		var vec = (pp.position - global_position)
		
		if vec.length() <= hit_radius:
			pp.take_hit(vec.normalized(), self)

func jump():
	# find closest player
	var prev_closest_dist = sight_radius
	for i in range(p.size()):
		var pp = p[i]
		var vec = (pp.position - global_position)
		var dist = vec.length()

		if dist <= prev_closest_dist:
			closest_player = pp
			prev_closest_dist = dist
	
	var angle = 0
	var vec = Vector2.UP
	if closest_player == null:
		angle = rand_range(-0.25*PI, -0.75*PI)
		vec = Vector2(cos(angle), sin(angle))
	else:
		vec += (closest_player.position - global_position).normalized()
	
	get_node("Sprite").flip_h = (vec.x < 0)
	apply_impulse(Vector2.ZERO, vec*jump_speed)

func _on_Timer_timeout():
	jump()
	
	timer.wait_time = rand_range(timer_range.min, timer_range.max)
	timer.start()
