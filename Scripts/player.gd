extends Sprite2D

@export var raycast: RayCast2D
@export var animation_player : AnimationPlayer

@export var size_mouse_zone:  float
@export var big_size: bool
var tile_pos : Vector2i
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	update_pos(true)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not Input.is_action_just_pressed("size"):
		return
		
	var mouse_pos = get_viewport().get_mouse_position()
	var delta_x = mouse_pos.x - position.x
	var delta_y = mouse_pos.y - position.y
	print((mouse_pos - position).length())
	if (mouse_pos - position).length_squared() < size_mouse_zone * size_mouse_zone:
		switch_size()
	else:
		if abs(delta_x) > abs(delta_y):
			move(Vector2i.RIGHT if delta_x > 0 else Vector2i.LEFT)
		else:
			move(Vector2i.DOWN if delta_y > 0 else Vector2i.UP)

func move(direction: Vector2i) -> void:
	raycast.target_position = Vector2(direction) * (96 if big_size else 128)
	print(raycast.target_position)
	raycast.force_raycast_update()
	if not raycast.is_colliding():
		tile_pos += direction
		update_pos(false)

func update_pos(instantanious: bool) -> void:
	var target = tile_pos * 64 + (Vector2i.ZERO if big_size else Vector2i(32, 32))
	if instantanious:
		position = target
	else:
		var tween = create_tween()
		tween.tween_property(self, "position", Vector2(target), 0.08)
func switch_size() -> void:
	if not animation_player.is_playing():
		big_size = not big_size
		animation_player.play("grow" if big_size else "shrink")
		update_pos(false)
	print("switch size")
	   
