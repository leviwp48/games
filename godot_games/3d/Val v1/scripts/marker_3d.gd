extends Marker3D

func reset():
	transform.basis = Basis() # reset rotation
	
	
func recoil():
	print('rotating')
	var rot_x = randf_range(-0.1, 0.1)
	var rot_y = randf_range(-0.1, 0.1)
	transform.basis = Basis() # reset rotation
	rotate_object_local(Vector3(0, 1, 0), rot_x) # first rotate in Y
	rotate_object_local(Vector3(1, 0, 0), rot_y) # then rotate in X
