extends RigidBody2D

var walk_direction = 1
const move_speed = 35.0

onready var sensor = get_node("Sensor")
onready var sensor_high = get_node("SensorHigh")
onready var sensor_feet = get_node("SensorFeet")

var explode_timer = 0
const explode_speed = 300.0

const direction_change_interval = 1.0

func _ready():
	get_node("SpotLight").exclude_bodies = [self]

func _physics_process(dt):
	if explode_timer > 0:
		explode_timer -= dt
		return
	
	var b0 = sensor_feet.get_overlapping_bodies()
	if b0.size() <= 0:
		return 
	
	var b1 = sensor.get_overlapping_bodies()
	var b2 = sensor_high.get_overlapping_bodies()
	if b1.size() <= 0 or (b2.size() > 0):
		change_direction()

func explode(vec):
	explode_timer = 3.0
	apply_impulse(Vector2.ZERO, vec.normalized() * explode_speed)

func _integrate_forces(state):
	if explode_timer > 0:
		return
	
	var vel = Vector2.RIGHT * walk_direction
	
	state.set_linear_velocity(vel*move_speed)

func change_direction():
	walk_direction *= -1
	
	var offset = Vector2(46, 0)
	
	sensor.position = walk_direction*offset
	sensor_high.position = walk_direction*offset + Vector2(0, -23)
	sensor_feet.position = walk_direction*Vector2(16, 0) + Vector2(0, 16)
	get_node("Sprite").flip_h = (walk_direction == -1)
	get_node("SpotLight").rotation = (walk_direction - 1)*0.5*PI
	
	var spotlight_offset = Vector2(12, -18)
	get_node("SpotLight").position = walk_direction*Vector2(spotlight_offset.x, 0) + Vector2(0, spotlight_offset.y)
	
	# small delay, otherwise we keep flipping all the time
	explode_timer = direction_change_interval
