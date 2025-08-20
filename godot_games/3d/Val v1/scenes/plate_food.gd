extends StaticBody3D

var speed=50

func _process(delta):
	position+=transform.basis * Vector3(0,0,-speed) * delta
