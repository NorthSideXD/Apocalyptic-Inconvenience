class_name PickupItem
extends RigidBody3D

@export var item_name := "Item"

func get_interaction_text() -> String:
	return "Pick up " + item_name

func interact(player: CharacterBody3D) -> void:
	player.pick_up(self)
