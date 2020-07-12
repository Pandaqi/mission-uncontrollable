extends RigidBody2D

var p

const sight_radius = 300.0
const hit_radius = 64

const move_speed = 100.0

var move_vec = Vector2.ZERO

func _ready():
	p = get_node("/root/Main").players

func _physics_process(_dt):
	var prev_closest_dist = sight_radius
	move_vec = Vector2.ZERO
	
	for i in range(p.size()):
		var pp = p[i]
		var vec = (pp.position - global_position)
		var dist = vec.length()
		
		if dist <= hit_radius:
			pp.take_hit(vec.normalized())
		
		if dist <= prev_closest_dist:
			move_vec = vec.normalized()
			prev_closest_dist = dist

func attack():
	queue_free()

func explode(vec):
	queue_free()

func _integrate_forces(state):
	get_node("Sprite").flip_h = (move_vec.x < 0)
	
	state.set_linear_velocity(move_vec*move_speed)
