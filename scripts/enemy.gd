extends Area2D
class_name Enemy

signal enemy_has_died

@onready var spawn_point: Marker2D = $SpawnPoint
@onready var body: CollisionShape2D = $Body
@onready var sprite: Sprite2D = $Sprite

var is_alive: bool = true

func _ready() -> void:
	spawn_point.position = position

func respawn() -> void:
	position = spawn_point.position
	body.set_deferred(&"disabled", false)
	is_alive = true
	show()

func die() -> void:
	hide()
	body.set_deferred(&"disabled", true)
	is_alive = false
	enemy_has_died.emit()

func _on_enemy_respawn_timer_timeout() -> void:
	respawn()

func _on_area_entered(area: Area2D) -> void:
	# die if collision is with a blast
	if area.is_in_group(&"blasts"):
		die()
