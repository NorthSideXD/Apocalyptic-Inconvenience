extends Interactable

@export var open_angle := -90.0
@export var open_speed := 5.0

var is_open := false
var target_angle := 0.0

func _ready() -> void:
	interaction_text = "Open"

func _process(delta: float) -> void:
	rotation_degrees.y = lerpf(rotation_degrees.y, target_angle, open_speed * delta)

func interact(_player: CharacterBody3D) -> void:
	is_open = !is_open
	target_angle = open_angle if is_open else 0.0
	interaction_text = "Close" if is_open else "Open"
