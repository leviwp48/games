extends Node3D

@onready var player = preload("res://scenes/player.tscn")
@onready var spawn_point = $SpawnPoint

func _ready() -> void:
	var p1 = player.instantiate()
	add_child(p1)
	p1.position = spawn_point.position
