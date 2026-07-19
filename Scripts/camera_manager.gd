extends Node2D

@export var playerBody: CharacterBody2D
@export var phantomCamera: PhantomCamera2D
@export var zone_centers: Array[Marker2D]
@export var zone_spawn_points: Array[Marker2D]
@export var confettis: Control
@export var music_player: AudioStreamPlayer2D

var current_zone: int

func _ready() -> void:
	if GlobalData.camera_center_path != "":
		var cam_center = get_node(GlobalData.camera_center_path)
		phantomCamera.follow_target = cam_center
		phantomCamera.teleport_position()

func update_current_zone(body, zone_number: int)-> void:
	if zone_number == current_zone:
		return
	if body == playerBody:
		current_zone = zone_number
	phantomCamera.follow_target = zone_centers[current_zone]
	GlobalData.camera_center_path = zone_centers[current_zone].get_path()
	GlobalData.spawn_point = zone_spawn_points[current_zone].position

	if zone_number == 9:
		confettis.can_play_confettis = true

func _on_zone_body_entered(body: Node2D, zone_number: int) -> void:
	update_current_zone(body, zone_number)

func _on_retry_button_pressed() -> void:
	GlobalData.musicProgress = music_player.get_playback_position()   
	get_tree().reload_current_scene()
