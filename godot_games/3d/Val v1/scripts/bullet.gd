extends RayCast3D

@export var speed := 40.0
@export var range := 40.0

var player_node: Node3D

#var is_moving = get_node("./ProtoController").is_moving
var traveled_distance = 0.0

func _ready():
	player_node = get_tree().get_first_node_in_group("player") # Assuming player is in "player" group
	print(player_node.is_waiting)
	
	
func _physics_process(delta: float) -> void:
	#print(is_moving)
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
	#var is_moving = get_root()
	#.get_node("ProtoController").is_moving
	#var is_moving = get_node("./ProtoController").is_moving
	#print(typeof(player_node))
	#print(is_moving)
	queue_free()
