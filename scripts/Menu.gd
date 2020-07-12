extends Node2D

func _ready():
	get_node("CanvasLayer/Control/CenterContainer/VBoxContainer2/CenterContainer/VBoxContainer/Setting_Fullscreen/Fullscreen_Checkbox").pressed = OS.window_fullscreen

func _process(_dt):
	var vp = get_viewport()
	var part_pos = Vector2(0.5*vp.size.x, vp.size.y)

	get_node("Particles2D").set_position(part_pos)

func _on_Button_Play_pressed():
	get_tree().change_scene('res://Main.tscn')

func _on_Button_Quit_pressed():
	get_tree().quit()

func _on_SizeSlider_value_changed(value):
	Global.difficulty = value

func _on_VolumeSlider_value_changed(value):
	BGAudio.main_volume = value
	BGAudio.music_player.volume_db = value

func _on_Fullscreen_Checkbox_toggled(button_pressed):
	OS.window_fullscreen = button_pressed

func _on_Tutorial_Checkbox_toggled(button_pressed):
	Global.tutorial_room = button_pressed
