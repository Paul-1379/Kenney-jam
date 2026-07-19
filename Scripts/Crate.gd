extends Area2D

@export var is_big: bool
@export var raycast: RayCast2D

var tile_pos : Vector2i

func _ready() -> void:
	guess_position()

func guess_position() -> void:
	tile_pos =  Vector2i((position - (Vector2.ZERO if is_big else Vector2(32, 32))) / 64)

func check_move(direction: Vector2i, big_force) -> bool:
	raycast.target_position = Vector2(direction) * (192 if is_big else 128)
	raycast.force_raycast_update()

	return not raycast.is_colliding() and ((big_force and is_big) or not is_big)
	
func apply_move(direction: Vector2i):
	tile_pos += direction
	update_pos(false)

func update_pos(instantanious: bool) -> void:
	var target = tile_pos * 64 + (Vector2i.ZERO if is_big else Vector2i(32, 32))
	if instantanious:
		position = target
	else:
		var tween = create_tween()
		tween.tween_property(self, "position", Vector2(target), 0.08)
