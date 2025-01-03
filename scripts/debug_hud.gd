extends CanvasLayer

class_name DebugHud

@onready var debug_click: Control = $DebugClick

@export var delay: float = 1.0
@export var radius: float = 20.0

func add_circle(position_, color = Color.BLACK, delay_ = delay, radius_ = radius):
	debug_click.add_circle(position_, delay_, radius_, color)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"click"):
		var click_location = debug_click.get_global_mouse_position()
		print("Click at " + str(click_location))
		add_circle(click_location)

func _process(_delta: float) -> void:
	debug_click.queue_redraw()
