extends CharacterBody2D

class_name Player

signal has_died

var blast_sprite = preload("res://art/blast.png")

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var body_hitbox: CollisionShape2D = $BodyHitbox
@onready var head_hitbox: CollisionShape2D = $HeadHitbox
@onready var debug_hud: DebugHud = $DebugHud

const SPEED = 300.0
const JUMP_VELOCITY = -400.0
var base_scale: float
var center: Vector2

var looking_left: bool = false

@export var debug = true

func look_in_direction(direction: Vector2, flipped: bool = false) -> void:

	look_at(direction + position)

	if flipped:
		direction = direction.rotated(PI)

	if direction.x < 0:
		if !looking_left:
			apply_scale(Vector2(1, -1))
			looking_left = true
	else:
		if looking_left:
			apply_scale(Vector2(1, -1))
			looking_left = false

	if debug:
		print ("Character looking left" if looking_left else "Character looking right")
		debug_hud.add_circle(200*direction + position, Color.BLUE)

func blast(click_location: Vector2) -> void:
	var blast_direction = (position - click_location).limit_length(1.0).normalized()

	if blast_direction.x > 0:
		look_in_direction(blast_direction.rotated(0.5 * PI), blast_direction.y > 0)
	else:
		look_in_direction(blast_direction.rotated(-0.5 * PI), blast_direction.y > 0)

	var blast_velocity =  blast_direction * 2 * SPEED
	velocity += blast_velocity

	if debug:
		print("Blast direction:" + str(blast_direction))
		debug_hud.add_circle(position + blast_velocity, Color.RED)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"click"):
		blast(get_global_mouse_position())

func _physics_process(delta: float) -> void:

	# Add the gravity.
	if not is_on_floor():
		velocity.x = lerp(velocity.x, 0.0, 0.01)
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept"):
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_direction := Input.get_axis("ui_left", "ui_right")
	if input_direction:
		sprite.play()
		look_in_direction(Vector2(input_direction, 0))

		velocity.x = input_direction * SPEED
	else:
		sprite.stop()
		#velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()
