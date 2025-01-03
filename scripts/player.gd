extends CharacterBody2D

class_name Player

signal has_died

var blast_sprite = preload("res://art/blast.png")

# debug true also sets infinite_blasts
@export var debug = true

#region nodes
@onready var sprite: AnimatedSprite2D = $Sprite
@onready var body_hitbox: CollisionShape2D = $BodyHitbox
@onready var head_hitbox: CollisionShape2D = $HeadHitbox
@onready var debug_hud: DebugHud = $DebugHud
@onready var spawn_point: Marker2D = $SpawnPoint
@onready var charge_timer: Timer = $ChargeTimer
@onready var effects_layer: CanvasLayer = $EffectsLayer

#endregion nodes

#region consts
const TERMINAL_SPEED = 1200.0
const SPEED = TERMINAL_SPEED/3
const JUMP_VELOCITY = -400.0
#endregion consts

var looking_left: bool = false
var has_jump: bool = true
var has_blast: bool = true

var infinite_blasts: bool = debug

func set_spawn_point(position_: Vector2) -> void:
	spawn_point.position = position_

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

func blast(click_location: Vector2, charge = 1.0) -> void:
	var blast_direction = (position - click_location).limit_length(1.0)

	if blast_direction.x > 0:
		look_in_direction(blast_direction.rotated(0.5 * PI), blast_direction.y > 0)
	else:
		look_in_direction(blast_direction.rotated(-0.5 * PI), blast_direction.y > 0)

	var min_blast = TERMINAL_SPEED * blast_direction * charge
	var redirect_blast = blast_direction * velocity.length()

	var redirect_is_larger = redirect_blast.length_squared() > min_blast.length_squared()

	velocity = redirect_blast if redirect_is_larger else min_blast

	if not infinite_blasts:
		has_blast = false

	create_blast_visual(100 * blast_direction * Vector2(-1, -1), charge)

	if debug:
		print("Charge power: " + str(charge))
		print("Blast direction:" + str(blast_direction))
		print("Velocity magnitude: " + str(velocity.length()))
		debug_hud.add_circle(position + 200*blast_direction, Color.PURPLE)
		debug_hud.add_circle(position + velocity, Color.RED)

func create_blast_visual(blast_location, charge = 1.0) -> void:
	# create blast
	var explosion = Sprite2D.new()
	explosion.global_position = position + blast_location
	explosion.texture = blast_sprite
	explosion.apply_scale(scale * charge)

	# add blast to tree
	effects_layer.add_child(explosion)

	# destroy after 2 seconds
	await get_tree().create_timer(2.0).timeout
	explosion.queue_free()

func jump() -> void:

	var look_direction: Vector2
	var look_direction_changed = false

	# if upward velocity smaller than jump velocity
	if velocity.y > JUMP_VELOCITY:
		velocity.y = JUMP_VELOCITY
		has_jump = false

		var look_rotation = 0.5

		if velocity.x < 0:
			look_rotation = -0.5

		look_direction = velocity.rotated(look_rotation * PI)
		look_direction_changed = true

	if velocity.x > -300 and velocity.x < 300:
		look_direction = Vector2(velocity.x, 0)
		look_direction_changed = true

	if look_direction_changed:
		look_in_direction(look_direction)

func walk(input_direction: float, delta) -> void:
	if input_direction:

		var input_velocity = input_direction * SPEED
		var abs_velocity_x = absf(velocity.x)

		if sign(velocity.x) == sign(input_direction):
			# Moving in the same direction as input
			if abs_velocity_x < SPEED:
				velocity.x += 2 * input_velocity * delta
		else:
			velocity.x += input_velocity * delta

		if absf(input_velocity) > abs_velocity_x:
			look_in_direction(Vector2(input_direction, 0))
			sprite.play()

	else:
		sprite.stop()
		# apply horizontal friction
		velocity.x = lerp(velocity.x, 0.0, 0.3 * delta)

func reset() -> void:
	velocity = Vector2.ZERO
	position = spawn_point.position
	look_in_direction(Vector2(position.x, 0))
	looking_left = false
	has_jump = true
	has_blast = true

func _ready() -> void:
	set_spawn_point(get_viewport_rect().size / 2)
	position = spawn_point.position

func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"click"):
		charge_timer.start()

	if event.is_action_released(&"click") and has_blast:
		blast(get_global_mouse_position(), 2.0 - (charge_timer.time_left / 2))
		charge_timer.stop()

func _physics_process(delta: float) -> void:

	if debug:
		debug_hud.add_circle(spawn_point.position, Color.CORNFLOWER_BLUE)

	# apply gravity and vertical friction
	if not is_on_floor():
		var gravity = get_gravity()
		var ver_friction = gravity/TERMINAL_SPEED
		var current_velocity = velocity

		velocity += gravity * delta
		velocity.y -= ver_friction.y * delta * current_velocity.y

	# handle jump
	if Input.is_action_just_pressed(&"jump") and has_jump:
		jump()
	if Input.is_action_just_pressed(&"respawn"):
		reset()

	# handle walking/countersteering
	var input_direction := Input.get_axis(&"left", &"right")
	walk(input_direction, delta)

	move_and_slide()
