extends Control
class_name Main

@onready var hud: Control = $HUD
@onready var ui: Control = $UI
@onready var main_2d: Node2D = $Main2D
@onready var main_camera: Camera2D = $Main2D/MainCamera
@onready var pause: Pause = $UI/Pause

const levels : Dictionary = {
	TEST = "res://levels/test_level.tscn",
	TUTORIAL = "res://levels/tutorial_level.tscn",
}

var level_instance : Level
var menu_open: bool

# should probably be in UI
func open_menu() -> void:
	pause.toggle_pause()
	ui.show()
	menu_open = true

func close_menu() -> void:
	pause.unpause()
	ui.hide()
	menu_open = false

func toggle_menu() -> void:
	if menu_open:
		close_menu()
	else:
		open_menu()

func unload_level() -> void:
	if (is_instance_valid(level_instance)):
		level_instance.queue_free()
	level_instance = null

func load_level(path: String, name_: String = "") -> void:
	unload_level()
	var level_resource := load(path)
	if level_resource:
		level_instance = level_resource.instantiate()
		add_child(level_instance)
		print("Loaded Level " + name_)

func _on_load_level_test_pressed() -> void:
	load_level(levels.TEST, "Test")
	close_menu()

func _on_load_level_tutorial_pressed() -> void:
	load_level(levels.TUTORIAL, "Tutorial")
	close_menu()

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed(&"menu"):
		toggle_menu()
