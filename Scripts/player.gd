extends Sprite2D

@export var override_position: bool
@export var simple_raycast: RayCast2D
@export var big_size_raycast: Array[RayCast2D]
@export var rotated_center: Node2D
@export var input_buffer_timer: Timer
@export var input_buffer_time: float = 0.2
@export var animation_player: AnimationPlayer
@export_group("sfx")
@export var push_sfx: AudioStreamPlayer2D
@export var grow_sfx: AudioStreamPlayer2D
@export var shrink_sfx: AudioStreamPlayer2D
@export_group("Player sprites")
@export var down_sprite: Texture
@export var up_sprite: Texture
@export var left_sprite: Texture
@export var right_sprite: Texture

@export var size_mouse_zone: float
@export var big_size: bool
var tile_pos: Vector2i
var move_tween_finished: bool = true

var input_buffer_move_dir: Vector2
func _ready() -> void:
	tile_pos = position_to_tile(GlobalData.spawn_point)
	if override_position and not GlobalData.override_position_done:
		tile_pos = position_to_tile(position)
		GlobalData.override_position_done = true
	
	update_pos(true)

func _process(_delta: float) -> void:
	if not input_buffer_timer.is_stopped():
		input_buffer_timer.stop()
		move(input_buffer_move_dir)
		return
	if not Input.is_action_just_pressed("size"):
		return

	var mouse_pos = get_global_mouse_position() - position

	if mouse_pos.length_squared() < size_mouse_zone * size_mouse_zone:
		switch_size()
	else:
		if abs(mouse_pos.x) > abs(mouse_pos.y):
			move(Vector2i.RIGHT if mouse_pos.x > 0 else Vector2i.LEFT)
		else:
			move(Vector2i.DOWN if mouse_pos.y > 0 else Vector2i.UP)

func move(direction: Vector2i) -> void:
	if not move_tween_finished or animation_player.is_playing():
		input_buffer_timer.wait_time = input_buffer_time
		input_buffer_timer.start()
		input_buffer_move_dir = direction
		return
	var can_move = false
	if big_size:
		can_move = check_can_move(direction, big_size_raycast)
	else:
		can_move = check_can_move(direction, [simple_raycast])
	if can_move:
		update_sprite(direction)
		tile_pos += direction
		update_pos(false)

func update_sprite(direction: Vector2i):
	match direction:
		Vector2i.RIGHT:
			texture = right_sprite
		Vector2i.LEFT:
			texture = left_sprite
		Vector2i.UP:
			texture = up_sprite
		Vector2i.DOWN:
			texture = down_sprite

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
	if can_move and checked_nodes.size() > 0:
		play_sound(push_sfx)
	return can_move
func play_sound(sfx: AudioStreamPlayer2D) -> void:
	sfx.play()
func set_raycast_target_to(relative_target_tile_pos: Vector2i):
	simple_raycast.target_position = (tile_to_position(relative_target_tile_pos + tile_pos) - tile_to_position(tile_pos)) * (1.5 if big_size else 2.0)
	simple_raycast.force_raycast_update()

func tile_to_position(tile_pos_to_convert: Vector2i) -> Vector2:
	var pos = tile_pos_to_convert * 64
	return pos + tile_shift()

func position_to_tile(position_to_convert: Vector2) -> Vector2i:
	position_to_convert -= Vector2(tile_shift())
	return Vector2i(position_to_convert / 64)
func tile_shift() -> Vector2i:
	return  Vector2.ZERO if big_size else Vector2(32, 32)
func update_pos(instantanious: bool) -> void:
	var target = tile_to_position(tile_pos)
	if instantanious:
		position = target
	else:
		move_tween_finished = false
		var tween = create_tween()
		var movement = target - position
		var overshoot = target + movement.normalized() * 4.0 # 4 pixels de dépassement

		tween.tween_property(self, "position", overshoot, 0.13) \
			.set_trans(Tween.TRANS_CUBIC) \
			.set_ease(Tween.EASE_OUT)

		tween.tween_property(self, "position", Vector2(target), 0.05) \
			.set_trans(Tween.TRANS_BACK) \
			.set_ease(Tween.EASE_OUT)
		
		var tween2 = create_tween()
		var initial_scale = scale
		var final_scale = scale
		final_scale.y *= 0.7 if movement.x < movement.y else 1.0
		final_scale.x *= 0.7 if movement.x > movement.y else 1.0
		
		tween2.tween_property(self, "scale", final_scale, 0.1) \
			.set_trans(Tween.TRANS_CUBIC) \
			.set_ease(Tween.EASE_OUT)

		tween2.tween_property(self, "scale", initial_scale, 0.1) \
			.set_trans(Tween.TRANS_BACK) \
			.set_ease(Tween.EASE_OUT)
		
		await tween.finished
		move_tween_finished = true

func switch_size() -> void:
	if animation_player.is_playing() or not move_tween_finished:
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
	play_sound(grow_sfx if big_size else shrink_sfx)
	update_pos(false)
