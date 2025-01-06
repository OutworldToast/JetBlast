extends CharacterBody2D

class_name Player

signal has_died
signal has_respawned

var blast_scene: PackedScene = preload("res://scenes/blast.tscn")

# debug true also sets infinite_blasts
@export var debug = false

#region nodes
@onready var sprite: AnimatedSprite2D = $Sprite
@onready var body_hitbox: CollisionShape2D = $BodyHitbox
@onready var head: Area2D = $Head
@onready var head_hitbox: CollisionShape2D = $Head/HeadHitbox
@onready var debug_hud: DebugHud = $DebugHud
@onready var charge_timer: Timer = $ChargeTimer
#TODO: move this to main?
@onready var effects_layer: CanvasLayer = $EffectsLayer
@onready var blast_refraction_timer: Timer = $BlastRefractionTimer

#TESTING BLAST REFRESH
@onready var enemy: Enemy = $"../Enemy"
@onready var enemy_respawn_timer: Timer = $"../EnemyRespawnTimer"

#endregion nodes

#region consts
const TERMINAL_SPEED = 1200.0
const SPEED = TERMINAL_SPEED/3
const JUMP_VELOCITY = -600.0

# should be multiplied by delta
const WALKING_FRICTION = 5.0
const ROLLING_FRICTION = 0.5

#endregion consts

# bools for game logic
var is_active: bool = true

var rolling: bool = true
var looking_left: bool = false

var has_jump: bool = true
var has_blast: bool = true
var blasting: bool = false

var blast_refresh_disabled: bool = false

# debug/simplifiers
var infinite_blasts: bool = debug

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

func create_blast(blast_location, charge = 1.0) -> void:
	# create blast

	var explosion = blast_scene.instantiate()

	explosion.global_position = position + blast_location
	explosion.apply_scale(scale * charge)
	#
	#debug_hud.add_circle(explosion.global_position, Color.DARK_RED, )

	# add blast to tree
	if effects_layer:
		effects_layer.add_child(explosion)
		#owner.add_child(explosion)
		#explosion.add_to_group(&"blasts")

	# destroy after 2 seconds
	await get_tree().create_timer(2.0).timeout
	explosion.queue_free()

func blast(click_location: Vector2, charge = 1.0) -> void:
	var blast_direction = (position - click_location).limit_length(1.0)

	# remove small charges for accuracy
	charge = charge if charge > 1.2 else 1.0

	if blast_direction.x > 0:
		look_in_direction(blast_direction.rotated(0.5 * PI), blast_direction.y > 0)
	else:
		look_in_direction(blast_direction.rotated(-0.5 * PI), blast_direction.y > 0)

	var min_blast = TERMINAL_SPEED * blast_direction * charge
	var redirect_blast = blast_direction * velocity.length()

	var redirect_is_larger = redirect_blast.length_squared() > min_blast.length_squared()

	velocity = redirect_blast if redirect_is_larger else min_blast

	blasting = true
	stop_rolling()

	if not infinite_blasts:
		blast_refresh_disabled = true
		blast_refraction_timer.start()
		has_blast = false

	create_blast(100 * blast_direction * Vector2(-1, -1), charge)

	if debug:
		print("Charge power: " + str(charge))
		print("Blast direction:" + str(blast_direction))
		print("Velocity magnitude: " + str(velocity.length()))
		debug_hud.add_circle(position + 200*blast_direction, Color.PURPLE)
		debug_hud.add_circle(position + velocity, Color.RED)

	#TESTING blast refresh
	if enemy.is_alive:
		#enemy.die()
		enemy_respawn_timer.start()

func jump() -> void:

	# TODO: bugfix for incorrect flip when moving right, tapping left then jumping after coming to standstill

	# jump only if it would increase velocity
	if velocity.y > JUMP_VELOCITY:

		var look_direction: Vector2
		var look_direction_changed = false

		velocity.y = JUMP_VELOCITY
		has_jump = false

		var look_rotation = 0.5

		if velocity.x < 0:
			look_rotation = -0.5
		look_direction = velocity.rotated(look_rotation * PI)
		look_direction_changed = true

		if absf(velocity.x) < 1.2*SPEED:
			look_direction = Vector2(velocity.x, 0)
			look_direction_changed = true

		if look_direction_changed:
			look_in_direction(look_direction)

		stop_rolling()
		blasting = false

func walk(input_direction: float, delta) -> void:

	# TODO: snappier turning

	if absf(velocity.x) < 5.0:
		velocity.x = 0
		stop_rolling()
		blasting = false

	if input_direction:

		var input_velocity = input_direction * SPEED
		var abs_velocity_x = absf(velocity.x)
		var modifier

		if absf(input_velocity) > abs_velocity_x:
			look_in_direction(Vector2(input_direction, 0))
			sprite.play()

		# checks if player within walking speed
		if abs_velocity_x < SPEED:
			blasting = false
			stop_rolling()
			# make walking snappier
			modifier = 3
		elif sign(velocity.x) != sign(input_direction):
			# allows for quicker countersteering in the air
			modifier = 2
		else:
			# do not modify speed if same direction and not in walking speed
			return

		velocity.x += modifier * input_velocity * delta

	else:
		sprite.stop()

func reset(position_ = get_viewport_rect().size/2) -> void:
	velocity = Vector2.ZERO
	position = position_

	look_in_direction(Vector2(position.x, 0))

	looking_left = false
	has_jump = true
	has_blast = true
	blasting = false
	stop_rolling()

	is_active = true
	has_respawned.emit()

func start_rolling() -> void:
	if not rolling:
		rolling = true
		#TODO: play rolling animation

		if debug:
			print("Started Rolling")

func stop_rolling() -> void:
	if rolling:
		rolling = false
		#TODO: stop rolling animation
		#TODO: consider look_direction

		if debug:
			print("Stopped Rolling")

func die() -> void:
	is_active = false
	has_died.emit()

func _on_blast_refraction_timer_timeout() -> void:
	blast_refresh_disabled = false

func _on_enemy_body_entered(body: Node2D) -> void:
	if body is Player:
		die()

func _on_enemy_enemy_has_died() -> void:
	has_blast = true
	has_jump = true

func _input(event: InputEvent) -> void:
	if not is_active:
		return

	if event.is_action_pressed(&"click") and has_blast:
		charge_timer.start()

	if event.is_action_released(&"click") and has_blast:
		blast(get_global_mouse_position(), 2.0 - (charge_timer.time_left / 2))
		charge_timer.stop()

func _physics_process(delta: float) -> void:

	if not is_active:
		return

	# handle walking/countersteering
	var input_direction := Input.get_axis(&"left", &"right")
	walk(input_direction, delta)

	# apply gravity and vertical friction
	if not is_on_floor():
		if Input.is_action_just_pressed("down"):
			velocity.y = TERMINAL_SPEED

		var gravity = get_gravity()
		var ver_friction = gravity/TERMINAL_SPEED
		var current_velocity = velocity

		velocity += gravity * delta

		# TODO: replace with gravity only applying at < terminal_speed?
		velocity.y -= ver_friction.y * delta * current_velocity.y
	else:
		# ensures you cannot blast twice off the ground
		if not blast_refresh_disabled:
			has_blast = true
		has_jump = true

		if not input_direction:
			# apply horizontal friction
			if not rolling:
				velocity.x = lerp(velocity.x, 0.0, WALKING_FRICTION * delta)
			else:
				velocity.x = lerp(velocity.x, 0.0, ROLLING_FRICTION * delta)

	# handle jump
	if Input.is_action_just_pressed(&"jump") and has_jump:
		jump()

	move_and_slide()

	if blasting and get_slide_collision_count() != 0:
		start_rolling()
