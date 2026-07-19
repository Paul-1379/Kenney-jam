extends AudioStreamPlayer2D

@export var retry_sfx: AudioStreamPlayer2D

func _ready() -> void:
	if GlobalData.musicProgress != 0:
		print("play")
		retry_sfx.play()
	play(GlobalData.musicProgress)
