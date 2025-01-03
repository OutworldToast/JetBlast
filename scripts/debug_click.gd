extends Control

class_name DebugClick

class Circle:
	var position_: Vector2
	var radius_: float
	var color_: Color

	func _init(pos, rad, color) -> void:
		position_ = pos
		radius_ = rad
		color_ = color

var circles: Array[Circle] = []

func add_circle(position_: Vector2, delay_: float, radius_: float, color: Color) -> void:
	# Add circle data
	var circle = Circle.new(position_, radius_, color)
	circles.append(circle)
	await get_tree().create_timer(delay_).timeout
	circles.erase(circle)

	#var tween = create_tween()
	#tween.tween_property(self, "modulate:a", 0, delay_)
	#await tween.finished

func _draw():
	# Draw all circles
	for circle in circles:
		draw_circle(circle.position_, circle.radius_, circle.color_, false)
