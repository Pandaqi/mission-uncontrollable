extends Node2D

func _on_Button_Play_pressed():
	get_tree().change_scene('res://Main.tscn')

func _on_Button_Quit_pressed():
	get_tree().quit()

func _on_SizeSlider_value_changed(value):
	pass
	# TO DO: Save level size in singleton; pass to Main.tscn

func _on_VolumeSlider_value_changed(value):
	BGAudio.music_player.volume_db = value

func _on_Fullscreen_Checkbox_toggled(button_pressed):
	OS.window_fullscreen = button_pressed

func _on_Tutorial_Checkbox_toggled(button_pressed):
	pass
	# TO DO: Save that we want a tutorial; listen to that in Main.tscn
