extends RayCast3D

#@onready var bullet_hole = preload("res://scenes/bullet_hole.tscn")
#@onready var cam = get_node("Head/Camera3D")
#
#@export var speed := 40.0
#@export var range := 40.0
#
#signal hit_object(collision_position, collision_normal)
#
#var player_node: Node3D
#var traveled_distance = 0.0
#const RAY_LENGTH = 1000

#func _physics_process(delta: float) -> void:
	#position += global_basis * -Vector3.FORWARD * speed * delta
	#target_position += Vector3.FORWARD
	#force_raycast_update()
	#var collider = get_collider()
	#if is_colliding():
		#print(position)
		#enabled = false
		#set_physics_process(false)
		#if get_collider().is_in_group("environment"):
			#global_position = get_collision_point()
			#hit_object.emit(global_position, get_collision_normal())
			#cleanup()

   
#func cleanup() -> void:
	#queue_free()
	
	
