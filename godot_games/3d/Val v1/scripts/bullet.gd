extends RayCast3D

@export var speed := 4.0
@export var range := 40.0

var traveled_distance = 0.0

func _physics_process(delta: float) -> void:
	position += global_basis * -Vector3.FORWARD * speed * delta
	target_position += Vector3.FORWARD * speed * delta
	force_raycast_update()
	var collider = get_collider()
	if is_colliding():
		global_position = get_collision_point()
		set_physics_process(false)
	#traveled_distance += SPEED * delta
	#if traveled_distance > RANGE:
		   
func cleanup() -> void:
	print('cleaning up')
	queue_free()
