extends Sprite

export(Vector2) var max_angles = Vector2(0, 0.5)
var move_offset = 0
var full_circle = false

func _ready():
	move_offset = randf()*2*PI
	
	if (max_angles.y - max_angles.x) == 2:
		full_circle = true

func explode(vec):
	queue_free()

func _physics_process(dt):
	var time = OS.get_system_time_msecs() / 1000.0
	
	if full_circle:
		rotation += dt
	
	else:
		rotation = (abs(sin(time + move_offset))*(max_angles.y-max_angles.x) + max_angles.x)*PI
