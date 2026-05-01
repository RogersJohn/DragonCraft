extends RefCounted

const MAX_INVENTORY = 1

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


func add_item(item: Dictionary) -> bool:
	if inventory.size() >= MAX_INVENTORY:
		return false
	inventory.append(item.duplicate())
	return true


func remove_item(item_id: String) -> bool:
	for i in range(inventory.size()):
		if str(inventory[i].get("id", "")) == item_id:
			inventory.remove_at(i)
			return true
	return false


func has_item(item_id: String) -> bool:
	for item in inventory:
		if str(item.get("id", "")) == item_id:
			return true
	return false


func to_dict() -> Dictionary:
	return {
		"id": id,
		"name": name,
		"house_id": house_id,
		"role": role,
		"inventory": inventory.duplicate(true)
	}
