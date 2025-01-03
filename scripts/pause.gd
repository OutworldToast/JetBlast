extends Control
class_name Pause

signal has_paused

func toggle_pause():
	get_tree().paused = not get_tree().paused

func _process(_delta: float) -> void:

	if Input.is_action_just_pressed("pause"):
		toggle_pause()
		has_paused.emit()
