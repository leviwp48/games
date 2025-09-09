extends RayCast3D

@onready var bullet_hole = preload("res://scenes/bullet_hole.tscn")

@export var speed := 40.0
@export var range := 40.0

signal hit_object(collision_position, collision_normal)

var player_node: Node3D
var traveled_distance = 0.0
	
	
func _physics_process(delta: float) -> void:
	position += global_basis * -Vector3.FORWARD * speed * delta
	target_position += Vector3.FORWARD * speed * delta
	force_raycast_update()
	var collider = get_collider()
	if is_colliding():
		enabled = false
		set_physics_process(false)
		if get_collider().is_in_group("environment"):
			#print(get_collider())
			global_position = get_collision_point()
			#print(get_collision_point())
			#print(global_position)
			#test_decal()
			hit_object.emit(global_position, get_collision_normal())
			cleanup()
			#print('colliding and creating marker')


#func test_decal():
	##const bullet_mark = preload("res://scenes/bullet_hole.tscn")
	#var b = bullet_hole.instantiate()
	##var marker = get_node("Head/Camera3D/Node3D/DunkelBlauWeaponsPackExportVersionCube/Marker3D")
	##marker.add_child(b)
	##print(get_tree().root)
	#get_tree().root.add_child(b)
	#print_tree_pretty()
	##print(typeof(get_collision_normal()))
	##print(typeof(global_position))
	#b.global_position = global_position
	#print(b.global_position)
	#b.look_at(b.global_position + get_collision_normal(), Vector3.UP)

   
func cleanup() -> void:
	print('cleaning up')
	queue_free()
	
	
