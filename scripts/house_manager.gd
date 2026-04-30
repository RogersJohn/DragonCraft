extends Node

var _houses: Array = []
var _settler_food_cost: int = 20


func _ready() -> void:
	_load_data()


func _load_data() -> void:
	var fallback := {
		"houses": [
			{"id": 1, "name": "House 1", "capacity": 5, "occupants": 1},
			{"id": 2, "name": "House 2", "capacity": 5, "occupants": 1},
			{"id": 3, "name": "House 3", "capacity": 5, "occupants": 1},
			{"id": 4, "name": "House 4", "capacity": 5, "occupants": 1},
			{"id": 5, "name": "House 5", "capacity": 5, "occupants": 1}
		],
		"settler_food_cost": 20
	}
	if not FileAccess.file_exists("res://data/houses.json"):
		push_error("houses.json not found — using fallback house data")
		_apply_data(fallback)
		return
	var file := FileAccess.open("res://data/houses.json", FileAccess.READ)
	var text := file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(text)
	if parsed == null:
		push_error("houses.json failed to parse — using fallback house data")
		_apply_data(fallback)
		return
	_apply_data(parsed)


func _apply_data(data: Dictionary) -> void:
	_settler_food_cost = int(data["settler_food_cost"])
	_houses = data["houses"].duplicate(true)


func get_house(id: int) -> Dictionary:
	for h in _houses:
		if int(h["id"]) == id:
			return h
	return {}


func add_settler(house_id: int) -> bool:
	var h := get_house(house_id)
	if h.is_empty():
		return false
	if not SeasonManager.is_population_growth_allowed():
		return false
	if int(h["occupants"]) >= int(h["capacity"]):
		return false
	h["occupants"] = int(h["occupants"]) + 1
	return true


func get_total_population() -> int:
	var total := 0
	for h in _houses:
		total += int(h["occupants"])
	return total


func get_max_population() -> int:
	var total := 0
	for h in _houses:
		total += int(h["capacity"])
	return total


func get_settler_food_cost() -> int:
	return _settler_food_cost
