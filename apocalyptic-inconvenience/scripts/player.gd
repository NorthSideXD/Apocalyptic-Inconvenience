extends CharacterBody3D

@export var move_speed := 4.0
@export var sprint_speed := 5.8
@export var crouch_speed := 2.0
@export var acceleration := 8.0
@export var deceleration := 10.0
@export var jump_velocity := 4.0
@export var mouse_sensitivity := 0.002

@export var stand_height := 1.8
@export var crouch_height := 1.0
@export var crouch_transition_speed := 8.0

@export var step_height := 0.45

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var is_crouching := false
var head_bob_time := 0.0

@onready var head: Node3D = $Head
@onready var collision: CollisionShape3D = $CollisionShape3D
@onready var mesh: MeshInstance3D = $MeshInstance3D
@onready var step_ahead_ray: RayCast3D = $StepAheadRay
@onready var step_height_ray: RayCast3D = $StepHeightRay

var _stand_head_y: float
var _crouch_head_y: float

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_stand_head_y = 1.6
	_crouch_head_y = 0.8

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		head.rotate_x(-event.relative.y * mouse_sensitivity)
		head.rotation.x = clampf(head.rotation.x, -PI / 2, PI / 2)

	if event.is_action_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
	# Gravity
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Jump
	if Input.is_action_just_pressed("ui_accept") and is_on_floor() and not is_crouching:
		velocity.y = jump_velocity

	# Crouch
	var wants_crouch := Input.is_action_pressed("crouch")
	if wants_crouch:
		is_crouching = true
	elif is_crouching:
		# Only uncrouch if there's room above
		is_crouching = false

	_update_crouch(delta)

	# Movement
	var target_speed: float
	if is_crouching:
		target_speed = crouch_speed
	elif Input.is_action_pressed("sprint"):
		target_speed = sprint_speed
	else:
		target_speed = move_speed

	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	var horizontal_vel := Vector3(velocity.x, 0, velocity.z)
	var target_vel := direction * target_speed

	if direction:
		horizontal_vel = horizontal_vel.lerp(target_vel, acceleration * delta)
	else:
		horizontal_vel = horizontal_vel.lerp(Vector3.ZERO, deceleration * delta)

	velocity.x = horizontal_vel.x
	velocity.z = horizontal_vel.z

	# Head bob while moving on ground
	if is_on_floor() and direction:
		var bob_speed := 10.0 if not is_crouching else 6.0
		head_bob_time += delta * bob_speed
		var bob_amount := 0.03 if not Input.is_action_pressed("sprint") else 0.04
		head.position.y = lerpf(head.position.y, _get_target_head_y() + sin(head_bob_time) * bob_amount, 10.0 * delta)
	else:
		head_bob_time = 0.0
		head.position.y = lerpf(head.position.y, _get_target_head_y(), 10.0 * delta)

	# Step-up: try to climb small ledges automatically
	if is_on_floor() and direction:
		_try_step_up(delta)

	move_and_slide()

func _update_crouch(delta: float) -> void:
	var target_height := crouch_height if is_crouching else stand_height
	var shape := collision.shape as CapsuleShape3D

	shape.height = lerpf(shape.height, target_height, crouch_transition_speed * delta)
	(mesh.mesh as CapsuleMesh).height = shape.height

	var half_h := shape.height / 2.0
	collision.position.y = half_h
	mesh.position.y = half_h

func _get_target_head_y() -> float:
	return _crouch_head_y if is_crouching else _stand_head_y

func _try_step_up(_delta: float) -> void:
	var move_dir := Vector3(velocity.x, 0, velocity.z).normalized()
	if move_dir.length() < 0.1:
		return

	# Point the ahead ray in the movement direction at ankle height
	step_ahead_ray.target_position = move_dir * 0.6
	step_ahead_ray.force_raycast_update()

	if not step_ahead_ray.is_colliding():
		return

	# Something is in front at ankle level, check if the top of it is within step height
	step_height_ray.global_position = global_position + move_dir * 0.6 + Vector3(0, step_height + 0.1, 0)
	step_height_ray.force_raycast_update()

	if step_height_ray.is_colliding():
		# There's still a wall above step height, can't step up
		return

	# Clear above the step, nudge the player up
	global_position.y += step_height
