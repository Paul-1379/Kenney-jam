extends Sprite2D

@export var simple_raycast: RayCast2D
@export var big_size_raycast: Array[RayCast2D]
@export var rotated_center: Node2D

@export var animation_player: AnimationPlayer

@export var size_mouse_zone: float
@export var big_size: bool
var tile_pos: Vector2i

func _ready() -> void:
	update_pos(true)

func _process(delta: float) -> void:
	if not Input.is_action_just_pressed("size"):
		return
		
	var mouse_pos = get_viewport().get_mouse_position()
	var delta_x = mouse_pos.x - position.x
	var delta_y = mouse_pos.y - position.y

	if (mouse_pos - position).length_squared() < size_mouse_zone * size_mouse_zone:
		switch_size()
	else:
		if abs(delta_x) > abs(delta_y):
			move(Vector2i.RIGHT if delta_x > 0 else Vector2i.LEFT)
		else:
			move(Vector2i.DOWN if delta_y > 0 else Vector2i.UP)

func move(direction: Vector2i) -> void:
	var can_move = false
	if big_size:
		can_move = check_can_move(direction, big_size_raycast)
	else:
		can_move = check_can_move(direction, [simple_raycast])
	if can_move:
		tile_pos += direction
		update_pos(false)

func check_can_move(direction: Vector2i, to_check_raycasts: Array[RayCast2D]) -> bool:
	rotated_center.rotation_degrees = rad_to_deg(Vector2(direction).angle()) - 90
	if to_check_raycasts.size() == 1:
		set_raycast_target_to(direction)
		
	var checked_nodes_path: Array[String]
	var checked_nodes : Array[Node2D]
	var big_crates_number = 0
	for raycast in to_check_raycasts:
		raycast.force_raycast_update()
		if raycast.is_colliding():
			var collider = raycast.get_collider()
			if collider.is_in_group("crates"):
				var can_move = collider.check_move(direction, big_size)
				if can_move:
					var path = collider.get_path()
					if not path in checked_nodes_path:
						checked_nodes_path.append(path)
						if collider.is_big:
							big_crates_number += 1
						checked_nodes.append(collider)
				if not can_move:
					return false
			else:
				return false
	var can_move = big_crates_number < 2
	if can_move:
		for checked in checked_nodes:
			checked.apply_move(direction)
	return can_move

func set_raycast_target_to(relative_target_tile_pos: Vector2i):
	simple_raycast.target_position = (tile_to_position(relative_target_tile_pos + tile_pos, true) - tile_to_position(tile_pos, true)) * (1.5 if big_size else 2)
	simple_raycast.force_raycast_update()

func tile_to_position(tile_pos: Vector2i, for_player: bool) -> Vector2:
	var pos = tile_pos * 64
	if for_player:
		pos += (Vector2i.ZERO if big_size else Vector2i(32, 32))
	return pos
	
func update_pos(instantanious: bool) -> void:
	var target = tile_to_position(tile_pos, true)
	if instantanious:
		position = target
	else:
		var tween = create_tween()
		tween.tween_property(self, "position", Vector2(target), 0.08)

func switch_size() -> void:
	if animation_player.is_playing():
		return
	
	if not big_size:
		set_raycast_target_to(Vector2i(-1, -1))
		if simple_raycast.is_colliding():
			set_raycast_target_to(Vector2i(-1, 1))
			if simple_raycast.is_colliding():
				set_raycast_target_to(Vector2i(1, -1))
				if simple_raycast.is_colliding():
					set_raycast_target_to(Vector2i(1, 1))
					if simple_raycast.is_colliding():
						return
					else:
						tile_pos += Vector2i(1, 1)
				else:
					tile_pos += Vector2i(1, 0)
			else:
				tile_pos += Vector2i(0, 1)
	
	big_size = not big_size
	animation_player.play("grow" if big_size else "shrink")
	update_pos(false)
