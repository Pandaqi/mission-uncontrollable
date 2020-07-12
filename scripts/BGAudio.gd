extends AudioStreamPlayer

var main_volume = 0.0

func set_main_volume(v):
	main_volume = v
	volume_db = v

func being_seen():
	volume_db = main_volume + 6.0

func end_being_seen():
	volume_db = main_volume
