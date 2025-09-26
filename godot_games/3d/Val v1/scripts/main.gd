extends Node3D

@onready var main_menu = $CanvasLayer/MainMenu
@onready var address_entry = $CanvasLayer/MainMenu/MarginContainer/VBoxContainer/AddressEnter
@onready var player_scene = preload("res://scenes/player.tscn")
@onready var spawn_point = $Level1/SpawnPoint
@onready var hud = $CanvasLayer/HUD
@onready var health_bar = $CanvasLayer/HUD/HealthBar
@onready var shop = $CanvasLayer/Shop
@onready var equip_pistol = $PanelContainer/HBoxContainer/VBoxContainer/EquipPistol
@onready var equip_rifle = $PanelContainer/HBoxContainer/VBoxContainer/EquipRifle
@onready var equip_sniper = $PanelContainer/HBoxContainer/VBoxContainer/EquipSniper
@onready var game_timer = $GameTimer
const PORT = 9999
var enet_peer = ENetMultiplayerPeer.new()
var game_score = [0, 0]
var player_scores = {}

#
#func _ready() -> void:
	#var p1 = player.instantiate()
	#add_child(p1)
	#p1.position = spawn_point.position


func add_player(peer_id) -> void:
	var player = player_scene.instantiate()
	player.name = str(peer_id)
	print(player.name)
	add_child(player)
	player.position = spawn_point.position
	if player.is_multiplayer_authority():
		print('adding health bar')
		player.changed_health.connect(update_health_bar)
	print('player added')
	player_scores[peer_id] = {"kills": 0, "deaths": 0}
	print(player_scores)


func remove_player(peer_id) -> void: 
	var player = get_node_or_null(str(peer_id))
	if player:
		player.queue_free()


func update_health_bar(health_value) -> void:
	health_bar.value = health_value


func respawn(peer_id) -> void:
	print('resapwning')
	var player = get_node_or_null(str(peer_id))
	player.health = 100
	player.position = spawn_point.position
	update_health_bar(player.health)
	add_kill(peer_id)



func toggle_shop() -> void:
	if shop.is_visible_in_tree():
		shop.hide()
	else:
		shop.show()
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		

@rpc("any_peer")
func add_kill(id) -> void:
	print('here 1')
	print(player_scores)
	player_scores[id]["kills"] += 1
	print('here 2')
	print(player_scores)

	

func _on_host_button_pressed() -> void:
	main_menu.hide()
	hud.show()	 
	enet_peer.create_server(PORT)
	multiplayer.multiplayer_peer = enet_peer
	multiplayer.peer_connected.connect(add_player)
	multiplayer.peer_disconnected.connect(remove_player)
	
	add_player(multiplayer.get_unique_id())

	upnp_setup()


func _on_join_button_pressed() -> void:
	main_menu.hide()
	hud.show()
	print(address_entry.text)
	# NEED TO FIX THIS LATER IT DOESN"T LIKE THE adress for some reason 
	#enet_peer.create_client(address_entry.text, PORT)
	enet_peer.create_client('localhost', PORT)
	multiplayer.multiplayer_peer = enet_peer
	#add_player(multiplayer.get_unique_id())
	print(multiplayer.multiplayer_peer)


func _on_multiplayer_spawner_spawned(node: Node) -> void:
	if node.is_multiplayer_authority():
		node.changed_health.connect(update_health_bar)


func upnp_setup():
	var upnp = UPNP.new()
	var discover_result = upnp.discover()
	assert(discover_result == UPNP.UPNP_RESULT_SUCCESS, \
		"UPNP Discover Failed! Error %s" % discover_result)
	assert(upnp.get_gateway() and upnp.get_gateway().is_valid_gateway(), \
		"UPNP Invalid Gateway!")
	
	var map_result = upnp.add_port_mapping(PORT)
	assert(map_result == UPNP.UPNP_RESULT_SUCCESS, \
		"UPNP Port Mapping Failed! Error %s" % map_result) 

	print("Success! Join Address: %s" % upnp.query_external_address())


func _on_equip_pistol_pressed() -> void:
	var player = get_node_or_null(str(multiplayer.get_unique_id()))
	player.equipped = "pistol"
	player.credits = player.credits - 400
	print(player.credits)


func _on_equip_rifle_pressed() -> void:
	var player = get_node_or_null(str(multiplayer.get_unique_id()))
	player.equipped = "rifle"
	player.credits = player.credits - 2900
	print(player.credits)


func _on_equip_sniper_pressed() -> void:
	var player = get_node_or_null(str(multiplayer.get_unique_id()))
	player.equipped = "sniper"
	player.credits = player.credits - 3600
	print(player.equipped)
	print(player.credits)
	

func _on_start_game_pressed() -> void:
	game_timer.start(10.0)


func _on_game_timer_timeout() -> void:
	print("game ended!")
