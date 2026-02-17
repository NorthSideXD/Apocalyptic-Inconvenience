extends Interactable

func _ready() -> void:
	interaction_text = "Use Cash Register"

func interact(_player: CharacterBody3D) -> void:
	print("Cash register opened!")
