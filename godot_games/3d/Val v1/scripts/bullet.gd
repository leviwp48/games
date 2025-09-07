extends RayCast3D

@onready var bullet_mark = preload("res://scenes/bullet_mark.tscn")

@export var speed := 40.0
@export var range := 40.0

var player_node: Node3D
var traveled_distance = 0.0
	
	
func _physics_process(delta: float) -> void:
	position += global_basis * -Vector3.FORWARD * speed * delta
	target_position += Vector3.FORWARD * speed * delta
	force_raycast_update()
	var collider = get_collider()
	if is_colliding():
		global_position = get_collision_point()
		set_physics_process(false)
		
		   
func cleanup() -> void:
	print('cleaning up')
	var b = bullet_mark.instance()
	b.global_transform = self.global_transform
	queue_free()
	
	
