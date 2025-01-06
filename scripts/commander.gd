extends Enemy
class_name Commander

signal commander_has_died

func die() -> void:
	super()
	commander_has_died.emit()
