extends Node

var music_player
var main_volume = 0.0

func being_seen():
	music_player.volume_db = main_volume + 5.0

func end_being_seen():
	music_player.volume_db = main_volume

func _ready():
	var music_file = "res://music.wav"
	music_player = AudioStreamPlayer.new()

	if File.new().file_exists(music_file):
		music_player.stream = load(music_file)
		music_player.play()
