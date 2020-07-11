extends Node2D

var players_in_area = []

const max_rays = 3
const alarm_raise_rate = 20.0
onready var main_node = get_node("/root/Main")

var exclude_bodies = []

func _physics_process(dt):
	var num_players_in_area = players_in_area.size()
	if num_players_in_area > 0:
		for i in range(num_players_in_area):
			var p = players_in_area[i]
			if try_ray(p):
				p.being_seen = true
				main_node.raise_alarm(alarm_raise_rate*dt)

func try_ray(body):
	var space_state = get_world_2d().direct_space_state
	
	var player_width = 64
	var from = global_position
	
	for i in range(max_rays):
		var player_body_offset = Vector2(1,0) * player_width * (-0.5 + (i+0.0)/(max_rays-1))
		var to = body.global_position + player_body_offset
		var result = space_state.intersect_ray(from, to, exclude_bodies)
		
		#main_node.get_node("Debug").set_line(from, to)
		#main_node.get_node("Debug").update()
		
		if result:
			if result.collider.is_in_group("Players"):
				return true
		
	return false

func _on_Area2D_body_entered(body):
	if body.is_in_group("Players"):
		players_in_area.append(body)

func _on_Area2D_body_exited(body):
	if body.is_in_group("Players"):
		players_in_area.erase(body)
