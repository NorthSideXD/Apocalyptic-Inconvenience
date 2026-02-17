class_name Interactable
extends StaticBody3D

@export var interaction_text := "Interact"

func get_interaction_text() -> String:
	return interaction_text

func interact(_player: CharacterBody3D) -> void:
	pass
