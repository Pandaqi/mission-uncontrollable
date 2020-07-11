extends Node2D

onready var main_node = get_node("/root/Main")

func _on_Area2D_body_entered(body):
	if body.is_in_group("Players"):
		main_node.game_over(true)
