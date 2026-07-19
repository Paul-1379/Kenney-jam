extends Control

@export var confettis_textures: Array[Texture]
@export var can_play_confettis: bool
@export var confettis_per_call: int = 120

func play_confettis() -> void:
	if can_play_confettis:
		var children = get_children()
		var current_time = Time.get_ticks_msec()
		for child in children:
			if current_time - int(child.name) > 13000:
				child.queue_free()
		for i in range(confettis_per_call):
			create_confetti()


func create_confetti() -> void:
	var screen_size = get_viewport_rect().size
	var sprite = Sprite2D.new()
	sprite.texture = confettis_textures.pick_random()
	sprite.position = Vector2(
		randi_range(0, screen_size.x),
		-50)
	sprite.scale = Vector2.ONE * (randf_range(0.2, 0.6))
	sprite.name = str(Time.get_ticks_msec())
	var tween = create_tween()
	tween.tween_property(sprite, "position", 
	sprite.position + Vector2(randi_range(-50, 50), randi_range(300, 800)), 6.0)
	tween.parallel().tween_property(sprite, "modulate:a", 0.0, 5)
	add_child(sprite)
