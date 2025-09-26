# ProtoController v1.0 by Brackeys
# CC0 License
# Intended for rapid prototyping of first-person games.
# Happy prototyping!

extends CharacterBody3D

signal changed_health(health_value)

## Can we move around?
@export var can_move : bool = true
## Are we affected by gravity?
@export var has_gravity : bool = true
## Can we press to jump?
@export var can_jump : bool = true
## Can we hold to run?
#@export var can_sprint : bool = false
## Can we press to enter freefly mode (noclip)?
@export var can_freefly : bool = false

@export_group("Speeds")
## Look around rotation speed.
@export var look_speed : float = 0.002
## Normal speed.
@export var base_speed : float = 7.0
## Speed of jump.
@export var jump_velocity : float = 3.5
## How fast do we run?
@export var walk_speed : float = 4.0
## How fast do we freefly?
@export var freefly_speed : float = 25.0

@export_group("Stats")
@export var health: int = 100
@export var armor: int = 50
@export var credits: int = 8000
@export var equipped: String = "pistol"
@export var primary_weapon: String
@export var secondary_weapon: String
@export var sound_range: int = 30

@export_group("Input Actions")
## Name of Input Action to move Left.
@export var input_left : String = "left"
## Name of Input Action to move Right.
@export var input_right : String = "right"
## Name of Input Action to move Forward.
@export var input_forward : String = "up"
## Name of Input Action to move Backward.
@export var input_back : String = "down"
## Name of Input Action to Jump.
@export var input_jump : String = "jump"
## Name of Input Action to Walk.
@export var input_walk: String = "walk"
## Name of Input Action to toggle freefly mode.
@export var input_freefly : String = "freefly"
@export var input_shop : String = "shop"

var mouse_captured : bool = false
var look_rotation : Vector2
var move_speed : float = 0.0
var freeflying : bool = false
var is_moving : bool = false

## IMPORTANT REFERENCES
@onready var head: Node3D = $Head
@onready var collider: CollisionShape3D = $Collider
@onready var shoot_timer: Timer = $Shoot_Timer

@onready var bullet = preload("res://scenes/bullet.tscn")
var new_bullet
@onready var bullet_hole = preload("res://scenes/bullet_hole.tscn")
@onready var marker = get_node("Head/Camera3D/Node3D/DunkelBlauWeaponsPackExportVersionCube/Marker3D")
var bullet_trail = load("res://scenes/bullet_trail.tscn")
@onready var aim_ray = $Head/Camera3D/AimRay
@onready var aim_ray_end = $Head/Camera3D/AimRayEnd
@onready var crosshair = $UserInterface/Reticle
@onready var temp = $Head/Camera3D/RayOrigin
@onready var cam = $Head/Camera3D
@onready var sound_radius = $Area3D/CollisionShape3D


var weapons = {
	"pistol": 15,
	"shotgun": 10,
	"rifle": 30,
	"sniper": 70
}

func _enter_tree() -> void:
	set_multiplayer_authority(str(name).to_int())
	
	
func _ready() -> void:
	print('just spawned')
	if not is_multiplayer_authority(): return 
	cam.current = true 
	
	check_input_mappings()
	look_rotation.y = rotation.y
	look_rotation.x = head.rotation.x
	crosshair.position.x = get_viewport().size.x / 2
	crosshair.position.y = get_viewport().size.y / 2 

func _unhandled_input(event: InputEvent) -> void:
	if not is_multiplayer_authority(): return 
	# Mouse capturing
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		capture_mouse()
	if Input.is_key_pressed(KEY_ESCAPE):
		release_mouse()
	
	# Look around
	if mouse_captured and event is InputEventMouseMotion:
		rotate_look(event.relative)
	
	# Toggle freefly mode
	if can_freefly and Input.is_action_just_pressed(input_freefly):
		if not freeflying:
			enable_freefly()
		else:
			disable_freefly()


func _process(delta: float) -> void:
	if not is_multiplayer_authority(): return 
	if health <= 0:
		death()
	
	if Input.is_action_just_pressed(input_shop):
		print('shop')
		get_parent().toggle_shop()


func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority(): return 
	# If freeflying, handle freefly and nothing else
	if can_freefly and freeflying:
		var input_dir := Input.get_vector(input_left, input_right, input_forward, input_back)
		var motion := (head.global_basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		motion *= freefly_speed * delta
		move_and_collide(motion)
		return
	
	# Apply gravity to velocity
	if has_gravity:
		if not is_on_floor():
			velocity += get_gravity() * delta

	# Apply jumping
	if can_jump:
		if Input.is_action_just_pressed(input_jump) and is_on_floor():
			velocity.y = jump_velocity

	## Modify speed based on sprinting
	#if can_sprint and Input.is_action_pressed(input_sprint):
			#move_speed = sprint_speed
	#else:
		#move_speed = base_speed
	
	# Modify speed based on walking
	if Input.is_action_pressed(input_walk):
		move_speed = walk_speed
	else:
		move_speed = base_speed
		
	# Apply desired movement to velocity
	if can_move:
		var input_dir := Input.get_vector(input_left, input_right, input_forward, input_back)
		var move_dir := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		if move_dir:
			velocity.x = move_dir.x * move_speed
			velocity.z = move_dir.z * move_speed
			is_moving = true
		else:
			velocity.x = move_toward(velocity.x, 0, move_speed)
			velocity.z = move_toward(velocity.z, 0, move_speed)
			is_moving = false
	else:
		velocity.x = 0
		velocity.y = 0
		is_moving = false
	
	if equipped == "pistol" or equipped == "sniper":
		if Input.is_action_just_pressed("shoot"):
			if shoot_timer.is_stopped():
				shoot_bullet.rpc()
	# might want to move this code to the guns themselves and have them inject the timer to the player
	elif equipped == "rifle":
		if Input.is_action_pressed("shoot"):
			if shoot_timer.is_stopped():
				shoot_bullet.rpc()
	
	# Use velocity to actually move
	move_and_slide()
	



## Rotate us to look around.
## Base of controller rotates around y (left/right). Head rotates around x (up/down).
## Modifies look_rotation based on rot_input, then resets basis and rotates by look_rotation.
func rotate_look(rot_input : Vector2):
	look_rotation.x -= rot_input.y * look_speed
	look_rotation.x = clamp(look_rotation.x, deg_to_rad(-85), deg_to_rad(85))
	look_rotation.y -= rot_input.x * look_speed
	transform.basis = Basis()
	rotate_y(look_rotation.y)
	head.transform.basis = Basis()
	head.rotate_x(look_rotation.x)


func enable_freefly():
	collider.disabled = true
	freeflying = true
	velocity = Vector3.ZERO

func disable_freefly():
	collider.disabled = false
	freeflying = false


func capture_mouse():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	mouse_captured = true


func release_mouse():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	mouse_captured = false


## Checks if some Input Actions haven't been created.
## Disables functionality accordingly.
func check_input_mappings():
	if can_move and not InputMap.has_action(input_left):
		push_error("Movement disabled. No InputAction found for input_left: " + input_left)
		can_move = false
	if can_move and not InputMap.has_action(input_right):
		push_error("Movement disabled. No InputAction found for input_right: " + input_right)
		can_move = false
	if can_move and not InputMap.has_action(input_forward):
		push_error("Movement disabled. No InputAction found for input_forward: " + input_forward)
		can_move = false
	if can_move and not InputMap.has_action(input_back):
		push_error("Movement disabled. No InputAction found for input_back: " + input_back)
		can_move = false
	if can_jump and not InputMap.has_action(input_jump):
		push_error("Jumping disabled. No InputAction found for input_jump: " + input_jump)
		can_jump = false
	#if can_sprint and not InputMap.has_action(input_sprint):
		#push_error("Sprinting disabled. No InputAction found for input_sprint: " + input_sprint)
		#can_sprint = false
	if can_freefly and not InputMap.has_action(input_freefly):
		push_error("Freefly disabled. No InputAction found for input_freefly: " + input_freefly)
		can_freefly = false


func enable_shoot():
	shoot_timer.stop()
	

#func test_decal(transform):
	##const bullet_mark = preload("res://scenes/test.tscn")
	##var b = bullet_mark.instantiate()
	##var marker = get_node("Head/Camera3D/Node3D/DunkelBlauWeaponsPackExportVersionCube/Marker3D")
	##marker.add_child(b)
	#get_tree().root.add_child(b)
	#print_tree_pretty()
	#b.global_transform = transform

func recoil_reset() -> void:
	aim_ray.transform.basis = temp.transform.basis
	aim_ray_end.transform.basis = temp.transform.basis
	#aim_ray.transform.basis = Basis()
	#aim_ray.transform.basis = transform.basis.rotated(Vector3(0,1,0), 0)
	#aim_ray_end.transform.basis = Basis()
	#aim_ray_end.transform.basis = transform.basis.rotated(Vector3(0,1,0), 0)

func recoil() -> void:
	var rot_x = randf_range(-0.1, 0.1)
	var rot_y = randf_range(-0.1, 0.1)
	#transform.basis = Basis() # reset rotation
	aim_ray.rotate_object_local(Vector3(0, 1, 0), rot_x) # first rotate in Y
	aim_ray.rotate_object_local(Vector3(1, 0, 0), rot_y) # then rotate in X
	aim_ray_end.rotate_object_local(Vector3(0, 1, 0), rot_x) # first rotate in Y
	aim_ray_end.rotate_object_local(Vector3(1, 0, 0), rot_y) # then rotate in X

@rpc("call_local")
func shoot_bullet():
	if is_moving:
		recoil()
	else:
		recoil_reset()
		
	if equipped == "pistol":
		shoot_timer.start(0.2)
	elif equipped == "rifle":
		shoot_timer.start(0.1)
	elif equipped == "sniper":
		shoot_timer.start(0.6)
	
	
	var b_trail_inst = bullet_trail.instantiate()
	if aim_ray.is_colliding():
		var index = aim_ray.get_collider_shape()
		var hit_obj = aim_ray.get_collider()
		var hit_obj_name = aim_ray.get_collider().shape_owner_get_owner(index).name
		print(hit_obj_name)
		b_trail_inst.init(marker.global_position, aim_ray.get_collision_point())
		if hit_obj.is_in_group("environment"):
			create_bullet_hole(aim_ray.get_collision_point())
		elif hit_obj.is_in_group("player"):
			if hit_obj_name == "Face":
				hit_obj.take_damage.rpc_id(hit_obj.get_multiplayer_authority(), weapons[equipped] * 1.5)
			else:
				hit_obj.take_damage.rpc_id(hit_obj.get_multiplayer_authority(), weapons[equipped])
			print(hit_obj.health)
	else:
		b_trail_inst.init(marker.global_position, aim_ray_end.global_position)
	get_parent().add_child(b_trail_inst)
	#marker.add_child(new_bullet)
	
	#new_bullet.global_transform = marker.global_transform
  # In the receiving node's script
	#var emitting_node = get_node("../Path/To/EmittingNode") # Adjust path as needed
	#if new_bullet:
		#new_bullet.hit_object.connect(_create_bullet_hole)
		#var b_trail = bullet_trail.instantiate()
		#b_trail.init(marker.global_position, )
	#func on_custom_signal_received(arg1, arg2):
		## Handle the signal here
		#print("Signal received with arguments: ", arg1, ", ", arg2)
	#test_decal(new_bullet.global_transform)
	
func create_bullet_hole(collision_position: Vector3) -> void:
	var b = bullet_hole.instantiate()
	get_tree().root.add_child(b)
	b.global_position = collision_position
	b.look_at(collision_position, Vector3.UP)

# probs delete this
func _create_bullet_hole(collision_position: Vector3, collision_normal: Vector3) -> void:
	#print('here')
	var b = bullet_hole.instantiate()
	get_tree().root.add_child(b)
	#print_tree_pretty()
	b.global_position = collision_position
	#print(b.global_position)
	b.look_at(collision_position + collision_normal, Vector3.UP)

@rpc("any_peer")
func take_damage(amount: int) -> void: 
	health -= amount
	print(health)	
	changed_health.emit(health)
	if health <= 0:
		get_parent().respawn(multiplayer.get_unique_id())
	

func death() -> void:
	pass
	#var spawn_point = get_parent().get_child(4).get_child(0)
	#position = spawn_point.position
	
