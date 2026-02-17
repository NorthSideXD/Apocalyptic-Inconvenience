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

@export var step_height := 0.4

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var is_crouching := false
var head_bob_time := 0.0

@onready var head: Node3D = $Head
@onready var collision: CollisionShape3D = $CollisionShape3D
@onready var mesh: MeshInstance3D = $MeshInstance3D
@onready var interact_ray: RayCast3D = $Head/Camera3D/InteractRay
@onready var interact_prompt: Label = $InteractUI/InteractPrompt

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

	# Step-up using physics body test
	if is_on_floor() and direction:
		_try_step_up()

	move_and_slide()

	# Interaction
	_update_interaction()

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

func _update_interaction() -> void:
	var interactable := _get_interactable()
	if interactable:
		interact_prompt.text = "[E] " + interactable.get_interaction_text()
		if Input.is_action_just_pressed("interact"):
			interactable.interact(self)
	else:
		interact_prompt.text = ""

func _get_interactable() -> Interactable:
	if not interact_ray.is_colliding():
		return null
	var collider := interact_ray.get_collider()
	if collider is Interactable:
		return collider
	# Check parent — interactable script may be on the parent of a collision shape
	if collider and collider.get_parent() is Interactable:
		return collider.get_parent()
	return null

func _try_step_up() -> void:
	var horizontal_motion := Vector3(velocity.x, 0, velocity.z) * get_physics_process_delta_time()
	if horizontal_motion.length() < 0.001:
		return

	# 1) Can we move forward at current height? If yes, no step needed.
	var forward_test := KinematicCollision3D.new()
	if not test_move(global_transform, horizontal_motion, forward_test):
		return

	# 2) We're blocked. Try lifting up by step_height.
	var up_motion := Vector3(0, step_height, 0)
	if test_move(global_transform, up_motion):
		# Can't even move up (ceiling above), bail
		return

	# 3) From the raised position, try moving forward again
	var raised_transform := global_transform
	raised_transform.origin += up_motion
	if test_move(raised_transform, horizontal_motion):
		# Still blocked even after raising, it's a wall not a step
		return

	# 4) From raised+forward position, snap back down to find the step surface
	var raised_forward_transform := raised_transform
	raised_forward_transform.origin += horizontal_motion
	var down_test := KinematicCollision3D.new()
	var down_motion := Vector3(0, -step_height * 1.5, 0)

	if test_move(raised_forward_transform, down_motion, down_test):
		# Found ground - move player to the step surface
		var step_up_pos := raised_forward_transform.origin + down_motion.normalized() * down_test.get_travel().length()
		# Only step up, never step down with this system
		if step_up_pos.y > global_position.y + 0.01:
			global_position = step_up_pos
			velocity.y = 0.0
	else:
		# No ground found after raising, it's a ledge/gap - don't step
		pass
