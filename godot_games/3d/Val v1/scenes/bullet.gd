extends Area3D

const SPEED = 55.0
const RANGE = 40.0

var traveled_distance = 0.0

func _physics_process(delta):
	position += transform.basis.z * SPEED * delta
	traveled_distance += SPEED * delta
	if traveled_distance > RANGE:
		queue_free()
