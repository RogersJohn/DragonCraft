extends RefCounted

var id: int
var name: String
var house_id: int
var role: String
var inventory: Array
var is_explorer: bool


func _init(p_id: int, p_name: String, p_house_id: int, p_role: String) -> void:
	id = p_id
	name = p_name
	house_id = p_house_id
	role = p_role
	inventory = []
	is_explorer = role == "explorer"


func to_dict() -> Dictionary:
	return {
		"id": id,
		"name": name,
		"house_id": house_id,
		"role": role,
		"inventory": inventory.duplicate()
	}
