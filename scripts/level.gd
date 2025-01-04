extends Node2D
class_name Level

@onready var player: Player = $Player
@onready var spawn_point: Marker2D = $SpawnPoint
@onready var tile_map_layer: TileMapLayer = $TileMapLayer


func reset() -> void:
	player.reset(spawn_point.position)

func _ready() -> void:
	player.position = spawn_point.position

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed(&"respawn"):
		reset()
